import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/health/health_repository.dart';
import '../../domain/health/health_source.dart';
import 'database.dart';

part 'health_samples_dao.g.dart';

/// 外部健康样本的持久化访问对象。
///
/// 只负责「样本信封 ↔ 数据行」的转换与幂等写入，不解释 [HealthSample.payload]
/// 的领域含义；那由 `lib/data/health/` 下的仓库实现按类别解码。
@DriftAccessor(tables: [ExternalHealthSamples, HealthSourceStates])
class HealthSamplesDao extends DatabaseAccessor<AppDatabase>
    with _$HealthSamplesDaoMixin {
  /// 绑定到宿主数据库。
  HealthSamplesDao(super.db);

  /// SQLite 单条语句的绑定参数上限保护值。
  ///
  /// 旧版 SQLite 的 `SQLITE_MAX_VARIABLE_NUMBER` 为 999，这里留出余量。
  static const int _maxVariablesPerStatement = 400;

  /// 按 `(sourceId, kind, externalId)` 幂等写入 [samples]。
  ///
  /// 已存在的键会被覆盖（同一记录被上游修正时以最新为准），并计入
  /// [HealthUpsertOutcome.updated]。
  Future<HealthUpsertOutcome> upsertAll(List<HealthSample> samples) async {
    if (samples.isEmpty) {
      return const HealthUpsertOutcome(inserted: 0, updated: 0);
    }

    final existing = await _existingKeys(samples);
    var inserted = 0;
    var updated = 0;

    await transaction(() async {
      await batch((b) {
        for (final sample in samples) {
          final companion = _toCompanion(sample);
          b.insert(
            externalHealthSamples,
            companion,
            onConflict: DoUpdate(
              (_) => companion,
              target: [
                externalHealthSamples.sourceId,
                externalHealthSamples.kind,
                externalHealthSamples.externalId,
              ],
            ),
          );
        }
      });
    });

    for (final sample in samples) {
      if (existing.contains(_keyOf(sample))) {
        updated++;
      } else {
        inserted++;
      }
    }

    return HealthUpsertOutcome(inserted: inserted, updated: updated);
  }

  /// 查询 [start, end) 内、类别与来源命中的样本，按发生时间升序。
  Future<List<HealthSample>> queryBetween({
    required DateTime start,
    required DateTime end,
    Set<String> kindCodes = const <String>{},
    Set<String> sourceCodes = const <String>{},
  }) async {
    final statement = select(externalHealthSamples)
      ..where((t) => t.startAt.isBiggerOrEqualValue(start))
      ..where((t) => t.startAt.isSmallerThanValue(end))
      ..orderBy([(t) => OrderingTerm.asc(t.startAt)]);

    if (kindCodes.isNotEmpty) {
      statement.where((t) => t.kind.isIn(kindCodes));
    }
    if (sourceCodes.isNotEmpty) {
      statement.where((t) => t.sourceId.isIn(sourceCodes));
    }

    final rows = await statement.get();
    return rows.map(_fromRow).toList();
  }

  /// 列出所有已有记录的来源与样本数。
  Future<List<({String sourceId, int sampleCount})>> sampleCountsBySource() async {
    final count = externalHealthSamples.id.count();
    final query = selectOnly(externalHealthSamples)
      ..addColumns([externalHealthSamples.sourceId, count])
      ..groupBy([externalHealthSamples.sourceId]);

    final rows = await query.get();
    return rows
        .map((row) => (
              sourceId: row.read(externalHealthSamples.sourceId)!,
              sampleCount: row.read(count) ?? 0,
            ))
        .toList();
  }

  /// 读取全部连接器状态行。
  Future<List<HealthSourceState>> allSourceStates() =>
      select(healthSourceStates).get();

  /// 写入或更新一个连接器的状态。
  Future<void> upsertSourceState({
    required String sourceId,
    bool? enabled,
    DateTime? lastSyncedAt,
    String? lastError,
    bool clearError = false,
  }) async {
    final companion = HealthSourceStatesCompanion(
      sourceId: Value(sourceId),
      enabled: enabled == null ? const Value.absent() : Value(enabled),
      lastSyncedAt: lastSyncedAt == null
          ? const Value.absent()
          : Value(lastSyncedAt),
      lastError: clearError
          ? const Value(null)
          : (lastError == null ? const Value.absent() : Value(lastError)),
    );
    await into(healthSourceStates).insertOnConflictUpdate(companion);
  }

  /// 删除某个来源的全部样本，返回删除行数。
  Future<int> deleteBySource(String sourceCode) =>
      (delete(externalHealthSamples)
            ..where((t) => t.sourceId.equals(sourceCode)))
          .go();

  /// 读取已存在的键，用于区分新增与覆盖。
  Future<Set<String>> _existingKeys(List<HealthSample> samples) async {
    final result = <String>{};
    final grouped = <String, Set<String>>{};

    for (final sample in samples) {
      final bucket = grouped.putIfAbsent(sample.source.code, () => <String>{});
      bucket.add(sample.externalId);
    }

    for (final entry in grouped.entries) {
      final ids = entry.value.toList();
      for (var offset = 0;
          offset < ids.length;
          offset += _maxVariablesPerStatement) {
        final chunk = ids.sublist(
          offset,
          (offset + _maxVariablesPerStatement).clamp(0, ids.length),
        );
        final rows = await (selectOnly(externalHealthSamples)
              ..addColumns([
                externalHealthSamples.kind,
                externalHealthSamples.externalId,
              ])
              ..where(externalHealthSamples.sourceId.equals(entry.key))
              ..where(externalHealthSamples.externalId.isIn(chunk)))
            .get();
        for (final row in rows) {
          final kind = row.read(externalHealthSamples.kind);
          final externalId = row.read(externalHealthSamples.externalId);
          if (kind != null && externalId != null) {
            result.add(_keyOfParts(entry.key, kind, externalId));
          }
        }
      }
    }

    return result;
  }

  /// 生成幂等键。
  static String _keyOf(HealthSample sample) =>
      _keyOfParts(sample.source.code, sample.kind.code, sample.externalId);

  /// 生成幂等键。分隔符取不可打印字符，避免与业务字段冲突。
  static String _keyOfParts(String sourceId, String kind, String externalId) =>
      '$sourceId\u0000$kind\u0000$externalId';

  /// 领域样本 → 数据行。
  static ExternalHealthSamplesCompanion _toCompanion(HealthSample sample) =>
      ExternalHealthSamplesCompanion(
        sourceId: Value(sample.source.code),
        kind: Value(sample.kind.code),
        externalId: Value(sample.externalId),
        startAt: Value(sample.startAt),
        endAt: Value(sample.endAt),
        title: Value(sample.title),
        originApp: Value(sample.originApp),
        payloadJson: Value(jsonEncode(sample.payload)),
        ingestedAt: Value(DateTime.now()),
      );

  /// 数据行 → 领域样本。未知的来源或类别编码会被跳过（由调用方过滤）。
  static HealthSample _fromRow(ExternalHealthSample row) {
    final source = HealthSourceId.tryFromCode(row.sourceId);
    final kind = HealthSampleKind.tryFromCode(row.kind);
    if (source == null || kind == null) {
      throw StateError(
          '数据库中存有未知的来源或类别编码：${row.sourceId}/${row.kind}');
    }
    return HealthSample(
      source: source,
      kind: kind,
      externalId: row.externalId,
      startAt: row.startAt,
      endAt: row.endAt,
      title: row.title,
      originApp: row.originApp,
      payload: _decodePayload(row.payloadJson),
    );
  }

  /// 解析载荷 JSON；内容损坏时返回空表，避免单行脏数据拖垮整次查询。
  static Map<String, Object?> _decodePayload(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } on FormatException {
      // payloadJson 由本 DAO 写入，唯一可能的来源是手工改库或磁盘损坏。
      return const <String, Object?>{};
    }
    return const <String, Object?>{};
  }
}
