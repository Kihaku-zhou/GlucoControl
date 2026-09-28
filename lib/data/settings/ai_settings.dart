import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_providers.dart';

/// AI 助手配置。
///
/// 是旧实现中散落在 `SharedPreferences` 里的 `ai_api_url` / `ai_api_key` /
/// `ai_model` / `ai_enabled` 四个键的类型化封装，键名保持不变以便沿用已有配置。
class AiSettings {
  /// 构造配置。
  const AiSettings({
    this.apiUrl = '',
    this.apiKey = '',
    this.model = 'MiniMax-Text-01',
    this.enabled = false,
  });

  /// 用户填写的接口地址。
  final String apiUrl;

  /// API Key。
  final String apiKey;

  /// 模型名。
  final String model;

  /// 是否启用 AI 功能。
  final bool enabled;

  /// 配置是否完整到可以发起请求。
  bool get isConfigured =>
      enabled && apiUrl.trim().isNotEmpty && apiKey.trim().isNotEmpty;

  /// 返回替换了部分字段的新配置。
  AiSettings copyWith({
    String? apiUrl,
    String? apiKey,
    String? model,
    bool? enabled,
  }) =>
      AiSettings(
        apiUrl: apiUrl ?? this.apiUrl,
        apiKey: apiKey ?? this.apiKey,
        model: model ?? this.model,
        enabled: enabled ?? this.enabled,
      );
}

/// AI 配置的读写。
class AiSettingsStore {
  /// 绑定已初始化的 [SharedPreferences]。
  const AiSettingsStore(this._preferences);

  final SharedPreferences _preferences;

  /// 读取配置。
  AiSettings read() => AiSettings(
        apiUrl: _preferences.getString(_keyApiUrl) ?? '',
        apiKey: _preferences.getString(_keyApiKey) ?? '',
        model: _preferences.getString(_keyModel) ?? 'MiniMax-Text-01',
        enabled: _preferences.getBool(_keyEnabled) ?? false,
      );

  /// 覆盖写入配置。
  Future<void> write(AiSettings settings) async {
    await _preferences.setString(_keyApiUrl, settings.apiUrl);
    await _preferences.setString(_keyApiKey, settings.apiKey);
    await _preferences.setString(_keyModel, settings.model);
    await _preferences.setBool(_keyEnabled, settings.enabled);
  }

  static const String _keyApiUrl = 'ai_api_url';
  static const String _keyApiKey = 'ai_api_key';
  static const String _keyModel = 'ai_model';
  static const String _keyEnabled = 'ai_enabled';
}

/// AI 配置的状态持有者。
///
/// 让依赖 AI 配置的 Provider（客户端、助手）在用户保存设置后自动重建，
/// 避免旧实现里「改了设置但服务仍是旧配置」的问题。
class AiSettingsNotifier extends Notifier<AiSettings> {
  @override
  AiSettings build() => _store.read();

  AiSettingsStore get _store =>
      AiSettingsStore(ref.read(sharedPreferencesProvider));

  /// 保存配置并刷新依赖方。
  Future<void> save(AiSettings settings) async {
    await _store.write(settings);
    state = settings;
  }
}

/// AI 配置 Provider。
final aiSettingsProvider =
    NotifierProvider<AiSettingsNotifier, AiSettings>(AiSettingsNotifier.new);
