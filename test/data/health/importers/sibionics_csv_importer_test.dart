/// [SibionicsCsvImporter] 的单元测试。
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:glucocontrol/core/glucose_units.dart';
import 'package:glucocontrol/core/result.dart';
import 'package:glucocontrol/data/health/importers/sibionics_csv_importer.dart';
import 'package:glucocontrol/domain/health/health_records.dart';
import 'package:glucocontrol/domain/health/health_source.dart';

void main() {
  final importer = SibionicsCsvImporter();

  test('识别并解析常规导出', () async {
    final result = await importer.parse(
      fileName: 'sibionics.csv',
      bytes: utf8.encode(
        '记录时间,血糖(mmol/L),趋势,事件,备注\n'
        '2025-01-02 08:30,5.6,→,空腹,起床\n'
        '2025-01-02 08:35,6.1,↑,,\n'
        '2025-01-02 08:40,7.2,快速上升,餐后,\n',
      ),
    );

    expect(result.isOk, isTrue);
    final samples = result.requireValue();
    expect(samples.length, 3);
    expect(samples.first.kind, HealthSampleKind.glucose);
    expect(samples.first.source, HealthSourceId.sibionics);
    expect(samples.first.startAt, DateTime(2025, 1, 2, 8, 30));
    expect(samples.first.payload['mmolPerL'], 5.6);
    expect(samples.first.payload['context'], 'fasting');
    expect(samples.first.payload['trend'], 'steady');
    expect(samples.first.payload['note'], '起床');
    expect(samples[1].payload['trend'], 'rising');
    expect(samples[2].payload['trend'], 'rising_fast');
    expect(samples[2].payload['context'], 'post_meal');
    expect(importer.lastStats.samplesProduced, 3);
  });

  test('兼容 UTF-8 BOM 与全角表头', () async {
    final text = '记录时间,血糖（mmol／L）,趋势\n'
        '2025/1/2 8:30,5.6,平稳\n';
    final result = await importer.parse(
      fileName: 'bom.csv',
      bytes: <int>[0xEF, 0xBB, 0xBF, ...utf8.encode(text)],
    );

    expect(result.isOk, isTrue);
    expect(result.requireValue().single.startAt, DateTime(2025, 1, 2, 8, 30));
    expect(result.requireValue().single.payload['trend'], 'steady');
  });

  test('兼容 GBK 编码的表头与数据', () async {
    // “记录时间,血糖(mmol/L),趋势,备注\n2025-01-02 08:30,5.6,→,空腹” 的 GBK 编码。
    const gbkBytes = <int>[
      0xBC, 0xC7, 0xC2, 0xBC, 0xCA, 0xB1, 0xBC, 0xE4, 0x2C, //
      0xD1, 0xAA, 0xCC, 0xC7, 0x28, 0x6D, 0x6D, 0x6F, 0x6C, 0x2F, 0x4C, 0x29,
      0x2C, 0xC7, 0xF7, 0xCA, 0xC6, 0x2C, 0xB1, 0xB8, 0xD7, 0xA2, 0x0A, //
      0x32, 0x30, 0x32, 0x35, 0x2D, 0x30, 0x31, 0x2D, 0x30, 0x32, 0x20, 0x30,
      0x38, 0x3A, 0x33, 0x30, 0x2C, 0x35, 0x2E, 0x36, 0x2C, 0xA1, 0xFA, 0x2C,
      0xBF, 0xD5, 0xB8, 0xB9,
    ];

    expect(importer.canHandle('sibionics.csv', gbkBytes), isTrue);
    final result =
        await importer.parse(fileName: 'sibionics.csv', bytes: gbkBytes);
    expect(result.isOk, isTrue);
    final sample = result.requireValue().single;
    expect(sample.payload['mmolPerL'], 5.6);
    expect(sample.payload['context'], 'fasting');
    expect(sample.payload['note'], '空腹');
  });

  test('mg/dL 表头按单位换算为 mmol/L', () async {
    final result = await importer.parse(
      fileName: 'mgdl.csv',
      bytes: utf8.encode('记录时间,血糖(mg/dL)\n2025-01-02 08:30,100\n'),
    );

    expect(result.isOk, isTrue);
    expect(result.requireValue().single.payload['mmolPerL'] as double,
        closeTo(5.55, 0.01));
  });

  test('脏数据被跳过并计数，不影响其余行', () async {
    final result = await importer.parse(
      fileName: 'dirty.csv',
      bytes: utf8.encode(
        '记录时间,血糖(mmol/L)\n'
        '2025-01-02 08:30,5.6\n'
        ',5.6\n'
        '2025-01-02 08:35,\n'
        '2025-01-02 08:40,--\n'
        '2025-01-02 08:45,999\n'
        'bad,5.0\n'
        '2025-01-02 08:50,6.0\n',
      ),
    );

    expect(result.isOk, isTrue);
    expect(result.requireValue().length, 2);
    expect(importer.lastStats.rowsRead, 7);
    expect(importer.lastStats.samplesProduced, 2);
    expect(importer.lastStats.rowsSkipped, 5);
    expect(importer.lastStats.skipReasons['缺少或无法解析的时间'], 2);
    expect(importer.lastStats.skipReasons['缺少或无法解析的血糖值'], 2);
    expect(importer.lastStats.skipReasons['血糖值超出合理范围'], 1);
  });

  test('日期与时刻分成两列时合并解析', () async {
    final result = await importer.parse(
      fileName: 'split.csv',
      bytes: utf8.encode(
        '日期,时间,血糖值\n'
        '2025-01-02,08:30,5.6\n',
      ),
    );

    expect(result.isOk, isTrue);
    expect(result.requireValue().single.startAt, DateTime(2025, 1, 2, 8, 30));
  });

  test('同一文件导入两次得到相同的 externalId 集合', () async {
    final bytes = utf8.encode(
      '记录时间,血糖(mmol/L)\n'
      '2025-01-02 08:30,5.6\n'
      '2025-01-02 08:35,6.1\n',
    );

    final first = await importer.parse(fileName: 'a.csv', bytes: bytes);
    final second = await importer.parse(fileName: 'a.csv', bytes: bytes);
    expect(
      first.requireValue().map((sample) => sample.externalId).toSet(),
      second.requireValue().map((sample) => sample.externalId).toSet(),
    );
  });

  test('缺少血糖列时拒绝接管并报解析失败', () async {
    final bytes = utf8.encode('记录时间,备注\n2025-01-02 08:30,起床\n');
    expect(importer.canHandle('x.csv', bytes), isFalse);

    final result = await importer.parse(fileName: 'x.csv', bytes: bytes);
    expect(result.isOk, isFalse);
    expect(result.failureOrNull!.kind, FailureKind.parsing);
    expect(result.failureOrNull!.code, 'sibionics_csv_no_header');
  });

  test('只有表头没有数据时报解析失败', () async {
    final result = await importer.parse(
      fileName: 'empty.csv',
      bytes: utf8.encode('记录时间,血糖(mmol/L)\n'),
    );
    expect(result.isOk, isFalse);
    expect(result.failureOrNull!.code, 'sibionics_csv_empty');
  });

  test('canHandle 拒绝其他应用的 CSV 与非 CSV 扩展名', () {
    final keepCsv = utf8.encode('运动类型,开始时间,时长,消耗\n跑步,2025-01-02 08:30,45,300\n');
    final xunjiCsv = utf8.encode('日期,动作,重量(kg),组数,次数\n2025-01-02,卧推,60,4,10\n');
    final noise = utf8.encode('a,b\n1,2\n');

    expect(importer.canHandle('keep.csv', keepCsv), isFalse);
    expect(importer.canHandle('xunji.csv', xunjiCsv), isFalse);
    expect(importer.canHandle('noise.csv', noise), isFalse);
    expect(
      importer.canHandle(
        'sibionics.txt',
        utf8.encode('记录时间,血糖(mmol/L)\n2025-01-02 08:30,5.6\n'),
      ),
      isFalse,
    );
  });

  test('样本可以被 GlucoseReading 还原', () async {
    final result = await importer.parse(
      fileName: 'sibionics.csv',
      bytes: utf8.encode(
        '记录时间,血糖(mmol/L),趋势,事件,备注\n'
        '2025-01-02 08:30,5.6,↑,空腹,起床\n',
      ),
    );

    final reading = GlucoseReading.tryFromSample(result.requireValue().single);
    expect(reading, isNotNull);
    expect(reading!.mmolPerL, 5.6);
    expect(reading.context, GlucoseContext.fasting);
    expect(reading.trend, GlucoseTrend.rising);
    expect(reading.note, '起床');
    expect(reading.recordedAt, DateTime(2025, 1, 2, 8, 30));
  });
}
