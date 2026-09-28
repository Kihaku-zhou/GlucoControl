import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';

import '../../../core/result.dart';
import '../../../domain/health/health_data_source.dart';
import '../../../domain/health/health_records.dart';
import '../../../domain/health/health_source.dart';
import '../health_source_config.dart';

/// 训记（Xunji）官方 Open API v2 连接器。
///
/// 五个目标数据源中唯一提供公开自助接口的一个：读取用
/// `POST {baseUrl}/api_trains_for_llm_v2`，凭据放在 `Authorization: Bearer <key>`
/// （或 `x-api-key`），请求体必须带 `schema_version: "train_open_api_v2"`。
///
/// 服务端按「训练日」限流，同一日期约 90 秒内只能读一次；命中限流时本连接器
/// 跳过该日并把它记入 [HealthFetchResult.warnings]，而不是让整次同步失败。
///
/// 字段映射依据训记官方 skill 文档
/// （https://github.com/AkiraLan/xunji-skills/blob/master/xunji/SKILL.md）。
/// 该文档描述了 `res.trains[].movements[].sets[]` 的语义与取值形式，但未逐字给出
/// 每个 JSON 键名，因此 [parseTrains] 采用容错取值，并把**整条原始 train 对象**
/// 保留在 `HealthSample.payload['raw']` 中——即使映射需要修正，原始数据也不会丢失。
class XunjiApiDataSource implements HealthDataSource {
  /// 构造连接器。
  ///
  /// [config] 提供 API Key 与可选的自定义基址；[dio] 便于测试注入。
  XunjiApiDataSource({
    required HealthSourceConfig config,
    Dio? dio,
    this.interRequestDelay = const Duration(seconds: 1),
  })  : _config = config,
        _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 60),
              // 训记在限流与鉴权失败时返回非 2xx，这里统一取回响应体自行判断。
              validateStatus: (_) => true,
            ));

  /// 默认服务基址。
  static const String defaultBaseUrl = 'https://trains.xunjiapp.cn';

  /// 协议版本字段，服务端强制校验。
  static const String schemaVersion = 'train_open_api_v2';

  final HealthSourceConfig _config;
  final Dio _dio;

  /// 相邻两天请求之间的间隔，用于对上游限流保持克制。
  final Duration interRequestDelay;

  @override
  HealthSourceId get id => HealthSourceId.xunji;

  @override
  bool get supportsAutomaticSync => true;

  /// 当前生效的基址。
  String get _baseUrl {
    final configured = _config.baseUrl?.trim();
    if (configured == null || configured.isEmpty) return defaultBaseUrl;
    return configured.endsWith('/')
        ? configured.substring(0, configured.length - 1)
        : configured;
  }

  @override
  Future<Result<HealthSourceAvailability>> checkAvailability() async {
    final apiKey = _config.apiKey?.trim() ?? '';
    if (apiKey.isEmpty) {
      return const Ok(HealthSourceAvailability.needsAuthorization(
        '需要在「我的 > 数据导出和导入」生成训记 API Key 后填入',
      ));
    }
    return const Ok(HealthSourceAvailability.ready());
  }

  @override
  Future<Result<HealthSourceAvailability>> authorize() async {
    // 训记用长期 API Key，没有 OAuth 往返：填入即视为已授权。
    return checkAvailability();
  }

  @override
  Future<Result<HealthFetchResult>> fetch(HealthFetchWindow window) async {
    final apiKey = _config.apiKey?.trim() ?? '';
    if (apiKey.isEmpty) {
      return const Err(AppFailure(
        kind: FailureKind.authentication,
        message: '未配置训记 API Key',
        code: 'xunji.missing_key',
      ));
    }

    final samples = <HealthSample>[];
    final warnings = <String>[];

    for (final day in _daysOf(window)) {
      final outcome = await _fetchDay(day, apiKey);
      switch (outcome) {
        case Ok(:final value):
          samples.addAll(value);
        case Err(:final failure):
          if (failure.code == _codeRateLimited) {
            warnings.add('${_formatDate(day)} 被训记限流跳过，稍后重试可补齐');
            continue;
          }
          return Err(failure);
      }
      if (interRequestDelay > Duration.zero) {
        await Future<void>.delayed(interRequestDelay);
      }
    }

    return Ok(HealthFetchResult(samples: samples, warnings: warnings));
  }

  /// 拉取单日训练并归一化；该日期被限流时返回带 [_codeRateLimited] 的失败。
  Future<Result<List<HealthSample>>> _fetchDay(
      DateTime day, String apiKey) async {
    final datestr = _formatDate(day);
    try {
      final response = await _dio.post<Object?>(
        '$_baseUrl/api_trains_for_llm_v2',
        data: <String, Object?>{
          'schema_version': schemaVersion,
          'datestr': datestr,
        },
        options: Options(
          headers: <String, String>{
            'Authorization': 'Bearer $apiKey',
            'x-api-key': apiKey,
            'Content-Type': 'application/json',
            'Accept-Encoding': 'gzip',
          },
          responseType: ResponseType.json,
        ),
      );

      final failure = _classifyError(response);
      if (failure != null) return Err(failure);

      final trains = extractTrains(response.data);
      if (trains.isEmpty && looksLikeUndecodedBytes(response.data)) {
        // 宁可报错也不要静默丢一天：用户会以为当天没有训练记录。
        return Err(AppFailure(
          kind: FailureKind.parsing,
          message: '训记 $datestr 的响应体无法解码（可能是未识别的压缩格式）',
          code: 'xunji.undecodable_body',
        ));
      }
      final samples = <HealthSample>[];
      for (final train in trains) {
        final sample = parseTrain(train, originDate: day);
        if (sample != null) samples.add(sample);
      }
      return Ok(samples);
    } on DioException catch (error) {
      return Err(AppFailure(
        kind: FailureKind.network,
        message: '读取训记 ${_formatDate(day)} 数据失败：${error.message ?? error.type.name}',
        code: 'xunji.network',
        cause: error,
      ));
    }
  }

  /// 识别训记返回的业务错误；无错误时返回 null。
  ///
  /// 上游用中文短句表达鉴权、会员与限流状态，因此这里同时检查状态码与响应文本。
  AppFailure? _classifyError(Response<Object?> response) {
    final status = response.statusCode ?? 0;
    final body = _responseText(response.data);
    final lower = body.toLowerCase();

    final rateLimited = lower.contains('too frequent') ||
        lower.contains('retry after') ||
        status == 429;
    if (rateLimited) {
      return const AppFailure(
        kind: FailureKind.network,
        message: '训记接口限流：同一训练日约 90 秒内只能读取一次',
        code: _codeRateLimited,
      );
    }

    final needsVip = body.contains('仅VIP可用') || body.contains('仅 VIP');
    if (needsVip) {
      return const AppFailure(
        kind: FailureKind.authentication,
        message: '训记开放 API 需要买断或 VIP 账号',
        code: 'xunji.vip_required',
      );
    }

    final badKey = lower.contains('apikey missing') ||
        lower.contains('apikey invalid') ||
        lower.contains('unauthorized') ||
        status == 401 ||
        status == 403;
    if (badKey) {
      return const AppFailure(
        kind: FailureKind.authentication,
        message: '训记 API Key 缺失或无效',
        code: 'xunji.bad_key',
      );
    }

    if (status >= 500) {
      return AppFailure(
        kind: FailureKind.network,
        message: '训记服务端错误（HTTP $status）',
        code: 'xunji.server_error',
      );
    }
    if (status < 200 || status >= 300) {
      return AppFailure(
        kind: FailureKind.unknown,
        message: '训记接口返回 HTTP $status',
        code: 'xunji.http_error',
      );
    }
    return null;
  }

  /// 从响应体中取出 `res.trains` 数组。
  ///
  /// 兼容三种形态：`{res: {trains: [...]}}`、`{trains: [...]}`、以及顶层数组。
  /// [extractTrains] 是纯函数，便于单元测试覆盖。
  static List<Map<String, Object?>> extractTrains(Object? data) {
    final decoded = _decodeMaybeGzipJson(data);
    if (decoded is List) {
      return decoded.whereType<Map>().map(_stringKeyed).toList();
    }
    if (decoded is Map) {
      final map = _stringKeyed(decoded);
      final res = map['res'];
      if (res is Map) {
        final trains = _stringKeyed(res)['trains'];
        if (trains is List) {
          return trains.whereType<Map>().map(_stringKeyed).toList();
        }
      }
      final trains = map['trains'];
      if (trains is List) {
        return trains.whereType<Map>().map(_stringKeyed).toList();
      }
    }
    return const <Map<String, Object?>>[];
  }

  /// 把一条训记 train 对象归一化为运动样本；无法还原时返回 null。
  ///
  /// [originDate] 是请求时使用的训练日，用于在 train 未给出开始时间时兜底。
  static HealthSample? parseTrain(
    Map<String, Object?> train, {
    required DateTime originDate,
  }) {
    final startedAt = _readDateTime(train, const ['start', 'startTime', 'train_time']) ??
        DateTime(originDate.year, originDate.month, originDate.day);
    final endedAt = _readDateTime(train, const ['end', 'endTime']) ??
        startedAt.add(const Duration(hours: 1));

    final localId = _readString(train, const ['localid', 'localId', 'id']);
    final title = _readString(train, const ['title', 'name']) ?? '训记训练';

    final movements = _readMovements(train);
    final volume = <String, Object?>{};
    var totalSets = 0;
    var totalReps = 0;
    var totalVolumeKg = 0.0;
    var hasStrength = false;
    var totalDistanceKm = 0.0;
    var hasDistance = false;
    var totalCalories = 0;
    var maxHeartRate = 0;
    var heartRateSum = 0;
    var heartRateCount = 0;

    for (final movement in movements) {
      for (final set in _readSets(movement)) {
        totalSets++;
        final weight = _readDouble(set, const ['weight', 'weightKg']);
        final reps = _readInt(set, const ['reps', 'count']);
        if (reps != null) totalReps += reps;
        if (weight != null || reps != null) hasStrength = true;
        if (weight != null && reps != null) totalVolumeKg += weight * reps;

        final metrics = set['metrics'];
        if (metrics is Map) {
          final metricsMap = _stringKeyed(metrics);
          final distance = _readDistanceKm(metricsMap);
          if (distance != null) {
            totalDistanceKm += distance;
            hasDistance = true;
          }
          final kcal = _readInt(metricsMap, const ['kcal', 'calories']);
          if (kcal != null) totalCalories += kcal;
          final bpm = _readInt(metricsMap, const ['bpm', 'heartRate']);
          if (bpm != null) {
            maxHeartRate = bpm > maxHeartRate ? bpm : maxHeartRate;
            heartRateSum += bpm;
            heartRateCount++;
          }
        }
      }
    }

    // 组次细节超出样本信封的表达能力，完整保留在扩展属性中供后续使用。
    volume['movementCount'] = movements.length;
    volume['movements'] = movements;

    final sample = WorkoutSession(
      source: HealthSourceId.xunji,
      externalId: localId != null && localId.isNotEmpty
          ? 'xunji:$localId'
          : 'xunji:${_formatDate(originDate)}:${_fingerprint(title, startedAt)}',
      startedAt: startedAt,
      endedAt: endedAt,
      category: hasDistance ? WorkoutCategory.other : WorkoutCategory.strength,
      name: title,
      distanceKm: hasDistance ? totalDistanceKm : null,
      calories: totalCalories > 0 ? totalCalories : null,
      avgHeartRate:
          heartRateCount > 0 ? (heartRateSum / heartRateCount).round() : null,
      maxHeartRate: maxHeartRate > 0 ? maxHeartRate : null,
      totalVolumeKg: hasStrength ? totalVolumeKg : null,
      totalSets: totalSets > 0 ? totalSets : null,
      totalReps: totalReps > 0 ? totalReps : null,
      note: _readString(train, const ['remark', 'note', 'comments']),
    ).toSample();

    // 原始对象一并入库：映射需要修正时无需重新拉取上游数据。
    return HealthSample(
      source: sample.source,
      kind: sample.kind,
      externalId: sample.externalId,
      startAt: sample.startAt,
      endAt: sample.endAt,
      title: sample.title,
      originApp: sample.originApp,
      payload: <String, Object?>{...sample.payload, 'raw': train},
    );
  }

  /// 生成稳定指纹，用于缺少 localid 时的幂等键。
  static String _fingerprint(String title, DateTime startedAt) =>
      '$title@${startedAt.toIso8601String()}'.hashCode.toRadixString(16);

  /// 展开窗口内的每一天（按当地日期）。
  static Iterable<DateTime> _daysOf(HealthFetchWindow window) sync* {
    var cursor = DateTime(window.start.year, window.start.month, window.start.day);
    final last = DateTime(window.end.year, window.end.month, window.end.day);
    while (!cursor.isAfter(last)) {
      yield cursor;
      cursor = cursor.add(const Duration(days: 1));
    }
  }

  /// 把训记的 `movements` 字段统一取成列表。
  static List<Map<String, Object?>> _readMovements(Map<String, Object?> train) {
    final raw = train['movements'] ?? train['actions'] ?? train['items'];
    if (raw is List) return raw.whereType<Map>().map(_stringKeyed).toList();
    return const <Map<String, Object?>>[];
  }

  /// 把一个动作的组列表统一取成列表。
  static List<Map<String, Object?>> _readSets(Map<String, Object?> movement) {
    final raw = movement['sets'] ?? movement['groups'];
    if (raw is List) return raw.whereType<Map>().map(_stringKeyed).toList();
    return const <Map<String, Object?>>[];
  }

  /// 距离统一换算为公里。
  ///
  /// 键名决定口径：`distanceKm` 的数值本身就是公里；`distance` 则需要看单位——
  /// 训记的有氧指标在文档里写作 `5km` 这类带单位的字符串，带 `km` 时按公里，
  /// 其余（带 `m` 或没有单位）以及直接给数字时一律按米处理，与华为云侧接口及
  /// Health Connect 的口径保持一致。同一个物理量必须得到同一结果，否则数字型
  /// 距离会被放大 1000 倍。
  static double? _readDistanceKm(Map<String, Object?> metrics) {
    final explicitKm = metrics['distanceKm'];
    if (explicitKm is num) return explicitKm.toDouble();
    if (explicitKm is String && explicitKm.trim().isNotEmpty) {
      return _leadingNumber(explicitKm);
    }

    final raw = metrics['distance'];
    if (raw is num) return raw.toDouble() / 1000.0;
    if (raw is! String || raw.trim().isEmpty) return null;

    final text = raw.trim().toLowerCase();
    final value = _leadingNumber(text);
    if (value == null) return null;
    return text.endsWith('km') ? value : value / 1000.0;
  }

  /// 取字符串开头的数字；没有数字时返回 null。
  static double? _leadingNumber(String text) => double.tryParse(
      RegExp(r'-?\d+(\.\d+)?').firstMatch(text)?.group(0) ?? '');

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
        final parsed =
            double.tryParse(RegExp(r'-?\d+(\.\d+)?').firstMatch(value)?.group(0) ?? '');
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  /// 读取时间戳；支持毫秒/秒 epoch 与 ISO 字符串。
  static DateTime? _readDateTime(
      Map<String, Object?> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is num) {
        final millis = value > 100000000000 ? value.toInt() : value.toInt() * 1000;
        return DateTime.fromMillisecondsSinceEpoch(millis);
      }
      if (value is String) {
        final trimmed = value.trim();
        final epoch = int.tryParse(trimmed);
        if (epoch != null) return _readDateTime({key: epoch}, [key]);
        final parsed = DateTime.tryParse(trimmed);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  /// `YYYY-MM-DD`。
  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// 把 Map 的键统一为 String。
  static Map<String, Object?> _stringKeyed(Map<Object?, Object?> source) =>
      source.map((key, value) => MapEntry(key.toString(), value));

  /// 取出响应文本用于错误判定。
  static String _responseText(Object? data) {
    if (data == null) return '';
    if (data is String) return data;
    try {
      return jsonEncode(data);
    } on JsonUnsupportedObjectError {
      // 非 JSON 可编码体（例如未自动解压的二进制流），无法从中提取错误文案。
      return data.toString();
    }
  }

  /// 兼容上游未声明 `Content-Encoding` 却返回压缩字节流的情况。
  ///
  /// 判定顺序很关键：`Uint8List` 也满足 `is List`，必须先处理字节流，
  /// 否则「解压后解析 JSON」的分支永远不可达，未解压的响应会被静默当成空结果。
  static Object? _decodeMaybeGzipJson(Object? data) {
    if (data is Map) return data;

    if (data is List<int>) {
      final bytes = data;
      final decoded = _looksGzipped(bytes)
          ? _gunzip(bytes)
          : (bytes is Uint8List ? bytes : Uint8List.fromList(bytes));
      if (decoded == null) return null;
      try {
        return jsonDecode(utf8.decode(decoded));
      } on FormatException {
        return null;
      }
    }

    if (data is String) {
      try {
        return jsonDecode(data);
      } on FormatException {
        return null;
      }
    }

    if (data is List) return data;
    return null;
  }

  /// 是否为 gzip 魔数（`0x1f 0x8b`）。
  static bool _looksGzipped(List<int> bytes) =>
      bytes.length >= 2 && bytes[0] == 0x1f && bytes[1] == 0x8b;

  /// 解压 gzip 字节流；不是合法 gzip 时返回 null。
  ///
  /// [ArchiveException] 继承自 [FormatException]，因此一个 catch 就够。
  static Uint8List? _gunzip(List<int> bytes) {
    try {
      return GZipDecoder().decodeBytes(bytes);
    } on FormatException {
      return null;
    }
  }

  /// 响应体是否是「需要解压但我们没能解压」的字节流。
  ///
  /// 用于把静默丢数据变成可见错误：宁可让这一天进 [HealthFetchResult.warnings]，
  /// 也不要让用户以为当天没有训练。
  static bool looksLikeUndecodedBytes(Object? data) =>
      data is List<int> && _decodeMaybeGzipJson(data) == null;

  /// 上游限流失败的稳定错误码。
  static const String _codeRateLimited = 'xunji.rate_limited';
}
