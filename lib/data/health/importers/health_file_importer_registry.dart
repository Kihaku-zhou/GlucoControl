/// 外部健康文件导入器的注册表。
library;

import '../../../domain/health/health_data_source.dart';
import 'fit_activity_importer.dart';
import 'gpx_track_importer.dart';
import 'import_utils.dart';
import 'keep_csv_importer.dart';
import 'sibionics_csv_importer.dart';
import 'tcx_activity_importer.dart';
import 'xunji_csv_importer.dart';

/// 按扩展名与表头嗅探挑选合适的导入器。
///
/// 选择分两步：先按文件名后缀缩小候选范围，再按声明顺序调用 [canHandle]，
/// 因此多个导入器共用 `.csv` 时不会互相抢文件——表头不匹配的导入器返回 false。
class HealthFileImporterRegistry {
  /// 构造注册表。
  ///
  /// @param importers 参与选择的导入器；省略时使用 [defaultImporters]。
  HealthFileImporterRegistry([List<HealthFileImporter>? importers])
      : importers = List<HealthFileImporter>.unmodifiable(
          importers ?? defaultImporters,
        );

  /// 内置导入器，顺序即 [resolve] 的优先级。
  ///
  /// CSV 三者在前，格式互斥的 GPX / TCX / FIT 在后。
  static final List<HealthFileImporter> defaultImporters =
      List<HealthFileImporter>.unmodifiable(<HealthFileImporter>[
    SibionicsCsvImporter(),
    XunjiCsvImporter(),
    KeepCsvImporter(),
    GpxTrackImporter(),
    TcxActivityImporter(),
    FitActivityImporter(),
  ]);

  /// 参与选择的导入器。
  final List<HealthFileImporter> importers;

  /// 按文件名后缀筛选候选导入器。
  ///
  /// @param fileName 文件名或路径。
  /// @returns 扩展名匹配的导入器，保持 [importers] 的顺序。
  List<HealthFileImporter> candidatesFor(String fileName) => importers
      .where((importer) => hasFileExtension(fileName, importer.fileExtensions))
      .toList();

  /// 为文件挑选导入器。
  ///
  /// 只解码文件头部（[headBytes]）做嗅探，不对大文件做全量解析。
  ///
  /// @param fileName 文件名或路径，用于扩展名筛选。
  /// @param bytes 文件原始字节。
  /// @returns 第一个 [HealthFileImporter.canHandle] 通过的导入器；都不匹配时返回 null。
  HealthFileImporter? resolve(String fileName, List<int> bytes) {
    final head = headBytes(bytes);
    for (final importer in candidatesFor(fileName)) {
      if (importer.canHandle(fileName, head)) return importer;
    }
    return null;
  }
}
