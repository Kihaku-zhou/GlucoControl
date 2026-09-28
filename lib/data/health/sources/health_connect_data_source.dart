import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:health/health.dart';

import '../../../core/glucose_units.dart';
import '../../../core/result.dart';
import '../../../domain/health/health_data_source.dart';
import '../../../domain/health/health_records.dart';
import '../../../domain/health/health_source.dart';

/// Android Health Connect 连接器。
///
/// Health Connect 是系统级健康数据中枢：任何把数据写进去的应用都会在此汇总，
/// 因此它是「一个连接器覆盖多款应用」的通道，读到的记录会用 [HealthSample.originApp]
/// 标注原始应用（Keep、训记、iGPSPORT 等）。
///
/// 需要说明的现实约束（依据 [docs/DATA_SOURCES.md]）：华为运动健康**不写入**
/// Health Connect，硅基轻享也没有写入方，两者的数据要分别走 Health Kit 与
/// Nightscout；桌面端没有 Health Connect，只能靠文件导入。
class HealthConnectDataSource implements HealthDataSource {
  /// 构造连接器。
  ///
  /// [health] 仅用于测试注入；生产环境使用插件默认实例。
  HealthConnectDataSource({Health? health}) : _health = health ?? Health();

  /// 本连接器申请读取的数据类型。
  ///
  /// 只申请真正会用到且能归一化的类型：申请用不到的类型会扩大权限面，
  /// 而 Health Connect 的授权界面会逐项展示给用户。
  static const List<HealthDataType> requestedTypes = <HealthDataType>[
    HealthDataType.BLOOD_GLUCOSE,
    HealthDataType.WEIGHT,
    HealthDataType.BODY_FAT_PERCENTAGE,
    HealthDataType.LEAN_BODY_MASS,
    HealthDataType.BODY_MASS_INDEX,
    HealthDataType.WAIST_CIRCUMFERENCE,
    HealthDataType.WORKOUT,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
  ];

  final Health _health;
  bool _configured = false;

  @override
  HealthSourceId get id => HealthSourceId.healthConnect;

  @override
  bool get supportsAutomaticSync => true;

  /// 当前平台是否可能提供 Health Connect。
  static bool get _isMobilePlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  Future<Result<HealthSourceAvailability>> checkAvailability() async {
    if (!_isMobilePlatform) {
      return const Ok(HealthSourceAvailability.unavailable(
        'Health Connect 只在 Android 14+ / iOS 上可用，桌面端请改用文件导入',
      ));
    }
    try {
      await _ensureConfigured();
      final available = await _health.isHealthConnectAvailable();
      if (!available) {
        return const Ok(HealthSourceAvailability.unavailable(
          '本机未安装或未启用 Health Connect，可在系统设置中安装后重试',
        ));
      }
      final granted = await _health.hasPermissions(requestedTypes);
      if (granted != true) {
        return const Ok(HealthSourceAvailability.needsAuthorization(
          '需要在 Health Connect 中授权读取血糖、体重、运动与睡眠数据',
        ));
      }
      return const Ok(HealthSourceAvailability.ready());
    } on Exception catch (error) {
      return Err(AppFailure(
        kind: FailureKind.unknown,
        message: '探测 Health Connect 失败：$error',
        code: 'health_connect.probe_failed',
        cause: error,
      ));
    }
  }

  @override
  Future<Result<HealthSourceAvailability>> authorize() async {
    if (!_isMobilePlatform) {
      return checkAvailability();
    }
    try {
      await _ensureConfigured();
      final granted = await _health.requestAuthorization(requestedTypes);
      if (!granted) {
        return const Ok(HealthSourceAvailability.needsAuthorization(
          '用户未授予 Health Connect 读取权限',
        ));
      }
      await _requestHistoryAccessIfNeeded();
      return const Ok(HealthSourceAvailability.ready());
    } on Exception catch (error) {
      return Err(AppFailure(
        kind: FailureKind.permission,
        message: '申请 Health Connect 授权失败：$error',
        code: 'health_connect.authorize_failed',
        cause: error,
      ));
    }
  }

  /// 申请读取 30 天以前的历史数据。
  ///
  /// Health Connect 默认只放行授权前 30 天的记录；要导入更早的导出数据，
  /// 必须先取得 `READ_HEALTH_DATA_HISTORY`。该系统权限在部分设备或版本上
  /// 不存在，因此失败只降级为「只能读近 30 天」，不影响基础同步。
  Future<void> _requestHistoryAccessIfNeeded() async {
    try {
      if (await _health.isHealthDataHistoryAuthorized()) return;
      if (await _health.isHealthDataHistoryAvailable()) {
        await _health.requestHealthDataHistoryAuthorization();
      }
    } on Exception catch (error) {
      debugPrint('Health Connect 历史数据权限申请未完成：$error');
    }
  }

  @override
  Future<Result<HealthFetchResult>> fetch(HealthFetchWindow window) async {
    if (!_isMobilePlatform) {
      return const Err(AppFailure(
        kind: FailureKind.unsupported,
        message: '当前平台没有 Health Connect',
        code: 'health_connect.unsupported_platform',
      ));
    }

    try {
      await _ensureConfigured();
      final points = await _health.getHealthDataFromTypes(
        types: requestedTypes,
        startTime: window.start,
        endTime: window.end,
      );
      return Ok(mapPoints(points));
    } on Exception catch (error) {
      return Err(AppFailure(
        kind: FailureKind.unknown,
        message: '读取 Health Connect 数据失败：$error',
        code: 'health_connect.fetch_failed',
        cause: error,
      ));
    }
  }

  /// 确保插件已配置。
  ///
  /// [Health.configure] 会读取设备标识，必须在任何查询之前完成且只需一次。
  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  /// 把 Health Connect 数据点归一化为样本。
  ///
  /// 纯函数，便于在不依赖平台通道的前提下单元测试字段映射。
  static HealthFetchResult mapPoints(List<HealthDataPoint> points) {
    final samples = <HealthSample>[];
    final warnings = <String>[];

    // 体重、体脂、肌肉量、BMI、腰围在 Health Connect 中是独立记录，
    // 但语义上属于同一次体测，按「来源 + 分钟」归并成一条。
    final bodyBuckets = <String, Map<String, Object?>>{};
    final bodyTimes = <String, DateTime>{};
    final bodySourceNames = <String, String>{};

    // 日常活动按当地日期汇总。
    final dailySteps = <String, int>{};
    final dailyCalories = <String, int>{};
    final dailyRestingHr = <String, List<double>>{};
    final dailyHrv = <String, List<double>>{};
    final dailyDates = <String, DateTime>{};

    for (final point in points) {
      switch (point.type) {
        case HealthDataType.BLOOD_GLUCOSE:
          final sample = _mapGlucose(point);
          if (sample == null) {
            warnings.add('有 1 条 Health Connect 血糖记录无法解析，已跳过');
          } else {
            samples.add(sample);
          }
        case HealthDataType.WORKOUT:
          final sample = _mapWorkout(point);
          if (sample == null) {
            warnings.add('有 1 条 Health Connect 运动记录无法解析，已跳过');
          } else {
            samples.add(sample);
          }
        case HealthDataType.SLEEP_SESSION:
          final sample = _mapSleep(point);
          if (sample != null) samples.add(sample);
        case HealthDataType.WEIGHT:
        case HealthDataType.BODY_FAT_PERCENTAGE:
        case HealthDataType.LEAN_BODY_MASS:
        case HealthDataType.BODY_MASS_INDEX:
        case HealthDataType.WAIST_CIRCUMFERENCE:
          _accumulateBody(point, bodyBuckets, bodyTimes, bodySourceNames);
        case HealthDataType.STEPS:
          _accumulateInt(point, dailySteps);
        case HealthDataType.ACTIVE_ENERGY_BURNED:
          _accumulateInt(point, dailyCalories);
        case HealthDataType.RESTING_HEART_RATE:
          _accumulateList(point, dailyRestingHr);
        case HealthDataType.HEART_RATE_VARIABILITY_RMSSD:
          _accumulateList(point, dailyHrv);
        default:
          // requestedTypes 已经限定了会读取的类型，走到这里说明上游新增了类型。
          break;
      }
    }

    for (final entry in bodyBuckets.entries) {
      final composition = BodyComposition(
        source: HealthSourceId.healthConnect,
        externalId: 'hc:body:${entry.key}',
        measuredAt: bodyTimes[entry.key]!,
        weightKg: entry.value['weightKg'] as double?,
        bodyFatPercent: entry.value['bodyFatPercent'] as double?,
        muscleMassKg: entry.value['muscleMassKg'] as double?,
        bmi: entry.value['bmi'] as double?,
        waistCm: entry.value['waistCm'] as double?,
      ).toSample();
      samples.add(HealthSample(
        source: composition.source,
        kind: composition.kind,
        externalId: composition.externalId,
        startAt: composition.startAt,
        title: composition.title,
        originApp: bodySourceNames[entry.key],
        payload: composition.payload,
      ));
    }

    final allDays = <String>{
      ...dailySteps.keys,
      ...dailyCalories.keys,
      ...dailyRestingHr.keys,
      ...dailyHrv.keys,
    };
    for (final day in allDays) {
      final resting = dailyRestingHr[day];
      final hrv = dailyHrv[day];
      samples.add(DailyActivity(
        source: HealthSourceId.healthConnect,
        externalId: 'hc:daily:$day',
        date: dailyDates[day] ?? DateTime.parse(day),
        steps: dailySteps[day],
        activeCalories: dailyCalories[day],
        restingHeartRate: resting == null || resting.isEmpty
            ? null
            : (resting.reduce((a, b) => a + b) / resting.length).round(),
        hrvMs: hrv == null || hrv.isEmpty
            ? null
            : hrv.reduce((a, b) => a + b) / hrv.length,
      ).toSample());
    }

    return HealthFetchResult(samples: samples, warnings: warnings);
  }

  /// 血糖：Health Connect 插件固定以 mg/dL 返回（`HealthDataConverter.kt`）。
  static HealthSample? _mapGlucose(HealthDataPoint point) {
    final value = _numeric(point);
    if (value == null || value <= 0) return null;
    final reading = GlucoseReading(
      source: HealthSourceId.healthConnect,
      externalId: 'hc:glucose:${point.uuid}',
      recordedAt: point.dateFrom,
      mmolPerL: toMmolPerL(value, GlucoseUnit.mgPerDl),
      context: GlucoseContext.continuous,
    );
    final sample = reading.toSample();
    return HealthSample(
      source: sample.source,
      kind: sample.kind,
      externalId: sample.externalId,
      startAt: sample.startAt,
      title: sample.title,
      originApp: point.sourceName,
      payload: <String, Object?>{...sample.payload, 'mgPerDl': value},
    );
  }

  /// 运动：时长、距离与消耗来自 Health Connect 的活动记录。
  ///
  /// Health Connect 的 `ExerciseSessionRecord` 不含逐组重量与次数，
  /// 因此力量训练的 [WorkoutSession.totalVolumeKg] 等字段保持 null，
  /// 那类细节由训记连接器或文件导入提供。
  static HealthSample? _mapWorkout(HealthDataPoint point) {
    final value = point.value;
    if (value is! WorkoutHealthValue) return null;

    final distance = value.totalDistance;
    final distanceKm = distance == null
        ? null
        : _toKilometers(distance.toDouble(), value.totalDistanceUnit);

    final session = WorkoutSession(
      source: HealthSourceId.healthConnect,
      externalId: 'hc:workout:${point.uuid}',
      startedAt: point.dateFrom,
      endedAt: point.dateTo,
      category: _categoryOf(value.workoutActivityType),
      name: _workoutName(value.workoutActivityType),
      distanceKm: distanceKm,
      calories: value.totalEnergyBurned,
      originApp: point.sourceName,
    );
    final sample = session.toSample();
    return HealthSample(
      source: sample.source,
      kind: sample.kind,
      externalId: sample.externalId,
      startAt: sample.startAt,
      endAt: sample.endAt,
      title: sample.title,
      originApp: sample.originApp,
      payload: sample.payload,
    );
  }

  /// 睡眠：只记录 Health Connect 给出的入睡与起床时间。
  ///
  /// 分期时长需要额外查询 `SLEEP_DEEP`/`SLEEP_REM`/`SLEEP_LIGHT` 并做区间归属，
  /// 在其准确性未被验证前不写入这些字段，避免给出错误的分期结论。
  static HealthSample? _mapSleep(HealthDataPoint point) {
    if (!point.dateTo.isAfter(point.dateFrom)) return null;
    final session = SleepSession(
      source: HealthSourceId.healthConnect,
      externalId: 'hc:sleep:${point.uuid}',
      startedAt: point.dateFrom,
      endedAt: point.dateTo,
    );
    final sample = session.toSample();
    return HealthSample(
      source: sample.source,
      kind: sample.kind,
      externalId: sample.externalId,
      startAt: sample.startAt,
      endAt: sample.endAt,
      title: sample.title,
      originApp: point.sourceName,
      payload: sample.payload,
    );
  }

  /// 把体测类数据点累加到「来源 + 分钟」桶中。
  static void _accumulateBody(
    HealthDataPoint point,
    Map<String, Map<String, Object?>> buckets,
    Map<String, DateTime> times,
    Map<String, String> sourceNames,
  ) {
    final value = _numeric(point);
    if (value == null) return;
    final key = '${point.sourceId}:'
        '${point.dateFrom.millisecondsSinceEpoch ~/ 60000}';
    final bucket = buckets.putIfAbsent(key, () => <String, Object?>{});
    times.putIfAbsent(key, () => point.dateFrom);
    sourceNames.putIfAbsent(key, () => point.sourceName);

    switch (point.type) {
      case HealthDataType.WEIGHT:
        bucket['weightKg'] = value;
      case HealthDataType.BODY_FAT_PERCENTAGE:
        bucket['bodyFatPercent'] = value;
      case HealthDataType.LEAN_BODY_MASS:
        bucket['muscleMassKg'] = value;
      case HealthDataType.BODY_MASS_INDEX:
        bucket['bmi'] = value;
      case HealthDataType.WAIST_CIRCUMFERENCE:
        bucket['waistCm'] = value;
      default:
        break;
    }
  }

  /// 按当地日期累加整数型指标。
  static void _accumulateInt(
      HealthDataPoint point, Map<String, int> bucket) {
    final value = _numeric(point);
    if (value == null) return;
    final key = _dayKey(point.dateFrom);
    bucket[key] = (bucket[key] ?? 0) + value.round();
  }

  /// 按当地日期收集数值型指标，供后续取平均。
  static void _accumulateList(
      HealthDataPoint point, Map<String, List<double>> bucket) {
    final value = _numeric(point);
    if (value == null) return;
    bucket.putIfAbsent(_dayKey(point.dateFrom), () => <double>[]).add(value);
  }

  /// 读取数值型数据点的值；非数值类型返回 null。
  static double? _numeric(HealthDataPoint point) {
    final value = point.value;
    if (value is NumericHealthValue) return value.numericValue.toDouble();
    return null;
  }

  /// 当地日期键，形如 `2026-09-28`。
  static String _dayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// 按单位把距离换算为公里。
  static double _toKilometers(double value, HealthDataUnit? unit) {
    final name = unit?.name ?? '';
    if (name.contains('MILE')) return value * 1.609344;
    if (name.contains('METER')) return value / 1000.0;
    if (name.contains('KILOMETER')) return value;
    // Health Connect 的距离类型在 Android 上以米为主，未知单位按米处理。
    return value / 1000.0;
  }

  /// 把 Health Connect 的运动类型映射到应用的归一化分类。
  static WorkoutCategory _categoryOf(HealthWorkoutActivityType type) =>
      switch (type) {
        HealthWorkoutActivityType.BIKING ||
        HealthWorkoutActivityType.BIKING_STATIONARY =>
          WorkoutCategory.cycling,
        HealthWorkoutActivityType.RUNNING ||
        HealthWorkoutActivityType.RUNNING_TREADMILL =>
          WorkoutCategory.running,
        HealthWorkoutActivityType.WALKING ||
        HealthWorkoutActivityType.WALKING_TREADMILL ||
        HealthWorkoutActivityType.HIKING =>
          WorkoutCategory.walking,
        HealthWorkoutActivityType.SWIMMING ||
        HealthWorkoutActivityType.SWIMMING_POOL ||
        HealthWorkoutActivityType.SWIMMING_OPEN_WATER =>
          WorkoutCategory.swimming,
        HealthWorkoutActivityType.HIGH_INTENSITY_INTERVAL_TRAINING =>
          WorkoutCategory.hiit,
        HealthWorkoutActivityType.YOGA ||
        HealthWorkoutActivityType.PILATES ||
        HealthWorkoutActivityType.GUIDED_BREATHING =>
          WorkoutCategory.yoga,
        HealthWorkoutActivityType.STRENGTH_TRAINING ||
        HealthWorkoutActivityType.TRADITIONAL_STRENGTH_TRAINING ||
        HealthWorkoutActivityType.WEIGHTLIFTING ||
        HealthWorkoutActivityType.CALISTHENICS =>
          WorkoutCategory.strength,
        _ => WorkoutCategory.other,
      };

  /// 运动类型的可读名称，用于列表与 AI 上下文。
  static String _workoutName(HealthWorkoutActivityType type) {
    final raw = type.name.toLowerCase().replaceAll('_', ' ');
    return raw.isEmpty ? '运动' : raw;
  }
}
