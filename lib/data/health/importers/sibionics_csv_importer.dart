/// 硅基轻享（硅基仿生 CGM）导出 CSV 的导入器。
library;

import '../../../core/glucose_units.dart';
import '../../../core/result.dart';
import '../../../domain/health/health_records.dart';
import '../../../domain/health/health_source.dart';
import 'import_utils.dart';

/// 解析硅基轻享 App 导出的动态血糖 CSV。
///
/// 一条数据行对应一条 [HealthSampleKind.glucose] 样本；缺时间或缺血糖值的行
/// 计入 [lastStats] 后跳过，不使整份文件失败。
class SibionicsCsvImporter extends HealthFileImporterBase {
  /// 构造导入器。
  SibionicsCsvImporter();

  /// 表头识别用的逻辑字段。
  ///
  /// `date` 与 `time` 分开声明，用于兼容部分导出把日期、时刻拆成两列的情况；
  /// [HeaderMatch] 的精确匹配保证 `记录时间` 落到 `time`、`日期` 落到 `date`。
  static const List<ImportColumn> _columns = <ImportColumn>[
    ImportColumn('time', <String>[
      '记录时间', '测量时间', '检测时间', '发生时间', '日期时间', '时间', '时刻',
      'datetime', 'timestamp', 'recordtime', 'time',
    ]),
    ImportColumn('date', <String>['日期', '测量日期', '记录日期', 'date']),
    ImportColumn('glucose', <String>[
      '血糖值', '血糖', '葡萄糖值', '葡萄糖', '传感器葡萄糖', 'glucose',
      'glucosevalue', 'sensorglucose', 'cgm', 'mmolL', 'mmol/L', 'mg/dL',
    ]),
    ImportColumn('trend', <String>['趋势', '变化趋势', '趋势箭头', 'trend', 'arrow']),
    ImportColumn('context', <String>[
      '事件类型', '事件', '标记', '时段', '餐别', 'context', 'event', 'eventtype',
      'meal',
    ]),
    ImportColumn('note', <String>['备注', '说明', 'note', 'remark', 'comment']),
  ];

  /// 血糖合理区间下限（mmol/L），低于视为无效读数。
  static const double _minPlausibleMmolPerL = 0.5;

  /// 血糖合理区间上限（mmol/L），高于视为误读或单位不符。
  static const double _maxPlausibleMmolPerL = 60.0;

  @override
  HealthSourceId get id => HealthSourceId.sibionics;

  @override
  String get displayName => '硅基轻享 CSV';

  @override
  List<String> get fileExtensions => const <String>['csv'];

  @override
  bool canHandle(String fileName, List<int> bytes) {
    if (!hasFileExtension(fileName, fileExtensions)) return false;
    final table = _locate(bytes);
    return table != null && _isSibionicsHeader(table.match);
  }

  /// 判断表头是否具备硅基轻享导出的特征。
  ///
  /// 必须命中血糖列（唯一的判别列），且至少命中两个逻辑字段。
  ///
  /// @param match 表头匹配结果。
  /// @returns 具备该导出格式特征时为 true。
  bool _isSibionicsHeader(HeaderMatch match) =>
      match.matchedAllOf(const <String>['glucose']) && match.matchedCount >= 2;

  @override
  Future<Result<List<HealthSample>>> parse({
    required String fileName,
    required List<int> bytes,
  }) {
    final builder = ImportStatsBuilder();
    return runImport('sibionics_csv', () {
      try {
        final table = _locate(bytes);
        if (table == null || !_isSibionicsHeader(table.match)) {
          throw importParsingFailure(
            '未找到可识别的表头，请确认是硅基轻享导出的 CSV 文件',
            code: 'sibionics_csv_no_header',
          );
        }
        final match = table.match;
        final glucoseIndex = match['glucose']!;
        final useMgPerDl = table.header.unitAt(glucoseIndex).contains('mg');

        final samples = <HealthSample>[];
        for (final row in table.dataRows) {
          builder.countRead();
          final timeTexts = timeCellTexts(match, row);
          final time = combineDateTimeCells(timeTexts);
          final timeText = timeTexts.join(' ');
          if (time == null) {
            builder.countSkipped('缺少或无法解析的时间');
            continue;
          }

          final rawGlucose = match.cell(row, 'glucose');
          final rawValue = parseDoubleCell(rawGlucose);
          if (rawValue == null) {
            builder.countSkipped('缺少或无法解析的血糖值');
            continue;
          }

          final mmolPerL = useMgPerDl
              ? toMmolPerL(rawValue, GlucoseUnit.mgPerDl)
              : rawValue;
          if (mmolPerL < _minPlausibleMmolPerL ||
              mmolPerL > _maxPlausibleMmolPerL) {
            builder.countSkipped('血糖值超出合理范围');
            continue;
          }

          final trendText = match.cell(row, 'trend');
          final contextText = match.cell(row, 'context');
          final note = match.cell(row, 'note');
          final context = _mapContext(contextText);
          final trend = _mapTrend(trendText);

          samples.add(HealthSample(
            source: id,
            externalId: buildExternalId(
              'sibionics',
              <Object?>[timeText, rawGlucose],
            ),
            kind: HealthSampleKind.glucose,
            startAt: time,
            title: '${context.label}血糖',
            payload: <String, Object?>{
              'mmolPerL': mmolPerL,
              'context': context.code,
              if (trend != null) 'trend': trend.code,
              if (note.isNotEmpty) 'note': note,
            },
          ));
          builder.countProduced();
        }

        if (samples.isEmpty) {
          throw importParsingFailure(
            '文件中没有可用的血糖记录',
            code: 'sibionics_csv_empty',
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

  /// 把导出的趋势列折算为 [GlucoseTrend]。
  ///
  /// @param raw 趋势列原值，可能是箭头、中文描述或英文描述。
  /// @returns 归一化趋势；无法识别时返回 null。
  GlucoseTrend? _mapTrend(String raw) {
    final key = _key(raw);
    if (key.isEmpty) return null;
    if (_containsAny(key, const <String>[
      '↑↑', '⇈', '⤊', '快速上升', '急速上升', 'risingfast', 'doubleup',
    ])) {
      return GlucoseTrend.risingFast;
    }
    if (_containsAny(key, const <String>[
      '↓↓', '⇊', '⤋', '快速下降', '急速下降', 'fallingfast', 'doubledown',
    ])) {
      return GlucoseTrend.fallingFast;
    }
    if (_containsAny(key, const <String>[
      '↑', '↗', '⇗', '⤴', '上升', 'rising', 'up',
    ])) {
      return GlucoseTrend.rising;
    }
    if (_containsAny(key, const <String>[
      '↓', '↘', '⇘', '⤵', '下降', 'falling', 'down',
    ])) {
      return GlucoseTrend.falling;
    }
    if (_containsAny(key, const <String>[
      '→', '⇨', '⤍', '平稳', '稳定', 'steady', 'flat',
    ])) {
      return GlucoseTrend.steady;
    }
    return null;
  }

  /// 把导出的事件/时段列折算为 [GlucoseContext]。
  ///
  /// CGM 自动采样没有明确采血时机，因此未识别或为空时回落到
  /// [GlucoseContext.continuous]。
  ///
  /// @param raw 事件/时段列原值。
  /// @returns 归一化采血时机。
  GlucoseContext _mapContext(String raw) {
    final key = _key(raw);
    if (_containsAny(key, const <String>[
      '空腹', '餐前', '饭前', 'fasting', 'beforemeal',
    ])) {
      return GlucoseContext.fasting;
    }
    if (_containsAny(key, const <String>[
      '餐后', '饭后', 'postmeal', 'aftermeal',
    ])) {
      return GlucoseContext.postMeal;
    }
    if (_containsAny(key, const <String>[
      '动态', '自动', 'continuous', 'cgm',
    ])) {
      return GlucoseContext.continuous;
    }
    if (_containsAny(key, const <String>['随机', 'random'])) {
      return GlucoseContext.random;
    }
    return GlucoseContext.continuous;
  }

  /// 归一化用于关键字比对的文本。
  ///
  /// @param raw 原始文本。
  /// @returns 半角小写且去空白的文本。
  String _key(String raw) =>
      toHalfWidth(raw).toLowerCase().replaceAll(RegExp(r'\s+'), '');

  /// 判断 [key] 是否包含 [candidates] 中任一子串。
  ///
  /// @param key 已归一化的文本。
  /// @param candidates 候选子串。
  /// @returns 命中任一子串时为 true。
  bool _containsAny(String key, List<String> candidates) =>
      candidates.any(key.contains);
}
