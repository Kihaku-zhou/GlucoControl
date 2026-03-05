import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// AI 配置
class AIConfig {
  final String apiUrl;
  final String apiKey;
  final String model;
  final bool enabled;

  AIConfig({
    required this.apiUrl,
    required this.apiKey,
    required this.model,
    required this.enabled,
  });

  factory AIConfig.fromJson(Map<String, dynamic> json) {
    return AIConfig(
      apiUrl: json['apiUrl'] ?? 'https://api.openai.com/v1/chat/completions',
      apiKey: json['apiKey'] ?? '',
      model: json['model'] ?? 'gpt-3.5-turbo',
      enabled: json['enabled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'apiUrl': apiUrl,
    'apiKey': apiKey,
    'model': model,
    'enabled': enabled,
  };
}

/// AI 分析结果
class AIAnalysisResult {
  final String summary;
  final List<String> suggestions;
  final Map<String, dynamic> analysis;
  final DateTime analyzedAt;

  AIAnalysisResult({
    required this.summary,
    required this.suggestions,
    required this.analysis,
    required this.analyzedAt,
  });
}

/// AI 分析服务
class AIAnalysisService {
  static final AIAnalysisService _instance = AIAnalysisService._internal();
  factory AIAnalysisService() => _instance;
  AIAnalysisService._internal();

  Dio? _dio;
  AIConfig? _config;

  /// 初始化 AI 服务
  void init(AIConfig config) {
    _config = config;
    _dio = Dio(BaseOptions(
      baseUrl: config.apiUrl.contains('v1/chat/completions') 
          ? config.apiUrl.replaceAll('/v1/chat/completions', '')
          : config.apiUrl,
      headers: {
        'Authorization': 'Bearer ${config.apiKey}',
        'Content-Type': 'application/json',
      },
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
    ));
  }

  /// 检查是否已初始化
  bool get isInitialized => _dio != null && _config != null && _config!.enabled;

  /// 测试 API 连接
  Future<bool> testConnection() async {
    if (!isInitialized) return false;
    
    try {
      final response = await _dio?.post(
        '/v1/models',
      );
      return response?.statusCode == 200;
    } catch (e) {
      debugPrint('AI API 测试失败: $e');
      return false;
    }
  }

  /// 分析血糖趋势
  Future<AIAnalysisResult?> analyzeBloodSugarTrend({
    required List<Map<String, dynamic>> bloodSugarRecords,
    required List<Map<String, dynamic>> exerciseRecords,
    required List<Map<String, dynamic>> mealRecords,
  }) async {
    if (!isInitialized) return null;

    try {
      // 构建提示词
      final prompt = _buildAnalysisPrompt(
        bloodSugarRecords: bloodSugarRecords,
        exerciseRecords: exerciseRecords,
        mealRecords: mealRecords,
      );

      final response = await _dio?.post(
        '/v1/chat/completions',
        data: {
          'model': _config!.model,
          'messages': [
            {
              'role': 'system',
              'content': '你是一位专业的糖尿病健康管理助手，擅长分析血糖数据、饮食和运动的关系，并给出科学的建议。请用中文回复。'
            },
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.7,
          'max_tokens': 1000,
        },
      );

      if (response?.statusCode == 200) {
        final content = response?.data['choices'][0]['message']['content'] as String;
        return _parseAnalysisResult(content);
      }
      return null;
    } catch (e) {
      debugPrint('AI 分析失败: $e');
      return null;
    }
  }

  /// 构建分析提示词
  String _buildAnalysisPrompt({
    required List<Map<String, dynamic>> bloodSugarRecords,
    required List<Map<String, dynamic>> exerciseRecords,
    required List<Map<String, dynamic>> mealRecords,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('请分析以下血糖数据、饮食记录和运动记录，并给出专业的健康建议。');
    buffer.writeln();
    
    // 血糖数据
    buffer.writeln('## 血糖记录 (${bloodSugarRecords.length} 条)');
    if (bloodSugarRecords.isNotEmpty) {
      for (final record in bloodSugarRecords.take(20)) {
        buffer.writeln('- 时间: ${record['recordedAt']}, '
            '血糖: ${record['value']} ${record['unit']}, '
            '类型: ${record['type']}');
      }
    }
    buffer.writeln();
    
    // 运动数据
    buffer.writeln('## 运动记录 (${exerciseRecords.length} 条)');
    if (exerciseRecords.isNotEmpty) {
      for (final record in exerciseRecords.take(10)) {
        buffer.writeln('- 时间: ${record['startedAt']}, '
            '类型: ${record['type']}, '
            '时长: ${record['duration']}分钟, '
            '消耗: ${record['calories']}kcal');
      }
    }
    buffer.writeln();
    
    // 饮食数据
    buffer.writeln('## 饮食记录 (${mealRecords.length} 条)');
    if (mealRecords.isNotEmpty) {
      for (final record in mealRecords.take(10)) {
        buffer.writeln('- 时间: ${record['recordedAt']}, '
            '类型: ${record['type']}');
      }
    }
    buffer.writeln();
    
    buffer.writeln('请分析以上数据，给出：');
    buffer.writeln('1. 血糖趋势总结');
    buffer.writeln('2. 饮食和运动对血糖的影响分析');
    buffer.writeln('3. 具体的改进建议');
    
    return buffer.toString();
  }

  /// 解析分析结果
  AIAnalysisResult _parseAnalysisResult(String content) {
    // 简单解析，实际应该更复杂
    final lines = content.split('\n');
    final suggestions = <String>[];
    String summary = content;
    
    // 提取建议
    for (final line in lines) {
      if (line.contains('建议') || line.contains('注意')) {
        suggestions.add(line.trim());
      }
    }
    
    return AIAnalysisResult(
      summary: summary,
      suggestions: suggestions,
      analysis: {},
      analyzedAt: DateTime.now(),
    );
  }

  /// 生成每日健康报告
  Future<String?> generateDailyReport({
    required double avgBloodSugar,
    required int exerciseMinutes,
    required double totalCarbs,
    required int caloriesBurned,
  }) async {
    if (!isInitialized) return null;

    try {
      final prompt = '''
请生成一份简洁的每日健康报告，包含：
- 今日血糖平均值: $avgBloodSugar mg/dL
- 运动时长: $exerciseMinutes 分钟
- 碳水摄入: ${totalCarbs}g
- 消耗卡路里: $caloriesBurned kcal

请用 2-3 句话总结今日健康状况，并给出 1 条建议。
''';

      final response = await _dio?.post(
        '/v1/chat/completions',
        data: {
          'model': _config!.model,
          'messages': [
            {
              'role': 'system',
              'content': '你是健康助手，请用中文生成简洁的每日报告。'
            },
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.7,
          'max_tokens': 200,
        },
      );

      if (response?.statusCode == 200) {
        return response?.data['choices'][0]['message']['content'] as String;
      }
      return null;
    } catch (e) {
      debugPrint('生成报告失败: $e');
      return null;
    }
  }
}

/// AI 分析服务 Provider
final aiAnalysisServiceProvider = Provider<AIAnalysisService>((ref) {
  return AIAnalysisService();
});

/// AI 分析结果 Provider
final aiAnalysisResultProvider = StateProvider<AIAnalysisResult?>((ref) => null);

/// 每日报告 Provider
final dailyReportProvider = StateProvider<String?>((ref) => null);
