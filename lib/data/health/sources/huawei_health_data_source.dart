import 'package:dio/dio.dart';

import '../../../core/glucose_units.dart';
import '../../../core/result.dart';
import '../../../domain/health/health_data_source.dart';
import '../../../domain/health/health_records.dart';
import '../../../domain/health/health_source.dart';
import '../health_source_config.dart';

/// 华为运动健康（Health Service Kit 云侧数据开放）连接器。
///
/// ## 使用前提
///
/// 华为的开放数据需要先在**华为开发者联盟申请「运动健康」应用并通过资质审核**，
/// 审批通过后才拿到 `client_id` / `client_secret` 与可用数据范围。访问令牌走
/// 标准 OAuth 2.0 授权码流程：
///
/// * 授权页 `https://oauth-login.cloud.huawei.com/oauth2/v3/authorize`
/// * 换取/刷新令牌 `POST https://oauth-login.cloud.huawei.com/oauth2/v3/token`
///   （`grant_type=authorization_code` 或 `refresh_token`，表单编码）
///
/// 这两条端点来自华为官方示例
/// （https://developer.huawei.com/consumer/en/doc/HMSCore-Guides/auth-example-0000001054581058
/// 的复述）。**数据侧路径不在本连接器内硬编码**：华为云侧各数据类型的 REST 路径
/// 随审核通过的范围与版本变化，且本仓库未能在无凭据条件下逐条核实，因此改由
/// [HealthSourceConfig.baseUrl] 与 [HealthSourceConfig.extra] 提供，避免写出看似
/// 可用实则错误的地址。
///
/// ## 与 Health Connect 的关系
///
/// 华为运动健康**不向 Android Health Connect 写入数据**，因此无法通过
/// [HealthSourceId.healthConnect] 拿到华为的数据；反过来，华为手环/手表可以用
/// Gadgetbridge 免官方 App 直连后再写入 Health Connect，那是不需要审核的替代通路。
/// 详见 `docs/DATA_SOURCES.md`。
class HuaweiHealthDataSource implements HealthDataSource {
  /// 构造连接器。
  HuaweiHealthDataSource({required HealthSourceConfig config, Dio? dio})
      : _config = config,
        _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 60),
              validateStatus: (_) => true,
            ));

  /// 华为 OAuth 2.0 令牌端点。
  static const String tokenUrl =
      'https://oauth-login.cloud.huawei.com/oauth2/v3/token';

  /// 华为 OAuth 2.0 授权页。
  static const String authorizeUrl =
      'https://oauth-login.cloud.huawei.com/oauth2/v3/authorize';

  /// 授权码回调地址在配置中的键名。
  static const String redirectUriKey = 'redirectUri';

  /// 数据路径在配置中的键名前缀，形如 `path.steps`、`path.glucose`。
  static const String pathKeyPrefix = 'path.';

  final HealthSourceConfig _config;
  final Dio _dio;

  @override
  HealthSourceId get id => HealthSourceId.huaweiHealth;

  @override
  bool get supportsAutomaticSync => true;

  @override
  Future<Result<HealthSourceAvailability>> checkAvailability() async {
    if ((_config.clientId ?? '').trim().isEmpty ||
        ((_config.clientSecret ?? '').trim().isEmpty &&
            (_config.accessToken ?? '').trim().isEmpty)) {
      return const Ok(HealthSourceAvailability.needsAuthorization(
        '需要先通过华为开发者联盟的「运动健康」资质审核，并填入 client_id 与 client_secret',
      ));
    }
    if ((_config.baseUrl ?? '').trim().isEmpty) {
      return const Ok(HealthSourceAvailability.needsAuthorization(
        '已配置凭据，但还缺少云侧数据接口地址（见 docs/DATA_SOURCES.md）',
      ));
    }
    if ((_config.accessToken ?? '').trim().isEmpty) {
      return const Ok(HealthSourceAvailability.needsAuthorization(
        '凭据已就绪，但尚未完成 OAuth 授权以取得 access_token',
      ));
    }
    return const Ok(HealthSourceAvailability.ready());
  }

  @override
  Future<Result<HealthSourceAvailability>> authorize() async {
    if ((_config.accessToken ?? '').trim().isEmpty) {
      return const Ok(HealthSourceAvailability.needsAuthorization(
        '华为要求用户在浏览器中完成授权码流程，请先在设置页填入 access_token',
      ));
    }
    return checkAvailability();
  }

  /// 用授权码换取访问令牌与刷新令牌。
  ///
  /// 调用方负责把返回的令牌写回 [HealthConfigStore]；本方法不做持久化，
  /// 以便在测试中直接验证请求体与响应解析。
  Future<Result<HuaweiTokenSet>> exchangeAuthorizationCode({
    required String code,
  }) =>
      _requestToken(<String, String>{
        'grant_type': 'authorization_code',
        'code': code,
        'client_id': _config.clientId ?? '',
        'client_secret': _config.clientSecret ?? '',
        if ((_config.extra[redirectUriKey] ?? '').isNotEmpty)
          'redirect_uri': _config.extra[redirectUriKey]!,
      });

  /// 用刷新令牌换取新的访问令牌。
  Future<Result<HuaweiTokenSet>> refreshAccessToken({
    required String refreshToken,
  }) =>
      _requestToken(<String, String>{
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'client_id': _config.clientId ?? '',
        'client_secret': _config.clientSecret ?? '',
      });

  /// 提交 OAuth 令牌请求并解析结果。
  Future<Result<HuaweiTokenSet>> _requestToken(
      Map<String, String> form) async {
    try {
      final response = await _dio.post<Object?>(
        tokenUrl,
        data: form,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          responseType: ResponseType.json,
        ),
      );
      final status = response.statusCode ?? 0;
      final data = response.data;
      if (status < 200 || status >= 300 || data is! Map) {
        return Err(AppFailure(
          kind: status == 400 || status == 401
              ? FailureKind.authentication
              : FailureKind.network,
          message: '华为令牌请求失败（HTTP $status）',
          code: 'huawei.token_failed',
        ));
      }
      final map = data.map((key, value) => MapEntry(key.toString(), value));
      final accessToken = map['access_token'];
      if (accessToken is! String || accessToken.isEmpty) {
        return const Err(AppFailure(
          kind: FailureKind.authentication,
          message: '华为返回的令牌响应缺少 access_token',
          code: 'huawei.malformed_token',
        ));
      }
      final refresh = map['refresh_token'];
      final expiresIn = map['expires_in'];
      return Ok(HuaweiTokenSet(
        accessToken: accessToken,
        refreshToken: refresh is String ? refresh : null,
        expiresAt: expiresIn is num
            ? DateTime.now().add(Duration(seconds: expiresIn.toInt()))
            : null,
      ));
    } on DioException catch (error) {
      return Err(AppFailure(
        kind: FailureKind.network,
        message: '请求华为令牌失败：${error.message ?? error.type.name}',
        code: 'huawei.token_network',
        cause: error,
      ));
    }
  }

  @override
  Future<Result<HealthFetchResult>> fetch(HealthFetchWindow window) async {
    final baseUrl = (_config.baseUrl ?? '').trim();
    final accessToken = (_config.accessToken ?? '').trim();
    if (baseUrl.isEmpty || accessToken.isEmpty) {
      final availability = await checkAvailability();
      return Err(AppFailure(
        kind: FailureKind.configuration,
        message: availability.valueOrNull?.hint ?? '华为健康数据源尚未配置完成',
        code: 'huawei.not_configured',
      ));
    }

    final samples = <HealthSample>[];
    final warnings = <String>[];

    for (final entry in _configuredPaths().entries) {
      final outcome =
          await _fetchPath(entry.key, entry.value, window, accessToken);
      switch (outcome) {
        case Ok(:final value):
          samples.addAll(value);
        case Err(:final failure):
          // 单个数据类型未获批或被拒不应中断其余类型，但要在结果里说明。
          warnings.add('${entry.key} 拉取失败：${failure.message}');
      }
    }

    return Ok(HealthFetchResult(samples: samples, warnings: warnings));
  }

  /// 读取配置中声明的数据路径。
  Map<String, String> _configuredPaths() => <String, String>{
        for (final entry in _config.extra.entries)
          if (entry.key.startsWith(pathKeyPrefix) &&
              entry.key.length > pathKeyPrefix.length &&
              entry.value.trim().isNotEmpty)
            entry.key.substring(pathKeyPrefix.length): entry.value.trim(),
      };

  /// 拉取单个数据路径并把记录按数据类别归一化。
  Future<Result<List<HealthSample>>> _fetchPath(
    String dataType,
    String path,
    HealthFetchWindow window,
    String accessToken,
  ) async {
    final baseUrl = (_config.baseUrl ?? '').trim();
    final url = path.startsWith('http')
        ? path
        : '${baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl}'
            '${path.startsWith('/') ? path : '/$path'}';

    try {
      final response = await _dio.get<Object?>(
        url,
        queryParameters: <String, Object?>{
          'startTime': window.start.millisecondsSinceEpoch,
          'endTime': window.end.millisecondsSinceEpoch,
        },
        options: Options(
          headers: <String, String>{
            'Authorization': 'Bearer $accessToken',
            'x-client-id': _config.clientId ?? '',
            'Accept': 'application/json',
          },
          responseType: ResponseType.json,
        ),
      );

      final status = response.statusCode ?? 0;
      if (status == 401 || status == 403) {
        return Err(AppFailure(
          kind: FailureKind.authentication,
          message: '华为拒绝了访问（HTTP $status），可能是数据范围未获批或令牌过期',
          code: 'huawei.unauthorized',
        ));
      }
      if (status < 200 || status >= 300) {
        return Err(AppFailure(
          kind: status >= 500 ? FailureKind.network : FailureKind.unknown,
          message: '华为数据接口返回 HTTP $status',
          code: 'huawei.http_error',
        ));
      }

      return Ok(_mapRecords(dataType, response.data));
    } on DioException catch (error) {
      return Err(AppFailure(
        kind: FailureKind.network,
        message: '访问华为数据接口失败：${error.message ?? error.type.name}',
        code: 'huawei.network',
        cause: error,
      ));
    }
  }

  /// 把华为返回的记录数组按数据类别归一化。
  ///
  /// 华为各数据类型的字段名随接口版本变化，这里按类别做容错取值；无法识别的
  /// 记录会被跳过而不是抛异常，同时把原始对象保留在载荷中以便后续修正映射。
  static List<HealthSample> _mapRecords(String dataType, Object? data) {
    final records = _recordsOf(data);
    final samples = <HealthSample>[];
    final normalized = dataType.toLowerCase();

    for (final record in records) {
      switch (normalized) {
        case 'glucose':
        case 'bloodglucose':
        case 'blood_glucose':
          final mmol = _readDouble(record, const ['mmolPerL', 'mmol', 'value']);
          final mgDl = _readDouble(record, const ['mgPerDl', 'mgdl']);
          final level = mmol ?? (mgDl == null ? null : toMmolPerL(mgDl, GlucoseUnit.mgPerDl));
          if (level == null) continue;
          final reading = GlucoseReading(
            source: HealthSourceId.huaweiHealth,
            externalId: 'huawei:$dataType:${_idOf(record)}',
            recordedAt: _timeOf(record),
            mmolPerL: level,
            context: GlucoseContext.continuous,
          );
          samples.add(_withRaw(reading.toSample(), record));
        case 'workout':
        case 'exercise':
        case 'activity':
          final startedAt = _timeOf(record);
          final endAt = _readDateTime(record, const ['endTime', 'end_time']) ??
              startedAt.add(Duration(
                  seconds: _readInt(record, const ['duration', 'durationSeconds']) ??
                      3600));
          final session = WorkoutSession(
            source: HealthSourceId.huaweiHealth,
            externalId: 'huawei:$dataType:${_idOf(record)}',
            startedAt: startedAt,
            endedAt: endAt,
            category: WorkoutCategory.other,
            name: _readString(record, const ['activityName', 'name', 'type']) ??
                '华为运动记录',
            distanceKm:
                _distanceKm(record, const ['distance', 'totalDistance']),
            calories: _readInt(record, const ['calories', 'totalCalories']),
            avgHeartRate:
                _readInt(record, const ['avgHeartRate', 'averageHeartRate']),
            maxHeartRate:
                _readInt(record, const ['maxHeartRate', 'maximumHeartRate']),
          );
          samples.add(_withRaw(session.toSample(), record));
        case 'sleep':
          final startedAt = _timeOf(record);
          final endAt =
              _readDateTime(record, const ['endTime', 'end_time', 'wakeTime']);
          if (endAt == null || !endAt.isAfter(startedAt)) continue;
          samples.add(_withRaw(
            SleepSession(
              source: HealthSourceId.huaweiHealth,
              externalId: 'huawei:$dataType:${_idOf(record)}',
              startedAt: startedAt,
              endedAt: endAt,
              deepMinutes: _readInt(record, const ['deepSleepTime', 'deepMinutes']),
              lightMinutes:
                  _readInt(record, const ['lightSleepTime', 'lightMinutes']),
              remMinutes: _readInt(record, const ['remSleepTime', 'remMinutes']),
              awakeMinutes:
                  _readInt(record, const ['awakeTime', 'awakeMinutes']),
            ).toSample(),
            record,
          ));
        case 'steps':
        case 'daily':
        case 'dailyactivity':
          final date = _timeOf(record);
          samples.add(_withRaw(
            DailyActivity(
              source: HealthSourceId.huaweiHealth,
              externalId: 'huawei:$dataType:${_idOf(record)}',
              date: DateTime(date.year, date.month, date.day),
              steps: _readInt(record, const ['steps', 'stepCount']),
              activeCalories: _readInt(record, const ['calories', 'activeCalories']),
              restingHeartRate:
                  _readInt(record, const ['restingHeartRate', 'restHeartRate']),
            ).toSample(),
            record,
          ));
        default:
          continue;
      }
    }
    return samples;
  }

  /// 把原始记录附加到样本载荷，便于上游字段变化后回溯。
  static HealthSample _withRaw(HealthSample sample, Map<String, Object?> raw) =>
      HealthSample(
        source: sample.source,
        kind: sample.kind,
        externalId: sample.externalId,
        startAt: sample.startAt,
        endAt: sample.endAt,
        title: sample.title,
        originApp: sample.originApp,
        payload: <String, Object?>{...sample.payload, 'raw': raw},
      );

  /// 从多种可能的响应包装中取出记录数组。
  static List<Map<String, Object?>> _recordsOf(Object? data) {
    if (data is List) {
      return data.whereType<Map>().map(_stringKeyed).toList();
    }
    if (data is Map) {
      final map = _stringKeyed(data);
      for (final key in const ['data', 'records', 'items', 'result']) {
        final nested = map[key];
        if (nested is List) {
          return nested.whereType<Map>().map(_stringKeyed).toList();
        }
      }
    }
    return const <Map<String, Object?>>[];
  }

  /// 生成稳定标识；华为记录通常带 `id` 或 `dataCollectorId`。
  static String _idOf(Map<String, Object?> record) {
    final id = _readString(record, const ['id', 'recordId', 'dataCollectorId']);
    if (id != null) return id;
    final time = _timeOf(record).millisecondsSinceEpoch;
    final type = _readString(record, const ['type', 'name']) ?? '';
    return '$time-$type';
  }

  /// 读取记录时间。
  static DateTime _timeOf(Map<String, Object?> record) =>
      _readDateTime(record, const ['startTime', 'start_time', 'time', 'date']) ??
      DateTime.now();

  /// 读取距离并换算为公里。
  static double? _distanceKm(
      Map<String, Object?> record, List<String> keys) {
    final raw = _readDouble(record, keys);
    if (raw == null) return null;
    // 华为云侧距离以米为单位。
    return raw > 1000 ? raw / 1000.0 : raw;
  }

  /// 读取时间戳；支持毫秒 epoch 与 ISO 字符串。
  static DateTime? _readDateTime(
      Map<String, Object?> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is num) {
        final millis = value > 100000000000 ? value.toInt() : value.toInt() * 1000;
        return DateTime.fromMillisecondsSinceEpoch(millis);
      }
      if (value is String) {
        final epoch = int.tryParse(value.trim());
        if (epoch != null) return _readDateTime({key: epoch}, [key]);
        final parsed = DateTime.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  /// 按候选键顺序读取字符串。
  static String? _readString(Map<String, Object?> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
      if (value is num) return value.toString();
    }
    return null;
  }

  /// 按候选键顺序读取整数。
  static int? _readInt(Map<String, Object?> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is int) return value;
      if (value is num) return value.round();
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
    }
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

/// 华为 OAuth 2.0 返回的令牌集合。
class HuaweiTokenSet {
  /// 构造令牌集合。
  const HuaweiTokenSet({
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
  });

  /// 访问令牌。
  final String accessToken;

  /// 刷新令牌；部分授权模式不返回。
  final String? refreshToken;

  /// 访问令牌的过期时刻。
  final DateTime? expiresAt;

  /// 令牌此刻是否已过期。
  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);
}
