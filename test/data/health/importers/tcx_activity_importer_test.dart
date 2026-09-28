/// [TcxActivityImporter] 的单元测试。
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:glucocontrol/core/result.dart';
import 'package:glucocontrol/data/health/importers/tcx_activity_importer.dart';
import 'package:glucocontrol/domain/health/health_records.dart';
import 'package:glucocontrol/domain/health/health_source.dart';

/// 一条含三个轨迹点的骑行活动，Lap 自带距离、卡路里与心率。
const String _cyclingActivity = '<?xml version="1.0" encoding="UTF-8"?>\n'
    '<TrainingCenterDatabase '
    'xmlns="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2">\n'
    '  <Activities>\n'
    '    <Activity Sport="Biking">\n'
    '      <Id>2025-01-02T08:30:00Z</Id>\n'
    '      <Lap StartTime="2025-01-02T08:30:00Z">\n'
    '        <TotalTimeSeconds>3600</TotalTimeSeconds>\n'
    '        <DistanceMeters>30000</DistanceMeters>\n'
    '        <Calories>900</Calories>\n'
    '        <AverageHeartRateBpm><Value>140</Value></AverageHeartRateBpm>\n'
    '        <MaximumHeartRateBpm><Value>175</Value></MaximumHeartRateBpm>\n'
    '        <Track>\n'
    '          <Trackpoint><Time>2025-01-02T08:30:00Z</Time>\n'
    '            <Position><LatitudeDegrees>30.0</LatitudeDegrees>'
    '<LongitudeDegrees>120.0</LongitudeDegrees></Position>\n'
    '            <AltitudeMeters>10.0</AltitudeMeters>\n'
    '            <HeartRateBpm><Value>130</Value></HeartRateBpm></Trackpoint>\n'
    '          <Trackpoint><Time>2025-01-02T09:00:00Z</Time>\n'
    '            <Position><LatitudeDegrees>30.05</LatitudeDegrees>'
    '<LongitudeDegrees>120.0</LongitudeDegrees></Position>\n'
    '            <AltitudeMeters>60.0</AltitudeMeters>\n'
    '            <HeartRateBpm><Value>150</Value></HeartRateBpm></Trackpoint>\n'
    '          <Trackpoint><Time>2025-01-02T09:30:00Z</Time>\n'
    '            <Position><LatitudeDegrees>30.10</LatitudeDegrees>'
    '<LongitudeDegrees>120.0</LongitudeDegrees></Position>\n'
    '            <AltitudeMeters>40.0</AltitudeMeters>\n'
    '            <HeartRateBpm><Value>145</Value></HeartRateBpm></Trackpoint>\n'
    '        </Track>\n'
    '      </Lap>\n'
    '      <Notes>周末拉练</Notes>\n'
    '    </Activity>\n'
    '  </Activities>\n'
    '</TrainingCenterDatabase>\n';

void main() {
  final importer = TcxActivityImporter();

  test('汇总 Lap 的时长、距离、卡路里与心率', () async {
    final result = await importer.parse(
      fileName: 'ride.tcx',
      bytes: utf8.encode(_cyclingActivity),
    );

    expect(result.isOk, isTrue);
    final sample = result.requireValue().single;
    expect(sample.kind, HealthSampleKind.workout);
    expect(sample.source, HealthSourceId.fileImport);
    expect(sample.title, '周末拉练');
    expect(sample.payload['category'], 'cycling');
    expect(sample.payload['distanceKm'], 30.0);
    expect(sample.payload['calories'], 900);
    expect(sample.payload['avgHeartRate'], 140);
    expect(sample.payload['maxHeartRate'], 175);
    expect(sample.payload['elevationGainM'], 50.0);
    expect(sample.startAt, DateTime.parse('2025-01-02T08:30:00Z').toLocal());
    expect(sample.endAt, DateTime.parse('2025-01-02T09:30:00Z').toLocal());
    expect(importer.lastStats.samplesProduced, 1);
  });

  test('Lap 没有距离时用轨迹点算距离', () async {
    final xml = _cyclingActivity.replaceFirst('<DistanceMeters>30000</DistanceMeters>', '');
    final result =
        await importer.parse(fileName: 'ride.tcx', bytes: utf8.encode(xml));

    // 两段各 0.05 度纬度，约 5.56 km。
    expect(result.requireValue().single.payload['distanceKm'] as double,
        closeTo(11.12, 0.05));
  });

  test('多个 Lap 累加时长、距离与卡路里', () async {
    final xml = _cyclingActivity.replaceFirst(
      '</Lap>',
      '</Lap>\n'
          '      <Lap StartTime="2025-01-02T09:30:00Z">\n'
          '        <TotalTimeSeconds>1800</TotalTimeSeconds>\n'
          '        <DistanceMeters>15000</DistanceMeters>\n'
          '        <Calories>400</Calories>\n'
          '        <AverageHeartRateBpm><Value>150</Value></AverageHeartRateBpm>\n'
          '        <MaximumHeartRateBpm><Value>180</Value></MaximumHeartRateBpm>\n'
          '      </Lap>',
    );

    final result =
        await importer.parse(fileName: 'ride.tcx', bytes: utf8.encode(xml));
    final sample = result.requireValue().single;
    expect(sample.payload['distanceKm'], 45.0);
    expect(sample.payload['calories'], 1300);
    expect(sample.payload['maxHeartRate'], 180);
    // 3600 秒 × 140 与 1800 秒 × 150 的加权平均。
    expect(sample.payload['avgHeartRate'], 143);
  });

  test('没有 Lap 心率时退化为轨迹点心率', () async {
    final xml = _cyclingActivity
        .replaceAll(RegExp(r'<AverageHeartRateBpm>.*?</AverageHeartRateBpm>'), '')
        .replaceAll(RegExp(r'<MaximumHeartRateBpm>.*?</MaximumHeartRateBpm>'), '');
    final result =
        await importer.parse(fileName: 'ride.tcx', bytes: utf8.encode(xml));

    final sample = result.requireValue().single;
    expect(sample.payload['avgHeartRate'], 142);
    expect(sample.payload['maxHeartRate'], 150);
  });

  test('只有 Lap 没有轨迹点时用 Lap 时长推算结束时间', () async {
    final xml = _cyclingActivity.replaceAll(
      RegExp(r'<Track>.*?</Track>', dotAll: true),
      '',
    );
    final result =
        await importer.parse(fileName: 'ride.tcx', bytes: utf8.encode(xml));

    final sample = result.requireValue().single;
    expect(sample.startAt, DateTime.parse('2025-01-02T08:30:00Z').toLocal());
    expect(sample.endAt, DateTime.parse('2025-01-02T09:30:00Z').toLocal());
    expect(sample.payload.containsKey('elevationGainM'), isFalse);
  });

  test('没有 Sport 属性时分类回落到 other', () async {
    final xml = _cyclingActivity.replaceFirst(' Sport="Biking"', '');
    final result =
        await importer.parse(fileName: 'ride.tcx', bytes: utf8.encode(xml));
    final sample = result.requireValue().single;
    expect(sample.payload['category'], 'other');
    expect(sample.title, '周末拉练');
  });

  test('没有 Activity 时报解析失败', () async {
    final result = await importer.parse(
      fileName: 'ride.tcx',
      bytes: utf8.encode('<TrainingCenterDatabase><Activities/></TrainingCenterDatabase>'),
    );
    expect(result.isOk, isFalse);
    expect(result.failureOrNull!.kind, FailureKind.parsing);
    expect(result.failureOrNull!.code, 'tcx_no_activity');
  });

  test('损坏的 XML 归为解析失败而不是抛异常', () async {
    final result = await importer.parse(
      fileName: 'ride.tcx',
      bytes: utf8.encode('<TrainingCenterDatabase><Activities>'),
    );
    expect(result.isOk, isFalse);
    expect(result.failureOrNull!.kind, FailureKind.parsing);
  });

  test('同一文件导入两次得到相同的 externalId', () async {
    final bytes = utf8.encode(_cyclingActivity);
    final first = await importer.parse(fileName: 'a.tcx', bytes: bytes);
    final second = await importer.parse(fileName: 'a.tcx', bytes: bytes);
    expect(first.requireValue().single.externalId,
        second.requireValue().single.externalId);
  });

  test('canHandle 只接受 TCX', () {
    expect(importer.canHandle('ride.tcx', utf8.encode(_cyclingActivity)),
        isTrue);
    expect(
      importer.canHandle('ride.gpx', utf8.encode('<gpx><trk/></gpx>')),
      isFalse,
    );
    expect(importer.canHandle('a.csv', utf8.encode('a,b\n1,2\n')), isFalse);
    expect(
      importer.canHandle('a.tcx', utf8.encode('<html></html>')),
      isFalse,
    );
  });

  test('样本可以被 WorkoutSession 还原', () async {
    final result = await importer.parse(
      fileName: 'ride.tcx',
      bytes: utf8.encode(_cyclingActivity),
    );

    final session = WorkoutSession.tryFromSample(result.requireValue().single);
    expect(session, isNotNull);
    expect(session!.category, WorkoutCategory.cycling);
    expect(session.name, '周末拉练');
    expect(session.distanceKm, 30.0);
    expect(session.calories, 900);
    expect(session.avgHeartRate, 140);
    expect(session.durationMinutes, 60.0);
  });
}
