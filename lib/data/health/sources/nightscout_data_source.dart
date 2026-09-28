import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import '../../../core/glucose_units.dart';
import '../../../core/result.dart';
import '../../../domain/health/health_data_source.dart';
import '../../../domain/health/health_records.dart';
import '../../../domain/health/health_source.dart';
import '../health_source_config.dart';

/// Nightscout 连接器：读取自建 CGM 服务上的血糖条目。
///
/// 硅基轻享没有公开 API，社区通行做法是用 Juggluco 直读传感器后推送到
/// Nightscout。本连接器以**只读**方式拉取 `GET /api/v1/entries.json`，
/// 从而在不收集任何第三方账号密码的前提下拿到 CGM 数据。
///
/// 鉴权支持两种 Nightscout 部署方式：把 API secret 经 SHA-1 后作为 `api-secret`
/// 请求头（默认），或直接使用只读 `token` 查询参数。
class NightscoutDataSource implements HealthDataSource {
  /// 构造连接器。
  NightscoutDataSource({required HealthSourceConfig config, Dio? dio})
      : _config = config,
        _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 60),
              validateStatus: (_) => true,
            ));

  /// 单次请求最多拉取的条目数。Nightscout 默认只返回 10 条，必须显式放大。
  static const int defaultCount = 2000;

  final HealthSourceConfig _config;
  final Dio _dio;

  @override
  HealthSourceId get id => HealthSourceId.nightscout;

  @override
  bool get supportsAutomaticSync => true;

  /// 去掉尾部斜杠的基址；未配置时返回空串。
  String get _baseUrl {
    final configured = _config.baseUrl?.trim() ?? '';
    if (configured.isEmpty) return '';
    return configured.endsWith('/')
        ? configured.substring(0, configured.length - 1)
        : configured;
  }

  @override
  Future<Result<HealthSourceAvailability>> checkAvailability() async {
    if (_baseUrl.isEmpty) {
      return const Ok(HealthSourceAvailability.needsAuthorization(
        '需要填写 Nightscout 站点地址，例如 https://your-site.example.com',
      ));
    }
    final hasSecret = (_config.accessToken ?? '').isNotEmpty;
    final hasToken = (_config.extra['token'] ?? '').isNotEmpty;
    if (!hasSecret && !hasToken) {
      return const Ok(HealthSourceAvailability.needsAuthorization(
        '需要填写 Nightscout 的 API secret 或只读 token',
      ));
    }
    return const Ok(HealthSourceAvailability.ready());
  }

  @override
  Future<Result<HealthSourceAvailability>> authorize() => checkAvailability();

  @override
  Future<Result<HealthFetchResult>> fetch(HealthFetchWindow window) async {
    final baseUrl = _baseUrl;
    if (baseUrl.isEmpty) {
      return const Err(AppFailure(
        kind: FailureKind.configuration,
        message: '未配置 Nightscout 站点地址',
        code: 'nightscout.missing_url',
      ));
    }

    try {
      final response = await _dio.get<Object?>(
        '$baseUrl/api/v1/entries.json',
        queryParameters: <String, Object?>{
          'find[date][\$gte]': window.start.millisecondsSinceEpoch,
          'count': defaultCount,
          if ((_config.extra['token'] ?? '').isNotEmpty)
            'token': _config.extra['token'],
        },
        options: Options(
          headers: <String, String>{
            ..._authorizationHeaders(),
            'Accept': 'application/json',
          },
          responseType: ResponseType.json,
        ),
      );

      final failure = _classifyError(response);
      if (failure != null) return Err(failure);

      final samples = <HealthSample>[];
      final warnings = <String>[];
      for (final entry in entriesOf(response.data)) {
        final sample = parseEntry(entry);
        if (sample != null) {
          samples.add(sample);
        } else {
          warnings.add('有 1 条 Nightscout 条目缺少血糖值，已跳过');
        }
      }
      return Ok(HealthFetchResult(samples: samples, warnings: warnings));
    } on DioException catch (error) {
      return Err(AppFailure(
        kind: FailureKind.network,
        message: '读取 Nightscout 失败：${error.message ?? error.type.name}',
        code: 'nightscout.network',
        cause: error,
      ));
    }
  }

  /// 构造鉴权请求头。缺少 secret 时返回只带 `Accept` 的头，由 token 查询参数兜底。
  Map<String, String> _authorizationHeaders() {
    final secret = _config.accessToken?.trim() ?? '';
    if (secret.isEmpty) return const <String, String>{};
    // Nightscout 约定：api-secret 头为 API secret 的 SHA-1 十六进制摘要。
    final digest = sha1.convert(utf8.encode(secret)).toString();
    return <String, String>{'api-secret': digest};
  }

  /// 识别 Nightscout 返回的错误；无错误时返回 null。
  AppFailure? _classifyError(Response<Object?> response) {
    final status = response.statusCode ?? 0;
    if (status == 401 || status == 403) {
      return const AppFailure(
        kind: FailureKind.authentication,
        message: 'Nightscout 拒绝了鉴权，请检查 API secret 或 token',
        code: 'nightscout.unauthorized',
      );
    }
    if (status == 404) {
      return const AppFailure(
        kind: FailureKind.configuration,
        message: 'Nightscout 站点地址不正确，或该实例未启用 API',
        code: 'nightscout.not_found',
      );
    }
    if (status >= 500) {
      return AppFailure(
        kind: FailureKind.network,
        message: 'Nightscout 服务端错误（HTTP $status）',
        code: 'nightscout.server_error',
      );
    }
    if (status < 200 || status >= 300) {
      return AppFailure(
        kind: FailureKind.unknown,
        message: 'Nightscout 返回 HTTP $status',
        code: 'nightscout.http_error',
      );
    }
    return null;
  }

  /// 从响应体中取出条目数组。
  ///
  /// Nightscout 正常返回顶层数组；鉴权失败等异常会被包装成对象。
  static List<Map<String, Object?>> entriesOf(Object? data) {
    if (data is List) {
      return data.whereType<Map>().map(_stringKeyed).toList();
    }
    if (data is String) {
      final decoded = jsonDecode(data);
      return entriesOf(decoded);
    }
    return const <Map<String, Object?>>[];
  }

  /// 把一条 Nightscout 条目归一化为血糖样本；缺少血糖值时返回 null。
  ///
  /// `sgv`/`mbg` 的单位是 mg/dL（Nightscout 内部约定），这里统一换算为 mmol/L。
  static HealthSample? parseEntry(Map<String, Object?> entry) {
    final mgPerDl = _readDouble(entry, const ['sgv', 'mbg', 'glucose']);
    if (mgPerDl == null || mgPerDl <= 0) return null;

    final recordedAt = _readDateTime(entry) ?? DateTime.now();
    final isManual = entry['type'] == 'mbg';
    final reading = GlucoseReading(
      source: HealthSourceId.nightscout,
      externalId: _externalIdOf(entry, recordedAt),
      recordedAt: recordedAt,
      mmolPerL: toMmolPerL(mgPerDl, GlucoseUnit.mgPerDl),
      context: isManual ? GlucoseContext.random : GlucoseContext.continuous,
      trend: _trendOf(entry['direction']),
    );
    final sample = reading.toSample();
    return HealthSample(
      source: sample.source,
      kind: sample.kind,
      externalId: sample.externalId,
      startAt: sample.startAt,
      title: sample.title,
      originApp: sample.originApp,
      // 保留原始 mg/dL 与设备名，便于回溯与设备维度的分析。
      payload: <String, Object?>{
        ...sample.payload,
        'mgPerDl': mgPerDl,
        if (entry['device'] is String) 'device': entry['device'],
      },
    );
  }

  /// 幂等键：优先用 Nightscout 的 `_id`，缺失时用时间戳兜底。
  static String _externalIdOf(Map<String, Object?> entry, DateTime recordedAt) {
    final id = entry['_id'];
    if (id is String && id.isNotEmpty) return 'nightscout:$id';
    return 'nightscout:${recordedAt.millisecondsSinceEpoch}';
  }

  /// 把 Nightscout 的 `direction` 映射为归一化趋势。
  static GlucoseTrend? _trendOf(Object? direction) {
    if (direction is! String) return null;
    return switch (direction.trim()) {
      'DoubleUp' => GlucoseTrend.risingFast,
      'SingleUp' || 'FortyFiveUp' => GlucoseTrend.rising,
      'Flat' => GlucoseTrend.steady,
      'FortyFiveDown' || 'SingleDown' => GlucoseTrend.falling,
      'DoubleDown' => GlucoseTrend.fallingFast,
      _ => null,
    };
  }

  /// 读取时间：优先 `date`（epoch 毫秒），其次 `dateString`（ISO）。
  static DateTime? _readDateTime(Map<String, Object?> entry) {
    final epoch = entry['date'];
    if (epoch is num) {
      final millis = epoch > 100000000000 ? epoch.toInt() : epoch.toInt() * 1000;
      return DateTime.fromMillisecondsSinceEpoch(millis);
    }
    final text = entry['dateString'];
    if (text is String) return DateTime.tryParse(text);
    return null;
  }

  /// 按候选键顺序读取浮点数。
  static double? _readDouble(Map<String, Object?> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  /// 把 Map 的键统一为 String。
  static Map<String, Object?> _stringKeyed(Map<Object?, Object?> source) =>
      source.map((key, value) => MapEntry(key.toString(), value));
}
