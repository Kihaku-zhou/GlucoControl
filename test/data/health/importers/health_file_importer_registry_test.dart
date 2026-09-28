/// [HealthFileImporterRegistry] 的单元测试。
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:glucocontrol/data/health/importers/fit_activity_importer.dart';
import 'package:glucocontrol/data/health/importers/gpx_track_importer.dart';
import 'package:glucocontrol/data/health/importers/health_file_importer_registry.dart';
import 'package:glucocontrol/data/health/importers/keep_csv_importer.dart';
import 'package:glucocontrol/data/health/importers/sibionics_csv_importer.dart';
import 'package:glucocontrol/data/health/importers/tcx_activity_importer.dart';
import 'package:glucocontrol/data/health/importers/xunji_csv_importer.dart';
import 'package:glucocontrol/domain/health/health_data_source.dart';
import 'package:glucocontrol/domain/health/health_source.dart';

/// 头长度合法、含 `.FIT` 签名的最小 FIT 字节。
final List<int> _minimalFit = <int>[
  14, 0x10, 0x23, 0x08, 0, 0, 0, 0, 0x2E, 0x46, 0x49, 0x54, 0, 0,
];

/// 各格式的最小可用样本。
final Map<String, List<int>> _samples = <String, List<int>>{
  'sibionics.csv':
      utf8.encode('记录时间,血糖(mmol/L)\n2025-01-02 08:30,5.6\n'),
  'xunji.csv': utf8.encode('日期,动作,重量(kg),组数,次数\n2025-01-02,卧推,60,4,10\n'),
  'keep.csv':
      utf8.encode('运动类型,开始时间,时长,消耗\n跑步,2025-01-02 08:30,45,300\n'),
  'ride.gpx': utf8.encode(
    '<gpx version="1.1"><trk><trkseg>'
    '<trkpt lat="30.0" lon="120.0"><time>2025-01-02T08:30:00Z</time></trkpt>'
    '</trkseg></trk></gpx>',
  ),
  'ride.tcx': utf8.encode(
    '<TrainingCenterDatabase><Activities><Activity Sport="Biking">'
    '<Id>2025-01-02T08:30:00Z</Id></Activity></Activities>'
    '</TrainingCenterDatabase>',
  ),
  'ride.fit': _minimalFit,
};

void main() {
  final registry = HealthFileImporterRegistry();

  test('内置导入器覆盖六种格式且来源标记正确', () {
    final importers = HealthFileImporterRegistry.defaultImporters;
    expect(importers.length, 6);
    expect(importers[0], isA<SibionicsCsvImporter>());
    expect(importers[1], isA<XunjiCsvImporter>());
    expect(importers[2], isA<KeepCsvImporter>());
    expect(importers[3], isA<GpxTrackImporter>());
    expect(importers[4], isA<TcxActivityImporter>());
    expect(importers[5], isA<FitActivityImporter>());

    expect(importers[0].id, HealthSourceId.sibionics);
    expect(importers[1].id, HealthSourceId.xunji);
    expect(importers[2].id, HealthSourceId.keep);
    for (final index in <int>[3, 4, 5]) {
      expect(importers[index].id, HealthSourceId.fileImport);
    }
    expect(registry.importers, importers);
  });

  test('按扩展名缩小候选范围', () {
    expect(registry.candidatesFor('a.csv').length, 3);
    expect(registry.candidatesFor('a.CSV').length, 3);
    expect(registry.candidatesFor('a.gpx').single, isA<GpxTrackImporter>());
    expect(registry.candidatesFor('a.tcx').single, isA<TcxActivityImporter>());
    expect(registry.candidatesFor('a.fit').single, isA<FitActivityImporter>());
    expect(registry.candidatesFor('a.txt'), isEmpty);
    expect(registry.candidatesFor('a'), isEmpty);
  });

  test('按表头把同名 CSV 分派给正确的导入器', () {
    expect(registry.resolve('a.csv', _samples['sibionics.csv']!),
        isA<SibionicsCsvImporter>());
    expect(registry.resolve('a.csv', _samples['xunji.csv']!),
        isA<XunjiCsvImporter>());
    expect(registry.resolve('a.csv', _samples['keep.csv']!),
        isA<KeepCsvImporter>());
  });

  test('按扩展名分派 XML 与二进制格式', () {
    expect(registry.resolve('ride.gpx', _samples['ride.gpx']!),
        isA<GpxTrackImporter>());
    expect(registry.resolve('ride.tcx', _samples['ride.tcx']!),
        isA<TcxActivityImporter>());
    expect(registry.resolve('ride.fit', _samples['ride.fit']!),
        isA<FitActivityImporter>());
  });

  test('无法识别时返回 null', () {
    expect(registry.resolve('a.csv', utf8.encode('a,b\n1,2\n')), isNull);
    expect(registry.resolve('a.txt', utf8.encode('a,b\n1,2\n')), isNull);
    expect(registry.resolve('a.gpx', utf8.encode('<html/>')), isNull);
  });

  test('可以注入自定义导入器集合', () {
    final custom = HealthFileImporterRegistry(<HealthFileImporter>[
      KeepCsvImporter(),
      SibionicsCsvImporter(),
    ]);
    expect(custom.importers.length, 2);
    expect(custom.candidatesFor('a.gpx'), isEmpty);
    // 顺序改变后，同一个文件由注入顺序决定归属。
    expect(custom.resolve('a.csv', _samples['keep.csv']!),
        isA<KeepCsvImporter>());
  });
}
