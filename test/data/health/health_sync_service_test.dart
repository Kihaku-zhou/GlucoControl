/// `HealthSyncService` 的单元测试。
///
/// 用自己写的假 [HealthRepository]、假 [HealthDataSource] 与假
/// [HealthFileImporter] 覆盖同步编排的四条失败路径与成功路径、状态写回、
/// 文件导入的导入器选择，以及 `FailureKind.unsupported` 的降级。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:glucocontrol/core/result.dart';
import 'package:glucocontrol/data/health/health_sync_service.dart';
import 'package:glucocontrol/domain/health/health_data_source.dart';
import 'package:glucocontrol/domain/health/health_repository.dart';
import 'package:glucocontrol/domain/health/health_source.dart';

/// 记录调用并向调用方回放预设结果的假仓库。
class _FakeRepository implements HealthRepository {
  _FakeRepository({
    this.upsertResult =
        const Ok<HealthUpsertOutcome>(HealthUpsertOutcome(inserted: 0, updated: 0)),
  });

  Result<HealthUpsertOutcome> upsertResult;
  Result<List<HealthSample>> queryResult = const Ok<List<HealthSample>>(
      <HealthSample>[]);
  Result<List<HealthSourceSyncState>> syncStatesResult =
      const Ok<List<HealthSourceSyncState>>(<HealthSourceSyncState>[]);
  Result<void> recordResult = const Ok<void>(null);
  Result<void> setEnabledResult = const Ok<void>(null);
  Result<int> purgeResult = const Ok<int>(0);

  final List<List<HealthSample>> upsertCalls = <List<HealthSample>>[];
  final List<HealthQuery> queryCalls = <HealthQuery>[];
  final List<_SyncOutcomeCall> outcomeCalls = <_SyncOutcomeCall>[];
  final List<({HealthSourceId source, bool enabled})> setEnabledCalls =
      <({HealthSourceId source, bool enabled})>[];
  final List<HealthSourceId> purgeCalls = <HealthSourceId>[];

  @override
  Future<Result<HealthUpsertOutcome>> upsertAll(
      Iterable<HealthSample> samples) async {
    upsertCalls.add(samples.toList());
    return upsertResult;
  }

  @override
  Future<Result<List<HealthSample>>> query(HealthQuery query) async {
    queryCalls.add(query);
    return queryResult;
  }

  @override
  Future<Result<List<HealthSourceSyncState>>> syncStates() async =>
      syncStatesResult;

  @override
  Future<Result<void>> recordSyncOutcome({
    required HealthSourceId source,
    required bool succeeded,
    String? error,
    DateTime? syncedAt,
  }) async {
    outcomeCalls.add(_SyncOutcomeCall(source, succeeded, error, syncedAt));
    return recordResult;
  }

  @override
  Future<Result<void>> setSourceEnabled(
      HealthSourceId source, bool enabled) async {
    setEnabledCalls.add((source: source, enabled: enabled));
    return setEnabledResult;
  }

  @override
  Future<Result<int>> purgeSource(HealthSourceId source) async {
    purgeCalls.add(source);
    return purgeResult;
  }
}

class _SyncOutcomeCall {
  _SyncOutcomeCall(this.source, this.succeeded, this.error, this.syncedAt);

  final HealthSourceId source;
  final bool succeeded;
  final String? error;
  final DateTime? syncedAt;
}

/// 记录调用并回放预设结果的假连接器。
class _FakeSource implements HealthDataSource {
  _FakeSource({
    required this.id,
    this.availability =
        const Ok<HealthSourceAvailability>(HealthSourceAvailability.ready()),
    this.fetchResult =
        const Ok<HealthFetchResult>(HealthFetchResult(samples: <HealthSample>[])),
  });

  @override
  final HealthSourceId id;

  @override
  bool supportsAutomaticSync = true;

  Result<HealthSourceAvailability> availability;
  Result<HealthSourceAvailability>? authorizeResult;
  Result<HealthFetchResult> fetchResult;

  int availabilityCalls = 0;
  int authorizeCalls = 0;
  int fetchCalls = 0;
  HealthFetchWindow? lastWindow;

  @override
  Future<Result<HealthSourceAvailability>> checkAvailability() async {
    availabilityCalls++;
    return availability;
  }

  @override
  Future<Result<HealthSourceAvailability>> authorize() async {
    authorizeCalls++;
    return authorizeResult ?? availability;
  }

  @override
  Future<Result<HealthFetchResult>> fetch(HealthFetchWindow window) async {
    fetchCalls++;
    lastWindow = window;
    return fetchResult;
  }
}

/// 记录调用并回放预设解析结果的假导入器。
class _FakeImporter implements HealthFileImporter {
  _FakeImporter({
    required this.id,
    required this.displayName,
    this.handleSuffix = '.csv',
    this.parseResult =
        const Ok<List<HealthSample>>(<HealthSample>[]),
  });

  @override
  final HealthSourceId id;

  @override
  final String displayName;

  @override
  List<String> fileExtensions = const <String>['csv'];

  final String? handleSuffix;

  Result<List<HealthSample>> parseResult;

  final List<String> handledFiles = <String>[];
  int parseCalls = 0;

  @override
  bool canHandle(String fileName, List<int> bytes) {
    handledFiles.add(fileName);
    if (handleSuffix == null) return false;
    return fileName.toLowerCase().endsWith(handleSuffix!);
  }

  @override
  Future<Result<List<HealthSample>>> parse({
    required String fileName,
    required List<int> bytes,
  }) async {
    parseCalls++;
    return parseResult;
  }
}

HealthSample _sample(String externalId) => HealthSample(
      source: HealthSourceId.nightscout,
      externalId: externalId,
      kind: HealthSampleKind.glucose,
      startAt: DateTime(2026, 3, 14, 8),
      payload: const <String, Object?>{'mmolPerL': 5.6},
    );

void main() {
  group('syncSource 的连接器缺失与可用性', () {
    test('未注册连接器时失败并给出可读原因', () async {
      final repository = _FakeRepository();
      final service = HealthSyncService(
        repository: repository,
        sources: const <HealthSourceId, HealthDataSource>{},
      );

      final report = await service.syncSource(HealthSourceId.huaweiHealth);

      expect(report.succeeded, isFalse);
      expect(report.source, HealthSourceId.huaweiHealth);
      expect(report.error, '华为运动健康在当前平台没有可用的连接器');
      expect(report.fetched, 0);
      expect(report.inserted, 0);
      expect(report.updated, 0);
      expect(report.warnings, isEmpty);
      // 「未注册」也属于失败，必须写回状态，否则界面无法展示上次错误。
      expect(repository.outcomeCalls.length, 1);
      expect(repository.outcomeCalls.single.succeeded, isFalse);
      expect(repository.outcomeCalls.single.error, report.error);
    });

    test('不可取数时不发起 fetch，并把原因写回状态', () async {
      final repository = _FakeRepository();
      final source = _FakeSource(
        id: HealthSourceId.healthConnect,
        availability: const Ok<HealthSourceAvailability>(
          HealthSourceAvailability.needsAuthorization('需要授权读取血糖数据'),
        ),
      );
      final service = HealthSyncService(
        repository: repository,
        sources: <HealthSourceId, HealthDataSource>{source.id: source},
      );

      final report = await service.syncSource(source.id);

      expect(report.succeeded, isFalse);
      expect(report.error, '需要授权读取血糖数据');
      expect(source.availabilityCalls, 1);
      expect(source.fetchCalls, 0);
      expect(repository.upsertCalls, isEmpty);
      expect(repository.outcomeCalls.single.source, source.id);
      expect(repository.outcomeCalls.single.succeeded, isFalse);
      expect(repository.outcomeCalls.single.error, '需要授权读取血糖数据');
    });

    test('不可取数且没有 hint 时给出通用授权提示', () async {
      final repository = _FakeRepository();
      final source = _FakeSource(
        id: HealthSourceId.sibionics,
        availability: const Ok<HealthSourceAvailability>(
          HealthSourceAvailability.unavailable(null),
        ),
      );
      final service = HealthSyncService(
        repository: repository,
        sources: <HealthSourceId, HealthDataSource>{source.id: source},
      );

      final report = await service.syncSource(source.id);

      expect(report.error, '硅基轻享尚未完成授权');
      expect(source.fetchCalls, 0);
      expect(repository.outcomeCalls.single.error, '硅基轻享尚未完成授权');
    });

    test('可用性探测本身失败时传播失败消息', () async {
      final repository = _FakeRepository();
      final source = _FakeSource(
        id: HealthSourceId.healthConnect,
        availability: const Err<HealthSourceAvailability>(AppFailure(
          kind: FailureKind.unknown,
          message: '探测 Health Connect 失败：平台通道不可用',
          code: 'health_connect.probe_failed',
        )),
      );
      final service = HealthSyncService(
        repository: repository,
        sources: <HealthSourceId, HealthDataSource>{source.id: source},
      );

      final report = await service.syncSource(source.id);

      expect(report.succeeded, isFalse);
      expect(report.error, contains('平台通道不可用'));
      expect(source.fetchCalls, 0);
      expect(repository.outcomeCalls.single.error, contains('平台通道不可用'));
    });
  });

  group('syncSource 的取数与落库', () {
    late _FakeRepository repository;
    late _FakeSource source;
    late HealthSyncService service;

    setUp(() {
      repository = _FakeRepository(
        upsertResult: const Ok<HealthUpsertOutcome>(
          HealthUpsertOutcome(inserted: 7, updated: 3),
        ),
      );
      source = _FakeSource(
        id: HealthSourceId.nightscout,
        fetchResult: Ok<HealthFetchResult>(HealthFetchResult(
          samples: <HealthSample>[_sample('a'), _sample('b')],
          warnings: const <String>['有 1 条条目缺少血糖值，已跳过'],
        )),
      );
      service = HealthSyncService(
        repository: repository,
        sources: <HealthSourceId, HealthDataSource>{source.id: source},
      );
    });

    test('成功路径汇总 fetched/inserted/updated 与告警', () async {
      final report = await service.syncSource(source.id);

      expect(report.succeeded, isTrue);
      expect(report.source, HealthSourceId.nightscout);
      expect(report.fetched, 2);
      expect(report.inserted, 7);
      expect(report.updated, 3);
      expect(report.warnings, <String>['有 1 条条目缺少血糖值，已跳过']);
      expect(report.error, isNull);
      expect(report.toString(), contains('ok=true'));
    });

    test('成功路径把取回样本交给 upsertAll 并标记来源为启用', () async {
      await service.syncSource(source.id);

      expect(repository.upsertCalls.single.length, 2);
      expect(
        repository.upsertCalls.single.map((sample) => sample.externalId).toList(),
        <String>['a', 'b'],
      );
      expect(repository.outcomeCalls.single.succeeded, isTrue);
      expect(repository.outcomeCalls.single.error, isNull);
      expect(repository.setEnabledCalls,
          <({HealthSourceId source, bool enabled})>[
        (source: HealthSourceId.nightscout, enabled: true),
      ]);
    });

    test('取数窗口按 days 参数生成', () async {
      await service.syncSource(source.id, days: 7);

      final window = source.lastWindow!;
      expect(window.days, 7);
      expect(window.end.difference(window.start), const Duration(days: 7));
      expect(window.end.isAfter(DateTime.now().subtract(const Duration(seconds: 5))),
          isTrue);
    });

    test('默认窗口为最近 30 天', () async {
      await service.syncSource(source.id);

      expect(source.lastWindow!.days, 30);
    });

    test('取数失败时传播错误且不落库', () async {
      source.fetchResult = const Err<HealthFetchResult>(AppFailure(
        kind: FailureKind.authentication,
        message: 'Nightscout 拒绝了鉴权，请检查 API secret 或 token',
        code: 'nightscout.unauthorized',
      ));

      final report = await service.syncSource(source.id);

      expect(report.succeeded, isFalse);
      expect(report.error, 'Nightscout 拒绝了鉴权，请检查 API secret 或 token');
      expect(report.fetched, 0);
      expect(repository.upsertCalls, isEmpty);
      expect(repository.setEnabledCalls, isEmpty);
      expect(repository.outcomeCalls.single.succeeded, isFalse);
      expect(repository.outcomeCalls.single.error, contains('拒绝了鉴权'));
    });

    test('落库失败时保留 fetched 并传播错误', () async {
      repository.upsertResult = const Err<HealthUpsertOutcome>(AppFailure(
        kind: FailureKind.storage,
        message: '本地数据库写入失败',
        code: 'db.write',
      ));

      final report = await service.syncSource(source.id);

      expect(report.succeeded, isFalse);
      expect(report.fetched, 2);
      expect(report.inserted, 0);
      expect(report.updated, 0);
      expect(report.error, '本地数据库写入失败');
      expect(report.warnings, hasLength(1));
      expect(repository.outcomeCalls.single.succeeded, isFalse);
      expect(repository.setEnabledCalls, isEmpty);
    });

    test('取回 0 条样本时仍算成功', () async {
      source.fetchResult = const Ok<HealthFetchResult>(
        HealthFetchResult(samples: <HealthSample>[]),
      );

      final report = await service.syncSource(source.id);

      expect(report.succeeded, isTrue);
      expect(report.fetched, 0);
      expect(report.inserted, 7);
      expect(report.updated, 3);
      expect(repository.upsertCalls.single, isEmpty);
      expect(repository.setEnabledCalls, hasLength(1));
    });
  });

  group('syncAll', () {
    test('依次同步所有已注册连接器并保持注册顺序', () async {
      final repository = _FakeRepository();
      final nightscout = _FakeSource(id: HealthSourceId.nightscout);
      final xunji = _FakeSource(
        id: HealthSourceId.xunji,
        availability: const Ok<HealthSourceAvailability>(
          HealthSourceAvailability.needsAuthorization('未配置训记 API Key'),
        ),
      );
      final service = HealthSyncService(
        repository: repository,
        sources: <HealthSourceId, HealthDataSource>{
          nightscout.id: nightscout,
          xunji.id: xunji,
        },
      );

      final reports = await service.syncAll(days: 3);

      expect(reports.length, 2);
      expect(reports.first.source, HealthSourceId.nightscout);
      expect(reports.first.succeeded, isTrue);
      expect(reports.last.source, HealthSourceId.xunji);
      expect(reports.last.succeeded, isFalse);
      expect(nightscout.fetchCalls, 1);
      expect(xunji.fetchCalls, 0);
      expect(nightscout.lastWindow!.days, 3);
    });

    test('没有注册连接器时返回空列表', () async {
      final service = HealthSyncService(
        repository: _FakeRepository(),
        sources: const <HealthSourceId, HealthDataSource>{},
      );

      expect(await service.syncAll(), isEmpty);
    });
  });

  group('importFile 与导入器选择', () {
    test('没有匹配导入器时返回 unsupported 失败', () async {
      final repository = _FakeRepository();
      final service = HealthSyncService(
        repository: repository,
        sources: const <HealthSourceId, HealthDataSource>{},
      );

      final result = await service.importFile(
        fileName: 'unknown.bin',
        bytes: <int>[1, 2, 3],
      );

      expect(result.isOk, isFalse);
      expect(result.failureOrNull!.kind, FailureKind.unsupported);
      expect(result.failureOrNull!.code, 'health.import_unsupported');
      expect(result.failureOrNull!.message, contains('unknown.bin'));
      expect(repository.upsertCalls, isEmpty);
    });

    test('按注册顺序选中第一个能处理的导入器', () async {
      final first = _FakeImporter(
        id: HealthSourceId.sibionics,
        displayName: '硅基轻享 CSV',
        parseResult: Ok<List<HealthSample>>(<HealthSample>[_sample('s1')]),
      );
      final second = _FakeImporter(
        id: HealthSourceId.keep,
        displayName: 'Keep CSV',
        parseResult: Ok<List<HealthSample>>(<HealthSample>[_sample('k1')]),
      );
      final service = HealthSyncService(
        repository: _FakeRepository(),
        sources: const <HealthSourceId, HealthDataSource>{},
        importers: <HealthFileImporter>[first, second],
      );

      final result = await service.importFile(
        fileName: 'export.csv',
        bytes: <int>[],
      );

      expect(result.requireValue().source, HealthSourceId.sibionics);
      expect(second.parseCalls, 0);
    });

    test('成功导入时汇总解析与写入条数', () async {
      final repository = _FakeRepository(
        upsertResult: const Ok<HealthUpsertOutcome>(
          HealthUpsertOutcome(inserted: 4, updated: 1),
        ),
      );
      final importer = _FakeImporter(
        id: HealthSourceId.sibionics,
        displayName: '硅基轻享 CSV',
        parseResult: Ok<List<HealthSample>>(
          <HealthSample>[_sample('s1'), _sample('s2')],
        ),
      );
      final service = HealthSyncService(
        repository: repository,
        sources: const <HealthSourceId, HealthDataSource>{},
        importers: <HealthFileImporter>[importer],
      );

      final report = (await service.importFile(
        fileName: 'bg.csv',
        bytes: <int>[1],
      ))
          .requireValue();

      expect(report.fileName, 'bg.csv');
      expect(report.source, HealthSourceId.sibionics);
      expect(report.succeeded, isTrue);
      expect(report.parsed, 2);
      expect(report.inserted, 4);
      expect(report.updated, 1);
      expect(report.warnings, isEmpty);
      expect(report.error, isNull);
      expect(repository.upsertCalls.single.length, 2);
      expect(report.toString(), contains('ok=true'));
    });

    test('解析失败时传播原始失败且不落库', () async {
      final repository = _FakeRepository();
      final importer = _FakeImporter(
        id: HealthSourceId.sibionics,
        displayName: '硅基轻享 CSV',
        parseResult: const Err<List<HealthSample>>(AppFailure(
          kind: FailureKind.parsing,
          message: 'CSV 缺少记录时间列',
          code: 'sibionics_csv_no_time_column',
        )),
      );
      final service = HealthSyncService(
        repository: repository,
        sources: const <HealthSourceId, HealthDataSource>{},
        importers: <HealthFileImporter>[importer],
      );

      final result = await service.importFile(
        fileName: 'bad.csv',
        bytes: <int>[],
      );

      expect(result.isOk, isFalse);
      expect(result.failureOrNull!.kind, FailureKind.parsing);
      expect(result.failureOrNull!.code, 'sibionics_csv_no_time_column');
      expect(repository.upsertCalls, isEmpty);
    });

    test('落库失败时把失败透传给调用方', () async {
      final repository = _FakeRepository(
        upsertResult: const Err<HealthUpsertOutcome>(AppFailure(
          kind: FailureKind.storage,
          message: '写库失败',
        )),
      );
      final importer = _FakeImporter(
        id: HealthSourceId.keep,
        displayName: 'Keep CSV',
        parseResult: Ok<List<HealthSample>>(<HealthSample>[_sample('k1')]),
      );
      final service = HealthSyncService(
        repository: repository,
        sources: const <HealthSourceId, HealthDataSource>{},
        importers: <HealthFileImporter>[importer],
      );

      final result = await service.importFile(
        fileName: 'keep.csv',
        bytes: <int>[],
      );

      expect(result.isOk, isFalse);
      expect(result.failureOrNull!.kind, FailureKind.storage);
      expect(result.failureOrNull!.message, '写库失败');
    });

    test('resolveImporter 没有匹配时返回 null，命中时返回该导入器', () {
      final importer = _FakeImporter(
        id: HealthSourceId.keep,
        displayName: 'Keep CSV',
        handleSuffix: '.csv',
      );
      final service = HealthSyncService(
        repository: _FakeRepository(),
        sources: const <HealthSourceId, HealthDataSource>{},
        importers: <HealthFileImporter>[importer],
      );

      expect(service.resolveImporter('a.csv', <int>[]), same(importer));
      expect(service.resolveImporter('a.gpx', <int>[]), isNull);
    });

    test('importers 暴露为只读列表', () {
      final importer = _FakeImporter(
        id: HealthSourceId.keep,
        displayName: 'Keep CSV',
      );
      final service = HealthSyncService(
        repository: _FakeRepository(),
        sources: const <HealthSourceId, HealthDataSource>{},
        importers: <HealthFileImporter>[importer],
      );

      expect(service.importers, hasLength(1));
      expect(() => service.importers.add(importer), throwsUnsupportedError);
    });

    test('没有注册导入器时 resolveImporter 恒为 null', () {
      final service = HealthSyncService(
        repository: _FakeRepository(),
        sources: const <HealthSourceId, HealthDataSource>{},
      );

      expect(service.resolveImporter('a.csv', <int>[]), isNull);
      expect(service.importers, isEmpty);
    });
  });

  group('报告对象的文本形态', () {
    test('HealthSyncReport 摘要包含来源与条数', () {
      const report = HealthSyncReport(
        source: HealthSourceId.nightscout,
        succeeded: true,
        fetched: 10,
        inserted: 8,
        updated: 2,
      );

      expect(report.toString(),
          'HealthSyncReport(nightscout: ok=true, fetched=10, inserted=8, updated=2)');
    });

    test('HealthImportReport 摘要包含文件名与条数', () {
      const report = HealthImportReport(
        fileName: 'bg.csv',
        source: HealthSourceId.sibionics,
        succeeded: true,
        parsed: 100,
        inserted: 90,
        updated: 10,
      );

      expect(report.toString(),
          'HealthImportReport(bg.csv: ok=true, parsed=100, inserted=90, updated=10)');
    });

    test('HealthUpsertOutcome 的 total 是新增与覆盖之和', () {
      const outcome = HealthUpsertOutcome(inserted: 3, updated: 4);

      expect(outcome.total, 7);
      expect(outcome.toString(),
          'HealthUpsertOutcome(inserted: 3, updated: 4)');
    });
  });

  group('同步状态与查询条件的构造', () {
    test('HealthSourceSyncState 默认值', () {
      const state = HealthSourceSyncState(
        source: HealthSourceId.manual,
        enabled: false,
      );

      expect(state.lastSyncedAt, isNull);
      expect(state.lastError, isNull);
      expect(state.sampleCount, 0);
    });

    test('HealthQuery.lastDays 生成左闭右开区间并携带过滤集', () {
      final query = HealthQuery.lastDays(
        30,
        kinds: <HealthSampleKind>{HealthSampleKind.glucose},
        sources: <HealthSourceId>{HealthSourceId.nightscout},
      );

      expect(query.end.difference(query.start), const Duration(days: 30));
      expect(query.kinds, <HealthSampleKind>{HealthSampleKind.glucose});
      expect(query.sources, <HealthSourceId>{HealthSourceId.nightscout});
    });

    test('HealthFetchWindow.lastDays 的 days 与窗口一致', () {
      final window = HealthFetchWindow.lastDays(14);

      expect(window.days, 14);
      expect(window.toString(), contains('HealthFetchWindow('));
    });

    test('HealthSourceAvailability 的三个命名构造', () {
      const ready = HealthSourceAvailability.ready();
      const unavailable = HealthSourceAvailability.unavailable('桌面端不支持');
      const needsAuth = HealthSourceAvailability.needsAuthorization('待授权');

      expect(ready.canFetch, isTrue);
      expect(ready.isAuthorized, isTrue);
      expect(ready.hint, isNull);
      expect(unavailable.canFetch, isFalse);
      expect(unavailable.isAuthorized, isFalse);
      expect(unavailable.hint, '桌面端不支持');
      expect(needsAuth.canFetch, isFalse);
      expect(needsAuth.hint, '待授权');
      expect(const HealthSourceAvailability(canFetch: true).isAuthorized, isFalse);
    });
  });
}
