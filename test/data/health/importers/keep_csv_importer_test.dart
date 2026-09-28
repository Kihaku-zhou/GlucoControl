/// [KeepCsvImporter] 的单元测试。
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:glucocontrol/core/result.dart';
import 'package:glucocontrol/data/health/importers/keep_csv_importer.dart';
import 'package:glucocontrol/domain/health/health_records.dart';
import 'package:glucocontrol/domain/health/health_source.dart';

void main() {
  final importer = KeepCsvImporter();

  test('解析常规运动记录并用时长补齐结束时间', () async {
    final result = await importer.parse(
      fileName: 'keep.csv',
      bytes: utf8.encode(
        '运动类型,开始时间,时长,消耗(千卡),距离(公里),平均心率,最大心率\n'
        '户外跑步,2025-01-02 08:30,00:45:00,420,7.5,150,172\n'
        '骑行,2025-01-03 07:00,1:30:00,600,30,130,160\n',
      ),
    );

    expect(result.isOk, isTrue);
    final samples = result.requireValue();
    expect(samples.length, 2);
    expect(samples.first.source, HealthSourceId.keep);
    expect(samples.first.kind, HealthSampleKind.workout);
    expect(samples.first.startAt, DateTime(2025, 1, 2, 8, 30));
    expect(samples.first.endAt, DateTime(2025, 1, 2, 9, 15));
    expect(samples.first.title, '户外跑步');
    expect(samples.first.payload['category'], 'running');
    expect(samples.first.payload['name'], '户外跑步');
    expect(samples.first.payload['distanceKm'], 7.5);
    expect(samples.first.payload['calories'], 420);
    expect(samples.first.payload['avgHeartRate'], 150);
    expect(samples.first.payload['maxHeartRate'], 172);
    expect(samples[1].payload['category'], 'cycling');
  });

  test('距离单位为米时换算为公里', () async {
    final result = await importer.parse(
      fileName: 'keep.csv',
      bytes: utf8.encode(
        '运动类型,开始时间,时长,距离(米)\n'
        '步行,2025-01-04 18:00,00:30:00,3200\n',
      ),
    );

    expect(result.requireValue().single.payload['distanceKm'], 3.2);
  });

  test('显式结束时间优先于时长', () async {
    final result = await importer.parse(
      fileName: 'keep.csv',
      bytes: utf8.encode(
        '运动类型,开始时间,结束时间,时长\n'
        '跑步,2025-01-02 08:30,2025-01-02 09:20,00:45:00\n',
      ),
    );

    expect(result.requireValue().single.endAt, DateTime(2025, 1, 2, 9, 20));
  });

  test('时长缺失时结束时间等于开始时间', () async {
    final result = await importer.parse(
      fileName: 'keep.csv',
      bytes: utf8.encode('运动类型,开始时间,消耗\n瑜伽,2025-01-05 20:00,120\n'),
    );

    final sample = result.requireValue().single;
    expect(sample.endAt, sample.startAt);
    expect(sample.payload['category'], 'yoga');
  });

  test('脏数据被跳过并计数', () async {
    final result = await importer.parse(
      fileName: 'dirty.csv',
      bytes: utf8.encode(
        '运动类型,开始时间,时长,消耗\n'
        '跑步,2025-01-02 08:30,00:45:00,420\n'
        ',2025-01-02 09:00,00:10:00,50\n'
        '走路,bad,00:20:00,80\n'
        '瑜伽,,00:30:00,100\n'
        '骑行,2025-01-02 10:00,--,abc\n',
      ),
    );

    expect(result.isOk, isTrue);
    final samples = result.requireValue();
    expect(samples.length, 3);
    expect(importer.lastStats.rowsRead, 5);
    expect(importer.lastStats.rowsSkipped, 2);
    expect(importer.lastStats.skipReasons['缺少或无法解析的开始时间'], 2);
    expect(samples[1].title, '运动');
    expect(samples[2].payload.containsKey('calories'), isFalse);
    expect(samples[2].endAt, samples[2].startAt);
  });

  test('同一文件导入两次得到相同的 externalId', () async {
    final bytes = utf8.encode(
      '运动类型,开始时间,时长,消耗\n'
      '跑步,2025-01-02 08:30,00:45:00,420\n'
      '骑行,2025-01-03 07:00,01:30:00,600\n',
    );

    final first = await importer.parse(fileName: 'a.csv', bytes: bytes);
    final second = await importer.parse(fileName: 'a.csv', bytes: bytes);
    expect(
      first.requireValue().map((sample) => sample.externalId).toSet(),
      second.requireValue().map((sample) => sample.externalId).toSet(),
    );
  });

  test('缺少时间列时报解析失败', () async {
    final bytes = utf8.encode('运动类型,时长,消耗\n跑步,45,420\n');
    expect(importer.canHandle('x.csv', bytes), isTrue);

    final result = await importer.parse(fileName: 'x.csv', bytes: bytes);
    expect(result.isOk, isFalse);
    expect(result.failureOrNull!.kind, FailureKind.parsing);
    expect(result.failureOrNull!.code, 'keep_csv_no_time_column');
  });

  test('判别字段不足时拒绝接管', () async {
    final weak = utf8.encode('运动类型,备注\n跑步,还行\n');
    expect(importer.canHandle('x.csv', weak), isFalse);

    final result = await importer.parse(fileName: 'x.csv', bytes: weak);
    expect(result.isOk, isFalse);
    expect(result.failureOrNull!.code, 'keep_csv_no_header');
  });

  test('canHandle 拒绝其他应用的 CSV 与 XML', () {
    expect(
      importer.canHandle(
        'sibionics.csv',
        utf8.encode('记录时间,血糖(mmol/L)\n2025-01-02 08:30,5.6\n'),
      ),
      isFalse,
    );
    expect(
      importer.canHandle(
        'xunji.csv',
        utf8.encode('日期,动作,重量(kg),组数,次数\n2025-01-02,卧推,60,4,10\n'),
      ),
      isFalse,
    );
    expect(importer.canHandle('noise.csv', utf8.encode('a,b\n1,2\n')), isFalse);
    expect(
      importer.canHandle(
        'track.gpx',
        utf8.encode('<?xml version="1.0"?><gpx><trk/></gpx>'),
      ),
      isFalse,
    );
  });

  test('样本可以被 WorkoutSession 还原', () async {
    final result = await importer.parse(
      fileName: 'keep.csv',
      bytes: utf8.encode(
        '运动类型,开始时间,时长,消耗(千卡),距离(公里)\n'
        '户外跑步,2025-01-02 08:30,00:45:00,420,7.5\n',
      ),
    );

    final session = WorkoutSession.tryFromSample(result.requireValue().single);
    expect(session, isNotNull);
    expect(session!.category, WorkoutCategory.running);
    expect(session.name, '户外跑步');
    expect(session.distanceKm, 7.5);
    expect(session.calories, 420);
    expect(session.durationMinutes, 45.0);
  });
}
