import '../../core/result.dart';
import '../../domain/health/health_data_source.dart';
import '../../domain/health/health_repository.dart';
import '../../domain/health/health_source.dart';

/// 单次单源同步的结果。
class HealthSyncReport {
  /// 构造同步结果。
  const HealthSyncReport({
    required this.source,
    required this.succeeded,
    this.fetched = 0,
    this.inserted = 0,
    this.updated = 0,
    this.warnings = const <String>[],
    this.error,
  });

  /// 被同步的数据源。
  final HealthSourceId source;

  /// 是否整体成功。部分数据类型失败但其余成功时仍为 true，细节见 [warnings]。
  final bool succeeded;

  /// 从上游取回的样本数。
  final int fetched;

  /// 新写入的样本数。
  final int inserted;

  /// 覆盖已有样本的数量。
  final int updated;

  /// 部分失败的说明。
  final List<String> warnings;

  /// 整体失败时的原因。
  final String? error;

  @override
  String toString() => 'HealthSyncReport(${source.code}: ok=$succeeded, '
      'fetched=$fetched, inserted=$inserted, updated=$updated)';
}

/// 一次文件导入的结果。
class HealthImportReport {
  /// 构造导入结果。
  const HealthImportReport({
    required this.fileName,
    required this.source,
    required this.succeeded,
    this.parsed = 0,
    this.inserted = 0,
    this.updated = 0,
    this.warnings = const <String>[],
    this.error,
  });

  /// 被导入的文件名。
  final String fileName;

  /// 导入器归属的数据源。
  final HealthSourceId source;

  /// 是否成功。
  final bool succeeded;

  /// 解析出的样本数。
  final int parsed;

  /// 新写入的样本数。
  final int inserted;

  /// 覆盖已有样本的数量。
  final int updated;

  /// 解析期的告警。
  final List<String> warnings;

  /// 失败原因。
  final String? error;

  @override
  String toString() => 'HealthImportReport($fileName: ok=$succeeded, '
      'parsed=$parsed, inserted=$inserted, updated=$updated)';
}

/// 外部健康数据的同步编排。
///
/// 职责边界：连接器只负责「取数并归一化」，本类负责「调度、幂等落库、记录状态」。
/// 把幂等交给统一的落库路径，意味着文件导入与在线同步共享同一套去重语义，
/// 重复导入同一个文件或重复同步同一天都不会产生重复记录。
class HealthSyncService {
  /// 构造同步服务。
  ///
  /// [sources] 按数据源索引可用连接器；未注册的数据源会被报告为「不支持」。
  /// [importers] 用于文件导入，顺序即优先级。
  HealthSyncService({
    required HealthRepository repository,
    required Map<HealthSourceId, HealthDataSource> sources,
    List<HealthFileImporter> importers = const <HealthFileImporter>[],
  })  : _repository = repository,
        _sources = sources,
        _importers = importers;

  final HealthRepository _repository;
  final Map<HealthSourceId, HealthDataSource> _sources;
  final List<HealthFileImporter> _importers;

  /// 同步单个数据源最近 [days] 天的数据。
  ///
  /// 无论成功与否都会把结果写回数据源状态，供界面展示「上次同步时间 / 上次错误」。
  Future<HealthSyncReport> syncSource(
    HealthSourceId source, {
    int days = 30,
  }) async {
    final dataSource = _sources[source];
    if (dataSource == null) {
      final reason = '${source.displayName}在当前平台没有可用的连接器';
      await _repository.recordSyncOutcome(
        source: source,
        succeeded: false,
        error: reason,
      );
      return HealthSyncReport(
        source: source,
        succeeded: false,
        error: reason,
      );
    }

    final availability = await dataSource.checkAvailability();
    final checked = availability.valueOrNull;
    if (!availability.isOk || checked == null || !checked.canFetch) {
      final reason = availability.failureOrNull?.message ??
          checked?.hint ??
          '${source.displayName}尚未完成授权';
      await _repository.recordSyncOutcome(
        source: source,
        succeeded: false,
        error: reason,
      );
      return HealthSyncReport(
        source: source,
        succeeded: false,
        error: reason,
      );
    }

    final window = HealthFetchWindow.lastDays(days);
    final fetched = await dataSource.fetch(window);
    if (!fetched.isOk) {
      final failure = fetched.failureOrNull!;
      await _repository.recordSyncOutcome(
        source: source,
        succeeded: false,
        error: failure.message,
      );
      return HealthSyncReport(
        source: source,
        succeeded: false,
        error: failure.message,
      );
    }

    final result = fetched.requireValue();
    final written = await _repository.upsertAll(result.samples);
    if (!written.isOk) {
      final failure = written.failureOrNull!;
      await _repository.recordSyncOutcome(
        source: source,
        succeeded: false,
        error: failure.message,
      );
      return HealthSyncReport(
        source: source,
        succeeded: false,
        fetched: result.samples.length,
        warnings: result.warnings,
        error: failure.message,
      );
    }

    final outcome = written.requireValue();
    await _repository.recordSyncOutcome(source: source, succeeded: true);
    await _repository.setSourceEnabled(source, true);

    return HealthSyncReport(
      source: source,
      succeeded: true,
      fetched: result.samples.length,
      inserted: outcome.inserted,
      updated: outcome.updated,
      warnings: result.warnings,
    );
  }

  /// 依次同步所有已注册的数据源。
  ///
  /// 串行而不是并行：多个连接器可能同时访问网络与数据库，串行能让限流类错误
  /// （例如训记的训练日限流）更容易定位到具体来源。
  Future<List<HealthSyncReport>> syncAll({int days = 30}) async {
    final reports = <HealthSyncReport>[];
    for (final source in _sources.keys) {
      reports.add(await syncSource(source, days: days));
    }
    return reports;
  }

  /// 解析并导入一个导出文件。
  ///
  /// 文件类型由 [HealthFileImporter.canHandle] 判定，调用方不需要预先知道来源。
  Future<Result<HealthImportReport>> importFile({
    required String fileName,
    required List<int> bytes,
  }) async {
    final importer = resolveImporter(fileName, bytes);
    if (importer == null) {
      return Err(AppFailure(
        kind: FailureKind.unsupported,
        message: '无法识别 $fileName 的格式，请确认它是所选应用导出的原始文件',
        code: 'health.import_unsupported',
      ));
    }

    final parsed = await importer.parse(fileName: fileName, bytes: bytes);
    if (!parsed.isOk) return Err(parsed.failureOrNull!);

    final samples = parsed.requireValue();
    final written = await _repository.upsertAll(samples);
    if (!written.isOk) return Err(written.failureOrNull!);

    final outcome = written.requireValue();
    return Ok(HealthImportReport(
      fileName: fileName,
      source: importer.id,
      succeeded: true,
      parsed: samples.length,
      inserted: outcome.inserted,
      updated: outcome.updated,
    ));
  }

  /// 选出能处理该文件的导入器；没有匹配时返回 null。
  HealthFileImporter? resolveImporter(String fileName, List<int> bytes) {
    for (final importer in _importers) {
      if (importer.canHandle(fileName, bytes)) return importer;
    }
    return null;
  }

  /// 当前可用的文件导入器，用于在设置页展示支持的导出格式。
  List<HealthFileImporter> get importers =>
      List<HealthFileImporter>.unmodifiable(_importers);
}
