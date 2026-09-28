/// [FitActivityImporter] 的单元测试。
///
/// 测试数据用 `fit_tool` 的 [FitFileBuilder] 现场生成，不依赖外部二进制样本。
library;

import 'dart:typed_data';

import 'package:fit_tool/fit_tool.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucocontrol/core/result.dart';
import 'package:glucocontrol/data/health/importers/fit_activity_importer.dart';
import 'package:glucocontrol/domain/health/health_records.dart';
import 'package:glucocontrol/domain/health/health_source.dart';

/// 活动开始时刻（UTC）。
final DateTime _startUtc = DateTime.utc(2025, 1, 2, 8, 30);

/// 活动开始时刻的 Unix 毫秒。
///
/// fit_tool 把 `timestamp` / `startTime` 声明为 `scale: 0.001,
/// offset: -631065600000`，因此这两个字段取值与赋值都是 Unix 毫秒。
final int _startMs = _startUtc.millisecondsSinceEpoch;

/// 构造一条含三个 Record 与一条 Session 的骑行 FIT 文件。
///
/// @param totalAscent Session 里的累计爬升；传 null 表示设备未提供该字段。
/// @param withSession 是否写入 Session 消息。
/// @returns FIT 文件字节。
Uint8List buildRideFit({int? totalAscent = 350, bool withSession = true}) {
  final builder = FitFileBuilder(autoDefine: true);

  builder.addAll(<Message>[
    RecordMessage()
      ..timestamp = _startMs
      ..altitude = 10.0
      ..heartRate = 120
      ..power = 180
      ..distance = 0.0,
    RecordMessage()
      ..timestamp = _startMs + 1800 * 1000
      ..altitude = 60.0
      ..heartRate = 150
      ..power = 220
      ..distance = 15000.0,
    RecordMessage()
      ..timestamp = _startMs + 3600 * 1000
      ..altitude = 40.0
      ..heartRate = 140
      ..power = 200
      ..distance = 30000.0,
  ]);

  if (withSession) {
    final session = SessionMessage()
      ..timestamp = _startMs + 3600 * 1000
      ..startTime = _startMs
      ..totalElapsedTime = 3600.0
      ..totalTimerTime = 3600.0
      ..totalDistance = 30000.0
      ..totalCalories = 900
      ..avgHeartRate = 140
      ..maxHeartRate = 175
      ..avgPower = 200
      ..normalizedPower = 210
      ..sport = Sport.cycling;
    if (totalAscent != null) session.totalAscent = totalAscent;
    builder.add(session);
  }

  return builder.build().toBytes();
}

void main() {
  final importer = FitActivityImporter();

  test('从 Session 汇总活动指标', () async {
    final result = await importer.parse(
      fileName: 'ride.fit',
      bytes: buildRideFit(),
    );

    expect(result.isOk, isTrue);
    final sample = result.requireValue().single;
    expect(sample.kind, HealthSampleKind.workout);
    expect(sample.source, HealthSourceId.fileImport);
    expect(sample.startAt, _startUtc.toLocal());
    expect(sample.endAt, _startUtc.add(const Duration(hours: 1)).toLocal());
    expect(sample.title, '骑行训练');
    expect(sample.payload['category'], 'cycling');
    expect(sample.payload['distanceKm'], 30.0);
    expect(sample.payload['calories'], 900);
    expect(sample.payload['avgHeartRate'], 140);
    expect(sample.payload['maxHeartRate'], 175);
    expect(sample.payload['avgPowerW'], 200.0);
    expect(sample.payload['normalizedPowerW'], 210.0);
    expect(sample.payload['elevationGainM'], 350.0);
    expect(importer.lastStats.samplesProduced, 1);
  });

  test('Session 没有累计爬升时用 Record 海拔推算', () async {
    final result = await importer.parse(
      fileName: 'ride.fit',
      bytes: buildRideFit(totalAscent: null),
    );

    // 10 → 60 → 40：只累加超过 1 米噪声门限的正高差。
    expect(result.requireValue().single.payload['elevationGainM'], 50.0);
  });

  test('没有 Session 时退化为按 Record 推断', () async {
    final result = await importer.parse(
      fileName: 'ride.fit',
      bytes: buildRideFit(withSession: false),
    );

    expect(result.isOk, isTrue);
    final sample = result.requireValue().single;
    expect(sample.title, 'FIT 活动');
    expect(sample.payload['category'], 'other');
    expect(sample.payload['distanceKm'], 30.0);
    expect(sample.payload['elevationGainM'], 50.0);
    expect(sample.payload['avgHeartRate'], 137);
    expect(sample.payload['maxHeartRate'], 150);
    expect(sample.startAt, _startUtc.toLocal());
    expect(sample.endAt, _startUtc.add(const Duration(hours: 1)).toLocal());
  });

  test('不同运动项目映射到对应分类', () async {
    for (final entry in <Sport, String>{
      Sport.running: 'running',
      Sport.walking: 'walking',
      Sport.swimming: 'swimming',
      Sport.training: 'strength',
      Sport.generic: 'other',
    }.entries) {
      final builder = FitFileBuilder(autoDefine: true);
      builder.add(SessionMessage()
        ..timestamp = _startMs + 600 * 1000
        ..startTime = _startMs
        ..totalElapsedTime = 600.0
        ..totalTimerTime = 600.0
        ..sport = entry.key);

      final result = await importer.parse(
        fileName: 'a.fit',
        bytes: builder.build().toBytes(),
      );
      expect(result.requireValue().single.payload['category'], entry.value,
          reason: entry.key.name);
    }
  });

  test('截断的文件归为解析失败而不是抛异常', () async {
    final bytes = buildRideFit().sublist(0, 20);
    final result = await importer.parse(fileName: 'ride.fit', bytes: bytes);

    expect(result.isOk, isFalse);
    expect(result.failureOrNull!.kind, FailureKind.parsing);
  });

  test('同一文件导入两次得到相同的 externalId', () async {
    final bytes = buildRideFit();
    final first = await importer.parse(fileName: 'a.fit', bytes: bytes);
    final second = await importer.parse(fileName: 'a.fit', bytes: bytes);
    expect(first.requireValue().single.externalId,
        second.requireValue().single.externalId);
  });

  test('canHandle 校验 FIT 文件头', () {
    expect(importer.canHandle('ride.fit', buildRideFit()), isTrue);
    expect(importer.canHandle('ride.fit', <int>[0, 1, 2, 3]), isFalse);
    expect(
      importer.canHandle('a.fit', List<int>.filled(16, 0x00)),
      isFalse,
    );
    expect(importer.canHandle('a.csv', buildRideFit()), isFalse);
    // 头长度合法但缺少 ".FIT" 签名。
    final noSignature = buildRideFit().toList();
    noSignature[9] = 0x00;
    expect(importer.canHandle('a.fit', noSignature), isFalse);
  });

  test('样本可以被 WorkoutSession 还原', () async {
    final result = await importer.parse(
      fileName: 'ride.fit',
      bytes: buildRideFit(),
    );

    final session = WorkoutSession.tryFromSample(result.requireValue().single);
    expect(session, isNotNull);
    expect(session!.category, WorkoutCategory.cycling);
    expect(session.name, '骑行训练');
    expect(session.distanceKm, 30.0);
    expect(session.avgPowerW, 200.0);
    expect(session.normalizedPowerW, 210.0);
    expect(session.avgHeartRate, 140);
    expect(session.calories, 900);
    expect(session.durationMinutes, 60.0);
    expect(session.intensityFactor(250), closeTo(0.84, 0.001));
  });
}
