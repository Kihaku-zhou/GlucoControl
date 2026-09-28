/// [GpxTrackImporter] 的单元测试。
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:glucocontrol/core/result.dart';
import 'package:glucocontrol/data/health/importers/gpx_track_importer.dart';
import 'package:glucocontrol/domain/health/health_records.dart';
import 'package:glucocontrol/domain/health/health_source.dart';

/// 一条含三个轨迹点的骑行轨迹，纬度每段增加 0.01 度、海拔 10→30→25。
const String _cyclingTrack = '<?xml version="1.0" encoding="UTF-8"?>\n'
    '<gpx version="1.1" creator="iGPSPORT">\n'
    '  <trk>\n'
    '    <name>晨间骑行</name>\n'
    '    <type>cycling</type>\n'
    '    <trkseg>\n'
    '      <trkpt lat="30.0000" lon="120.0000">'
    '<ele>10.0</ele><time>2025-01-02T08:30:00Z</time></trkpt>\n'
    '      <trkpt lat="30.0100" lon="120.0000">'
    '<ele>30.0</ele><time>2025-01-02T08:35:00Z</time></trkpt>\n'
    '      <trkpt lat="30.0200" lon="120.0000">'
    '<ele>25.0</ele><time>2025-01-02T08:40:00Z</time></trkpt>\n'
    '    </trkseg>\n'
    '  </trk>\n'
    '</gpx>\n';

void main() {
  final importer = GpxTrackImporter();

  test('解析轨迹并计算距离、爬升与起止时间', () async {
    final result = await importer.parse(
      fileName: 'ride.gpx',
      bytes: utf8.encode(_cyclingTrack),
    );

    expect(result.isOk, isTrue);
    final sample = result.requireValue().single;
    expect(sample.kind, HealthSampleKind.workout);
    expect(sample.source, HealthSourceId.fileImport);
    expect(sample.title, '晨间骑行');
    expect(sample.payload['name'], '晨间骑行');
    expect(sample.payload['category'], 'cycling');
    // 每段 0.01 度纬度约 1.112 km。
    expect(sample.payload['distanceKm'] as double, closeTo(2.224, 0.01));
    expect(sample.payload['elevationGainM'], 20.0);
    expect(sample.startAt, DateTime.parse('2025-01-02T08:30:00Z').toLocal());
    expect(sample.endAt, DateTime.parse('2025-01-02T08:40:00Z').toLocal());
    expect(importer.lastStats.samplesProduced, 1);
  });

  test('缺少 type 时分类回落到 other', () async {
    final xml = _cyclingTrack.replaceFirst('<type>cycling</type>', '');
    final result = await importer.parse(
      fileName: 'ride.gpx',
      bytes: utf8.encode(xml),
    );

    expect(result.requireValue().single.payload['category'], 'other');
  });

  test('按 type 映射骑行、跑步与步行', () async {
    for (final entry in <String, String>{
      'running': 'running',
      'hiking': 'walking',
      'swimming': 'swimming',
      'other': 'other',
    }.entries) {
      final xml = _cyclingTrack.replaceFirst(
        '<type>cycling</type>',
        '<type>${entry.key}</type>',
      );
      final result =
          await importer.parse(fileName: 'r.gpx', bytes: utf8.encode(xml));
      expect(result.requireValue().single.payload['category'], entry.value,
          reason: entry.key);
    }
  });

  test('带命名空间前缀的 GPX 同样可以解析', () async {
    final xml = '<?xml version="1.0"?>\n'
        '<g:gpx xmlns:g="http://www.topografix.com/GPX/1/1">\n'
        '  <g:trk><g:name>夜骑</g:name><g:type>cycling</g:type>\n'
        '    <g:trkseg>\n'
        '      <g:trkpt lat="30.0" lon="120.0">'
        '<g:ele>10</g:ele><g:time>2025-01-02T08:30:00Z</g:time></g:trkpt>\n'
        '      <g:trkpt lat="30.01" lon="120.0">'
        '<g:ele>20</g:ele><g:time>2025-01-02T08:35:00Z</g:time></g:trkpt>\n'
        '    </g:trkseg>\n'
        '  </g:trk>\n'
        '</g:gpx>\n';

    expect(importer.canHandle('ride.gpx', utf8.encode(xml)), isTrue);
    final result =
        await importer.parse(fileName: 'ride.gpx', bytes: utf8.encode(xml));
    expect(result.requireValue().single.title, '夜骑');
  });

  test('多个 trk 各产出一条样本', () async {
    final xml = _cyclingTrack.replaceFirst(
      '</gpx>',
      '<trk><name>返程</name><type>cycling</type><trkseg>'
          '<trkpt lat="30.02" lon="120.0">'
          '<ele>25</ele><time>2025-01-02T09:00:00Z</time></trkpt>'
          '<trkpt lat="30.03" lon="120.0">'
          '<ele>40</ele><time>2025-01-02T09:05:00Z</time></trkpt>'
          '</trkseg></trk></gpx>',
    );

    final result =
        await importer.parse(fileName: 'ride.gpx', bytes: utf8.encode(xml));
    final samples = result.requireValue();
    expect(samples.length, 2);
    expect(samples[1].title, '返程');
    expect(samples[1].payload['elevationGainM'], 15.0);
  });

  test('缺少 ele 时不输出爬升字段', () async {
    final xml = _cyclingTrack
        .replaceAll(RegExp(r'<ele>[^<]*</ele>'), '')
        .replaceAll('<type>cycling</type>', '');
    final result =
        await importer.parse(fileName: 'ride.gpx', bytes: utf8.encode(xml));
    expect(result.requireValue().single.payload.containsKey('elevationGainM'),
        isFalse);
  });

  test('轨迹点没有时间时报解析失败', () async {
    final xml = _cyclingTrack.replaceAll(
      RegExp(r'<time>[^<]*</time>'),
      '',
    );
    final result =
        await importer.parse(fileName: 'ride.gpx', bytes: utf8.encode(xml));
    expect(result.isOk, isFalse);
    expect(result.failureOrNull!.kind, FailureKind.parsing);
    expect(result.failureOrNull!.code, 'gpx_empty');
    expect(importer.lastStats.rowsSkipped, 1);
  });

  test('没有 trk 时报解析失败', () async {
    final result = await importer.parse(
      fileName: 'ride.gpx',
      bytes: utf8.encode('<gpx version="1.1"><metadata/></gpx>'),
    );
    expect(result.isOk, isFalse);
    expect(result.failureOrNull!.code, 'gpx_no_track');
  });

  test('同一文件导入两次得到相同的 externalId', () async {
    final bytes = utf8.encode(_cyclingTrack);
    final first = await importer.parse(fileName: 'a.gpx', bytes: bytes);
    final second = await importer.parse(fileName: 'a.gpx', bytes: bytes);
    expect(first.requireValue().single.externalId,
        second.requireValue().single.externalId);
  });

  test('canHandle 只接受 GPX', () {
    expect(importer.canHandle('ride.gpx', utf8.encode(_cyclingTrack)), isTrue);
    expect(
      importer.canHandle(
        'ride.tcx',
        utf8.encode('<TrainingCenterDatabase/>'),
      ),
      isFalse,
    );
    expect(importer.canHandle('a.csv', utf8.encode('a,b\n1,2\n')), isFalse);
    expect(importer.canHandle('a.gpx', utf8.encode('<html></html>')), isFalse);
    expect(importer.canHandle('a.gpx', const <int>[]), isFalse);
  });

  test('样本可以被 WorkoutSession 还原', () async {
    final result = await importer.parse(
      fileName: 'ride.gpx',
      bytes: utf8.encode(_cyclingTrack),
    );

    final session = WorkoutSession.tryFromSample(result.requireValue().single);
    expect(session, isNotNull);
    expect(session!.category, WorkoutCategory.cycling);
    expect(session.name, '晨间骑行');
    expect(session.distanceKm, closeTo(2.224, 0.01));
    expect(session.elevationGainM, 20.0);
    expect(session.durationMinutes, 10.0);
  });
}
