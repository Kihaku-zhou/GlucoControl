# GlucoControl

以血糖管理为核心的多源健康数据聚合与 AI 分析应用。跨平台支持 Android、Windows 与 Linux。

应用本身负责记录与展示（血糖、饮食、运动、体测、训练计划），并通过一组**标准化连接器**
把散落在各处的运动健康数据汇入同一条时间线，再交给 AI 按需查询、综合判断。

> **免责声明**：本应用只做数据记录与展示，不能作为诊断依据。涉及用药、胰岛素剂量
> 调整与低血糖处置的问题请咨询医生。

---

## 核心能力

### 本地记录

- 血糖记录（空腹、餐后、动态监测、自定义时间），mmol/L 与 mg/dL 双向换算
- 饮食记录（含图片与食物明细）
- 运动记录（有氧、力量、耐力；距离、爬升、功率、心率）
- 体测记录（体重、体脂、肌肉量、围度）与训练计划
- 血糖图表、趋势分析、周报、TIR 统计与糖化血红蛋白推算
- 数据导出（JSON/CSV）与坚果云 WebDAV 同步

### 多源数据接入

五个目标应用的开放程度差别很大，因此接入分三条通路。**文件导入对所有来源都有效**，
是在线通路不可用时的兜底。

| 数据源 | 通路 | 可行性 | 说明 |
| --- | --- | --- | --- |
| **训记** | 官方 Open API v2 | 高 | 唯一开箱即用的来源。在 App 的「我的 > 数据导出和导入」生成 API Key 即可；需买断/VIP 账号，接口按训练日限流约 90 秒 |
| **iGPSPORT** | FIT/GPX 文件、Strava/TrainingPeaks 中转 | 中 | 有官方 API 但无自助申请入口，需商务流程 |
| **华为运动健康** | Health Kit（需资质审核）、文件导入 | 中 | 覆盖步数、心率、睡眠、运动与血糖；**不向 Health Connect 写入**，也不支持其授权 |
| **硅基轻享** | Nightscout（经 Juggluco） | 低 | 没有公开 API。社区通行做法是用 Juggluco 直读传感器后推送 Nightscout，本应用以只读方式拉取 |
| **Keep** | 文件导入、Health Connect | 低 | 未找到官方开放接口；隐私政策承诺可导出，但入口与格式未核实 |

另支持 **Android Health Connect** 作为系统级中转：任何写入其中的应用的数据都会在此汇总，
读取时以 `originApp` 标注原始应用来源。

详细的调研过程、信息来源与未核实事项见 [`docs/DATA_SOURCES.md`](docs/DATA_SOURCES.md)。

### AI 助手：按需查询，而非预先喂数据

旧实现把全部健康数据拼成一段文本塞进系统提示。现在模型通过**工具调用**自行取数：

| 工具 | 用途 |
| --- | --- |
| `list_data_sources` | 各数据源的启用状态、最近同步、最近错误与数据量 |
| `query_health_timeline` | 按时间范围与类别拉取跨来源统一时间线 |
| `glucose_summary` | 平均血糖、极值、TIR、范围内时间占比、eA1c |
| `glucose_context` | 某个时刻前后的运动与饮食，用于解释血糖波动 |
| `compare_active_rest_days` | 有运动日与无运动日的血糖对比 |
| `sync_data_source` | 立即拉取某个或全部数据源的最新数据 |

每次问答都会在回答下方显示「查询了 N 项数据」的可展开记录，且该记录跨会话保留，
便于复核结论依据。

---

## 架构

```
lib/
  core/          Result/Failure、血糖单位换算
  domain/        领域模型与契约（纯 Dart，不依赖 Flutter/drift/网络）
  data/          drift 存储、外部连接器、文件导入、同步编排
  services/      AI 工具、对话客户端、助手循环
  presentation/  Riverpod Provider 与界面
```

分层规则、关键抽象与扩展点见 [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)。

**新增数据源**：实现 `HealthDataSource`（在线）或 `HealthFileImporter`（文件）并注册，
数据源管理页会自动列出，无需改动界面。
**新增 AI 能力**：实现 `AiTool` 并加入 `HealthTools.build` 的列表。

技术栈：Flutter 3.27 · Riverpod · Drift (SQLite) · fl_chart · go_router · dio。

---

## 构建

```bash
flutter pub get

# 生成 drift 数据库代码（修改表结构后必须执行）
dart run build_runner build --delete-conflicting-outputs

flutter analyze
flutter test

flutter build apk --debug     # 或 --release
```

Android 侧要求 `minSdk = 26`（Health Connect 的下限），`MainActivity` 继承
`FlutterFragmentActivity`，并在 `AndroidManifest.xml` 中声明所读取的
`android.permission.health.READ_*` 权限——这三处配置缺一不可，详见
[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)。

---

## 项目状态

当前验证结果（本机 Flutter 3.27.3）：

```
flutter analyze   →  No issues found!
flutter test      →  475 passed，0 failed，0 skipped
flutter build apk --debug  →  成功
```

已完成的工程化改造：

- 修复了提交时无法编译的问题（生成的 drift 代码与表定义不同步，133 个编译错误）
- 依赖从 `any` 收敛为精确版本约束，移除未使用的 `freezed`/`riverpod_annotation`
- 建立上述分层与 475 个单元测试，覆盖血糖单位换算、模型字段守恒、时间线统计、
  同步编排、四个连接器的响应解析与 AI 工具调用循环
- AI 从「预生成数据摘要」改为「模型按需调用工具」；旧的分析页也已迁移到同一套机制
- 数据源管理页：逐源探测可用性、配置、同步、清除，以及通用文件导入
- 删除不可达的死代码：BLE 心率服务（其实现恒抛异常、异常被吞掉，运行时静默失效）、
  Web 平台 stub、旧的 AI 分析实现
- CI 拆分为「静态分析 + 单元测试」与「构建 APK」两个作业，`flutter analyze` 改为严格模式
- 修复了 5 个由测试暴露的实现缺陷（AI 接口地址少一段 `/v1`、训记响应体
  解码分支不可达、距离单位口径不一致、连接配置空白判定、未注册连接器不写回状态），
  详见 [`CHANGELOG.md`](CHANGELOG.md)

尚未处理的问题（详见架构文档的「已知债务」）：

- `WebDAVService` 仍是单例，配置靠 `init()` 注入
- WebDAV 备份尚未覆盖外部样本表与 AI 对话
- 凭据以明文存于 `SharedPreferences`，未接入平台密钥库
- 界面文案未国际化；旧列表页仍直接访问数据库
- `go_router` 已引入但基本未使用，跳转仍走 `Navigator.push`
- **四个在线连接器均未做过真实调用**：本仓库没有账号、设备与凭据，
  训记 / Nightscout / 华为 Health Kit / Health Connect 的行为只经过离线单元测试验证

---

## 参与

见 [`CONTRIBUTING.md`](CONTRIBUTING.md) 与 [`SECURITY.md`](SECURITY.md)。

## 许可证

MIT License
