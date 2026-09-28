# GlucoControl 架构

本文说明应用的分层、依赖方向、关键抽象与扩展点。目标是让「再加一个数据源」或
「再加一个 AI 能问的问题」都变成局部改动，而不是跨文件改一遍。

## 目录与依赖方向

依赖只能自上而下，不允许反向引用：

```
lib/
  core/          零依赖的基础设施：Result/Failure、血糖单位换算
  domain/        纯 Dart 领域模型与契约，不依赖 Flutter、drift、网络
  data/          领域契约的实现：drift 存储、外部连接器、文件导入、同步编排
  services/      跨领域能力：AI 工具、对话客户端、助手循环
  presentation/  Riverpod Provider、界面
```

| 层 | 可以依赖 | 不允许依赖 |
| --- | --- | --- |
| `core` | 仅 Dart SDK | 其余任何层 |
| `domain` | `core` | Flutter、drift、dio |
| `data` | `core`、`domain`、第三方库 | `presentation`、`services` |
| `services` | `core`、`domain`、`data` | `presentation` |
| `presentation` | 全部 | —— |

`domain` 不依赖 Flutter 是刻意约束：它使时间线、统计与模型往返可以用纯
`flutter_test` 快速验证，也避免领域逻辑被 Widget 生命周期绑架。

## 关键抽象

### `Result<T>` / `AppFailure`

`core/result.dart`。旧代码用 `null` 同时表达「没有数据」和「出错了」，调用方无法
区分二者。新代码统一返回 `Result<T>`，失败携带 `FailureKind`，从而让调用方决定
是否可以重试（`AppFailure.isRetryable`）。

跨边界调用（网络、文件、数据库）用 `guardAsync` 收敛异常。

### `HealthSample`：归一化信封

`domain/health/health_source.dart`。每个连接器把自己 API 或导出文件的字段翻译成
同一个结构：

```
HealthSample {
  source: HealthSourceId      // 从哪里取数
  externalId: String          // 源内稳定标识
  kind: HealthSampleKind      // glucose / workout / bodyComposition / sleep / dailyActivity
  startAt, endAt              // 时间区间
  title, originApp            // 展示与溯源
  payload: Map<String,Object?>  // 领域字段
}
```

`(source, kind, externalId)` 构成唯一键，**幂等由落库路径统一保证**，连接器不需要
自己判断「这条是不是已经有了」。这是重复导入同一个文件、重复同步同一天都不会
产生重复记录的原因。

它的领域含义由 `domain/health/health_records.dart` 中的类型化模型解释：
`GlucoseReading`、`WorkoutSession`、`BodyComposition`、`SleepSession`、
`DailyActivity`。每个模型提供 `toSample()` 与 `tryFromSample()`，二者必须成对保持
字段守恒——这是单元测试覆盖的重点。

### `HealthDataSource` / `HealthFileImporter`

`domain/health/health_data_source.dart`。连接器只做两件事：报告可用性、取数并归一化。

* `checkAvailability()` 必须如实报告「当前平台不支持」「需要先授权」还是「可以取数」，
  让界面能解释**为什么用不了**，而不是让入口凭空消失。
* `fetch(window)` 不做持久化、不做去重。
* 文件型来源实现 `HealthFileImporter`：`canHandle` 通过扩展名 + 表头嗅探判定格式，
  `parse` 返回归一化样本。这是五个目标应用的通用兜底通路。

### `HealthRepository`

`domain/health/health_repository.dart`。查询与写入的唯一入口，把 drift 细节挡在
`data/database/health_samples_dao.dart` 之后。同步逻辑因此可以在没有数据库的情况下
用假实现测试。

### `HealthTimeline`：跨来源的统一时间轴

`domain/health/health_timeline.dart`。把本应用录入的记录与所有外部来源的记录合并成
一条按时间排序的列表，并提供：

* `glucoseSummary()` —— 平均/极值、TIR、按 ADAG 公式推算的 eA1c。**没有读数时返回
  `null` 而不是全零**，避免把「没有数据」误报成「全部达标」。
* `contextAround()` —— 某个时刻前后的运动与饮食，用于回答「这次血糖为什么高」。
* `toJson(maxEntries:)` —— 超过上限时按类别各保留最新若干条，而不是简单截断尾部，
  因为截断尾部会让最近的血糖读数消失。

### `AiTool`：模型可调用的能力

`services/ai/ai_tool.dart`。工具的 `parameters` 是标准 JSON Schema，直接透传给
OpenAI 兼容接口的 `tools` 字段。

`HealthAssistant.send` 是带工具调用的循环：模型请求工具 → 执行 → 把结果作为
`role: tool` 消息回填 → 继续推理，直到模型给出正文或达到 `maxToolRounds`。
最后一轮不再提供工具，促使模型基于已有数据收口。

**与旧实现的关键区别**：旧实现把全部健康数据拼成一段文本塞进系统提示。新实现让
模型按问题决定查什么、查多久。收益有三点：上下文占用与数据量解耦；每条结论都能
对应到一次具体的工具调用（记录在气泡下方，可跨会话复核）；新增数据源时只要注册
新工具，提示词不必修改。

## 数据流

### 同步

```
连接器 fetch() ──► HealthSample[] ──► HealthSyncService ──► HealthRepository.upsertAll()
                                                    │                    │
                                                    └─► 记录同步状态       └─► HealthSamplesDao
                                                        (HealthSourceStates)   (ExternalHealthSamples)
```

文件导入走同一条落库路径，因此两种通路共享同一套幂等语义。

### AI 问答

```
用户提问 ──► HealthAssistant.send
                 │
                 ├─► AiChatClient.complete(messages, tools)
                 │        └─ 模型返回 tool_calls
                 ├─► AiToolRegistry.invoke ──► HealthTimelineService / HealthRepository
                 └─► 回填工具结果，继续循环，直到得到正文
```

## 扩展点

### 新增一个数据源

1. 在 `HealthSourceId` 中登记编码、展示名与说明。
2. 在 `lib/data/health/sources/` 下实现 `HealthDataSource`（在线）或
   `HealthFileImporter`（文件）。
3. 若为在线来源，在 `presentation/providers/health_providers.dart` 的
   `healthDataSourcesProvider` 中注册。
4. 若为文件来源，加入 `HealthFileImporterRegistry`。

界面无需改动：数据源管理页遍历 `HealthSourceId.values`。

### 新增一个 AI 工具

1. 在 `lib/services/ai/health_tools.dart` 中实现 `AiTool`。
2. 加入 `HealthTools.build` 的返回列表。

### 修改数据库结构

`AppDatabase.schemaVersion` 单调递增，并在 `onUpgrade` 中按版本区间添加迁移。
当前版本 4：

| 版本 | 变更 |
| --- | --- |
| 2 | 训练计划、训练计划动作、体测记录 |
| 3 | `ExternalHealthSamples`、`HealthSourceStates` |
| 4 | `AIMessages.toolTraceJson` |

## 已知债务

以下问题在本轮重构中被识别但未处理，按影响排序：

1. **`WebDAVService` 仍是单例**。它用私有单例构造 + `init()` 注入配置，难以测试且
   配置变更不会传播。`AIChatClient`/`HealthAssistant` 已改为 Provider 构造的普通对象，
   其余服务应照此迁移。
2. **WebDAV 备份未覆盖新表**。`SyncManager` 只导出四张本地表，
   `ExternalHealthSamples`、`HealthSourceStates` 与 AI 对话均未纳入备份，
   换机时会丢失已导入的外部数据。
3. **凭据明文存放**。`HealthConfigStore` 与 `AiSettingsStore` 使用
   `SharedPreferences`，未加密。正式发布前应换用平台密钥库（如
   `flutter_secure_storage`）；该替换只涉及存储实现，调用方不变。
4. **界面文案未国际化**。文案直接写在 Widget 中。若要支持多语言，应统一走 locale 字典。
5. **`go_router` 基本未使用**。`app/router.dart` 只注册了首页，实际跳转全部走
   `Navigator.push`。要么补齐路由表，要么移除该依赖。
6. **界面层仍有直接访问数据库的位置**。旧页面通过
   `ref.read(databaseProvider)` 直接调用 `AppDatabase` 的方法（`exercise`、
   `blood_sugar`、`meal`、`body_measurement` 各列表页，以及 AI 对话页的消息读写）。
   新代码应走仓库接口；把这些页面迁移到仓库是下一步的工作量所在。

已在本轮解决：提交时无法编译（生成的 drift 代码与表定义不同步）、BLE 心率服务
死代码、无人引用且被未使用 import 引用的旧 AI 分析实现。
