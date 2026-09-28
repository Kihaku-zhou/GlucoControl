import '../../core/result.dart';
import '../../domain/health/health_repository.dart';
import '../../domain/health/health_source.dart';
import '../database/database.dart';
import '../database/health_samples_dao.dart';

/// 基于 drift DAO 的 [HealthRepository] 实现。
///
/// 本类只做「领域查询 ↔ 存储查询」的翻译与失败包装；所有 SQL 细节留在
/// [HealthSamplesDao] 中，使同步逻辑可以在没有数据库的情况下用假实现测试。
class HealthRepositoryImpl implements HealthRepository {
  /// 绑定到样本 DAO。
  const HealthRepositoryImpl(this._dao);

  final HealthSamplesDao _dao;

  @override
  Future<Result<HealthUpsertOutcome>> upsertAll(
          Iterable<HealthSample> samples) =>
      guardAsync(
        () => _dao.upsertAll(samples.toList()),
        code: 'health.upsert',
        message: '写入外部健康数据失败',
      );

  @override
  Future<Result<List<HealthSample>>> query(HealthQuery query) => guardAsync(
        () => _dao.queryBetween(
          start: query.start,
          end: query.end,
          kindCodes: query.kinds.map((kind) => kind.code).toSet(),
          sourceCodes: query.sources.map((source) => source.code).toSet(),
        ),
        code: 'health.query',
        message: '读取外部健康数据失败',
      );

  @override
  Future<Result<List<HealthSourceSyncState>>> syncStates() => guardAsync(
        () async {
          final states = await _dao.allSourceStates();
          final counts = <String, int>{
            for (final row in await _dao.sampleCountsBySource())
              row.sourceId: row.sampleCount,
          };
          final bySource = <String, HealthSourceState>{
            for (final state in states) state.sourceId: state,
          };

          return HealthSourceId.values.map((source) {
            final row = bySource[source.code];
            return HealthSourceSyncState(
              source: source,
              enabled: row?.enabled ?? false,
              lastSyncedAt: row?.lastSyncedAt,
              lastError: row?.lastError,
              sampleCount: counts[source.code] ?? 0,
            );
          }).toList();
        },
        code: 'health.sync_states',
        message: '读取数据源状态失败',
      );

  @override
  Future<Result<void>> recordSyncOutcome({
    required HealthSourceId source,
    required bool succeeded,
    String? error,
    DateTime? syncedAt,
  }) =>
      guardAsync(
        () => _dao.upsertSourceState(
          sourceId: source.code,
          enabled: succeeded ? true : null,
          lastSyncedAt: succeeded ? (syncedAt ?? DateTime.now()) : null,
          lastError: succeeded ? null : (error ?? '未知错误'),
          clearError: succeeded,
        ),
        code: 'health.record_sync',
        message: '记录同步状态失败',
      );

  @override
  Future<Result<void>> setSourceEnabled(HealthSourceId source, bool enabled) =>
      guardAsync(
        () => _dao.upsertSourceState(
          sourceId: source.code,
          enabled: enabled,
          clearError: !enabled,
        ),
        code: 'health.set_enabled',
        message: '更新数据源开关失败',
      );

  @override
  Future<Result<int>> purgeSource(HealthSourceId source) => guardAsync(
        () => _dao.deleteBySource(source.code),
        code: 'health.purge',
        message: '清理数据源数据失败',
      );
}
