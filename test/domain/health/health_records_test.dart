/// `health_records.dart` 中类型化记录模型的单元测试。
///
/// 每个模型的 `toSample()` → `tryFromSample()` 字段守恒、payload 键名与模型
/// 使用的键名一致（往返时不丢字段、不产生幻影值）、缺必要字段时的降级，以及
/// [WorkoutSession.durationMinutes] 等派生量。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:glucocontrol/core/glucose_units.dart';
import 'package:glucocontrol/domain/health/health_records.dart';
import 'package:glucocontrol/domain/health/health_source.dart';

final DateTime _at = DateTime(2026, 3, 14, 8, 30);

void main() {
  group('HealthSourceId 与 HealthSampleKind 的编码', () {
    test('tryFromCode 还原全部已知编码并拒绝未知值', () {
      for (final source in HealthSourceId.values) {
        expect(HealthSourceId.tryFromCode(source.code), source);
      }
      expect(HealthSourceId.tryFromCode('nightscout'), HealthSourceId.nightscout);
      expect(HealthSourceId.tryFromCode('nope'), isNull);
      expect(HealthSourceId.tryFromCode(null), isNull);

      for (final kind in HealthSampleKind.values) {
        expect(HealthSampleKind.tryFromCode(kind.code), kind);
      }
      expect(HealthSampleKind.tryFromCode('body_composition'),
          HealthSampleKind.bodyComposition);
      expect(HealthSampleKind.tryFromCode('nope'), isNull);
    });

    test('文件型与在线授权型数据源分类正确', () {
      expect(HealthSourceId.fileImport.isFileBased, isTrue);
      expect(HealthSourceId.sibionics.isFileBased, isTrue);
      expect(HealthSourceId.nightscout.isFileBased, isFalse);

      expect(HealthSourceId.healthConnect.requiresOnlineAuthorization, isTrue);
      expect(HealthSourceId.huaweiHealth.requiresOnlineAuthorization, isTrue);
      expect(HealthSourceId.manual.requiresOnlineAuthorization, isFalse);
    });
  });

  group('HealthSample 的载荷读取', () {
    final sample = HealthSample(
      source: HealthSourceId.manual,
      externalId: 'm:1',
      kind: HealthSampleKind.bodyComposition,
      startAt: _at,
      endAt: _at.add(const Duration(minutes: 30)),
      payload: const <String, Object?>{
        'asInt': 70,
        'asDouble': 22.5,
        'asNum': 3,
        'numAsText': '18.5',
        'intAsText': '7',
        'flag': true,
        'flagText': 'TRUE',
        'flagTextFalse': 'false',
        'wrongType': <String>[],
      },
    );

    test('doubleField 接受 num 与可解析字符串', () {
      expect(sample.doubleField('asInt'), 70.0);
      expect(sample.doubleField('asDouble'), 22.5);
      expect(sample.doubleField('numAsText'), 18.5);
      expect(sample.doubleField('missing'), isNull);
      expect(sample.doubleField('wrongType'), isNull);
      expect(sample.doubleField('flag'), isNull);
    });

    test('intField 接受 int、num 与可解析字符串并四舍五入', () {
      expect(sample.intField('asInt'), 70);
      expect(sample.intField('asNum'), 3);
      expect(sample.intField('intAsText'), 7);
      expect(sample.intField('wrongType'), isNull);
      expect(
        HealthSample(
          source: HealthSourceId.manual,
          externalId: 'm:2',
          kind: HealthSampleKind.bodyComposition,
          startAt: _at,
          payload: const <String, Object?>{'v': 3.7},
        ).intField('v'),
        4,
      );
    });

    test('stringField 只接受字符串', () {
      expect(sample.stringField('numAsText'), '18.5');
      expect(sample.stringField('asInt'), isNull);
      expect(sample.stringField('missing'), isNull);
    });

    test('boolField 接受 bool 与大小写不敏感的字符串', () {
      expect(sample.boolField('flag'), isTrue);
      expect(sample.boolField('flagText'), isTrue);
      expect(sample.boolField('flagTextFalse'), isFalse);
      expect(sample.boolField('asInt'), isNull);
      expect(sample.boolField('missing'), isNull);
    });

    test('duration 由 endAt 与 startAt 之差得到，瞬时样本为 null', () {
      expect(sample.duration, const Duration(minutes: 30));
      expect(
        HealthSample(
          source: HealthSourceId.manual,
          externalId: 'm:3',
          kind: HealthSampleKind.glucose,
          startAt: _at,
        ).duration,
        isNull,
      );
    });

    test('payload 缺省为空映射', () {
      final bare = HealthSample(
        source: HealthSourceId.manual,
        externalId: 'm:4',
        kind: HealthSampleKind.glucose,
        startAt: _at,
      );
      expect(bare.payload, isEmpty);
      expect(bare.endAt, isNull);
      expect(bare.title, isNull);
      expect(bare.originApp, isNull);
    });
  });

  group('GlucoseReading', () {
    test('payload 键名与模型字段一致', () {
      final sample = GlucoseReading(
        source: HealthSourceId.nightscout,
        externalId: 'nightscout:abc',
        recordedAt: _at,
        mmolPerL: 5.6,
        context: GlucoseContext.postMeal,
        trend: GlucoseTrend.steady,
      ).toSample();

      expect(sample.kind, HealthSampleKind.glucose);
      expect(sample.externalId, 'nightscout:abc');
      expect(sample.startAt, _at);
      expect(sample.endAt, isNull);
      expect(sample.payload.keys.toSet(), <String>{'mmolPerL', 'context', 'trend'});
      expect(sample.title, '餐后血糖');
      expect(sample.payload['mmolPerL'], 5.6);
      expect(sample.payload['context'], 'post_meal');
      expect(sample.payload['trend'], 'steady');
    });

    test('往返守恒：全部字段还原', () {
      final original = GlucoseReading(
        source: HealthSourceId.healthConnect,
        externalId: 'hc:glucose:u1',
        recordedAt: _at,
        mmolPerL: 9.99,
        context: GlucoseContext.continuous,
        trend: GlucoseTrend.risingFast,
        note: '运动后',
      );

      final restored = GlucoseReading.tryFromSample(original.toSample())!;

      expect(restored.source, original.source);
      expect(restored.externalId, original.externalId);
      expect(restored.recordedAt, original.recordedAt);
      expect(restored.mmolPerL, original.mmolPerL);
      expect(restored.context, original.context);
      expect(restored.trend, original.trend);
      expect(restored.note, original.note);
    });

    test('可空字段为 null 时不写入 payload，往返后仍为 null', () {
      final sample = GlucoseReading(
        source: HealthSourceId.manual,
        externalId: 'm:9',
        recordedAt: _at,
        mmolPerL: 4.4,
      ).toSample();

      expect(sample.payload.containsKey('trend'), isFalse);
      expect(sample.payload.containsKey('note'), isFalse);
      expect(sample.payload['context'], 'random');

      final restored = GlucoseReading.tryFromSample(sample)!;
      expect(restored.trend, isNull);
      expect(restored.note, isNull);
      expect(restored.context, GlucoseContext.random);
    });

    test('缺少 mmolPerL 时 tryFromSample 返回 null', () {
      final sample = HealthSample(
        source: HealthSourceId.manual,
        externalId: 'm:10',
        kind: HealthSampleKind.glucose,
        startAt: _at,
        payload: const <String, Object?>{'context': 'fasting'},
      );

      expect(GlucoseReading.tryFromSample(sample), isNull);
    });

    test('缺 context 时降级为随机，非法 trend 降级为 null', () {
      final restored = GlucoseReading.tryFromSample(HealthSample(
        source: HealthSourceId.manual,
        externalId: 'm:11',
        kind: HealthSampleKind.glucose,
        startAt: _at,
        payload: const <String, Object?>{'mmolPerL': 6.0, 'trend': 'sideways'},
      ))!;

      expect(restored.context, GlucoseContext.random);
      expect(restored.trend, isNull);
    });

    test('valueIn 按目标单位换算', () {
      final reading = GlucoseReading(
        source: HealthSourceId.manual,
        externalId: 'm:12',
        recordedAt: _at,
        mmolPerL: 5.5,
      );

      expect(reading.valueIn(GlucoseUnit.mmolPerL), 5.5);
      expect(reading.valueIn(GlucoseUnit.mgPerDl), closeTo(99.1001, 1e-4));
    });
  });

  group('GlucoseTrend 与 WorkoutCategory', () {
    test('GlucoseTrend 的编码与箭头齐全', () {
      expect(GlucoseTrend.risingFast.code, 'rising_fast');
      expect(GlucoseTrend.risingFast.arrow, '↑↑');
      expect(GlucoseTrend.steady.code, 'steady');
      expect(GlucoseTrend.steady.arrow, '→');
      expect(GlucoseTrend.fallingFast.arrow, '↓↓');
      for (final trend in GlucoseTrend.values) {
        expect(GlucoseTrend.tryFromCode(trend.code), trend);
      }
      expect(GlucoseTrend.tryFromCode('flat'), isNull);
      expect(GlucoseTrend.tryFromCode(null), isNull);
    });

    test('WorkoutCategory 的未知编码降级为 other', () {
      expect(WorkoutCategory.fromCode('strength'), WorkoutCategory.strength);
      expect(WorkoutCategory.fromCode('cycling'), WorkoutCategory.cycling);
      expect(WorkoutCategory.fromCode('STRENGTH'), WorkoutCategory.other);
      expect(WorkoutCategory.fromCode(null), WorkoutCategory.other);
      expect(WorkoutCategory.other.label, '其他');
    });

    test('有氧分类判定覆盖五种项目', () {
      for (final category in <WorkoutCategory>[
        WorkoutCategory.cycling,
        WorkoutCategory.running,
        WorkoutCategory.walking,
        WorkoutCategory.swimming,
        WorkoutCategory.hiit,
      ]) {
        expect(category.isAerobic, isTrue, reason: '${category.code} 应为有氧');
      }
      expect(WorkoutCategory.strength.isAerobic, isFalse);
      expect(WorkoutCategory.yoga.isAerobic, isFalse);
      expect(WorkoutCategory.other.isAerobic, isFalse);
    });
  });

  group('WorkoutSession', () {
    WorkoutSession full() => WorkoutSession(
          source: HealthSourceId.igpsport,
          externalId: 'igpsport:ride-1',
          startedAt: DateTime(2026, 3, 14, 7, 0),
          endedAt: DateTime(2026, 3, 14, 8, 30, 30),
          category: WorkoutCategory.cycling,
          name: '晨骑',
          distanceKm: 42.195,
          elevationGainM: 320,
          avgPowerW: 187.5,
          normalizedPowerW: 205,
          avgHeartRate: 142,
          maxHeartRate: 176,
          calories: 720,
          totalVolumeKg: 1250.5,
          totalSets: 12,
          totalReps: 96,
          note: '逆风',
          originApp: 'iGPSPORT',
        );

    test('payload 键名与模型字段一致且可空字段按需写入', () {
      final sample = full().toSample();

      expect(sample.kind, HealthSampleKind.workout);
      expect(sample.startAt, DateTime(2026, 3, 14, 7, 0));
      expect(sample.endAt, DateTime(2026, 3, 14, 8, 30, 30));
      expect(sample.title, '晨骑');
      expect(sample.originApp, 'iGPSPORT');
      expect(sample.payload.keys.toSet(), <String>{
        'category',
        'name',
        'distanceKm',
        'elevationGainM',
        'avgPowerW',
        'normalizedPowerW',
        'avgHeartRate',
        'maxHeartRate',
        'calories',
        'totalVolumeKg',
        'totalSets',
        'totalReps',
        'note',
      });
      expect(sample.payload['category'], 'cycling');
      expect(sample.payload['maxHeartRate'], 176);
      expect(sample.payload['totalVolumeKg'], 1250.5);
    });

    test('往返守恒：全部字段还原', () {
      final original = full();

      final restored = WorkoutSession.tryFromSample(original.toSample())!;

      expect(restored.source, original.source);
      expect(restored.externalId, original.externalId);
      expect(restored.startedAt, original.startedAt);
      expect(restored.endedAt, original.endedAt);
      expect(restored.category, original.category);
      expect(restored.name, original.name);
      expect(restored.distanceKm, original.distanceKm);
      expect(restored.elevationGainM, original.elevationGainM);
      expect(restored.avgPowerW, original.avgPowerW);
      expect(restored.normalizedPowerW, original.normalizedPowerW);
      expect(restored.avgHeartRate, original.avgHeartRate);
      expect(restored.maxHeartRate, original.maxHeartRate);
      expect(restored.calories, original.calories);
      expect(restored.totalVolumeKg, original.totalVolumeKg);
      expect(restored.totalSets, original.totalSets);
      expect(restored.totalReps, original.totalReps);
      expect(restored.note, original.note);
      expect(restored.originApp, original.originApp);
    });

    test('可空字段全为 null 时 payload 只剩必填项且往返不产生幻影值', () {
      final original = WorkoutSession(
        source: HealthSourceId.xunji,
        externalId: 'xunji:t1',
        startedAt: _at,
        endedAt: _at.add(const Duration(hours: 1)),
        category: WorkoutCategory.strength,
        name: '练背',
      );

      final sample = original.toSample();
      expect(sample.payload.keys.toSet(), <String>{'category', 'name'});

      final restored = WorkoutSession.tryFromSample(sample)!;
      expect(restored.distanceKm, isNull);
      expect(restored.avgPowerW, isNull);
      expect(restored.calories, isNull);
      expect(restored.totalVolumeKg, isNull);
      expect(restored.totalSets, isNull);
      expect(restored.totalReps, isNull);
      expect(restored.note, isNull);
      expect(restored.originApp, isNull);
    });

    test('durationMinutes 精确到秒换算为分钟', () {
      expect(full().durationMinutes, 90.5);

      final short = WorkoutSession(
        source: HealthSourceId.manual,
        externalId: 'm:1',
        startedAt: DateTime(2026, 3, 14, 9, 0),
        endedAt: DateTime(2026, 3, 14, 9, 0, 45),
        category: WorkoutCategory.other,
        name: '拉伸',
      );
      expect(short.durationMinutes, 0.75);
    });

    test('缺少 endAt 时 tryFromSample 返回 null', () {
      final sample = HealthSample(
        source: HealthSourceId.manual,
        externalId: 'm:2',
        kind: HealthSampleKind.workout,
        startAt: _at,
        payload: const <String, Object?>{'name': '跑步'},
      );

      expect(WorkoutSession.tryFromSample(sample), isNull);
    });

    test('缺 name 时用样本标题兜底，再退化到「运动」', () {
      final withTitle = WorkoutSession.tryFromSample(HealthSample(
        source: HealthSourceId.keep,
        externalId: 'k:1',
        kind: HealthSampleKind.workout,
        startAt: _at,
        endAt: _at.add(const Duration(minutes: 30)),
        title: '户外跑',
        payload: const <String, Object?>{'category': 'running'},
      ))!;
      expect(withTitle.name, '户外跑');

      final bare = WorkoutSession.tryFromSample(HealthSample(
        source: HealthSourceId.keep,
        externalId: 'k:2',
        kind: HealthSampleKind.workout,
        startAt: _at,
        endAt: _at.add(const Duration(minutes: 30)),
      ))!;
      expect(bare.name, '运动');
      expect(bare.category, WorkoutCategory.other);
    });

    test('occurredAt 取开始时间', () {
      expect(full().occurredAt, full().startedAt);
    });

    test('intensityFactor 优先用标准化功率，缺 FTP 时返回 null', () {
      final session = full();

      expect(session.intensityFactor(250), closeTo(0.82, 1e-9));
      expect(session.intensityFactor(null), isNull);
      expect(session.intensityFactor(0), isNull);
      expect(session.intensityFactor(-10), isNull);
    });

    test('intensityFactor 在缺标准化功率时退回平均功率', () {
      final session = WorkoutSession(
        source: HealthSourceId.igpsport,
        externalId: 'igpsport:2',
        startedAt: _at,
        endedAt: _at.add(const Duration(hours: 1)),
        category: WorkoutCategory.cycling,
        name: '骑行',
        avgPowerW: 150,
      );

      expect(session.intensityFactor(200), closeTo(0.75, 1e-9));
    });

    test('两个功率都缺时 intensityFactor 返回 null', () {
      final session = WorkoutSession(
        source: HealthSourceId.keep,
        externalId: 'k:3',
        startedAt: _at,
        endedAt: _at.add(const Duration(minutes: 45)),
        category: WorkoutCategory.hiit,
        name: 'HIIT',
      );

      expect(session.intensityFactor(250), isNull);
    });
  });

  group('BodyComposition', () {
    test('payload 键名与模型字段一致', () {
      final sample = BodyComposition(
        source: HealthSourceId.healthConnect,
        externalId: 'hc:body:src:1',
        measuredAt: _at,
        weightKg: 70.5,
        bodyFatPercent: 18.2,
        muscleMassKg: 55.1,
        bmi: 22.8,
        waistCm: 82,
        hipCm: 95,
        note: '晨起',
      ).toSample();

      expect(sample.kind, HealthSampleKind.bodyComposition);
      expect(sample.startAt, _at);
      expect(sample.title, '体测记录');
      expect(sample.payload.keys.toSet(), <String>{
        'weightKg',
        'bodyFatPercent',
        'muscleMassKg',
        'bmi',
        'waistCm',
        'hipCm',
        'note',
      });
    });

    test('往返守恒：全部字段还原', () {
      final original = BodyComposition(
        source: HealthSourceId.healthConnect,
        externalId: 'hc:body:src:1',
        measuredAt: _at,
        weightKg: 70.5,
        bodyFatPercent: 18.2,
        muscleMassKg: 55.1,
        bmi: 22.8,
        waistCm: 82,
        hipCm: 95,
        note: '晨起',
      );

      final restored = BodyComposition.tryFromSample(original.toSample())!;

      expect(restored.source, original.source);
      expect(restored.externalId, original.externalId);
      expect(restored.measuredAt, original.measuredAt);
      expect(restored.weightKg, original.weightKg);
      expect(restored.bodyFatPercent, original.bodyFatPercent);
      expect(restored.muscleMassKg, original.muscleMassKg);
      expect(restored.bmi, original.bmi);
      expect(restored.waistCm, original.waistCm);
      expect(restored.hipCm, original.hipCm);
      expect(restored.note, original.note);
    });

    test('全空体测也不报错，payload 为空映射', () {
      final original = BodyComposition(
        source: HealthSourceId.healthConnect,
        externalId: 'hc:body:src:2',
        measuredAt: _at,
      );

      final sample = original.toSample();
      expect(sample.payload, isEmpty);

      final restored = BodyComposition.tryFromSample(sample)!;
      expect(restored.weightKg, isNull);
      expect(restored.bmi, isNull);
      expect(restored.occurredAt, _at);
    });
  });

  group('SleepSession', () {
    test('payload 键名与模型字段一致', () {
      final sample = SleepSession(
        source: HealthSourceId.huaweiHealth,
        externalId: 'hw:sleep:1',
        startedAt: DateTime(2026, 3, 13, 23, 10),
        endedAt: DateTime(2026, 3, 14, 7, 5),
        deepMinutes: 95,
        lightMinutes: 250,
        remMinutes: 80,
        awakeMinutes: 12,
      ).toSample();

      expect(sample.kind, HealthSampleKind.sleep);
      expect(sample.title, '睡眠');
      expect(sample.payload.keys.toSet(),
          <String>{'deepMinutes', 'lightMinutes', 'remMinutes', 'awakeMinutes'});
      expect(sample.payload['deepMinutes'], 95);
    });

    test('往返守恒：时长与分期字段还原', () {
      final original = SleepSession(
        source: HealthSourceId.huaweiHealth,
        externalId: 'hw:sleep:1',
        startedAt: DateTime(2026, 3, 13, 23, 10),
        endedAt: DateTime(2026, 3, 14, 7, 5),
        deepMinutes: 95,
        lightMinutes: 250,
        remMinutes: 80,
        awakeMinutes: 12,
      );

      final restored = SleepSession.tryFromSample(original.toSample())!;

      expect(restored.startedAt, original.startedAt);
      expect(restored.endedAt, original.endedAt);
      expect(restored.deepMinutes, 95);
      expect(restored.lightMinutes, 250);
      expect(restored.remMinutes, 80);
      expect(restored.awakeMinutes, 12);
      expect(restored.totalMinutes, 475);
      expect(restored.occurredAt, original.startedAt);
    });

    test('分期字段缺失时不写入 payload，往返后仍为 null', () {
      final original = SleepSession(
        source: HealthSourceId.healthConnect,
        externalId: 'hc:sleep:1',
        startedAt: DateTime(2026, 3, 13, 23, 0),
        endedAt: DateTime(2026, 3, 14, 6, 30),
      );

      final sample = original.toSample();
      expect(sample.payload, isEmpty);

      final restored = SleepSession.tryFromSample(sample)!;
      expect(restored.deepMinutes, isNull);
      expect(restored.lightMinutes, isNull);
      expect(restored.remMinutes, isNull);
      expect(restored.awakeMinutes, isNull);
      expect(restored.totalMinutes, 450);
    });

    test('缺少结束时间时 tryFromSample 返回 null', () {
      final sample = HealthSample(
        source: HealthSourceId.healthConnect,
        externalId: 'hc:sleep:2',
        kind: HealthSampleKind.sleep,
        startAt: _at,
        payload: const <String, Object?>{'deepMinutes': 30},
      );

      expect(SleepSession.tryFromSample(sample), isNull);
    });
  });

  group('DailyActivity', () {
    test('payload 键名与模型字段一致', () {
      final sample = DailyActivity(
        source: HealthSourceId.healthConnect,
        externalId: 'hc:daily:2026-03-14',
        date: DateTime(2026, 3, 14),
        steps: 8421,
        activeCalories: 512,
        restingHeartRate: 58,
        hrvMs: 42.5,
      ).toSample();

      expect(sample.kind, HealthSampleKind.dailyActivity);
      expect(sample.title, '日常活动');
      expect(sample.payload.keys.toSet(),
          <String>{'steps', 'activeCalories', 'restingHeartRate', 'hrvMs'});
      expect(sample.startAt, DateTime(2026, 3, 14));
    });

    test('往返守恒：汇总字段还原', () {
      final original = DailyActivity(
        source: HealthSourceId.healthConnect,
        externalId: 'hc:daily:2026-03-14',
        date: DateTime(2026, 3, 14),
        steps: 8421,
        activeCalories: 512,
        restingHeartRate: 58,
        hrvMs: 42.5,
      );

      final restored = DailyActivity.tryFromSample(original.toSample())!;

      expect(restored.source, original.source);
      expect(restored.externalId, original.externalId);
      expect(restored.date, original.date);
      expect(restored.steps, 8421);
      expect(restored.activeCalories, 512);
      expect(restored.restingHeartRate, 58);
      expect(restored.hrvMs, 42.5);
      expect(restored.occurredAt, original.date);
    });

    test('全部指标缺失时 payload 为空且往返不产生 0', () {
      final original = DailyActivity(
        source: HealthSourceId.healthConnect,
        externalId: 'hc:daily:2026-03-15',
        date: DateTime(2026, 3, 15),
      );

      final sample = original.toSample();
      expect(sample.payload, isEmpty);

      final restored = DailyActivity.tryFromSample(sample)!;
      expect(restored.steps, isNull);
      expect(restored.activeCalories, isNull);
      expect(restored.restingHeartRate, isNull);
      expect(restored.hrvMs, isNull);
    });

    test('字符串型数值可以被还原', () {
      final restored = DailyActivity.tryFromSample(HealthSample(
        source: HealthSourceId.huaweiHealth,
        externalId: 'hw:daily:1',
        kind: HealthSampleKind.dailyActivity,
        startAt: DateTime(2026, 3, 14),
        payload: const <String, Object?>{'steps': '9000', 'hrvMs': '38.25'},
      ))!;

      expect(restored.steps, 9000);
      expect(restored.hrvMs, 38.25);
    });
  });
}
