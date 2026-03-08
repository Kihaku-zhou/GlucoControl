import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/database/database_providers.dart';

/// WebDAV 同步状态
enum WebDAVSyncState {
  idle,
  syncing,
  success,
  error,
}

/// WebDAV 同步状态 Provider
final webdavSyncStateProvider = StateProvider<WebDAVSyncState>((ref) => WebDAVSyncState.idle);

/// 最后同步时间 Provider
final lastSyncTimeProvider = StateProvider<DateTime?>((ref) => null);

/// WebDAV 配置
class WebDAVConfig {
  final String server;
  final String username;
  final String password;
  final bool enabled;

  WebDAVConfig({
    required this.server,
    required this.username,
    required this.password,
    required this.enabled,
  });

  factory WebDAVConfig.fromJson(Map<String, dynamic> json) {
    return WebDAVConfig(
      server: json['server'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      enabled: json['enabled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'server': server,
    'username': username,
    'password': password,
    'enabled': enabled,
  };
}

/// WebDAV 服务
class WebDAVService {
  static final WebDAVService _instance = WebDAVService._internal();
  factory WebDAVService() => _instance;
  WebDAVService._internal();

  Dio? _dio;
  // ignore: unused_field - 保留配置供后续使用
  WebDAVConfig? _config;

  /// 初始化 WebDAV 服务
  void init(WebDAVConfig config) {
    _config = config;
    debugPrint('WebDAV init - server: ${config.server}');
    
    // 确保服务器地址格式正确
    String server = config.server.trim();
    if (!server.endsWith('/')) {
      server += '/';
    }
    
    _dio = Dio(BaseOptions(
      baseUrl: server,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
    
    // 使用 Basic Auth
    _dio?.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final credentials = base64Encode(utf8.encode('${config.username}:${config.password}'));
        options.headers['Authorization'] = 'Basic $credentials';
        debugPrint('WebDAV request: ${options.method} ${options.path}');
        return handler.next(options);
      },
      onError: (error, handler) {
        debugPrint('WebDAV error: ${error.type} - ${error.message}');
        debugPrint('WebDAV response: ${error.response?.statusCode}');
        return handler.next(error);
      },
    ));
  }

  /// 测试连接
  Future<bool> testConnection() async {
    try {
      if (_dio == null) {
        debugPrint('WebDAV: _dio is null, not initialized');
        return false;
      }
      // 使用 PROPFIND 方法（标准 WebDAV 方法）
      final response = await _dio?.request(
        '/',
        options: Options(
          method: 'PROPFIND',
          headers: {
            'Depth': '0',
          },
        ),
      );
      // 207 Multi-Status 表示成功
      debugPrint('WebDAV test response: ${response?.statusCode}');
      return response?.statusCode == 207;
    } catch (e) {
      debugPrint('WebDAV 连接测试失败: $e');
      if (e is DioException) {
        debugPrint('DioError type: ${e.type}');
        debugPrint('DioError message: ${e.message}');
        debugPrint('DioError response: ${e.response?.statusCode}');
      }
      return false;
    }
  }

  /// 上传数据
  Future<bool> uploadData(String fileName, String content) async {
    try {
      if (_dio == null) {
        debugPrint('WebDAV: _dio is null, not initialized');
        return false;
      }
      
      // 确保目录存在
      await _ensureDirectory('/glucocontrol');

      debugPrint('WebDAV uploading: $fileName');
      final response = await _dio?.put(
        '/glucocontrol/$fileName',
        data: content,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      
      debugPrint('WebDAV upload response: ${response?.statusCode}');
      return response?.statusCode == 200 || response?.statusCode == 201;
    } catch (e) {
      debugPrint('WebDAV 上传失败: $e');
      if (e is DioException) {
        debugPrint('DioError: ${e.type} - ${e.message}');
      }
      return false;
    }
  }

  /// 下载数据
  Future<String?> downloadData(String fileName) async {
    try {
      final response = await _dio?.get(
        '/glucocontrol/$fileName',
        options: Options(
          responseType: ResponseType.plain,
        ),
      );
      
      if (response?.statusCode == 200) {
        return response?.data.toString();
      }
      return null;
    } catch (e) {
      debugPrint('WebDAV 下载失败: $e');
      return null;
    }
  }

  /// 列出文件
  Future<List<String>> listFiles() async {
    try {
      final response = await _dio?.request(
        '/glucocontrol/',
        options: Options(
          headers: {
            'Depth': '1',
          },
        ),
      );
      
      if (response?.statusCode == 207) {
        // 解析 WebDAV 响应，提取文件名
        final content = response?.data.toString();
        // 简单的解析，实际应该使用 webdav 库解析 XML
        final files = <String>[];
        final regex = RegExp(r'<d:href>([^<]+)</d:href>');
        final matches = regex.allMatches(content ?? '');
        for (final match in matches) {
          final path = match.group(1) ?? '';
          if (path.isNotEmpty && path != '/glucocontrol/') {
            files.add(path.split('/').last);
          }
        }
        return files;
      }
      return [];
    } catch (e) {
      debugPrint('WebDAV 列出文件失败: $e');
      return [];
    }
  }

  /// 删除文件
  Future<bool> deleteFile(String fileName) async {
    try {
      final response = await _dio?.delete('/glucocontrol/$fileName');
      return response?.statusCode == 200 || response?.statusCode == 204;
    } catch (e) {
      debugPrint('WebDAV 删除失败: $e');
      return false;
    }
  }

  /// 确保目录存在
  Future<void> _ensureDirectory(String path) async {
    try {
      // 使用 MKCOL 方法创建目录
      await _dio?.request(
        path,
        options: Options(
          method: 'MKCOL',
        ),
      );
      debugPrint('WebDAV created directory: $path');
    } catch (e) {
      // 目录可能已存在，忽略错误
      debugPrint('WebDAV directory may already exist: $path');
    }
  }

  /// 获取所有数据的 JSON
  Map<String, dynamic> exportAllData({
    required List<Map<String, dynamic>> bloodSugarRecords,
    required List<Map<String, dynamic>> exerciseRecords,
    required List<Map<String, dynamic>> mealRecords,
    Map<String, dynamic>? settings,
  }) {
    return {
      'version': '1.0',
      'exportTime': DateTime.now().toIso8601String(),
      'bloodSugarRecords': bloodSugarRecords,
      'exerciseRecords': exerciseRecords,
      'mealRecords': mealRecords,
      'settings': settings ?? {},
    };
  }
}

/// WebDAV 服务 Provider
final webdavServiceProvider = Provider<WebDAVService>((ref) {
  return WebDAVService();
});

/// 同步管理器
class SyncManager {
  final WebDAVService _webDAVService;
  final Ref _ref;

  SyncManager(this._webDAVService, this._ref);

  /// 执行完整同步
  Future<bool> syncAll() async {
    _ref.read(webdavSyncStateProvider.notifier).state = WebDAVSyncState.syncing;
    
    try {
      // 从数据库获取所有数据
      final db = _ref.read(databaseProvider);
      
      final bloodSugarRecords = await db.getAllBloodSugarRecords();
      final exerciseRecords = await db.getAllExerciseRecords();
      final mealRecords = await db.getAllMealRecords();

      // 转换为 Map 格式
      final bloodSugarData = bloodSugarRecords.map((r) => {
        'id': r.id,
        'value': r.value,
        'unit': r.unit,
        'type': r.type,
        'recordedAt': r.recordedAt.toIso8601String(),
        'hoursAfterMeal': r.hoursAfterMeal,
        'mealId': r.mealId,
        'note': r.note,
      }).toList();
      
      final exerciseData = exerciseRecords.map((r) => {
        'id': r.id,
        'type': r.type,
        'name': r.name,
        'duration': r.duration,
        'calories': r.calories,
        'heartRateAvg': r.heartRateAvg,
        'heartRateMax': r.heartRateMax,
        'startedAt': r.startedAt.toIso8601String(),
        'endedAt': r.endedAt.toIso8601String(),
        'note': r.note,
      }).toList();
      
      final mealData = mealRecords.map((r) => {
        'id': r.id,
        'type': r.type,
        'recordedAt': r.recordedAt.toIso8601String(),
        'imagePath': r.imagePath,
        'note': r.note,
      }).toList();

      // 获取设置数据（包括 AI API 配置）
      final prefs = await SharedPreferences.getInstance();
      final settings = <String, dynamic>{};
      
      // AI 相关设置
      settings['ai_enabled'] = prefs.getBool('ai_enabled');
      settings['ai_api_url'] = prefs.getString('ai_api_url');
      settings['ai_api_key'] = prefs.getString('ai_api_key');
      settings['ai_model'] = prefs.getString('ai_model');
      
      // 血糖目标设置
      settings['blood_sugar_min'] = prefs.getDouble('blood_sugar_min');
      settings['blood_sugar_max'] = prefs.getDouble('blood_sugar_max');
      settings['blood_sugar_target'] = prefs.getDouble('blood_sugar_target');
      
      // 运动目标设置
      settings['exercise_goal_minutes'] = prefs.getInt('exercise_goal_minutes');
      
      // 主题设置
      settings['theme_mode'] = prefs.getString('theme_mode');

      final data = _webDAVService.exportAllData(
        bloodSugarRecords: bloodSugarData,
        exerciseRecords: exerciseData,
        mealRecords: mealData,
        settings: settings,
      );

      final jsonStr = jsonEncode(data);
      final fileName = 'glucocontrol_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      
      final success = await _webDAVService.uploadData(fileName, jsonStr);
      
      if (success) {
        _ref.read(webdavSyncStateProvider.notifier).state = WebDAVSyncState.success;
        _ref.read(lastSyncTimeProvider.notifier).state = DateTime.now();
        return true;
      } else {
        _ref.read(webdavSyncStateProvider.notifier).state = WebDAVSyncState.error;
        return false;
      }
    } catch (e) {
      debugPrint('同步失败: $e');
      _ref.read(webdavSyncStateProvider.notifier).state = WebDAVSyncState.error;
      return false;
    }
  }

  /// 从云端恢复数据
  Future<Map<String, dynamic>?> restore() async {
    _ref.read(webdavSyncStateProvider.notifier).state = WebDAVSyncState.syncing;
    
    try {
      final files = await _webDAVService.listFiles();
      
      // 找到最新的备份文件
      files.sort((a, b) => b.compareTo(a)); // 降序排列
      
      if (files.isEmpty) {
        _ref.read(webdavSyncStateProvider.notifier).state = WebDAVSyncState.idle;
        return null;
      }

      final latestFile = files.first;
      final content = await _webDAVService.downloadData(latestFile);
      
      if (content != null) {
        _ref.read(webdavSyncStateProvider.notifier).state = WebDAVSyncState.success;
        return jsonDecode(content) as Map<String, dynamic>;
      } else {
        _ref.read(webdavSyncStateProvider.notifier).state = WebDAVSyncState.error;
        return null;
      }
    } catch (e) {
      debugPrint('恢复失败: $e');
      _ref.read(webdavSyncStateProvider.notifier).state = WebDAVSyncState.error;
      return null;
    }
  }
}

/// SyncManager Provider
final syncManagerProvider = Provider<SyncManager>((ref) {
  final webdavService = ref.watch(webdavServiceProvider);
  return SyncManager(webdavService, ref);
});
