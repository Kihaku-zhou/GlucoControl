/// `health_timeline.dart` 的单元测试。
///
/// 覆盖时间线条目的 JSON 形态、区间查询、`glucoseSummary()` 的统计口径
/// （含 ADAG 估算糖化、TIR 三档占比）、`contextAround()` 的时间窗边界，
/// 以及 `toJson(maxEntries:)` 的「每类各留最新若干条」压缩策略。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:glucocontrol/domain/health/health_records.dart';
import 'package:glucocontrol/domain/health/health_source.dart';
import 'package:glucocontrol/domain/health/health_timeline.dart';

HealthTimelineEntry _glucose(DateTime at, double mmolPerL) =>
    HealthTimelineEntry(
      kind: HealthTimelineKind.glucose,
      at: at,
      sourceLabel: '硅基轻享',
      title: '动态监测血糖',
      metrics: <String, Object?>{'mmolPerL': mmolPerL},
    );

HealthTimelineEntry _workout(DateTime at, {DateTime? until}) =>
    HealthTimelineEntry(
      kind: HealthTimelineKind.workout,
      at: at,
      until: until,
      sourceLabel: '训记',
      title: '力量训练',
    );

HealthTimelineEntry _meal(DateTime at) => HealthTimelineEntry(
      kind: HealthTimelineKind.meal,
      at: at,
      sourceLabel: '本应用',
      title: '午餐',
      isLocal: true,
    );

/// 便于用 `HH:mm:ss` 描述时间点。
DateTime _t(int hour, [int minute = 0, int second = 0]) =>
    DateTime(2026, 3, 14, hour, minute, second);

void main() {
  group('HealthTimelineKind', () {
    test('编码与样本类别的映射覆盖全部取值', () {
      expect(HealthTimelineKind.glucose.code, 'glucose');
      expect(HealthTimelineKind.meal.code, 'meal');

      expect(HealthTimelineKind.fromSampleKind(HealthSampleKind.glucose),
          HealthTimelineKind.glucose);
      expect(HealthTimelineKind.fromSampleKind(HealthSampleKind.workout),
          HealthTimelineKind.workout);
      expect(
          HealthTimelineKind.fromSampleKind(HealthSampleKind.bodyComposition),
          HealthTimelineKind.bodyComposition);
      expect(HealthTimelineKind.fromSampleKind(HealthSampleKind.sleep),
          HealthTimelineKind.sleep);
      expect(HealthTimelineKind.fromSampleKind(HealthSampleKind.dailyActivity),
          HealthTimelineKind.dailyActivity);
    });

    test('tryFromCode 还原已知编码并拒绝未知值', () {
      for (final kind in HealthTimelineKind.values) {
        expect(HealthTimelineKind.tryFromCode(kind.code), kind);
      }
      expect(HealthTimelineKind.tryFromCode('glucose'),
          HealthTimelineKind.glucose);
      expect(HealthTimelineKind.tryFromCode('blood_glucose'), isNull);
      expect(HealthTimelineKind.tryFromCode(null), isNull);
    });
  });

  group('HealthTimelineEntry', () {
    test('toJson 输出全部非空字段', () {
      final entry = HealthTimelineEntry(
        kind: HealthTimelineKind.workout,
        at: _t(9),
        until: _t(10),
        sourceLabel: 'Health Connect',
        originApp: 'Keep',
        isLocal: true,
        title: '户外跑',
        metrics: const <String, Object?>{'distanceKm': 5.2},
      );

      expect(entry.toJson(), <String, Object?>{
        'kind': 'workout',
        'at': '2026-03-14T09:00:00.000',
        'until': '2026-03-14T10:00:00.000',
        'source': 'Health Connect',
        'originApp': 'Keep',
        'local': true,
        'title': '户外跑',
        'metrics': <String, Object?>{'distanceKm': 5.2},
      });
    });

    test('toJson 省略空字段，瞬时记录不含 until', () {
      final entry = HealthTimelineEntry(
        kind: HealthTimelineKind.glucose,
        at: _t(8),
        sourceLabel: '手动录入',
      );

      final json = entry.toJson();
      expect(json.keys.toSet(), <String>{'kind', 'at', 'source'});
      expect(json.containsKey('until'), isFalse);
      expect(json.containsKey('local'), isFalse);
      expect(json.containsKey('metrics'), isFalse);
      expect(json.containsKey('originApp'), isFalse);
    });

    test('duration 由 until 与 at 之差得到', () {
      expect(_workout(_t(9), until: _t(10, 30)).duration,
          const Duration(hours: 1, minutes: 30));
      expect(_workout(_t(9)).duration, isNull);
      expect(_glucose(_t(8), 5.5).duration, isNull);
    });

    test('toString 便于日志定位', () {
      expect(
        _glucose(_t(8), 5.5).toString(),
        'HealthTimelineEntry(glucose @2026-03-14T08:00:00.000 动态监测血糖)',
      );
    });
  });

  group('HealthTimeline 的基础查询', () {
    test('空时间线的 span 为 null', () {
      expect(const HealthTimeline(<HealthTimelineEntry>[]).span, isNull);
    });

    test('span 取首尾条目的发生时间', () {
      final timeline = HealthTimeline(<HealthTimelineEntry>[
        _workout(_t(7)),
        _glucose(_t(8), 5.5),
        _meal(_t(12)),
      ]);

      expect(timeline.span!.start, _t(7));
      expect(timeline.span!.end, _t(12));
    });

    test('ofKind 只返回指定类别', () {
      final timeline = HealthTimeline(<HealthTimelineEntry>[
        _workout(_t(7)),
        _glucose(_t(8), 5.5),
        _glucose(_t(9), 6.1),
      ]);

      expect(timeline.ofKind(HealthTimelineKind.glucose).length, 2);
      expect(timeline.ofKind(HealthTimelineKind.sleep), isEmpty);
    });

    test('between 为左闭右开区间', () {
      final timeline = HealthTimeline(<HealthTimelineEntry>[
        _workout(_t(9)),
        _glucose(_t(10), 5.5),
        _glucose(_t(11), 6.1),
        _glucose(_t(12), 7.0),
      ]);

      final between = timeline.between(_t(10), _t(12));

      expect(between.map((entry) => entry.at).toList(), <DateTime>[_t(10), _t(11)]);
    });

    test('between 的右端被排除、左端被包含', () {
      final timeline = HealthTimeline(<HealthTimelineEntry>[
        _glucose(_t(10), 5.5),
        _glucose(_t(12), 6.1),
      ]);

      expect(timeline.between(_t(10), _t(12)).single.at, _t(10));
      expect(timeline.between(_t(10, 1), _t(12)), isEmpty);
    });
  });

  group('glucoseSummary', () {
    test('没有血糖记录时返回 null 而不是全零', () {
      final timeline = HealthTimeline(<HealthTimelineEntry>[
        _workout(_t(7)),
        _meal(_t(12)),
      ]);

      expect(timeline.glucoseSummary(), isNull);
    });

    test('空时间线同样返回 null', () {
      expect(const HealthTimeline(<HealthTimelineEntry>[]).glucoseSummary(), isNull);
    });

    test('metrics 里没有可用数值时返回 null', () {
      final timeline = HealthTimeline(<HealthTimelineEntry>[
        HealthTimelineEntry(
          kind: HealthTimelineKind.glucose,
          at: _t(8),
          sourceLabel: '手动录入',
          metrics: const <String, Object?>{'mmolPerL': '五点五'},
        ),
      ]);

      expect(timeline.glucoseSummary(), isNull);
    });

    test('TIR/below/above 三档占比之和为 100', () {
      final timeline = HealthTimeline(<HealthTimelineEntry>[
        _glucose(_t(6), 3.5), // 偏低
        _glucose(_t(7), 5.0), // 达标
        _glucose(_t(8), 7.0), // 达标
        _glucose(_t(9), 12.0), // 偏高
      ]);

      final summary = timeline.glucoseSummary()!;

      expect(summary.count, 4);
      expect(summary.belowRangePercent, 25.0);
      expect(summary.aboveRangePercent, 25.0);
      expect(summary.withinRangePercent, 50.0);
      expect(
        summary.withinRangePercent +
            summary.belowRangePercent +
            summary.aboveRangePercent,
        closeTo(100.0, 1e-9),
      );
    });

    test('目标范围边界值计入达标档', () {
      final timeline = HealthTimeline(<HealthTimelineEntry>[
        _glucose(_t(6), 3.9),
        _glucose(_t(7), 10.0),
      ]);

      final summary = timeline.glucoseSummary()!;

      expect(summary.withinRangePercent, 100.0);
      expect(summary.belowRangePercent, 0.0);
      expect(summary.aboveRangePercent, 0.0);
    });

    test('自定义目标范围改变分档结果', () {
      final timeline = HealthTimeline(<HealthTimelineEntry>[
        _glucose(_t(6), 5.0),
        _glucose(_t(7), 8.0),
      ]);

      final summary =
          timeline.glucoseSummary(targetMinMmolPerL: 6.0, targetMaxMmolPerL: 7.0)!;

      expect(summary.belowRangePercent, 50.0);
      expect(summary.aboveRangePercent, 50.0);
      expect(summary.withinRangePercent, 0.0);
    });

    test('均值与极值由原始读数得到', () {
      final timeline = HealthTimeline(<HealthTimelineEntry>[
        _glucose(_t(6), 4.0),
        _glucose(_t(7), 6.0),
        _glucose(_t(8), 8.0),
        _glucose(_t(9), 12.0),
      ]);

      final summary = timeline.glucoseSummary()!;

      expect(summary.meanMmolPerL, 7.5);
      expect(summary.minMmolPerL, 4.0);
      expect(summary.maxMmolPerL, 12.0);
    });

    test('估算糖化使用 ADAG 公式 (meanMgDl + 46.7) / 28.7', () {
      final timeline = HealthTimeline(<HealthTimelineEntry>[
        _glucose(_t(6), 4.0),
        _glucose(_t(7), 6.0),
        _glucose(_t(8), 8.0),
        _glucose(_t(9), 12.0),
      ]);

      final summary = timeline.glucoseSummary()!;
      const mgPerDlFactor = 18.0182;
      final expected = (7.5 * mgPerDlFactor + 46.7) / 28.7;

      expect(summary.estimatedA1cPercent, closeTo(expected, 1e-9));
      // 平均 7.5 mmol/L（≈135.14 mg/dL）对应约 6.34%。
      expect(summary.estimatedA1cPercent, closeTo(6.3358, 1e-4));
    });

    test('只有一个读数时占比不除零', () {
      final timeline = HealthTimeline(<HealthTimelineEntry>[_glucose(_t(6), 5.6)]);

      final summary = timeline.glucoseSummary()!;

      expect(summary.count, 1);
      expect(summary.meanMmolPerL, 5.6);
      expect(summary.withinRangePercent, 100.0);
      expect(summary.estimatedA1cPercent, closeTo((5.6 * 18.0182 + 46.7) / 28.7, 1e-9));
    });

    test('只统计血糖类别的条目', () {
      final timeline = HealthTimeline(<HealthTimelineEntry>[
        _glucose(_t(6), 5.0),
        _workout(_t(7), until: _t(8)),
        HealthTimelineEntry(
          kind: HealthTimelineKind.bodyComposition,
          at: _t(9),
          sourceLabel: 'Health Connect',
          metrics: const <String, Object?>{'mmolPerL': 99.0},
        ),
      ]);

      final summary = timeline.glucoseSummary()!;

      expect(summary.count, 1);
      expect(summary.maxMmolPerL, 5.0);
    });

    test('toJson 按约定精度四舍五入', () {
      final timeline = HealthTimeline(<HealthTimelineEntry>[
        _glucose(_t(6), 3.5),
        _glucose(_t(7), 5.0),
        _glucose(_t(8), 8.25),
      ]);

      final json = timeline.glucoseSummary()!.toJson();

      expect(json['count'], 3);
      expect(json['meanMmolPerL'], 5.58);
      expect(json['minMmolPerL'], 3.5);
      expect(json['maxMmolPerL'], 8.25);
      expect(json['belowRangePercent'], 33.3);
      expect(json['withinRangePercent'], 66.7);
      expect(json['aboveRangePercent'], 0.0);
      expect(json['estimatedA1cPercent'], 5.1);
    });
  });

  group('contextAround', () {
    test('只返回运动与饮食，忽略血糖与体测', () {
      final timeline = HealthTimeline(<HealthTimelineEntry>[
        _workout(_t(10), until: _t(11)),
        _glucose(_t(10, 30), 6.0),
        _meal(_t(11, 30)),
        HealthTimelineEntry(
          kind: HealthTimelineKind.sleep,
          at: _t(11),
          sourceLabel: '华为运动健康',
        ),
      ]);

      final context = timeline.contextAround(_t(12));

      expect(context.length, 2);
      expect(context.map((entry) => entry.kind).toSet(), <HealthTimelineKind>{
        HealthTimelineKind.workout,
        HealthTimelineKind.meal,
      });
    });

    test('恰好落在 lookBack 边界上的事件被包含', () {
      final timeline = HealthTimeline(<HealthTimelineEntry>[
        _meal(_t(9)), // moment - 3h，正好等于 lookBack 边界
        _meal(_t(8, 59)), // 早于边界 1 分钟
      ]);

      final context = timeline.contextAround(_t(12));

      expect(context.map((entry) => entry.at).toList(), <DateTime>[_t(9)]);
    });

    test('恰好落在 lookAhead 边界上的事件被排除', () {
      final timeline = HealthTimeline(<HealthTimelineEntry>[
        _meal(_t(12, 59)),
        _meal(_t(13)), // 正好等于 moment + lookAhead
      ]);

      final context = timeline.contextAround(_t(12));

      expect(context.map((entry) => entry.at).toList(), <DateTime>[_t(12, 59)]);
    });

    test('跨越窗口左界的运动按重叠计入', () {
      // 8:00 开始、9:30 结束的运动与 [9:00, 13:00) 窗口重叠。
      final timeline = HealthTimeline(<HealthTimelineEntry>[
        _workout(_t(8), until: _t(9, 30)),
      ]);

      expect(timeline.contextAround(_t(12)).length, 1);
    });

    test('在窗口左界之前就已经结束的运动被排除', () {
      final timeline = HealthTimeline(<HealthTimelineEntry>[
        // 结束时间正好等于 lookBack 边界，重叠判定用 isAfter，因此被排除。
        _workout(_t(8), until: _t(9)),
        _workout(_t(8), until: _t(9, 0, 1)),
      ]);

      final context = timeline.contextAround(_t(12));

      expect(context.length, 1);
      expect(context.single.until, _t(9, 0, 1));
    });

    test('在窗口右界之后开始的运动被排除', () {
      final timeline = HealthTimeline(<HealthTimelineEntry>[
        _workout(_t(13), until: _t(14)),
      ]);

      expect(timeline.contextAround(_t(12)), isEmpty);
    });

    test('自定义 lookBack/lookAhead 改变窗口', () {
      final timeline = HealthTimeline(<HealthTimelineEntry>[
        _meal(_t(9)),
        _meal(_t(11)),
      ]);

      expect(
        timeline.contextAround(_t(12), lookBack: const Duration(hours: 2)).length,
        1,
      );
      expect(
        timeline
            .contextAround(
              _t(12),
              lookBack: const Duration(hours: 1),
              lookAhead: const Duration(hours: 4),
            )
            .length,
        1,
      );
      expect(
        timeline
            .contextAround(_t(12),
                lookBack: const Duration(hours: 4),
                lookAhead: const Duration(hours: 4))
            .length,
        2,
      );
    });

    test('结果保持时间线原有顺序', () {
      final timeline = HealthTimeline(<HealthTimelineEntry>[
        _workout(_t(10), until: _t(11)),
        _meal(_t(11, 30)),
      ]);

      final context = timeline.contextAround(_t(12));

      expect(context.first.kind, HealthTimelineKind.workout);
      expect(context.last.kind, HealthTimelineKind.meal);
    });
  });

  group('toJson 的条数压缩', () {
    test('未超限时原样输出全部条目', () {
      final timeline = HealthTimeline(<HealthTimelineEntry>[
        _glucose(_t(6), 5.0),
        _glucose(_t(7), 5.5),
        _glucose(_t(8), 6.0),
      ]);

      final json = timeline.toJson(maxEntries: 3);

      expect(json.length, 3);
      expect(json.map((item) => item['at']).toList(), <String>[
        '2026-03-14T06:00:00.000',
        '2026-03-14T07:00:00.000',
        '2026-03-14T08:00:00.000',
      ]);
    });

    test('超限时每类各保留最新若干条且仍按时间升序', () {
      final timeline = HealthTimeline(<HealthTimelineEntry>[
        _workout(_t(6)),
        _workout(_t(7)),
        _workout(_t(8)),
        _workout(_t(9)),
        _glucose(_t(10), 5.0),
        _glucose(_t(11), 5.5),
        _glucose(_t(12), 6.0),
        _glucose(_t(13), 6.5),
        _glucose(_t(14), 7.0),
      ]);

      final json = timeline.toJson(maxEntries: 4);

      // 两类共 4 个名额 → 每类 2 条，取各类最新。
      expect(json.length, 4);
      expect(json.map((item) => item['at']).toList(), <String>[
        '2026-03-14T08:00:00.000',
        '2026-03-14T09:00:00.000',
        '2026-03-14T13:00:00.000',
        '2026-03-14T14:00:00.000',
      ]);
      expect(json.map((item) => item['kind']).toList(), <String>[
        'workout',
        'workout',
        'glucose',
        'glucose',
      ]);
    });

    test('某类条数不足配额时全部保留，名额不补偿给其他类', () {
      final timeline = HealthTimeline(<HealthTimelineEntry>[
        _workout(_t(6)),
        _glucose(_t(10), 5.0),
        _glucose(_t(11), 5.5),
        _glucose(_t(12), 6.0),
        _glucose(_t(13), 6.5),
      ]);

      final json = timeline.toJson(maxEntries: 4);

      // quota = 4 / 2 = 2：运动只有 1 条（全部保留），血糖保留最新 2 条。
      expect(json.length, 3);
      expect(json.map((item) => item['at']).toList(), <String>[
        '2026-03-14T06:00:00.000',
        '2026-03-14T12:00:00.000',
        '2026-03-14T13:00:00.000',
      ]);
    });

    test('类别数多于名额时配额下限为 1，结果条数可能超过 maxEntries', () {
      final timeline = HealthTimeline(<HealthTimelineEntry>[
        _workout(_t(6)),
        _workout(_t(7)),
        _glucose(_t(8), 5.0),
        _glucose(_t(9), 5.5),
      ]);

      final json = timeline.toJson(maxEntries: 1);

      // quota = floor(1/2)=0，被 clamp 到 1：两类各留最新 1 条。
      expect(json.length, 2);
      expect(json.map((item) => item['at']).toList(), <String>[
        '2026-03-14T07:00:00.000',
        '2026-03-14T09:00:00.000',
      ]);
    });

    test('默认 maxEntries=200 时不压缩常见规模的时间线', () {
      final entries = <HealthTimelineEntry>[
        for (var hour = 0; hour < 10; hour++) _glucose(_t(hour), 5.0 + hour * 0.1),
      ];

      expect(HealthTimeline(entries).toJson().length, 10);
    });
  });

  group('从样本与记录构造条目', () {
    test('timelineEntryFromSample 搬运信封字段并把 payload 当 metrics', () {
      final sample = HealthSample(
        source: HealthSourceId.healthConnect,
        externalId: 'hc:workout:1',
        kind: HealthSampleKind.workout,
        startAt: _t(9),
        endAt: _t(10),
        title: '骑行',
        originApp: 'Keep',
        payload: const <String, Object?>{'distanceKm': 30.0},
      );

      final entry = timelineEntryFromSample(sample);

      expect(entry.kind, HealthTimelineKind.workout);
      expect(entry.at, _t(9));
      expect(entry.until, _t(10));
      expect(entry.sourceLabel, HealthSourceId.healthConnect.displayName);
      expect(entry.originApp, 'Keep');
      expect(entry.title, '骑行');
      expect(entry.metrics, <String, Object?>{'distanceKm': 30.0});
      expect(entry.isLocal, isFalse);
    });

    test('timelineEntryFromRecord 走 toSample 得到同样的指标键', () {
      final record = WorkoutSession(
        source: HealthSourceId.xunji,
        externalId: 'xunji:1',
        startedAt: _t(19),
        endedAt: _t(20),
        category: WorkoutCategory.strength,
        name: '练腿',
        totalVolumeKg: 4200,
        totalSets: 16,
        totalReps: 128,
      );

      final entry = timelineEntryFromRecord(record);

      expect(entry.kind, HealthTimelineKind.workout);
      expect(entry.at, _t(19));
      expect(entry.until, _t(20));
      expect(entry.title, '练腿');
      expect(entry.sourceLabel, HealthSourceId.xunji.displayName);
      expect(entry.metrics['totalVolumeKg'], 4200.0);
      expect(entry.metrics['totalSets'], 16);
      expect(entry.metrics['totalReps'], 128);
    });

    test('血糖记录转换后可直接参与 glucoseSummary', () {
      final timeline = HealthTimeline(<HealthTimelineEntry>[
        timelineEntryFromRecord(GlucoseReading(
          source: HealthSourceId.manual,
          externalId: 'm:1',
          recordedAt: _t(8),
          mmolPerL: 5.6,
        )),
      ]);

      expect(timeline.glucoseSummary()!.count, 1);
      expect(timeline.glucoseSummary()!.meanMmolPerL, 5.6);
    });
  });
}
