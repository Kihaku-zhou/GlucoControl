import '../../core/result.dart';
import 'health_source.dart';

/// 一次历史查询的条件。
class HealthQuery {
  /// 构造查询条件。区间为左闭右开。
  const HealthQuery({
    required this.start,
    required this.end,
    this.kinds = const <HealthSampleKind>{},
    this.sources = const <HealthSourceId>{},
  });

  /// 覆盖最近 [days] 天的查询。
  factory HealthQuery.lastDays(
    int days, {
    Set<HealthSampleKind> kinds = const <HealthSampleKind>{},
    Set<HealthSourceId> sources = const <HealthSourceId>{},
  }) {
    final end = DateTime.now();
    return HealthQuery(
      start: end.subtract(Duration(days: days)),
      end: end,
      kinds: kinds,
      sources: sources,
    );
  }

  /// 起始时间（含）。
  final DateTime start;

  /// 结束时间（不含）。
  final DateTime end;

  /// 需要的样本类别；为空表示不限。
  final Set<HealthSampleKind> kinds;

  /// 需要的数据源；为空表示不限。
  final Set<HealthSourceId> sources;
}

/// 一个连接器的同步状态。
class HealthSourceSyncState {
  /// 构造同步状态。
  const HealthSourceSyncState({
    required this.source,
    required this.enabled,
    this.lastSyncedAt,
    this.lastError,
    this.sampleCount = 0,
  });

  /// 连接器标识。
  final HealthSourceId source;

  /// 用户是否启用了该连接器。
  final bool enabled;

  /// 最近一次成功同步的时间。
  final DateTime? lastSyncedAt;

  /// 最近一次失败的原因；成功后清空。
  final String? lastError;

  /// 该来源已入库的样本数。
  final int sampleCount;
}

/// 归一化外部健康样本的持久化与查询入口。
abstract interface class HealthRepository {
  /// 按 `(source, kind, externalId)` 幂等写入样本，返回新增与更新之外的净新增条数。
  Future<Result<HealthUpsertOutcome>> upsertAll(
      Iterable<HealthSample> samples);

  /// 按条件查询样本，按发生时间升序返回。
  Future<Result<List<HealthSample>>> query(HealthQuery query);

  /// 列出所有连接器及其同步状态。
  Future<Result<List<HealthSourceSyncState>>> syncStates();

  /// 记录一次同步尝试的结果，用于界面展示与增量同步决策。
  Future<Result<void>> recordSyncOutcome({
    required HealthSourceId source,
    required bool succeeded,
    String? error,
    DateTime? syncedAt,
  });

  /// 设置连接器启用状态。
  Future<Result<void>> setSourceEnabled(HealthSourceId source, bool enabled);

  /// 删除某个来源的全部样本，用于用户撤销授权后的数据清理。
  Future<Result<int>> purgeSource(HealthSourceId source);
}

/// 一次批量写入的结果。
class HealthUpsertOutcome {
  /// 构造写入结果。
  const HealthUpsertOutcome({required this.inserted, required this.updated});

  /// 新插入的样本数。
  final int inserted;

  /// 覆盖已有样本的数量。
  final int updated;

  /// 写入影响的样本总数。
  int get total => inserted + updated;

  @override
  String toString() => 'HealthUpsertOutcome(inserted: $inserted, updated: $updated)';
}
