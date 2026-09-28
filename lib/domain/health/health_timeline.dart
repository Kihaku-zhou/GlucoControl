import '../../core/glucose_units.dart';
import 'health_records.dart';
import 'health_source.dart';

/// 统一时间线上的记录类别。
///
/// 把「本应用录入的数据」与「各外部来源的数据」放进同一套类别，使 AI 工具
/// 与界面可以用一个列表完成跨来源的综合判断，而不是分别遍历若干张表。
enum HealthTimelineKind {
  /// 血糖读数。
  glucose('glucose'),

  /// 一次运动。
  workout('workout'),

  /// 一顿饭。
  meal('meal'),

  /// 一次体测。
  bodyComposition('body_composition'),

  /// 一段睡眠。
  sleep('sleep'),

  /// 单日活动汇总。
  dailyActivity('daily_activity');

  const HealthTimelineKind(this.code);

  /// 用于 AI 工具过滤参数的稳定编码。
  final String code;

  /// 从编码还原；未知编码返回 null。
  static HealthTimelineKind? tryFromCode(String? code) {
    for (final kind in values) {
      if (kind.code == code) return kind;
    }
    return null;
  }

  /// 由外部样本类别映射而来。
  static HealthTimelineKind fromSampleKind(HealthSampleKind kind) =>
      switch (kind) {
        HealthSampleKind.glucose => HealthTimelineKind.glucose,
        HealthSampleKind.workout => HealthTimelineKind.workout,
        HealthSampleKind.bodyComposition => HealthTimelineKind.bodyComposition,
        HealthSampleKind.sleep => HealthTimelineKind.sleep,
        HealthSampleKind.dailyActivity => HealthTimelineKind.dailyActivity,
      };
}

/// 时间线上的一条记录。
class HealthTimelineEntry {
  /// 构造时间线条目。
  const HealthTimelineEntry({
    required this.kind,
    required this.at,
    required this.sourceLabel,
    this.until,
    this.title,
    this.originApp,
    this.isLocal = false,
    this.metrics = const <String, Object?>{},
  });

  /// 记录类别。
  final HealthTimelineKind kind;

  /// 发生时间。
  final DateTime at;

  /// 结束时间；瞬时记录为 null。
  final DateTime? until;

  /// 数据来源的展示名（例如「华为运动健康」「本应用」）。
  final String sourceLabel;

  /// 数据最初由哪个应用产生；无此信息时为 null。
  final String? originApp;

  /// 是否由本应用直接录入。
  final bool isLocal;

  /// 人类可读的标题。
  final String? title;

  /// 结构化指标，键名与 [GlucoseReading.toSample] 等类型化模型使用的键名一致。
  final Map<String, Object?> metrics;

  /// 该记录的时长；瞬时记录返回 null。
  Duration? get duration => until?.difference(at);

  /// 转为便于喂给模型或写入日志的 JSON。
  Map<String, Object?> toJson() => <String, Object?>{
        'kind': kind.code,
        'at': at.toIso8601String(),
        if (until != null) 'until': until!.toIso8601String(),
        'source': sourceLabel,
        if (originApp != null) 'originApp': originApp,
        if (isLocal) 'local': true,
        if (title != null) 'title': title,
        if (metrics.isNotEmpty) 'metrics': metrics,
      };

  @override
  String toString() =>
      'HealthTimelineEntry(${kind.code} @${at.toIso8601String()} $title)';
}

/// 一段区间内的血糖统计。
class GlucoseSummary {
  /// 构造统计结果。
  const GlucoseSummary({
    required this.count,
    required this.meanMmolPerL,
    required this.minMmolPerL,
    required this.maxMmolPerL,
    required this.withinRangePercent,
    required this.belowRangePercent,
    required this.aboveRangePercent,
    required this.estimatedA1cPercent,
  });

  /// 参与统计的读数条数。
  final int count;

  /// 平均血糖（mmol/L）。
  final double meanMmolPerL;

  /// 最低血糖（mmol/L）。
  final double minMmolPerL;

  /// 最高血糖（mmol/L）。
  final double maxMmolPerL;

  /// 处于目标范围内的读数占比（百分比）。
  final double withinRangePercent;

  /// 低于目标范围的读数占比（百分比）。
  final double belowRangePercent;

  /// 高于目标范围的读数占比（百分比）。
  final double aboveRangePercent;

  /// 根据平均血糖推算的糖化血红蛋白（百分比）。
  ///
  /// 使用 ADAG 研究给出的线性关系 `eA1c(%) = (平均血糖[mg/dL] + 46.7) / 28.7`。
  /// 它是群体回归式，个体差异明显，只可作为趋势参考。
  final double estimatedA1cPercent;

  /// 转为便于喂给模型的 JSON。
  Map<String, Object?> toJson() => <String, Object?>{
        'count': count,
        'meanMmolPerL': double.parse(meanMmolPerL.toStringAsFixed(2)),
        'minMmolPerL': double.parse(minMmolPerL.toStringAsFixed(2)),
        'maxMmolPerL': double.parse(maxMmolPerL.toStringAsFixed(2)),
        'withinRangePercent': double.parse(withinRangePercent.toStringAsFixed(1)),
        'belowRangePercent': double.parse(belowRangePercent.toStringAsFixed(1)),
        'aboveRangePercent': double.parse(aboveRangePercent.toStringAsFixed(1)),
        'estimatedA1cPercent':
            double.parse(estimatedA1cPercent.toStringAsFixed(1)),
      };
}

/// 跨来源的统一健康时间线。
class HealthTimeline {
  /// 用已按时间排序的条目构造时间线。
  const HealthTimeline(this.entries);

  /// 按发生时间升序排列的条目。
  final List<HealthTimelineEntry> entries;

  /// 时间线覆盖的起止范围；为空时返回 null。
  ({DateTime start, DateTime end})? get span {
    if (entries.isEmpty) return null;
    return (start: entries.first.at, end: entries.last.at);
  }

  /// 取出指定类别的条目。
  List<HealthTimelineEntry> ofKind(HealthTimelineKind kind) =>
      entries.where((entry) => entry.kind == kind).toList();

  /// 取出发生在 [from, to] 内的条目（左闭右开）。
  List<HealthTimelineEntry> between(DateTime from, DateTime to) => entries
      .where((entry) => !entry.at.isBefore(from) && entry.at.isBefore(to))
      .toList();

  /// 找出与时间点 [moment] 相关的事件：在前 [lookBack] 内开始、或在后
  /// [lookAhead] 内开始的运动与饮食。
  ///
  /// 这是「血糖为什么升高」这类问题的核心查询：把升糖事件与可能的诱因
  /// 放在同一个时间窗里。
  List<HealthTimelineEntry> contextAround(
    DateTime moment, {
    Duration lookBack = const Duration(hours: 3),
    Duration lookAhead = const Duration(hours: 1),
  }) {
    final from = moment.subtract(lookBack);
    final to = moment.add(lookAhead);
    return entries.where((entry) {
      if (entry.kind != HealthTimelineKind.workout &&
          entry.kind != HealthTimelineKind.meal) {
        return false;
      }
      final overlaps = entry.until == null
          ? !entry.at.isBefore(from) && entry.at.isBefore(to)
          : entry.at.isBefore(to) && entry.until!.isAfter(from);
      return overlaps;
    }).toList();
  }

  /// 统计血糖读数；没有读数时返回 null（而不是 0，避免误报「全部达标」）。
  ///
  /// [targetMinMmolPerL] 与 [targetMaxMmolPerL] 为目标的血糖范围，
  /// 默认取中国 2 型糖尿病防治指南常用的 3.9–10.0 mmol/L。
  GlucoseSummary? glucoseSummary({
    double targetMinMmolPerL = 3.9,
    double targetMaxMmolPerL = 10.0,
  }) {
    final values = <double>[];
    for (final entry in entries) {
      if (entry.kind != HealthTimelineKind.glucose) continue;
      final value = entry.metrics['mmolPerL'];
      if (value is num) values.add(value.toDouble());
    }
    if (values.isEmpty) return null;

    final total = values.length;
    final sum = values.reduce((a, b) => a + b);
    final mean = sum / total;
    var below = 0;
    var above = 0;
    for (final value in values) {
      if (value < targetMinMmolPerL) below++;
      if (value > targetMaxMmolPerL) above++;
    }

    final meanMgDl = mmolPerLTo(mean, GlucoseUnit.mgPerDl);
    return GlucoseSummary(
      count: total,
      meanMmolPerL: mean,
      minMmolPerL: values.reduce((a, b) => a < b ? a : b),
      maxMmolPerL: values.reduce((a, b) => a > b ? a : b),
      withinRangePercent: (total - below - above) / total * 100,
      belowRangePercent: below / total * 100,
      aboveRangePercent: above / total * 100,
      estimatedA1cPercent: (meanMgDl + 46.7) / 28.7,
    );
  }

  /// 把时间线压缩为固定条数以内的 JSON，控制模型上下文的体积。
  ///
  /// 超出 [maxEntries] 时保留**每条类别各自最新的若干条**，而不是简单截断，
  /// 因为截断尾部会让最近的血糖读数缺失。
  List<Map<String, Object?>> toJson({int maxEntries = 200}) {
    if (entries.length <= maxEntries) {
      return entries.map((entry) => entry.toJson()).toList();
    }
    final perKind = <HealthTimelineKind, List<HealthTimelineEntry>>{};
    for (final entry in entries) {
      perKind.putIfAbsent(entry.kind, () => <HealthTimelineEntry>[]).add(entry);
    }
    final quota = (maxEntries / perKind.length).floor().clamp(1, maxEntries);
    final kept = <HealthTimelineEntry>[];
    for (final bucket in perKind.values) {
      kept.addAll(bucket.length <= quota
          ? bucket
          : bucket.sublist(bucket.length - quota));
    }
    kept.sort((a, b) => a.at.compareTo(b.at));
    return kept.map((entry) => entry.toJson()).toList();
  }
}

/// 把外部归一化样本转换为时间线条目。
///
/// 只依赖领域类型，因此可以在没有数据库与网络的条件下单元测试。
HealthTimelineEntry timelineEntryFromSample(HealthSample sample) {
  final kind = HealthTimelineKind.fromSampleKind(sample.kind);
  return HealthTimelineEntry(
    kind: kind,
    at: sample.startAt,
    until: sample.endAt,
    sourceLabel: sample.source.displayName,
    originApp: sample.originApp,
    title: sample.title,
    metrics: sample.payload,
  );
}

/// 把外部类型化记录转换为时间线条目。
HealthTimelineEntry timelineEntryFromRecord(HealthRecord record) {
  final sample = record.toSample();
  return timelineEntryFromSample(sample);
}
