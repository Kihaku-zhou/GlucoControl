import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/health/health_source.dart';

/// 外部数据源的连接参数。
///
/// 每个字段都是连接器取数所必需的，缺失时连接器应在
/// `checkAvailability` 阶段返回 [HealthSourceAvailability.unavailable]，
/// 而不是在取数中途失败。
class HealthSourceConfig {
  /// 构造配置。
  const HealthSourceConfig({
    this.baseUrl,
    this.apiKey,
    this.accessToken,
    this.clientId,
    this.clientSecret,
    this.extra = const <String, String>{},
  });

  /// 从持久化的 JSON 还原；缺少字段时取默认值。
  factory HealthSourceConfig.fromJson(Map<String, Object?> json) =>
      HealthSourceConfig(
        baseUrl: json['baseUrl'] as String?,
        apiKey: json['apiKey'] as String?,
        accessToken: json['accessToken'] as String?,
        clientId: json['clientId'] as String?,
        clientSecret: json['clientSecret'] as String?,
        extra: (json['extra'] as Map?)?.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            ) ??
            const <String, String>{},
      );

  /// 服务基址。
  final String? baseUrl;

  /// 长期 API Key。
  final String? apiKey;

  /// OAuth 访问令牌，可能短期有效。
  final String? accessToken;

  /// OAuth 客户端 ID。
  final String? clientId;

  /// OAuth 客户端密钥。
  final String? clientSecret;

  /// 连接器自定义的附加参数。
  final Map<String, String> extra;

  /// 是否一个字段都没有填写。
  ///
  /// 只含空白的字符串视为未填写：设置页把「已填写但全是空格」当成已配置，
  /// 会让用户在毫无提示的情况下永远取不到数。
  bool get isEmpty =>
      _isBlank(baseUrl) &&
      _isBlank(apiKey) &&
      _isBlank(accessToken) &&
      _isBlank(clientId) &&
      _isBlank(clientSecret) &&
      extra.isEmpty;

  /// 判断一个可选文本是否为空或只含空白。
  static bool _isBlank(String? value) => value == null || value.trim().isEmpty;

  /// 序列化为可持久化的 JSON。
  Map<String, Object?> toJson() => {
        if (baseUrl != null) 'baseUrl': baseUrl,
        if (apiKey != null) 'apiKey': apiKey,
        if (accessToken != null) 'accessToken': accessToken,
        if (clientId != null) 'clientId': clientId,
        if (clientSecret != null) 'clientSecret': clientSecret,
        if (extra.isNotEmpty) 'extra': extra,
      };

  /// 返回替换了部分字段的新配置。
  HealthSourceConfig copyWith({
    String? baseUrl,
    String? apiKey,
    String? accessToken,
    String? clientId,
    String? clientSecret,
    Map<String, String>? extra,
  }) =>
      HealthSourceConfig(
        baseUrl: baseUrl ?? this.baseUrl,
        apiKey: apiKey ?? this.apiKey,
        accessToken: accessToken ?? this.accessToken,
        clientId: clientId ?? this.clientId,
        clientSecret: clientSecret ?? this.clientSecret,
        extra: extra ?? this.extra,
      );
}

/// 各数据源连接参数的读写入口。
///
/// 配置存在 [SharedPreferences] 中，与既有 AI/WebDAV 配置保持一致。
/// **注意**：`SharedPreferences` 未加密，仅适用于本地个人使用的开发阶段；
/// 正式发布前应换用平台密钥库（例如 `flutter_secure_storage`），
/// 该替换只涉及本类的实现，不影响任何调用方。
class HealthConfigStore {
  /// 绑定到已初始化的 [SharedPreferences]。
  const HealthConfigStore(this._preferences);

  final SharedPreferences _preferences;

  /// 存储键前缀，避免与既有 AI/WebDAV 配置冲突。
  static const String _prefix = 'health_source_config_';

  /// 读取指定数据源的配置；未配置时返回空配置。
  HealthSourceConfig read(HealthSourceId source) {
    final raw = _preferences.getString('$_prefix${source.code}');
    if (raw == null || raw.isEmpty) return const HealthSourceConfig();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return HealthSourceConfig.fromJson(
          decoded.map((key, value) => MapEntry(key.toString(), value)),
        );
      }
    } on FormatException {
      // 手工改库或旧版本写入的非法 JSON；按未配置处理，用户重填即可。
    }
    return const HealthSourceConfig();
  }

  /// 覆盖写入指定数据源的配置。
  Future<void> write(HealthSourceId source, HealthSourceConfig config) =>
      _preferences.setString('$_prefix${source.code}', jsonEncode(config.toJson()));

  /// 清除指定数据源的配置（撤销授权或断开连接时使用）。
  Future<void> clear(HealthSourceId source) =>
      _preferences.remove('$_prefix${source.code}');
}
