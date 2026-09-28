/// [import_utils] 的单元测试。
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:glucocontrol/data/health/importers/import_utils.dart';
import 'package:glucocontrol/domain/health/health_records.dart';

void main() {
  group('decodeImportText', () {
    test('去掉 UTF-8 BOM 后解码', () {
      final bytes = <int>[
        0xEF, 0xBB, 0xBF,
        ...utf8.encode('时间,血糖\n'),
      ];
      expect(decodeImportText(bytes), '时间,血糖\n');
    });

    test('无 BOM 的 UTF-8 原样解码', () {
      expect(decodeImportText(utf8.encode('记录时间,血糖(mmol/L)')),
          '记录时间,血糖(mmol/L)');
    });

    test('GBK 字节解码为中文', () {
      // “记录时间,血糖(mmol/L),趋势,备注” 的 GBK 编码。
      const gbkBytes = <int>[
        0xBC, 0xC7, 0xC2, 0xBC, 0xCA, 0xB1, 0xBC, 0xE4, 0x2C, //
        0xD1, 0xAA, 0xCC, 0xC7, 0x28, 0x6D, 0x6D, 0x6F, 0x6C, 0x2F, 0x4C,
        0x29, 0x2C, 0xC7, 0xF7, 0xCA, 0xC6, 0x2C, 0xB1, 0xB8, 0xD7, 0xA2,
      ];
      expect(decodeImportText(gbkBytes), '记录时间,血糖(mmol/L),趋势,备注');
    });

    test('UTF-16LE BOM 字节解码为中文', () {
      const utf16 = <int>[0xFF, 0xFE, 0xF6, 0x65, 0xF4, 0x95];
      expect(decodeImportText(utf16), '时间');
    });

    test('空字节返回空串', () {
      expect(decodeImportText(const <int>[]), '');
    });
  });

  group('normalizeHeaderKey', () {
    test('去掉括号里的单位', () {
      expect(normalizeHeaderKey('血糖(mmol/L)'), '血糖');
      expect(normalizeHeaderKey('体重[kg]'), '体重');
      expect(normalizeHeaderKey('距离（公里）'), '距离');
      expect(normalizeHeaderKey('血糖【mmol/L】'), '血糖');
    });

    test('容忍空格、大小写与前后缀', () {
      expect(normalizeHeaderKey('  Total Distance ( km ) '), 'totaldistance');
      expect(normalizeHeaderKey('Glucose'), 'glucose');
      expect(normalizeHeaderKey('运动类型'), '运动类型');
    });

    test('去掉 BOM 与分隔符', () {
      expect(normalizeHeaderKey('\uFEFF记录-时间'), '记录时间');
      expect(normalizeHeaderKey('备注/说明'), '备注说明');
    });
  });

  group('parseDoubleCell', () {
    test('剥离单位后缀', () {
      expect(parseDoubleCell('5.6 mmol/L'), 5.6);
      expect(parseDoubleCell('72 bpm'), 72);
      expect(parseDoubleCell('>7.8'), 7.8);
    });

    test('处理千分位与逗号小数', () {
      expect(parseDoubleCell('1,234.5'), 1234.5);
      expect(parseDoubleCell('1,234'), 1234);
      expect(parseDoubleCell('5,6'), 5.6);
    });

    test('占位符与空值返回 null', () {
      expect(parseDoubleCell(''), isNull);
      expect(parseDoubleCell('--'), isNull);
      expect(parseDoubleCell('N/A'), isNull);
      expect(parseDoubleCell(null), isNull);
      expect(parseDoubleCell('  '), isNull);
    });

    test('数值类型直接返回', () {
      expect(parseDoubleCell(42), 42.0);
      expect(parseDoubleCell(5.6), 5.6);
    });
  });

  group('parseIntCell', () {
    test('小数四舍五入', () {
      expect(parseIntCell('72.0'), 72);
      expect(parseIntCell('72.6'), 73);
      expect(parseIntCell('abc'), isNull);
    });
  });

  group('parseDateTimeCell', () {
    test('解析空格分隔的日期时间', () {
      expect(parseDateTimeCell('2025-01-02 08:30'), DateTime(2025, 1, 2, 8, 30));
    });

    test('解析斜杠与不补零写法', () {
      expect(parseDateTimeCell('2025/1/2 8:30'), DateTime(2025, 1, 2, 8, 30));
      expect(parseDateTimeCell('2025/01/02 08:30:15'),
          DateTime(2025, 1, 2, 8, 30, 15));
    });

    test('解析中文年月日时分', () {
      expect(parseDateTimeCell('2025年1月2日 8时30分'),
          DateTime(2025, 1, 2, 8, 30));
    });

    test('解析紧凑写法', () {
      expect(parseDateTimeCell('20250102'), DateTime(2025, 1, 2));
      expect(parseDateTimeCell('202501020830'), DateTime(2025, 1, 2, 8, 30));
    });

    test('带偏移的 ISO 8601 换算为本地时间', () {
      final expected = DateTime.parse('2025-01-02T08:30:00+08:00').toLocal();
      expect(parseDateTimeCell('2025-01-02T08:30:00+08:00'), expected);
    });

    test('非法日期返回 null', () {
      expect(parseDateTimeCell('2025-02-30'), isNull);
      expect(parseDateTimeCell('2025-13-01'), isNull);
      expect(parseDateTimeCell(''), isNull);
      expect(parseDateTimeCell('08:30'), isNull);
    });
  });

  group('parseDurationCell', () {
    test('解析冒号写法', () {
      expect(parseDurationCell('01:02:03'),
          const Duration(hours: 1, minutes: 2, seconds: 3));
      expect(parseDurationCell('45:30'),
          const Duration(minutes: 45, seconds: 30));
    });

    test('解析中文单位', () {
      expect(parseDurationCell('1小时30分'),
          const Duration(hours: 1, minutes: 30));
      expect(parseDurationCell('90分钟'), const Duration(minutes: 90));
      expect(parseDurationCell('45秒'), const Duration(seconds: 45));
    });

    test('纯数字按 hint 解释', () {
      expect(parseDurationCell('45'), const Duration(minutes: 45));
      expect(parseDurationCell('45', hint: DurationUnitHint.seconds),
          const Duration(seconds: 45));
    });

    test('无法识别返回 null', () {
      expect(parseDurationCell('--'), isNull);
      expect(parseDurationCell(''), isNull);
    });
  });

  group('buildExternalId', () {
    test('同输入两次得到相同标识', () {
      final first = buildExternalId('sibionics', <Object?>['2025-01-02 08:30', '5.6']);
      final second = buildExternalId('sibionics', <Object?>['2025-01-02 08:30', '5.6']);
      expect(first, second);
      expect(first, startsWith('sibionics-'));
    });

    test('关键字段变化导致标识变化', () {
      final base = buildExternalId('sibionics', <Object?>['2025-01-02 08:30', '5.6']);
      final changed =
          buildExternalId('sibionics', <Object?>['2025-01-02 08:31', '5.6']);
      expect(base, isNot(changed));
    });

    test('来源前缀参与摘要', () {
      expect(buildExternalId('keep', <Object?>['a']),
          isNot(buildExternalId('gpx', <Object?>['a'])));
    });

    test('两侧空白被归一化', () {
      expect(buildExternalId('keep', <Object?>[' a ']),
          buildExternalId('keep', <Object?>['a']));
    });
  });

  group('parseCsvRows', () {
    test('切分 CRLF 行并去掉空行', () {
      final rows = parseCsvRows('a,b\r\n1,2\r\n\r\n3,4\r\n');
      expect(rows, <List<String>>[
        <String>['a', 'b'],
        <String>['1', '2'],
        <String>['3', '4'],
      ]);
    });

    test('自动识别分号与制表符分隔', () {
      expect(parseCsvRows('a;b\n1;2'), <List<String>>[
        <String>['a', 'b'],
        <String>['1', '2'],
      ]);
      expect(detectCsvDelimiter('a\tb\tc'), '\t');
    });

    test('去除单元格两侧空白', () {
      expect(parseCsvRows('a , b \n1,2').first, <String>['a', 'b']);
    });
  });

  group('表头匹配', () {
    test('单位后缀的列名归一化后命中别名', () {
      final header = ImportHeader(<String>['记录时间', '血糖值(mmol/L)', '趋势']);
      final match = HeaderMatch.resolve(header, _glucoseColumns);
      expect(match['time'], 0);
      expect(match['glucose'], 1);
      expect(match['trend'], 2);
      expect(match.matchedCount, 3);
      expect(header.unitAt(1), 'mmol/l');
    });

    test('精确匹配优先于包含匹配', () {
      final header = ImportHeader(<String>['日期', '记录时间']);
      final match = HeaderMatch.resolve(header, const <ImportColumn>[
        ImportColumn('time', <String>['记录时间']),
        ImportColumn('date', <String>['日期']),
      ]);
      expect(match['time'], 1);
      expect(match['date'], 0);
    });

    test('cell 越界与缺列返回空串', () {
      final header = ImportHeader(<String>['血糖']);
      final match = HeaderMatch.resolve(header, _glucoseColumns);
      expect(match.cell(<String>['5.6'], 'glucose'), '5.6');
      expect(match.cell(<String>[], 'glucose'), '');
      expect(match.cell(<String>['5.6'], 'note'), '');
    });
  });

  group('CsvTable.tryLocate', () {
    test('跳过表头前的导言行', () {
      final rows = parseCsvRows(
        '# 导出时间,2025-01-02 09:00\n'
        '记录时间,血糖(mmol/L)\n'
        '2025-01-02 08:30,5.6\n',
      );
      final table = CsvTable.tryLocate(rows, _glucoseColumns);
      expect(table, isNotNull);
      expect(table!.headerRowIndex, 1);
      expect(table.dataRows.length, 1);
    });

    test('命中列数不足时返回 null', () {
      final rows = parseCsvRows('a,b\n1,2\n');
      expect(CsvTable.tryLocate(rows, _glucoseColumns), isNull);
    });
  });

  group('几何', () {
    test('Haversine 距离误差在百米内', () {
      expect(haversineMeters(0, 0, 0, 1), closeTo(111195, 50));
      expect(haversineMeters(30.0, 120.0, 30.0, 120.0), 0);
    });

    test('累计爬升只计入超过噪声门限的正高差', () {
      expect(elevationGainMeters(<double?>[100, 110, 105, 120]), 25);
      expect(elevationGainMeters(<double?>[100, 100.5, 101]), 0);
      expect(elevationGainMeters(<double?>[null, 100, 110]), 10);
      expect(elevationGainMeters(<double?>[]), 0);
    });
  });

  group('mapWorkoutCategoryKeyword', () {
    test('按关键字归一化', () {
      expect(mapWorkoutCategoryKeyword('户外跑步'), WorkoutCategory.running);
      expect(mapWorkoutCategoryKeyword('Biking'), WorkoutCategory.cycling);
      expect(mapWorkoutCategoryKeyword('力量训练'), WorkoutCategory.strength);
      expect(mapWorkoutCategoryKeyword('HIIT 燃脂'), WorkoutCategory.hiit);
      expect(mapWorkoutCategoryKeyword('瑜伽'), WorkoutCategory.yoga);
      expect(mapWorkoutCategoryKeyword('hiking'), WorkoutCategory.walking);
      expect(mapWorkoutCategoryKeyword('游泳'), WorkoutCategory.swimming);
    });

    test('未知或空值回落到 other', () {
      expect(mapWorkoutCategoryKeyword('Other'), WorkoutCategory.other);
      expect(mapWorkoutCategoryKeyword(''), WorkoutCategory.other);
      expect(mapWorkoutCategoryKeyword(null), WorkoutCategory.other);
    });
  });

  group('hasFileExtension', () {
    test('忽略大小写且要求点号分隔', () {
      expect(hasFileExtension('a.CSV', const <String>['csv']), true);
      expect(hasFileExtension('a.csv', const <String>['csv']), true);
      expect(hasFileExtension('acsv', const <String>['csv']), false);
      expect(hasFileExtension('a.gpx', const <String>['csv']), false);
    });
  });

  group('ImportStatsBuilder', () {
    test('汇总读入、产出与跳过原因', () {
      final builder = ImportStatsBuilder()
        ..countRead()
        ..countRead()
        ..countProduced()
        ..countSkipped('缺时间')
        ..countSkipped('缺时间');
      final stats = builder.build();
      expect(stats.rowsRead, 2);
      expect(stats.samplesProduced, 1);
      expect(stats.rowsSkipped, 2);
      expect(stats.skipReasons['缺时间'], 2);
    });
  });
}

/// 血糖类文件的列定义，供多个用例复用。
const List<ImportColumn> _glucoseColumns = <ImportColumn>[
  ImportColumn('time', <String>['记录时间', '时间', 'datetime']),
  ImportColumn('glucose', <String>['血糖值', '血糖', 'glucose']),
  ImportColumn('trend', <String>['趋势', 'trend']),
  ImportColumn('note', <String>['备注', 'note']),
];
