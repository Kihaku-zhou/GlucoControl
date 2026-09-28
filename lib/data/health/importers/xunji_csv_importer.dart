/// 训记导出的力量训练 CSV 导入器。
library;

import '../../../core/result.dart';
import '../../../domain/health/health_records.dart';
import '../../../domain/health/health_source.dart';
import 'import_utils.dart';

/// 解析训记导出的组次明细 CSV。
///
/// 同一自然日的所有组次汇总为一条 [HealthSampleKind.workout] 样本，容量按
/// `重量 × 次数 × 组数` 累加。行级脏数据跳过并计入 [lastStats]。
class XunjiCsvImporter extends HealthFileImporterBase {
  /// 构造导入器。
  XunjiCsvImporter();

  /// 表头识别用的逻辑字段。
  static const List<ImportColumn> _columns = <ImportColumn>[
    ImportColumn('time', <String>[
      '训练时间', '开始时间', '记录时间', '日期时间', '时间', '时刻', 'datetime',
      'timestamp', 'time',
    ]),
    ImportColumn('date', <String>['训练日期', '日期', 'date']),
    ImportColumn('exercise', <String>[
      '动作名称', '动作', '训练动作', '项目', 'exercise', 'movement', 'name',
    ]),
    ImportColumn('weight', <String>[
      '重量', '负重', '配重', '阻力', 'weight', 'load', 'kg',
    ]),
    ImportColumn('sets', <String>['组数', '组次', 'sets', 'set']),
    ImportColumn('reps', <String>['次数', '个数', '反复次数', 'reps', 'repetitions']),
    ImportColumn('volume', <String>['容量', '总容量', '训练容量', 'volume', 'tonnage']),
    ImportColumn('duration', <String>['时长', '训练时长', '用时', 'duration']),
    ImportColumn('note', <String>['备注', '说明', 'note', 'remark', 'comment']),
  ];

  /// [canHandle] 使用的判别字段：至少命中其中两个才认为是训记导出。
  static const List<String> _discriminatorFields = <String>[
    'exercise', 'weight', 'sets', 'reps',
  ];

  @override
  HealthSourceId get id => HealthSourceId.xunji;

  @override
  String get displayName => '训记 CSV';

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
    return runImport('xunji_csv', () {
      try {
        final table = _locate(bytes);
        if (table == null) {
          throw importParsingFailure(
            '未找到可识别的表头，请确认是训记导出的 CSV 文件',
            code: 'xunji_csv_no_header',
          );
        }
        if (!table.match.matchedAnyOf(const <String>['time', 'date'])) {
          throw importParsingFailure(
            '缺少日期或时间列，无法确定训练发生时间',
            code: 'xunji_csv_no_time_column',
          );
        }

        final groups = <DateTime, _DayGroup>{};
        for (final row in table.dataRows) {
          builder.countRead();
          final timeTexts = timeCellTexts(table.match, row);
          final time = combineDateTimeCells(timeTexts);
          if (time == null) {
            builder.countSkipped('缺少或无法解析的时间');
            continue;
          }

          final day = DateTime(time.year, time.month, time.day);
          final group = groups.putIfAbsent(day, () => _DayGroup(day));
          group.addRow(table.match, row, time);
        }

        if (groups.isEmpty) {
          throw importParsingFailure(
            '文件中没有可用的训练记录',
            code: 'xunji_csv_empty',
          );
        }

        final orderedDays = groups.keys.toList()
          ..sort((a, b) => a.compareTo(b));
        final samples = <HealthSample>[];
        for (final day in orderedDays) {
          final group = groups[day]!;
          samples.add(group.toSample(id, _dayKey(day)));
          builder.countProduced();
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

  /// 把日期折算为幂等键使用的稳定文本。
  ///
  /// @param day 当地零点。
  /// @returns `yyyy-MM-dd` 形式的文本。
  String _dayKey(DateTime day) {
    final month = day.month.toString().padLeft(2, '0');
    final date = day.day.toString().padLeft(2, '0');
    return '${day.year}-$month-$date';
  }
}

/// 同一训练日内累积的组次明细。
class _DayGroup {
  _DayGroup(this.day);

  /// 该组所属的自然日（当地零点）。
  final DateTime day;

  DateTime? _firstAt;
  DateTime? _lastAt;
  double _volumeKg = 0;
  int _sets = 0;
  int _reps = 0;
  Duration _duration = Duration.zero;
  bool _hasVolume = false;
  bool _hasReps = false;
  bool _hasDuration = false;
  final List<String> _exercises = <String>[];

  /// 累加一行数据。
  ///
  /// @param match 表头匹配结果。
  /// @param row 数据行。
  /// @param time 该行的发生时间。
  void addRow(HeaderMatch match, List<String> row, DateTime time) {
    if (_firstAt == null || time.isBefore(_firstAt!)) _firstAt = time;
    if (_lastAt == null || time.isAfter(_lastAt!)) _lastAt = time;

    final exercise = match.cell(row, 'exercise');
    if (exercise.isNotEmpty && !_exercises.contains(exercise)) {
      _exercises.add(exercise);
    }

    final setsValue = parseIntCell(match.cell(row, 'sets'));
    final sets = setsValue == null || setsValue <= 0 ? 1 : setsValue;
    final reps = parseIntCell(match.cell(row, 'reps'));
    final weight = parseDoubleCell(match.cell(row, 'weight'));

    _sets += sets;
    if (reps != null && reps > 0) {
      _reps += reps * sets;
      _hasReps = true;
      if (weight != null && weight > 0) {
        _volumeKg += weight * reps * sets;
        _hasVolume = true;
      }
    }

    final duration = parseDurationCell(match.cell(row, 'duration'));
    if (duration != null) {
      _duration += duration;
      _hasDuration = true;
    }
  }

  /// 汇总为归一化样本。
  ///
  /// @param source 数据来源标识。
  /// @param dayKey 幂等键使用的日期文本。
  /// @returns 当天的一条运动样本。
  HealthSample toSample(HealthSourceId source, String dayKey) {
    final startedAt = _firstAt ?? day;
    var endedAt = _lastAt ?? startedAt;
    if (!endedAt.isAfter(startedAt) && _hasDuration && _duration > Duration.zero) {
      endedAt = startedAt.add(_duration);
    }

    return HealthSample(
      source: source,
      externalId: buildExternalId('xunji', <Object?>[dayKey]),
      kind: HealthSampleKind.workout,
      startAt: startedAt,
      endAt: endedAt,
      title: _name,
      payload: <String, Object?>{
        'category': WorkoutCategory.strength.code,
        'name': _name,
        if (_hasVolume) 'totalVolumeKg': _volumeKg,
        if (_sets > 0) 'totalSets': _sets,
        if (_hasReps) 'totalReps': _reps,
        if (endedAt == startedAt) 'note': '原始文件未提供训练时长',
      },
    );
  }

  /// 展示名称：固定前缀 + 前三个动作名。
  String get _name {
    if (_exercises.isEmpty) return '力量训练';
    final head = _exercises.take(3).join(' / ');
    return '力量训练 · $head';
  }
}
