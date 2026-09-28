import '../../core/glucose_units.dart';
import '../../core/result.dart';
import '../../domain/health/health_records.dart';
import '../../domain/health/health_repository.dart';
import '../../domain/health/health_source.dart';
import '../../domain/health/health_timeline.dart';
import '../database/database.dart';

/// 把本应用录入的数据与外部来源的数据合并成一条统一时间线。
///
/// 这是 AI 工具与统计界面的共同数据底座：只有在同一时间轴上，才能回答
/// 「这顿饭后血糖为什么高」「昨天骑车的功率和今天的空腹血糖有没有关系」
/// 这类跨来源问题。
///
/// 本应用录入的记录以 mmol/L 参与统计——[BloodSugarRecord.unit] 记录的是用户
/// 录入时使用的单位，历史数据可能是 mg/dL，这里统一换算，避免同一份统计里
/// 混入两种量纲。
class HealthTimelineService {
  /// 构造服务。
  HealthTimelineService({
    required AppDatabase database,
    required HealthRepository externalRepository,
  })  : _database = database,
        _external = externalRepository;

  /// 本应用录入数据在时间线上的来源标签。
  static const String localSourceLabel = '本应用';

  final AppDatabase _database;
  final HealthRepository _external;

  /// 按 [query] 构造时间线。
  ///
  /// 本地数据与外部数据任一读取失败都会使整体失败——部分时间线比没有时间线
  /// 更容易导致错误结论，因此不做静默降级。
  Future<Result<HealthTimeline>> build(HealthQuery query) async {
    return guardAsync(
      () async {
        final entries = <HealthTimelineEntry>[];

        if (query.kinds.isEmpty ||
            query.kinds.contains(HealthSampleKind.glucose)) {
          entries.addAll(await _localGlucose(query));
        }
        if (query.kinds.isEmpty ||
            query.kinds.contains(HealthSampleKind.workout)) {
          entries.addAll(await _localWorkouts(query));
        }
        if (query.kinds.isEmpty ||
            query.kinds.contains(HealthSampleKind.glucose) ||
            query.kinds.contains(HealthSampleKind.workout)) {
          // 饮食不是独立样本类别，但它是血糖波动的首要解释变量，
          // 因此在任何涉及血糖或运动的查询里一并带上。
          entries.addAll(await _localMeals(query));
        }
        if (query.kinds.isEmpty ||
            query.kinds.contains(HealthSampleKind.bodyComposition)) {
          entries.addAll(await _localBodyMeasurements(query));
        }

        final external = await _external.query(query);
        if (!external.isOk) throw external.failureOrNull!;
        entries.addAll(
          external.requireValue().map(timelineEntryFromSample),
        );

        entries.sort((a, b) => a.at.compareTo(b.at));
        return HealthTimeline(entries);
      },
      code: 'health.timeline_build',
      message: '构建健康时间线失败',
    );
  }

  /// 读取本应用录入的血糖记录并统一换算为 mmol/L。
  Future<List<HealthTimelineEntry>> _localGlucose(HealthQuery query) async {
    final rows = await _database.getBloodSugarRecordsByDateRange(
      query.start,
      query.end,
    );
    return rows.map((row) {
      final unit = GlucoseUnit.fromLabel(row.unit);
      return HealthTimelineEntry(
        kind: HealthTimelineKind.glucose,
        at: row.recordedAt,
        sourceLabel: localSourceLabel,
        isLocal: true,
        title: _glucoseContextLabel(row.type),
        metrics: <String, Object?>{
          'mmolPerL': toMmolPerL(row.value, unit),
          'context': _glucoseContextCode(row.type),
          if (row.hoursAfterMeal != null)
            'hoursAfterMeal': row.hoursAfterMeal,
          if (row.note != null && row.note!.isNotEmpty) 'note': row.note,
        },
      );
    }).toList();
  }

  /// 读取本应用录入的运动记录。
  ///
  /// `sets`/`weight`/`repsList` 等字段是应用早期版本为力量训练预留的，
  /// 组次明细现在存放在 `strength_trainings` 表；这里只给出汇总口径，
  /// 明细由 AI 工具按需单独查询。
  Future<List<HealthTimelineEntry>> _localWorkouts(HealthQuery query) async {
    final rows = await _database.getExerciseRecordsByDateRange(
      query.start,
      query.end,
    );
    return rows.map((row) {
      final category = _workoutCategoryOf(row.type);
      return HealthTimelineEntry(
        kind: HealthTimelineKind.workout,
        at: row.startedAt,
        until: row.endedAt.isAfter(row.startedAt) ? row.endedAt : null,
        sourceLabel: localSourceLabel,
        isLocal: true,
        title: row.name,
        metrics: <String, Object?>{
          'category': category.code,
          'durationMinutes': row.duration,
          if (row.distance != null) 'distanceKm': row.distance,
          if (row.elevation != null) 'elevationGainM': row.elevation,
          if (row.power != null) 'avgPowerW': row.power,
          if (row.calories != null) 'calories': row.calories,
          if (row.heartRateAvg != null) 'avgHeartRate': row.heartRateAvg,
          if (row.heartRateMax != null) 'maxHeartRate': row.heartRateMax,
          if (row.note != null && row.note!.isNotEmpty) 'note': row.note,
        },
      );
    }).toList();
  }

  /// 读取本应用录入的体测记录。
  Future<List<HealthTimelineEntry>> _localBodyMeasurements(
      HealthQuery query) async {
    final rows = await _database.getBodyMeasurementsByDateRange(
      query.start,
      query.end,
    );
    return rows.map((row) {
      return HealthTimelineEntry(
        kind: HealthTimelineKind.bodyComposition,
        at: row.measuredAt,
        sourceLabel: localSourceLabel,
        isLocal: true,
        title: '体测记录',
        metrics: <String, Object?>{
          if (row.weight != null) 'weightKg': row.weight,
          if (row.bodyFat != null) 'bodyFatPercent': row.bodyFat,
          if (row.muscleMass != null) 'muscleMassKg': row.muscleMass,
          if (row.bmi != null) 'bmi': row.bmi,
          if (row.waist != null) 'waistCm': row.waist,
          if (row.hip != null) 'hipCm': row.hip,
        },
      );
    }).toList();
  }

  /// 读取本应用录入的饮食记录及其食物明细。
  Future<List<HealthTimelineEntry>> _localMeals(HealthQuery query) async {
    final rows = await _database.getMealRecordsByDateRange(
      query.start,
      query.end,
    );
    final entries = <HealthTimelineEntry>[];
    for (final row in rows) {
      final foods = await _database.getFoodItemsByMealId(row.id);
      final carbs = foods
          .map((food) => food.carbs ?? 0)
          .fold<double>(0, (sum, value) => sum + value);
      entries.add(HealthTimelineEntry(
        kind: HealthTimelineKind.meal,
        at: row.recordedAt,
        sourceLabel: localSourceLabel,
        isLocal: true,
        title: _mealTypeLabel(row.type),
        metrics: <String, Object?>{
          'type': row.type,
          if (foods.isNotEmpty)
            'foods': foods
                .map((food) => <String, Object?>{
                      'name': food.name,
                      'amount': food.amount,
                      'unit': food.unit,
                      if (food.carbs != null) 'carbs': food.carbs,
                    })
                .toList(),
          if (carbs > 0) 'carbs': carbs,
          if (row.note != null && row.note!.isNotEmpty) 'note': row.note,
        },
      ));
    }
    return entries;
  }

  /// 把应用内部的餐次编码映射为展示名。
  static String _mealTypeLabel(String type) => switch (type) {
        'breakfast' => '早餐',
        'lunch' => '午餐',
        'dinner' => '晚餐',
        'snack' => '加餐',
        _ => '饮食记录',
      };

  /// 把应用内部的血糖类型字符串映射为归一化编码。
  static String _glucoseContextCode(String type) => switch (type) {
        'fasting' => GlucoseContext.fasting.code,
        'post_meal' => GlucoseContext.postMeal.code,
        'continuous' => GlucoseContext.continuous.code,
        _ => GlucoseContext.random.code,
      };

  /// 把应用内部的血糖类型字符串映射为展示名。
  static String _glucoseContextLabel(String type) =>
      '${GlucoseContext.fromCode(_glucoseContextCode(type)).label}血糖';

  /// 把应用内部的运动类型字符串映射为归一化分类。
  static WorkoutCategory _workoutCategoryOf(String type) => switch (type) {
        'aerobic' => WorkoutCategory.other,
        'anaerobic' => WorkoutCategory.strength,
        'endurance' => WorkoutCategory.other,
        _ => WorkoutCategory.other,
      };
}
