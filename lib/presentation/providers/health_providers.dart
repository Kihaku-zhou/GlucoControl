import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database_providers.dart';
import '../../data/health/health_repository_impl.dart';
import '../../data/health/health_source_config.dart';
import '../../data/health/health_sync_service.dart';
import '../../data/health/health_timeline_service.dart';
import '../../data/health/importers/health_file_importer_registry.dart';
import '../../data/health/sources/health_connect_data_source.dart';
import '../../data/health/sources/huawei_health_data_source.dart';
import '../../data/health/sources/nightscout_data_source.dart';
import '../../data/health/sources/xunji_api_data_source.dart';
import '../../data/settings/ai_settings.dart';
import '../../domain/health/health_data_source.dart';
import '../../domain/health/health_repository.dart';
import '../../domain/health/health_source.dart';
import '../../services/ai/ai_chat_client.dart';
import '../../services/ai/ai_tool.dart';
import '../../services/ai/health_assistant.dart';
import '../../services/ai/health_tools.dart';

/// 外部数据源连接参数的读写入口。
final healthConfigStoreProvider = Provider<HealthConfigStore>((ref) {
  return HealthConfigStore(ref.watch(sharedPreferencesProvider));
});

/// 各数据源当前的连接参数。
///
/// 保存设置后会刷新本 Provider，从而使依赖它的连接器与同步服务重建，
/// 避免出现「配置已改但连接器仍用旧参数」的情况。
class HealthSourceSettingsNotifier
    extends Notifier<Map<HealthSourceId, HealthSourceConfig>> {
  @override
  Map<HealthSourceId, HealthSourceConfig> build() {
    final store = ref.watch(healthConfigStoreProvider);
    return <HealthSourceId, HealthSourceConfig>{
      for (final source in HealthSourceId.values) source: store.read(source),
    };
  }

  /// 保存某个数据源的连接参数。
  Future<void> save(HealthSourceId source, HealthSourceConfig config) async {
    await ref.read(healthConfigStoreProvider).write(source, config);
    state = <HealthSourceId, HealthSourceConfig>{...state, source: config};
  }

  /// 清除某个数据源的连接参数（断开连接）。
  Future<void> clear(HealthSourceId source) async {
    await ref.read(healthConfigStoreProvider).clear(source);
    state = <HealthSourceId, HealthSourceConfig>{
      ...state,
      source: const HealthSourceConfig(),
    };
  }
}

/// 各数据源连接参数 Provider。
final healthSourceSettingsProvider =
    NotifierProvider<HealthSourceSettingsNotifier,
        Map<HealthSourceId, HealthSourceConfig>>(
  HealthSourceSettingsNotifier.new,
);

/// 外部健康样本仓库。
final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  return HealthRepositoryImpl(ref.watch(databaseProvider).healthSamplesDao);
});

/// 已配置的连接器集合，按数据源索引。
///
/// 只注册当前平台确实能构造的连接器：桌面端没有 Health Connect，但连接器本身
/// 负责在 `checkAvailability` 中如实报告不可用，因此这里统一注册，
/// 让界面能展示「为什么用不了」而不是干脆消失。
final healthDataSourcesProvider =
    Provider<Map<HealthSourceId, HealthDataSource>>((ref) {
  final settings = ref.watch(healthSourceSettingsProvider);
  return <HealthSourceId, HealthDataSource>{
    HealthSourceId.healthConnect: HealthConnectDataSource(),
    HealthSourceId.xunji: XunjiApiDataSource(
      config: settings[HealthSourceId.xunji] ?? const HealthSourceConfig(),
    ),
    HealthSourceId.nightscout: NightscoutDataSource(
      config: settings[HealthSourceId.nightscout] ?? const HealthSourceConfig(),
    ),
    HealthSourceId.huaweiHealth: HuaweiHealthDataSource(
      config:
          settings[HealthSourceId.huaweiHealth] ?? const HealthSourceConfig(),
    ),
  };
});

/// 可用的文件导入器。
final healthFileImportersProvider = Provider<List<HealthFileImporter>>((ref) {
  return HealthFileImporterRegistry.defaultImporters;
});

/// 外部健康数据同步编排。
final healthSyncServiceProvider = Provider<HealthSyncService>((ref) {
  return HealthSyncService(
    repository: ref.watch(healthRepositoryProvider),
    sources: ref.watch(healthDataSourcesProvider),
    importers: ref.watch(healthFileImportersProvider),
  );
});

/// 跨来源统一时间线服务。
final healthTimelineServiceProvider = Provider<HealthTimelineService>((ref) {
  return HealthTimelineService(
    database: ref.watch(databaseProvider),
    externalRepository: ref.watch(healthRepositoryProvider),
  );
});

/// 各数据源的同步状态，用于设置页展示。
final healthSourceStatesProvider =
    FutureProvider<List<HealthSourceSyncState>>((ref) async {
  final repository = ref.watch(healthRepositoryProvider);
  final states = await repository.syncStates();
  return states.requireValue();
});

/// 注册给模型的健康数据工具集。
final aiToolRegistryProvider = Provider<AiToolRegistry>((ref) {
  final registry = AiToolRegistry();
  registry.registerAll(HealthTools.build(
    timelineService: ref.watch(healthTimelineServiceProvider),
    repository: ref.watch(healthRepositoryProvider),
    syncService: ref.watch(healthSyncServiceProvider),
  ));
  return registry;
});

/// AI 接口客户端。
final aiChatClientProvider = Provider<AiChatClient?>((ref) {
  final settings = ref.watch(aiSettingsProvider);
  if (!settings.isConfigured) return null;
  return AiChatClient(
    config: AiEndpointConfig.fromUserInput(
      apiUrl: settings.apiUrl,
      apiKey: settings.apiKey,
      model: settings.model,
    ),
  );
});

/// 带工具调用的健康助手。未配置 AI 时返回 null。
final healthAssistantProvider = Provider<HealthAssistant?>((ref) {
  final client = ref.watch(aiChatClientProvider);
  if (client == null) return null;
  return HealthAssistant(
    client: client,
    tools: ref.watch(aiToolRegistryProvider),
  );
});
