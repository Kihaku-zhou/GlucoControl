/// [XunjiCsvImporter] 的单元测试。
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:glucocontrol/core/result.dart';
import 'package:glucocontrol/data/health/importers/xunji_csv_importer.dart';
import 'package:glucocontrol/domain/health/health_records.dart';
import 'package:glucocontrol/domain/health/health_source.dart';

void main() {
  final importer = XunjiCsvImporter();

  test('按自然日汇总组次明细', () async {
    final result = await importer.parse(
      fileName: 'xunji.csv',
      bytes: utf8.encode(
        '日期,动作,重量(kg),组数,次数\n'
        '2025-01-02,卧推,60,4,10\n'
        '2025-01-02,卧推,60,4,8\n'
        '2025-01-02,深蹲,80,5,5\n'
        '2025-01-03,硬拉,100,3,5\n',
      ),
    );

    expect(result.isOk, isTrue);
    final samples = result.requireValue();
    expect(samples.length, 2);
    expect(samples.first.kind, HealthSampleKind.workout);
    expect(samples.first.source, HealthSourceId.xunji);
    expect(samples.first.startAt, DateTime(2025, 1, 2));
    expect(samples.first.payload['category'], 'strength');
    expect(samples.first.payload['name'], '力量训练 · 卧推 / 深蹲');
    expect(samples.first.payload['totalVolumeKg'], 6320.0);
    expect(samples.first.payload['totalSets'], 13);
    expect(samples.first.payload['totalReps'], 97);

    expect(samples[1].startAt, DateTime(2025, 1, 3));
    expect(samples[1].payload['totalVolumeKg'], 1500.0);
    expect(samples[1].payload['totalSets'], 3);
    expect(samples[1].payload['totalReps'], 15);
    expect(importer.lastStats.samplesProduced, 2);
  });

  test('带时刻时用首末时刻作为起止时间', () async {
    final result = await importer.parse(
      fileName: 'xunji.csv',
      bytes: utf8.encode(
        '训练时间,动作名称,重量,组数,次数\n'
        '2025-01-02 08:30,卧推,60,4,10\n'
        '2025-01-02 09:30,深蹲,80,5,5\n',
      ),
    );

    expect(result.isOk, isTrue);
    final sample = result.requireValue().single;
    expect(sample.startAt, DateTime(2025, 1, 2, 8, 30));
    expect(sample.endAt, DateTime(2025, 1, 2, 9, 30));
    expect(sample.payload.containsKey('note'), isFalse);
  });

  test('只有日期时按零时长记录并给出说明', () async {
    final result = await importer.parse(
      fileName: 'xunji.csv',
      bytes: utf8.encode('日期,动作,重量,组数,次数\n2025-01-02,卧推,60,4,10\n'),
    );

    final sample = result.requireValue().single;
    expect(sample.endAt, sample.startAt);
    expect(sample.payload['note'], '原始文件未提供训练时长');
  });

  test('没有次数时仍统计组数与容量以外的字段', () async {
    final result = await importer.parse(
      fileName: 'xunji.csv',
      bytes: utf8.encode('日期,动作,重量,组数\n2025-01-02,平板支撑,0,3\n'),
    );

    final sample = result.requireValue().single;
    expect(sample.payload['totalSets'], 3);
    expect(sample.payload.containsKey('totalReps'), isFalse);
    expect(sample.payload.containsKey('totalVolumeKg'), isFalse);
  });

  test('脏数据被跳过并计数', () async {
    final result = await importer.parse(
      fileName: 'dirty.csv',
      bytes: utf8.encode(
        '日期,动作,重量,组数,次数\n'
        '2025-01-02,卧推,60,4,10\n'
        'bad,深蹲,80,5,5\n'
        '2025-01-02,,abc,4,10\n',
      ),
    );

    expect(result.isOk, isTrue);
    expect(importer.lastStats.rowsRead, 3);
    expect(importer.lastStats.rowsSkipped, 1);
    expect(importer.lastStats.skipReasons['缺少或无法解析的时间'], 1);
    expect(result.requireValue().single.payload['totalSets'], 8);
  });

  test('同一文件导入两次得到相同的 externalId', () async {
    final bytes = utf8.encode(
      '日期,动作,重量,组数,次数\n'
      '2025-01-02,卧推,60,4,10\n'
      '2025-01-03,深蹲,80,5,5\n',
    );

    final first = await importer.parse(fileName: 'a.csv', bytes: bytes);
    final second = await importer.parse(fileName: 'a.csv', bytes: bytes);
    expect(
      first.requireValue().map((sample) => sample.externalId).toSet(),
      second.requireValue().map((sample) => sample.externalId).toSet(),
    );
  });

  test('缺少时间列时报解析失败', () async {
    final bytes = utf8.encode('动作,重量,组数,次数\n卧推,60,4,10\n');
    expect(importer.canHandle('x.csv', bytes), isTrue);

    final result = await importer.parse(fileName: 'x.csv', bytes: bytes);
    expect(result.isOk, isFalse);
    expect(result.failureOrNull!.kind, FailureKind.parsing);
    expect(result.failureOrNull!.code, 'xunji_csv_no_time_column');
  });

  test('判别字段不足时拒绝接管', () async {
    final onlyWeight = utf8.encode('日期,重量,备注\n2025-01-02,60,还行\n');
    expect(importer.canHandle('x.csv', onlyWeight), isFalse);

    final result = await importer.parse(fileName: 'x.csv', bytes: onlyWeight);
    expect(result.isOk, isFalse);
    expect(result.failureOrNull!.code, 'xunji_csv_no_header');
  });

  test('canHandle 拒绝其他应用的 CSV 与非 CSV 扩展名', () {
    expect(
      importer.canHandle(
        'sibionics.csv',
        utf8.encode('记录时间,血糖(mmol/L)\n2025-01-02 08:30,5.6\n'),
      ),
      isFalse,
    );
    expect(
      importer.canHandle(
        'keep.csv',
        utf8.encode('运动类型,开始时间,时长,消耗\n跑步,2025-01-02 08:30,45,300\n'),
      ),
      isFalse,
    );
    expect(importer.canHandle('noise.csv', utf8.encode('a,b\n1,2\n')), isFalse);
    expect(
      importer.canHandle(
        'xunji.txt',
        utf8.encode('日期,动作,重量,组数,次数\n2025-01-02,卧推,60,4,10\n'),
      ),
      isFalse,
    );
  });

  test('样本可以被 WorkoutSession 还原', () async {
    final result = await importer.parse(
      fileName: 'xunji.csv',
      bytes: utf8.encode('日期,动作,重量(kg),组数,次数\n2025-01-02,卧推,60,4,10\n'),
    );

    final session = WorkoutSession.tryFromSample(result.requireValue().single);
    expect(session, isNotNull);
    expect(session!.category, WorkoutCategory.strength);
    expect(session.name, '力量训练 · 卧推');
    expect(session.totalVolumeKg, 2400.0);
    expect(session.totalSets, 4);
    expect(session.totalReps, 40);
    expect(session.startedAt, DateTime(2025, 1, 2));
  });
}
