# 变更记录

## [1.2.0] - 2026-09-28

本轮以「修复可构建性 + 分层重构 + 多源数据接入 + AI 工具调用」为目标。

### 修复

- **修复项目无法编译的问题。** 此前提交的 `database.g.dart` 与 `database.dart` 的表定义
  不同步，缺 `ExerciseRecords` 的 `distance`/`elevation`/`power`/`sets`/`weight`/`seconds`/
  `repsList`、`MealRecords.imagePaths`、`BodyMeasurements.imagePath`、
  `TrainingPlanExercises.targetRepsList`，导致 133 个编译错误。重新生成代码后归零。
- 修复 `BodyMeasurementListScreen` 调用了另一个 State 类的私有方法
  `_showRecordDetail` 的未定义错误；顺带把该详情弹窗提取为共享组件
  `presentation/widgets/body_measurement_detail_sheet.dart`，消除重复实现。

### 新增

- **多源健康数据接入层**
  - 领域模型：`HealthSourceId`（8 个来源）、`HealthSample` 归一化信封、
    `GlucoseReading`/`WorkoutSession`/`BodyComposition`/`SleepSession`/`DailyActivity`
    类型化模型，均提供字段守恒的 `toSample`/`tryFromSample` 往返。
  - 连接器：训记官方 Open API v2、Nightscout（只读，覆盖硅基轻享场景）、
    Android Health Connect、华为 Health Kit（OAuth2 端点已核实，数据路径可配置）。
  - 文件导入器：硅基轻享 CSV、训记 CSV、Keep CSV、GPX、TCX、FIT。
  - 统一时间线 `HealthTimeline`，提供 TIR、eA1c（ADAG 公式）与「某时刻前后事件」查询。
- **AI 工具调用**
  - `AiTool`/`AiToolRegistry`/`AiChatClient`/`HealthAssistant`：模型按需调用 6 个工具
    并多轮推理，取代旧实现「把全部数据拼进系统提示」的做法。
  - 工具调用留痕：`AIMessages.toolTraceJson`（drift v4）使查询依据跨会话可复核。
- **数据源管理界面**：逐源探测可用性、配置参数、立即同步、清除数据，以及通用文件导入。
- **Android Health Connect 配置**：minSdk 26、`FlutterFragmentActivity`、
  `READ_HEALTH_*` 权限、`READ_HEALTH_DATA_HISTORY`、权限说明页 `activity-alias`。

### 变更

- 依赖从 `any` 收敛为精确版本约束；移除未被使用的 `freezed`、`freezed_annotation`、
  `riverpod_annotation`；新增 `health`、`csv`、`xml`、`fit_tool`、`crypto`。
- 数据库 schema 升到 4，新增 `ExternalHealthSamples`、`HealthSourceStates` 两张表
  与 `AIMessages.toolTraceJson` 列，并补齐迁移。
- AI 聊天页重写为工具调用模式；AI 配置改由 `AiSettingsNotifier` 托管，保存后
  自动刷新依赖方，避免「改了设置但服务仍用旧配置」。

### 文档

- `docs/DATA_SOURCES.md`：五个目标应用的数据接入可行性调研，含来源链接、推荐架构、
  风险合规与未核实事项；顶部新增「实现状态」对照表。
- `docs/ARCHITECTURE.md`：分层规则、关键抽象、数据流、扩展点与已知债务。
