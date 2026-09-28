/// Keep 导出的运动记录 CSV 导入器。
library;

import '../../../core/result.dart';
import '../../../domain/health/health_source.dart';
import 'import_utils.dart';

/// 解析 Keep 导出的运动记录 CSV。
///
/// 一条数据行对应一条 [HealthSampleKind.workout] 样本；结束时间缺失时按
/// `开始时间 + 时长` 补齐，时长也缺失时以开始时间作为结束时间。
class KeepCsvImporter extends HealthFileImporterBase {
  /// 构造导入器。
  KeepCsvImporter();

  /// 表头识别用的逻辑字段。
  static const List<ImportColumn> _columns = <ImportColumn>[
    ImportColumn('time', <String>[
      '开始时间', '运动时间', '训练时间', '日期时间', '时间', 'datetime',
      'timestamp', 'starttime', 'time',
    ]),
    ImportColumn('date', <String>['日期', 'date']),
    ImportColumn('endTime', <String>['结束时间', 'endtime', 'end']),
    ImportColumn('sportType', <String>[
      '运动类型', '运动名称', '训练类型', '课程名称', '课程', '类型', 'sporttype',
      'sport', 'workouttype', 'type',
    ]),
    ImportColumn('duration', <String>[
      '运动时长', '持续时间', '时长', '用时', 'duration',
    ]),
    ImportColumn('calories', <String>[
      '消耗热量', '消耗', '卡路里', '热量', '千卡', 'calories', 'kcal',
    ]),
    ImportColumn('distance', <String>['总距离', '距离', '里程', 'distance']),
    ImportColumn('elevation', <String>['累计爬升', '爬升', '海拔爬升', 'elevation']),
    ImportColumn('avgHeartRate', <String>['平均心率', '平均心跳', 'avghr', 'avgheartrate']),
    ImportColumn('maxHeartRate', <String>['最大心率', 'maxhr']),
    ImportColumn('note', <String>['备注', '说明', 'note', 'remark', 'comment']),
  ];

  /// [canHandle] 使用的判别字段：至少命中其中两个才认为是 Keep 导出。
  static const List<String> _discriminatorFields = <String>[
    'sportType', 'duration', 'calories',
  ];

  @override
  HealthSourceId get id => HealthSourceId.keep;

  @override
  String get displayName => 'Keep CSV';

  @override
  List<String> get fileExtensions => const <String>['csv'];

  @override
  bool canHandle(String fileName, List<int> bytes) {
    if (!hasFileExtension(fileName, fileExtensions)) return false;
    final table = _locate(bytes);
    if (table == null) return false;
    final matched = _discriminatorFields
        .where((field) => table.match[field] != null)
        .length;
    return matched >= 2;
  }

  @override
  Future<Result<List<HealthSample>>> parse({
    required String fileName,
    required List<int> bytes,
  }) {
    final builder = ImportStatsBuilder();
    return runImport('keep_csv', () {
      try {
        final table = _locate(bytes);
        if (table == null) {
          throw importParsingFailure(
            '未找到可识别的表头，请确认是 Keep 导出的 CSV 文件',
            code: 'keep_csv_no_header',
          );
        }
        final match = table.match;
        if (!match.matchedAnyOf(const <String>['time', 'date'])) {
          throw importParsingFailure(
            '缺少开始时间或日期列，无法确定运动发生时间',
            code: 'keep_csv_no_time_column',
          );
        }

        final distanceIsMeters = _isMeterUnit(table, match, 'distance');
        final samples = <HealthSample>[];

        for (final row in table.dataRows) {
          builder.countRead();
          final timeTexts = timeCellTexts(match, row);
          final startedAt = combineDateTimeCells(timeTexts);
          final timeText = timeTexts.join(' ');
          if (startedAt == null) {
            builder.countSkipped('缺少或无法解析的开始时间');
            continue;
          }

          final sportType = match.cell(row, 'sportType');
          final name = sportType.isEmpty ? '运动' : sportType;
          final duration = parseDurationCell(match.cell(row, 'duration'));
          final endedAt = _resolveEnd(match, row, startedAt, duration);

          final rawDistance = parseDoubleCell(match.cell(row, 'distance'));
          final distanceKm = rawDistance == null
              ? null
              : (distanceIsMeters ? rawDistance / 1000.0 : rawDistance);
          final elevationGainM = parseDoubleCell(match.cell(row, 'elevation'));
          final avgHeartRate = parseIntCell(match.cell(row, 'avgHeartRate'));
          final maxHeartRate = parseIntCell(match.cell(row, 'maxHeartRate'));
          final calories = parseIntCell(match.cell(row, 'calories'));
          final note = match.cell(row, 'note');

          samples.add(HealthSample(
            source: id,
            externalId: buildExternalId(
              'keep',
              <Object?>[timeText, sportType, match.cell(row, 'duration')],
            ),
            kind: HealthSampleKind.workout,
            startAt: startedAt,
            endAt: endedAt,
            title: name,
            payload: <String, Object?>{
              'category': mapWorkoutCategoryKeyword(sportType).code,
              'name': name,
              if (distanceKm != null) 'distanceKm': distanceKm,
              if (elevationGainM != null) 'elevationGainM': elevationGainM,
              if (avgHeartRate != null) 'avgHeartRate': avgHeartRate,
              if (maxHeartRate != null) 'maxHeartRate': maxHeartRate,
              if (calories != null) 'calories': calories,
              if (note.isNotEmpty) 'note': note,
            },
          ));
          builder.countProduced();
        }

        if (samples.isEmpty) {
          throw importParsingFailure(
            '文件中没有可用的运动记录',
            code: 'keep_csv_empty',
          );
        }
        return samples;
      } finally {
        recordStats(builder.build());
      }
    });
  }

  /// 定位表头行。
  ///
  /// @param bytes 文件原始字节。
  /// @returns 定位结果；没有合格表头时返回 null。
  CsvTable? _locate(List<int> bytes) {
    final rows = parseCsvRows(decodeImportText(headBytes(bytes)));
    return CsvTable.tryLocate(rows, _columns);
  }

  /// 判断 [field] 列表头声明的长度单位是否为米。
  ///
  /// @param table 定位到的 CSV 表。
  /// @param match 表头匹配结果。
  /// @param field 逻辑字段名。
  /// @returns 单位为米（而非公里）时为 true。
  bool _isMeterUnit(CsvTable table, HeaderMatch match, String field) {
    final index = match[field];
    if (index == null) return false;
    final unit = table.header.unitAt(index);
    if (unit.isEmpty) return false;
    if (unit.contains('km') || unit.contains('公里') || unit.contains('千米')) {
      return false;
    }
    return unit.contains('m') || unit.contains('米');
  }

  /// 计算结束时间。
  ///
  /// 优先取结束时间列；否则用开始时间加时长；两者都缺时以开始时间作结束时间，
  /// 使样本仍是零时长而不是伪造一个时长。
  ///
  /// @param match 表头匹配结果。
  /// @param row 数据行。
  /// @param startedAt 开始时间。
  /// @param duration 时长，可为 null。
  /// @returns 结束时间。
  DateTime _resolveEnd(
    HeaderMatch match,
    List<String> row,
    DateTime startedAt,
    Duration? duration,
  ) {
    final explicitEnd = parseDateTimeCell(match.cell(row, 'endTime'));
    if (explicitEnd != null && explicitEnd.isAfter(startedAt)) {
      return explicitEnd;
    }
    if (duration != null && duration > Duration.zero) {
      return startedAt.add(duration);
    }
    return startedAt;
  }
}
