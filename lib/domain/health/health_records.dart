import '../../core/glucose_units.dart';
import 'health_source.dart';

/// 所有归一化健康记录的公共接口。
///
/// 让调用方（统计、AI 工具、时间线界面）能以同一类型处理不同类别的记录，
/// 而不必依赖 `dynamic` 或重复的 `switch`。
sealed class HealthRecord {
  /// 数据来自哪个连接器。
  HealthSourceId get source;

  /// 源内稳定标识，用于幂等去重。
  String get externalId;

  /// 该记录在时间线上的位置。
  DateTime get occurredAt;

  /// 还原为可持久化的样本信封。
  HealthSample toSample();
}

/// CGM 趋势箭头所表达的血糖变化方向。
enum GlucoseTrend {
  /// 快速上升。
  risingFast('rising_fast', '↑↑'),

  /// 上升。
  rising('rising', '↑'),

  /// 平稳。
  steady('steady', '→'),

  /// 下降。
  falling('falling', '↓'),

  /// 快速下降。
  fallingFast('falling_fast', '↓↓');

  const GlucoseTrend(this.code, this.arrow);

  /// 持久化编码。
  final String code;

  /// 界面展示的箭头。
  final String arrow;

  /// 从持久化编码还原；未知编码返回 null。
  static GlucoseTrend? tryFromCode(String? code) {
    for (final trend in values) {
      if (trend.code == code) return trend;
    }
    return null;
  }
}

/// 一条血糖读数，统一以 mmol/L 表达。
class GlucoseReading implements HealthRecord {
  /// 构造读数。
  const GlucoseReading({
    required this.source,
    required this.externalId,
    required this.recordedAt,
    required this.mmolPerL,
    this.context = GlucoseContext.random,
    this.trend,
    this.note,
  });

  /// 从归一化样本还原；缺少必要字段时返回 null。
  static GlucoseReading? tryFromSample(HealthSample sample) {
    final mmolPerL = sample.doubleField(_fieldMmolPerL);
    if (mmolPerL == null) return null;
    return GlucoseReading(
      source: sample.source,
      externalId: sample.externalId,
      recordedAt: sample.startAt,
      mmolPerL: mmolPerL,
      context: GlucoseContext.fromCode(sample.stringField(_fieldContext)),
      trend: GlucoseTrend.tryFromCode(sample.stringField(_fieldTrend)),
      note: sample.stringField(_fieldNote),
    );
  }

  @override
  final HealthSourceId source;

  @override
  final String externalId;

  /// 采样时间。
  final DateTime recordedAt;

  /// 血糖值，单位 mmol/L。
  final double mmolPerL;

  /// 采血时机分类。
  final GlucoseContext context;

  /// CGM 趋势箭头；指尖血读数没有该信息。
  final GlucoseTrend? trend;

  /// 备注。
  final String? note;

  /// 换算为指定单位后的数值。
  double valueIn(GlucoseUnit unit) => mmolPerLTo(mmolPerL, unit);

  @override
  DateTime get occurredAt => recordedAt;

  @override
  HealthSample toSample() => HealthSample(
        source: source,
        externalId: externalId,
        kind: HealthSampleKind.glucose,
        startAt: recordedAt,
        title: '${context.label}血糖',
        payload: {
          _fieldMmolPerL: mmolPerL,
          _fieldContext: context.code,
          if (trend != null) _fieldTrend: trend!.code,
          if (note != null) _fieldNote: note,
        },
      );

  static const String _fieldMmolPerL = 'mmolPerL';
  static const String _fieldContext = 'context';
  static const String _fieldTrend = 'trend';
  static const String _fieldNote = 'note';
}

/// 运动项目的归一化分类，用于把不同应用的品类名映射到同一套分析口径。
enum WorkoutCategory {
  /// 力量训练。
  strength('strength', '力量'),

  /// 骑行。
  cycling('cycling', '骑行'),

  /// 跑步。
  running('running', '跑步'),

  /// 步行。
  walking('walking', '步行'),

  /// 游泳。
  swimming('swimming', '游泳'),

  /// 高强度间歇。
  hiit('hiit', 'HIIT'),

  /// 瑜伽与拉伸。
  yoga('yoga', '瑜伽'),

  /// 其他或无法归类。
  other('other', '其他');

  const WorkoutCategory(this.code, this.label);

  /// 持久化编码。
  final String code;

  /// 界面展示名。
  final String label;

  /// 从持久化编码还原；未知编码回退到 [WorkoutCategory.other]。
  static WorkoutCategory fromCode(String? code) {
    for (final category in values) {
      if (category.code == code) return category;
    }
    return WorkoutCategory.other;
  }

  /// 该分类是否以有氧供能为主。用于血糖-运动分析时区分代谢路径。
  bool get isAerobic =>
      this == cycling ||
      this == running ||
      this == walking ||
      this == swimming ||
      this == hiit;
}

/// 一次训练/运动记录。
///
/// 字段覆盖三类来源的实际产出：iGPSPORT 的骑行功率与距离、Keep 的课程与消耗、
/// 训记与华为运动健康的组次与心率。来源不提供的字段保持 null。
class WorkoutSession implements HealthRecord {
  /// 构造运动记录。
  const WorkoutSession({
    required this.source,
    required this.externalId,
    required this.startedAt,
    required this.endedAt,
    required this.category,
    required this.name,
    this.distanceKm,
    this.elevationGainM,
    this.avgPowerW,
    this.normalizedPowerW,
    this.avgHeartRate,
    this.maxHeartRate,
    this.calories,
    this.totalVolumeKg,
    this.totalSets,
    this.totalReps,
    this.note,
    this.originApp,
  });

  /// 从归一化样本还原；缺少必要字段时返回 null。
  static WorkoutSession? tryFromSample(HealthSample sample) {
    final endedAt = sample.endAt;
    if (endedAt == null) return null;
    return WorkoutSession(
      source: sample.source,
      externalId: sample.externalId,
      startedAt: sample.startAt,
      endedAt: endedAt,
      category: WorkoutCategory.fromCode(sample.stringField(_fieldCategory)),
      name: sample.stringField(_fieldName) ?? sample.title ?? '运动',
      distanceKm: sample.doubleField(_fieldDistanceKm),
      elevationGainM: sample.doubleField(_fieldElevationGainM),
      avgPowerW: sample.doubleField(_fieldAvgPowerW),
      normalizedPowerW: sample.doubleField(_fieldNormalizedPowerW),
      avgHeartRate: sample.intField(_fieldAvgHeartRate),
      maxHeartRate: sample.intField(_fieldMaxHeartRate),
      calories: sample.intField(_fieldCalories),
      totalVolumeKg: sample.doubleField(_fieldTotalVolumeKg),
      totalSets: sample.intField(_fieldTotalSets),
      totalReps: sample.intField(_fieldTotalReps),
      note: sample.stringField(_fieldNote),
      originApp: sample.originApp,
    );
  }

  @override
  final HealthSourceId source;

  @override
  final String externalId;

  /// 开始时间。
  final DateTime startedAt;

  /// 结束时间。
  final DateTime endedAt;

  /// 归一化分类。
  final WorkoutCategory category;

  /// 展示名称，沿用来源应用的叫法。
  final String name;

  /// 距离（公里）。
  final double? distanceKm;

  /// 累计爬升（米）。
  final double? elevationGainM;

  /// 平均功率（瓦）。
  final double? avgPowerW;

  /// 标准化功率（瓦），反映骑行真实强度。
  final double? normalizedPowerW;

  /// 平均心率（次/分）。
  final int? avgHeartRate;

  /// 最大心率（次/分）。
  final int? maxHeartRate;

  /// 消耗热量（千卡）。
  final int? calories;

  /// 力量训练总容量（公斤·次），来源未提供时为 null。
  final double? totalVolumeKg;

  /// 力量训练总组数。
  final int? totalSets;

  /// 力量训练总次数。
  final int? totalReps;

  /// 备注。
  final String? note;

  /// 原始应用名；经 Health Connect 取数时有值。
  final String? originApp;

  /// 训练时长（分钟，保留一位小数）。
  double get durationMinutes =>
      endedAt.difference(startedAt).inSeconds / 60.0;

  /// 骑行训练强度系数 `NP / FTP`；缺少功率或未提供 [functionalThresholdPowerW] 时返回 null。
  double? intensityFactor(double? functionalThresholdPowerW) {
    final normalized = normalizedPowerW ?? avgPowerW;
    if (normalized == null ||
        functionalThresholdPowerW == null ||
        functionalThresholdPowerW <= 0) {
      return null;
    }
    return normalized / functionalThresholdPowerW;
  }

  @override
  DateTime get occurredAt => startedAt;

  @override
  HealthSample toSample() => HealthSample(
        source: source,
        externalId: externalId,
        kind: HealthSampleKind.workout,
        startAt: startedAt,
        endAt: endedAt,
        title: name,
        originApp: originApp,
        payload: {
          _fieldCategory: category.code,
          _fieldName: name,
          if (distanceKm != null) _fieldDistanceKm: distanceKm,
          if (elevationGainM != null) _fieldElevationGainM: elevationGainM,
          if (avgPowerW != null) _fieldAvgPowerW: avgPowerW,
          if (normalizedPowerW != null)
            _fieldNormalizedPowerW: normalizedPowerW,
          if (avgHeartRate != null) _fieldAvgHeartRate: avgHeartRate,
          if (maxHeartRate != null) _fieldMaxHeartRate: maxHeartRate,
          if (calories != null) _fieldCalories: calories,
          if (totalVolumeKg != null) _fieldTotalVolumeKg: totalVolumeKg,
          if (totalSets != null) _fieldTotalSets: totalSets,
          if (totalReps != null) _fieldTotalReps: totalReps,
          if (note != null) _fieldNote: note,
        },
      );

  static const String _fieldCategory = 'category';
  static const String _fieldName = 'name';
  static const String _fieldDistanceKm = 'distanceKm';
  static const String _fieldElevationGainM = 'elevationGainM';
  static const String _fieldAvgPowerW = 'avgPowerW';
  static const String _fieldNormalizedPowerW = 'normalizedPowerW';
  static const String _fieldAvgHeartRate = 'avgHeartRate';
  static const String _fieldMaxHeartRate = 'maxHeartRate';
  static const String _fieldCalories = 'calories';
  static const String _fieldTotalVolumeKg = 'totalVolumeKg';
  static const String _fieldTotalSets = 'totalSets';
  static const String _fieldTotalReps = 'totalReps';
  static const String _fieldNote = 'note';
}

/// 一次身体成分测量。
class BodyComposition implements HealthRecord {
  /// 构造体测记录。
  const BodyComposition({
    required this.source,
    required this.externalId,
    required this.measuredAt,
    this.weightKg,
    this.bodyFatPercent,
    this.muscleMassKg,
    this.bmi,
    this.waistCm,
    this.hipCm,
    this.note,
  });

  /// 从归一化样本还原；缺少必要字段时返回 null。
  static BodyComposition? tryFromSample(HealthSample sample) =>
      BodyComposition(
        source: sample.source,
        externalId: sample.externalId,
        measuredAt: sample.startAt,
        weightKg: sample.doubleField(_fieldWeightKg),
        bodyFatPercent: sample.doubleField(_fieldBodyFatPercent),
        muscleMassKg: sample.doubleField(_fieldMuscleMassKg),
        bmi: sample.doubleField(_fieldBmi),
        waistCm: sample.doubleField(_fieldWaistCm),
        hipCm: sample.doubleField(_fieldHipCm),
        note: sample.stringField(_fieldNote),
      );

  @override
  final HealthSourceId source;

  @override
  final String externalId;

  /// 测量时间。
  final DateTime measuredAt;

  /// 体重（公斤）。
  final double? weightKg;

  /// 体脂率（百分比，取值 0-100）。
  final double? bodyFatPercent;

  /// 肌肉量（公斤）。
  final double? muscleMassKg;

  /// 身体质量指数。
  final double? bmi;

  /// 腰围（厘米）。
  final double? waistCm;

  /// 臀围（厘米）。
  final double? hipCm;

  /// 备注。
  final String? note;

  @override
  DateTime get occurredAt => measuredAt;

  @override
  HealthSample toSample() => HealthSample(
        source: source,
        externalId: externalId,
        kind: HealthSampleKind.bodyComposition,
        startAt: measuredAt,
        title: '体测记录',
        payload: {
          if (weightKg != null) _fieldWeightKg: weightKg,
          if (bodyFatPercent != null) _fieldBodyFatPercent: bodyFatPercent,
          if (muscleMassKg != null) _fieldMuscleMassKg: muscleMassKg,
          if (bmi != null) _fieldBmi: bmi,
          if (waistCm != null) _fieldWaistCm: waistCm,
          if (hipCm != null) _fieldHipCm: hipCm,
          if (note != null) _fieldNote: note,
        },
      );

  static const String _fieldWeightKg = 'weightKg';
  static const String _fieldBodyFatPercent = 'bodyFatPercent';
  static const String _fieldMuscleMassKg = 'muscleMassKg';
  static const String _fieldBmi = 'bmi';
  static const String _fieldWaistCm = 'waistCm';
  static const String _fieldHipCm = 'hipCm';
  static const String _fieldNote = 'note';
}

/// 一段睡眠。
class SleepSession implements HealthRecord {
  /// 构造睡眠记录。
  const SleepSession({
    required this.source,
    required this.externalId,
    required this.startedAt,
    required this.endedAt,
    this.deepMinutes,
    this.lightMinutes,
    this.remMinutes,
    this.awakeMinutes,
  });

  /// 从归一化样本还原；缺少结束时间时返回 null。
  static SleepSession? tryFromSample(HealthSample sample) {
    final endedAt = sample.endAt;
    if (endedAt == null) return null;
    return SleepSession(
      source: sample.source,
      externalId: sample.externalId,
      startedAt: sample.startAt,
      endedAt: endedAt,
      deepMinutes: sample.intField(_fieldDeepMinutes),
      lightMinutes: sample.intField(_fieldLightMinutes),
      remMinutes: sample.intField(_fieldRemMinutes),
      awakeMinutes: sample.intField(_fieldAwakeMinutes),
    );
  }

  @override
  final HealthSourceId source;

  @override
  final String externalId;

  /// 入睡时间。
  final DateTime startedAt;

  /// 起床时间。
  final DateTime endedAt;

  /// 深睡时长（分钟）。
  final int? deepMinutes;

  /// 浅睡时长（分钟）。
  final int? lightMinutes;

  /// 快速眼动时长（分钟）。
  final int? remMinutes;

  /// 清醒时长（分钟）。
  final int? awakeMinutes;

  @override
  DateTime get occurredAt => startedAt;

  /// 卧床总时长（分钟）。
  int get totalMinutes => endedAt.difference(startedAt).inMinutes;

  @override
  HealthSample toSample() => HealthSample(
        source: source,
        externalId: externalId,
        kind: HealthSampleKind.sleep,
        startAt: startedAt,
        endAt: endedAt,
        title: '睡眠',
        payload: {
          if (deepMinutes != null) _fieldDeepMinutes: deepMinutes,
          if (lightMinutes != null) _fieldLightMinutes: lightMinutes,
          if (remMinutes != null) _fieldRemMinutes: remMinutes,
          if (awakeMinutes != null) _fieldAwakeMinutes: awakeMinutes,
        },
      );

  static const String _fieldDeepMinutes = 'deepMinutes';
  static const String _fieldLightMinutes = 'lightMinutes';
  static const String _fieldRemMinutes = 'remMinutes';
  static const String _fieldAwakeMinutes = 'awakeMinutes';
}

/// 某一天的活动汇总。
class DailyActivity implements HealthRecord {
  /// 构造日常活动汇总。
  const DailyActivity({
    required this.source,
    required this.externalId,
    required this.date,
    this.steps,
    this.activeCalories,
    this.restingHeartRate,
    this.hrvMs,
  });

  /// 从归一化样本还原。
  static DailyActivity? tryFromSample(HealthSample sample) => DailyActivity(
        source: sample.source,
        externalId: sample.externalId,
        date: sample.startAt,
        steps: sample.intField(_fieldSteps),
        activeCalories: sample.intField(_fieldActiveCalories),
        restingHeartRate: sample.intField(_fieldRestingHeartRate),
        hrvMs: sample.doubleField(_fieldHrvMs),
      );

  @override
  final HealthSourceId source;

  @override
  final String externalId;

  /// 汇总所属日期（取当地零点）。
  final DateTime date;

  /// 步数。
  final int? steps;

  /// 活动消耗（千卡）。
  final int? activeCalories;

  /// 静息心率（次/分）。
  final int? restingHeartRate;

  /// 心率变异性（毫秒）。
  final double? hrvMs;

  @override
  DateTime get occurredAt => date;

  @override
  HealthSample toSample() => HealthSample(
        source: source,
        externalId: externalId,
        kind: HealthSampleKind.dailyActivity,
        startAt: date,
        title: '日常活动',
        payload: {
          if (steps != null) _fieldSteps: steps,
          if (activeCalories != null) _fieldActiveCalories: activeCalories,
          if (restingHeartRate != null)
            _fieldRestingHeartRate: restingHeartRate,
          if (hrvMs != null) _fieldHrvMs: hrvMs,
        },
      );

  static const String _fieldSteps = 'steps';
  static const String _fieldActiveCalories = 'activeCalories';
  static const String _fieldRestingHeartRate = 'restingHeartRate';
  static const String _fieldHrvMs = 'hrvMs';
}
