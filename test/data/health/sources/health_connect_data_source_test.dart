/// `HealthConnectDataSource.mapPoints` 的单元测试。
///
/// 覆盖血糖 mg/dL → mmol/L 换算、运动分类与距离单位、按「来源 + 分钟」归并
/// 体测记录、按当地日期汇总步数与消耗，以及睡眠与无法解析记录的处理。
/// 测试只构造 [HealthDataPoint] 纯数据对象，不触碰平台通道。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:glucocontrol/data/health/sources/health_connect_data_source.dart';
import 'package:glucocontrol/domain/health/health_records.dart';
import 'package:glucocontrol/domain/health/health_source.dart';
import 'package:health/health.dart';

final DateTime _day = DateTime(2026, 3, 14);

/// 构造一个数值型数据点。
HealthDataPoint _numeric({
  required HealthDataType type,
  required num value,
  required DateTime dateFrom,
  DateTime? dateTo,
  String uuid = 'u1',
  String sourceId = 'com.example.app',
  String sourceName = 'Example',
  HealthDataUnit unit = HealthDataUnit.UNKNOWN_UNIT,
}) =>
    HealthDataPoint(
      uuid: uuid,
      value: NumericHealthValue(numericValue: value),
      type: type,
      unit: unit,
      dateFrom: dateFrom,
      dateTo: dateTo ?? dateFrom,
      sourcePlatform: HealthPlatformType.googleHealthConnect,
      sourceDeviceId: 'device-1',
      sourceId: sourceId,
      sourceName: sourceName,
    );

/// 构造一个运动数据点。
HealthDataPoint _workout({
  required HealthWorkoutActivityType activityType,
  required DateTime dateFrom,
  required DateTime dateTo,
  int? totalDistance,
  HealthDataUnit? totalDistanceUnit,
  int? totalEnergyBurned,
  String uuid = 'w1',
  String sourceName = 'Keep',
}) =>
    HealthDataPoint(
      uuid: uuid,
      value: WorkoutHealthValue(
        workoutActivityType: activityType,
        totalDistance: totalDistance,
        totalDistanceUnit: totalDistanceUnit,
        totalEnergyBurned: totalEnergyBurned,
      ),
      type: HealthDataType.WORKOUT,
      unit: HealthDataUnit.UNKNOWN_UNIT,
      dateFrom: dateFrom,
      dateTo: dateTo,
      sourcePlatform: HealthPlatformType.googleHealthConnect,
      sourceDeviceId: 'device-1',
      sourceId: 'com.gotokeep.keep',
      sourceName: sourceName,
    );

void main() {
  group('血糖换算', () {
    test('mg/dL 换算为 mmol/L 并保留原始值', () {
      final at = _day.add(const Duration(hours: 8, minutes: 30));
      final result = HealthConnectDataSource.mapPoints(<HealthDataPoint>[
        _numeric(
          type: HealthDataType.BLOOD_GLUCOSE,
          value: 180,
          dateFrom: at,
          uuid: 'g1',
          sourceName: '硅基轻享',
        ),
      ]);

      final sample = result.samples.single;
      expect(result.warnings, isEmpty);
      expect(sample.source, HealthSourceId.healthConnect);
      expect(sample.kind, HealthSampleKind.glucose);
      expect(sample.externalId, 'hc:glucose:g1');
      expect(sample.startAt, at);
      expect(sample.endAt, isNull);
      expect(sample.originApp, '硅基轻享');
      expect(sample.doubleField('mmolPerL'), closeTo(9.9899, 1e-4));
      expect(sample.doubleField('mgPerDl'), 180.0);
      expect(sample.payload['context'], 'continuous');
      expect(sample.title, '动态监测血糖');
    });

    test('换算使用 18.0182 系数', () {
      final result = HealthConnectDataSource.mapPoints(<HealthDataPoint>[
        _numeric(
          type: HealthDataType.BLOOD_GLUCOSE,
          value: 100,
          dateFrom: _day,
        ),
      ]);

      expect(result.samples.single.doubleField('mmolPerL'), closeTo(5.5499, 1e-4));
    });

    test('非正血糖值被跳过并计入告警', () {
      final result = HealthConnectDataSource.mapPoints(<HealthDataPoint>[
        _numeric(type: HealthDataType.BLOOD_GLUCOSE, value: 0, dateFrom: _day),
        _numeric(
          type: HealthDataType.BLOOD_GLUCOSE,
          value: -3,
          dateFrom: _day,
          uuid: 'g2',
        ),
      ]);

      expect(result.samples, isEmpty);
      expect(result.warnings.length, 2);
      expect(result.warnings.first, contains('血糖'));
    });

    test('非数值型血糖数据点被跳过', () {
      final result = HealthConnectDataSource.mapPoints(<HealthDataPoint>[
        _workout(
          activityType: HealthWorkoutActivityType.BIKING,
          dateFrom: _day,
          dateTo: _day.add(const Duration(hours: 1)),
        ).copyWithType(HealthDataType.BLOOD_GLUCOSE),
      ]);

      expect(result.samples, isEmpty);
      expect(result.warnings.single, contains('血糖'));
    });
  });

  group('运动记录', () {
    test('距离与消耗被换算并保留来源应用', () {
      final from = _day.add(const Duration(hours: 7));
      final result = HealthConnectDataSource.mapPoints(<HealthDataPoint>[
        _workout(
          activityType: HealthWorkoutActivityType.BIKING,
          dateFrom: from,
          dateTo: from.add(const Duration(hours: 1, minutes: 30)),
          totalDistance: 5000,
          totalDistanceUnit: HealthDataUnit.METER,
          totalEnergyBurned: 320,
        ),
      ]);

      final sample = result.samples.single;
      expect(result.warnings, isEmpty);
      expect(sample.kind, HealthSampleKind.workout);
      expect(sample.externalId, 'hc:workout:w1');
      expect(sample.title, 'biking');
      expect(sample.originApp, 'Keep');
      expect(sample.payload['category'], 'cycling');
      expect(sample.doubleField('distanceKm'), closeTo(5.0, 1e-9));
      expect(sample.payload['calories'], 320);

      final session = WorkoutSession.tryFromSample(sample)!;
      expect(session.category, WorkoutCategory.cycling);
      expect(session.durationMinutes, 90.0);
      expect(session.distanceKm, closeTo(5.0, 1e-9));
      expect(session.calories, 320);
    });

    test('英里距离按 1.609344 换算为公里', () {
      final result = HealthConnectDataSource.mapPoints(<HealthDataPoint>[
        _workout(
          activityType: HealthWorkoutActivityType.RUNNING,
          dateFrom: _day,
          dateTo: _day.add(const Duration(minutes: 30)),
          totalDistance: 3,
          totalDistanceUnit: HealthDataUnit.MILE,
        ),
      ]);

      expect(result.samples.single.doubleField('distanceKm'),
          closeTo(3 * 1.609344, 1e-9));
    });

    test('未知距离单位按米处理', () {
      final result = HealthConnectDataSource.mapPoints(<HealthDataPoint>[
        _workout(
          activityType: HealthWorkoutActivityType.WALKING,
          dateFrom: _day,
          dateTo: _day.add(const Duration(minutes: 30)),
          totalDistance: 2500,
          totalDistanceUnit: HealthDataUnit.UNKNOWN_UNIT,
        ),
      ]);

      expect(result.samples.single.doubleField('distanceKm'), closeTo(2.5, 1e-9));
    });

    test('没有距离与消耗时不写入对应字段', () {
      final result = HealthConnectDataSource.mapPoints(<HealthDataPoint>[
        _workout(
          activityType: HealthWorkoutActivityType.YOGA,
          dateFrom: _day,
          dateTo: _day.add(const Duration(minutes: 45)),
        ),
      ]);

      final sample = result.samples.single;
      expect(sample.payload.containsKey('distanceKm'), isFalse);
      expect(sample.payload.containsKey('calories'), isFalse);
      expect(sample.payload['category'], 'yoga');
      expect(sample.title, 'yoga');
    });

    test('运动类型到归一化分类的映射', () {
      final cases = <HealthWorkoutActivityType, WorkoutCategory>{
        HealthWorkoutActivityType.BIKING: WorkoutCategory.cycling,
        HealthWorkoutActivityType.BIKING_STATIONARY: WorkoutCategory.cycling,
        HealthWorkoutActivityType.RUNNING: WorkoutCategory.running,
        HealthWorkoutActivityType.RUNNING_TREADMILL: WorkoutCategory.running,
        HealthWorkoutActivityType.WALKING: WorkoutCategory.walking,
        HealthWorkoutActivityType.WALKING_TREADMILL: WorkoutCategory.walking,
        HealthWorkoutActivityType.HIKING: WorkoutCategory.walking,
        HealthWorkoutActivityType.SWIMMING: WorkoutCategory.swimming,
        HealthWorkoutActivityType.SWIMMING_POOL: WorkoutCategory.swimming,
        HealthWorkoutActivityType.SWIMMING_OPEN_WATER: WorkoutCategory.swimming,
        HealthWorkoutActivityType.HIGH_INTENSITY_INTERVAL_TRAINING:
            WorkoutCategory.hiit,
        HealthWorkoutActivityType.YOGA: WorkoutCategory.yoga,
        HealthWorkoutActivityType.PILATES: WorkoutCategory.yoga,
        HealthWorkoutActivityType.STRENGTH_TRAINING: WorkoutCategory.strength,
        HealthWorkoutActivityType.WEIGHTLIFTING: WorkoutCategory.strength,
        HealthWorkoutActivityType.CALISTHENICS: WorkoutCategory.strength,
        HealthWorkoutActivityType.AMERICAN_FOOTBALL: WorkoutCategory.other,
      };

      cases.forEach((activityType, expected) {
        final result = HealthConnectDataSource.mapPoints(<HealthDataPoint>[
          _workout(
            activityType: activityType,
            dateFrom: _day,
            dateTo: _day.add(const Duration(minutes: 30)),
          ),
        ]);

        expect(
          WorkoutCategory.fromCode(
              result.samples.single.stringField('category')),
          expected,
          reason: '$activityType 应映射为 ${expected.code}',
        );
      });
    });

    test('运动名称由枚举名转小写并去掉下划线', () {
      final result = HealthConnectDataSource.mapPoints(<HealthDataPoint>[
        _workout(
          activityType: HealthWorkoutActivityType.RUNNING_TREADMILL,
          dateFrom: _day,
          dateTo: _day.add(const Duration(minutes: 30)),
        ),
      ]);

      expect(result.samples.single.title, 'running treadmill');
    });

    test('运动数据点的值不是 WorkoutHealthValue 时跳过并告警', () {
      final result = HealthConnectDataSource.mapPoints(<HealthDataPoint>[
        _numeric(
          type: HealthDataType.WORKOUT,
          value: 30,
          dateFrom: _day,
          dateTo: _day.add(const Duration(minutes: 30)),
        ),
      ]);

      expect(result.samples, isEmpty);
      expect(result.warnings.single, contains('运动'));
    });
  });

  group('体测记录的归并', () {
    test('同一来源同一分钟内的体重与体脂合并为一条体测', () {
      final from = DateTime(2026, 3, 14, 7, 0, 10);
      final result = HealthConnectDataSource.mapPoints(<HealthDataPoint>[
        _numeric(
          type: HealthDataType.WEIGHT,
          value: 70.5,
          dateFrom: from,
          sourceId: 'scale-a',
          sourceName: '智能秤',
        ),
        _numeric(
          type: HealthDataType.BODY_FAT_PERCENTAGE,
          value: 18.2,
          dateFrom: from.add(const Duration(seconds: 40)),
          sourceId: 'scale-a',
          sourceName: '智能秤',
        ),
      ]);

      final sample = result.samples.single;
      expect(sample.kind, HealthSampleKind.bodyComposition);
      expect(
        sample.externalId,
        'hc:body:scale-a:${from.millisecondsSinceEpoch ~/ 60000}',
      );
      expect(sample.startAt, from);
      expect(sample.originApp, '智能秤');
      expect(sample.doubleField('weightKg'), 70.5);
      expect(sample.doubleField('bodyFatPercent'), 18.2);
    });

    test('肌肉量、BMI 与腰围各自映射到对应字段', () {
      final from = DateTime(2026, 3, 14, 7, 0);
      final result = HealthConnectDataSource.mapPoints(<HealthDataPoint>[
        _numeric(
          type: HealthDataType.LEAN_BODY_MASS,
          value: 55.1,
          dateFrom: from,
        ),
        _numeric(
          type: HealthDataType.BODY_MASS_INDEX,
          value: 22.8,
          dateFrom: from,
        ),
        _numeric(
          type: HealthDataType.WAIST_CIRCUMFERENCE,
          value: 0.82,
          dateFrom: from,
        ),
      ]);

      final sample = result.samples.single;
      expect(sample.doubleField('muscleMassKg'), 55.1);
      expect(sample.doubleField('bmi'), 22.8);
      expect(sample.doubleField('waistCm'), 0.82);
      expect(sample.payload.containsKey('weightKg'), isFalse);
    });

    test('来源不同则分成两条体测', () {
      final from = DateTime(2026, 3, 14, 7, 0);
      final result = HealthConnectDataSource.mapPoints(<HealthDataPoint>[
        _numeric(
          type: HealthDataType.WEIGHT,
          value: 70.5,
          dateFrom: from,
          sourceId: 'scale-a',
        ),
        _numeric(
          type: HealthDataType.WEIGHT,
          value: 71.0,
          dateFrom: from,
          sourceId: 'scale-b',
          uuid: 'u2',
        ),
      ]);

      expect(result.samples.length, 2);
      expect(
        result.samples.map((sample) => sample.externalId).toSet(),
        <String>{
          'hc:body:scale-a:${from.millisecondsSinceEpoch ~/ 60000}',
          'hc:body:scale-b:${from.millisecondsSinceEpoch ~/ 60000}',
        },
      );
    });

    test('同一来源但跨分钟则分成两条体测', () {
      final from = DateTime(2026, 3, 14, 7, 0, 10);
      final result = HealthConnectDataSource.mapPoints(<HealthDataPoint>[
        _numeric(type: HealthDataType.WEIGHT, value: 70.5, dateFrom: from),
        _numeric(
          type: HealthDataType.BODY_FAT_PERCENTAGE,
          value: 18.2,
          dateFrom: from.add(const Duration(minutes: 2)),
        ),
      ]);

      expect(result.samples.length, 2);
    });

    test('数值缺失的体测数据点被整条忽略', () {
      final result = HealthConnectDataSource.mapPoints(<HealthDataPoint>[
        _workout(
          activityType: HealthWorkoutActivityType.BIKING,
          dateFrom: _day,
          dateTo: _day.add(const Duration(hours: 1)),
        ).copyWithType(HealthDataType.WEIGHT),
      ]);

      expect(result.samples, isEmpty);
      expect(result.warnings, isEmpty);
    });
  });

  group('日常活动按当地日期汇总', () {
    test('同一天的步数累加为一条记录', () {
      final result = HealthConnectDataSource.mapPoints(<HealthDataPoint>[
        _numeric(
          type: HealthDataType.STEPS,
          value: 4000,
          dateFrom: DateTime(2026, 3, 14, 10),
        ),
        _numeric(
          type: HealthDataType.STEPS,
          value: 4421,
          dateFrom: DateTime(2026, 3, 14, 15),
        ),
      ]);

      final sample = result.samples.single;
      expect(sample.kind, HealthSampleKind.dailyActivity);
      expect(sample.externalId, 'hc:daily:2026-03-14');
      expect(sample.startAt, DateTime(2026, 3, 14));
      expect(sample.payload['steps'], 8421);
      expect(sample.payload.containsKey('activeCalories'), isFalse);
    });

    test('不同日期的步数分别汇总', () {
      final result = HealthConnectDataSource.mapPoints(<HealthDataPoint>[
        _numeric(
          type: HealthDataType.STEPS,
          value: 3000,
          dateFrom: DateTime(2026, 3, 14, 23, 30),
        ),
        _numeric(
          type: HealthDataType.STEPS,
          value: 1000,
          dateFrom: DateTime(2026, 3, 15, 0, 30),
          uuid: 'u2',
        ),
      ]);

      expect(
        result.samples.map((sample) => sample.externalId).toList(),
        <String>['hc:daily:2026-03-14', 'hc:daily:2026-03-15'],
      );
      expect(result.samples.first.payload['steps'], 3000);
      expect(result.samples.last.payload['steps'], 1000);
    });

    test('同一天的步数、消耗与心率合并为一条记录', () {
      final result = HealthConnectDataSource.mapPoints(<HealthDataPoint>[
        _numeric(
          type: HealthDataType.STEPS,
          value: 8000,
          dateFrom: DateTime(2026, 3, 14, 20),
        ),
        _numeric(
          type: HealthDataType.ACTIVE_ENERGY_BURNED,
          value: 300,
          dateFrom: DateTime(2026, 3, 14, 12),
        ),
        _numeric(
          type: HealthDataType.ACTIVE_ENERGY_BURNED,
          value: 212,
          dateFrom: DateTime(2026, 3, 14, 21),
        ),
        _numeric(
          type: HealthDataType.RESTING_HEART_RATE,
          value: 57,
          dateFrom: DateTime(2026, 3, 14, 6),
        ),
        _numeric(
          type: HealthDataType.RESTING_HEART_RATE,
          value: 60,
          dateFrom: DateTime(2026, 3, 14, 22),
        ),
        _numeric(
          type: HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
          value: 40,
          dateFrom: DateTime(2026, 3, 14, 6),
        ),
        _numeric(
          type: HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
          value: 45,
          dateFrom: DateTime(2026, 3, 14, 22),
        ),
      ]);

      final sample = result.samples.single;
      expect(sample.payload['steps'], 8000);
      expect(sample.payload['activeCalories'], 512);
      // (57 + 60) / 2 = 58.5 → 四舍五入为 59。
      expect(sample.payload['restingHeartRate'], 59);
      expect(sample.doubleField('hrvMs'), 42.5);
    });

    test('静息心率与 HRV 的均值按当日样本计算', () {
      final result = HealthConnectDataSource.mapPoints(<HealthDataPoint>[
        _numeric(
          type: HealthDataType.RESTING_HEART_RATE,
          value: 60,
          dateFrom: DateTime(2026, 3, 14, 6),
        ),
        _numeric(
          type: HealthDataType.RESTING_HEART_RATE,
          value: 61,
          dateFrom: DateTime(2026, 3, 14, 7),
        ),
        _numeric(
          type: HealthDataType.RESTING_HEART_RATE,
          value: 62,
          dateFrom: DateTime(2026, 3, 14, 8),
        ),
      ]);

      // (60 + 61 + 62) / 3 = 61。
      expect(result.samples.single.payload['restingHeartRate'], 61);
    });

    test('日常活动记录可以被 DailyActivity 还原', () {
      final result = HealthConnectDataSource.mapPoints(<HealthDataPoint>[
        _numeric(
          type: HealthDataType.STEPS,
          value: 8421,
          dateFrom: DateTime(2026, 3, 14, 10),
        ),
      ]);

      final activity = DailyActivity.tryFromSample(result.samples.single)!;
      expect(activity.steps, 8421);
      expect(activity.date, DateTime(2026, 3, 14));
      expect(activity.source, HealthSourceId.healthConnect);
    });
  });

  group('睡眠记录', () {
    test('有结束时间时生成一条睡眠样本', () {
      final from = DateTime(2026, 3, 13, 23, 10);
      final to = DateTime(2026, 3, 14, 7, 5);
      final result = HealthConnectDataSource.mapPoints(<HealthDataPoint>[
        _numeric(
          type: HealthDataType.SLEEP_SESSION,
          value: 0,
          dateFrom: from,
          dateTo: to,
          uuid: 's1',
          sourceName: '华为运动健康',
        ),
      ]);

      final sample = result.samples.single;
      expect(sample.kind, HealthSampleKind.sleep);
      expect(sample.externalId, 'hc:sleep:s1');
      expect(sample.startAt, from);
      expect(sample.endAt, to);
      expect(sample.originApp, '华为运动健康');
      expect(sample.title, '睡眠');
      // 不写入未经验证的睡眠分期。
      expect(sample.payload, isEmpty);

      expect(SleepSession.tryFromSample(sample)!.totalMinutes, 475);
    });

    test('结束时间不晚于开始时间时跳过且不告警', () {
      final at = DateTime(2026, 3, 14, 7);
      final result = HealthConnectDataSource.mapPoints(<HealthDataPoint>[
        _numeric(
          type: HealthDataType.SLEEP_SESSION,
          value: 0,
          dateFrom: at,
          dateTo: at,
        ),
      ]);

      expect(result.samples, isEmpty);
      expect(result.warnings, isEmpty);
    });
  });

  group('混合输入', () {
    test('各类型记录同时出现时按类别分别产出并给出告警', () {
      final result = HealthConnectDataSource.mapPoints(<HealthDataPoint>[
        _numeric(
          type: HealthDataType.BLOOD_GLUCOSE,
          value: 108,
          dateFrom: DateTime(2026, 3, 14, 8),
          uuid: 'g1',
        ),
        _numeric(
          type: HealthDataType.WEIGHT,
          value: 70.5,
          dateFrom: DateTime(2026, 3, 14, 7),
        ),
        _numeric(
          type: HealthDataType.STEPS,
          value: 5000,
          dateFrom: DateTime(2026, 3, 14, 12),
        ),
        _workout(
          activityType: HealthWorkoutActivityType.RUNNING,
          dateFrom: DateTime(2026, 3, 14, 18),
          dateTo: DateTime(2026, 3, 14, 19),
          totalDistance: 10000,
          totalDistanceUnit: HealthDataUnit.METER,
        ),
        _numeric(
          type: HealthDataType.SLEEP_SESSION,
          value: 0,
          dateFrom: DateTime(2026, 3, 13, 23),
          dateTo: DateTime(2026, 3, 14, 6, 30),
          uuid: 's1',
        ),
        _numeric(
          type: HealthDataType.BLOOD_GLUCOSE,
          value: 0,
          dateFrom: DateTime(2026, 3, 14, 9),
          uuid: 'g2',
        ),
      ]);

      expect(result.warnings.length, 1);
      expect(result.samples.length, 5);
      expect(
        result.samples.map((sample) => sample.kind).toList(),
        <HealthSampleKind>[
          HealthSampleKind.glucose,
          HealthSampleKind.workout,
          HealthSampleKind.sleep,
          HealthSampleKind.bodyComposition,
          HealthSampleKind.dailyActivity,
        ],
      );
    });

    test('空输入返回空结果', () {
      final result = HealthConnectDataSource.mapPoints(<HealthDataPoint>[]);

      expect(result.samples, isEmpty);
      expect(result.warnings, isEmpty);
    });

    test('连接器标识与请求类型清单稳定', () {
      final source = HealthConnectDataSource();

      expect(source.id, HealthSourceId.healthConnect);
      expect(source.supportsAutomaticSync, isTrue);
      expect(
        HealthConnectDataSource.requestedTypes,
        containsAll(<HealthDataType>[
          HealthDataType.BLOOD_GLUCOSE,
          HealthDataType.WEIGHT,
          HealthDataType.WORKOUT,
          HealthDataType.SLEEP_SESSION,
          HealthDataType.STEPS,
        ]),
      );
      expect(HealthConnectDataSource.requestedTypes.length, 12);
    });
  });
}

/// 便于把运动数据点改写成其他类型，用于验证类型不符时的降级。
extension on HealthDataPoint {
  HealthDataPoint copyWithType(HealthDataType newType) => HealthDataPoint(
        uuid: uuid,
        value: value,
        type: newType,
        unit: unit,
        dateFrom: dateFrom,
        dateTo: dateTo,
        sourcePlatform: sourcePlatform,
        sourceDeviceId: sourceDeviceId,
        sourceId: sourceId,
        sourceName: sourceName,
      );
}
