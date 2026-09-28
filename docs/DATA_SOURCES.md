# 多源中文运动健康 App 数据接入自研 Flutter 血糖/健康管理 App 可行性报告

> 调研日期：2026-09-28
> 目标平台：Android + Windows/Linux 桌面（Flutter）
> 方法：公开网络检索（中英文关键词）+ 关键页面抓取核实。**未核实的内容一律标注「未找到公开资料」或「未核实」，不做推测性陈述。**

---

## 0. 一句话结论

五个数据源里，**只有训记（训记 App）和 iGPSPORT 存在可确认的官方 API**；**华为有完整的 Health Kit（Health Service Kit），但接入需要审核资质、且不走 Android Health Connect**；**Keep 未找到任何官方开放接口**；**硅基轻享没有任何官方 API，只能靠开源社区方案（Juggluco 系）从传感器层旁路**。因此现实的接入路径是「官方 API + Health Connect 本地中转 + 自建服务端 + 手动导入兜底」的混合架构，而不是一个统一的官方网关。

---

## 1. 总览表

| 数据源 | 官方 API | 间接通路 | 手动导出 | 推荐接入方式 | 可行性评级 |
|---|---|---|---|---|---|
| **华为运动健康 / Health Service Kit** | ✅ 有。Health Service Kit（Health Kit），分「端侧数据开放服务」（HMS Core Android SDK）与「云侧数据开放服务」两套 | ①官方支持把数据推给咕咚/悦跑圈/Keep/京东健康/蚂蚁阿福等第三方；②Gadgetbridge 可直连华为手环/手表（蓝牙层）；③**不支持 Health Connect** | ✅ 华为隐私中心「获取您的数据副本」，在线自助仅近一年，7 个工作日左右 | 若只为自用：Gadgetbridge 直连穿戴设备 + Health Connect；若要正式商用：走 Health Service Kit 审核 | **中** |
| **硅基轻享**（硅基仿生 CGM 消费级 App） | ❌ 未找到公开资料 | ✅ Juggluco 直接支持 Sibionics GS1 / GS3 传感器 → 可广播给 xDrip+ / AndroidAPS / Nightscout | ❌ 未找到 App 内导出；GS3 账号绑定值需 root 读取 | Juggluco + 自建 Nightscout（个人自用）；商用需与硅基仿生谈合作 | **低**（技术可行，合规风险高） |
| **iGPSPORT** | ✅ 有官方 API（Postman 工作区 + 官方 GitHub 示例），但**无公开自助申请入口** | ✅ ①Strava 中转；②TrainingPeaks 中转；③Gadgetbridge 直连码表抓活动 | ✅ App/网页下载 FIT 文件；活动详情接口返回 `fitUrl` | 官方 API（能拿到凭据时）或 Strava 中转；自用可 Gadgetbridge | **中** |
| **Keep** | ❌ 未找到官方开放平台 / API | ⚠️ 华为运动健康 → Keep（官方支持，Keep 侧绑定）；Keep → Apple Health（第三方资料提及，官方证据未找到）；Keep → Health Connect **未找到证据** | ⚠️ 隐私政策承诺可复制/导出运动记录，但官方导出入口与格式**未找到** | 一次性手动导入为主；iOS 侧可尝试 Apple Health 中转 | **低** |
| **训记** | ✅ 有官方 Open API v2（`trains.xunjiapp.cn`），支持读 + 写回 | ❌ 未找到 Health Connect / Strava 支持 | ✅ App 内「我的 > 数据导出和导入」 | **直接用官方 Open API**（服务端拉取，走 Bearer Token） | **高** |

---

## 2. 逐数据源调研（a)–(g)

### 2.1 华为运动健康 / Health Service Kit（Health Kit）

**(a) 是否存在官方公开 API / 开放平台 / Health Kit 类 SDK？名称与入口**

存在，产品名 **Health Service Kit（运动健康服务 / Health Kit）**，且明确分为两条线：

- 产品总览（官方）：<https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/health-service-kit-guide>
- **端侧数据开放服务**（Android，HMS Core SDK，直接读取手机/穿戴侧聚合后的数据）：接入文档 <https://developer.huawei.com/consumer/cn/doc/HMSCore-Guides/apply-kitservice-0000001050707556>
- **云侧数据开放服务**（云端，按华为帐号授权拉取）：认证鉴权文档 <https://developer.huawei.com/consumer/cn/doc/hmscore-guides/auth-example-0000001054581058>；FAQ <https://developer.huawei.com/consumer/cn/doc/HMsCore-Guides/faq-0000001476980529>
- HarmonyOS 侧另有接入流程：<https://developer.huawei.com/consumer/en/doc/atomic-guides/health-application-access-as>

> ⚠️ 说明：`developer.huawei.com` 文档站是 JS 客户端渲染，本次调研中 `web_fetch` 只能取到「文档中心」外壳，**正文未能渲染**。上述入口 URL 与页面标题来自搜索结果，属于可靠定位但不等于已逐字核验正文。

**(b) 接入门槛：企业资质 / 审核 / 商务合作 / 个人开发者**

- 有专门的**《应用开发者申请资质说明》**，说明这不是自助开通的接口：
  - 中文：<https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/health-application-qualifications>
  - 英文：<https://developer.huawei.com/consumer/en/doc/harmonyos-guides/health-application-qualifications>
  - 旧版入口：<https://developer.huawei.com/consumer/cn/doc/HMSCore-Guides/application-qualification-description-0000001425636570>
- 另有**「申请验证获取正式权限」**环节（说明存在试用/正式权限两阶段，权限有期限）：<https://device.harmonyos.com/cn/docs/apiref/harmonyos-guides/health-verification>
- 华为开发者论坛存在真实驳回案例，理由是**药监处罚记录**，说明审核会做医疗合规尽调：<https://developer.huawei.com/consumer/cn/forum/topic/0201173017567466131>
- 论坛另有「个人开发者申请运动健康问题」讨论帖（标题即表明个人申请存在专门疑问）：<https://developer.huawei.com/consumer/cn/forum/topic/0202211659324026031>
- **个人开发者能否申请？** 少数派会员文章《让 Agent 读懂你的身体：数据获取篇》（作者实测 + 公开资料整理）给出结论：华为、小米、OPPO、vivo 中「**只有华为的 Health Service Kit 允许个人开发者申请，不一定需要公司主体**」，并注明「按项目申请，权限有使用期限，并有应用相关要求」：<https://sspai.com/prime/story/how-to-obtain-data-for-agent-analysis>
  - **这是本次调研中唯一明确回答「个人可申请」的来源，属第三方单一来源，建议以工单向华为确认。**
- 关于材料清单（第三方论坛回答，含 AI 生成内容，**可信度低，仅作参考**）：营业执照/法人身份证/软著/医疗器械注册证（若声明医疗级）等 <https://bbs.itying.com/topic/69e2f56ac504c50058fd6e44>

**(c) 支持的数据类型**

- 官方数据类型参考（HealthDataTypes）：<https://developer.huawei.com/consumer/ru/doc/HMSCore-References/healthdatatypes-0000001050092315>
- 授权 scope 列表（Scopes 类）：<https://developer.huawei.com/consumer/cn/doc/HMSCore-References-V5/scopes-0000001050092713-V5>
- **血糖确实在支持范围内**，且端侧与云侧各有一页：
  - 端侧血糖：<https://developer.huawei.com/consumer/cn/doc/HMSCore-Guides/blood-glucose-0000001131417182>
  - 云侧血糖：<https://developer.huawei.com/consumer/cn/doc/HMSCore-Guides/blood-glucose-0000001177423531>
  - 英文：<https://developer.huawei.com/consumer/en/doc/hmscore-guides/blood-glucose-0000001177423531>
- 常规类型（步数/心率/睡眠/运动记录/血氧/体温/血压等）见 HealthDataTypes 与 Scopes 文档。
- ⚠️ **未核实**：Health Kit 的血糖字段是否覆盖 **CGM 连续血糖**（而非指尖血/手动录入），以及第三方 CGM App（硅基等）是否会写入华为健康。华为穿戴设备本身不产 CGM 数据，因此该字段的实际数据来源存疑。

**(d) 认证方式与授权模型**

- 云侧数据开放服务有独立的「认证鉴权」章节：<https://developer.huawei.com/consumer/cn/doc/hmscore-guides/auth-example-0000001054581058>
- 端侧有「获取用户授权」文档，说明是**用户级授权**（scope 粒度）：<https://developer.huawei.com/consumer/fr/doc/HMSCore-Guides/extended-requesting-user-authorization-0000001071733944>
- 申请华为帐号服务（前置）：<https://developer.huawei.com/consumer/cn/doc/HMSCore-Guides/apply-id-0000001050747587>
- ⚠️ **未核实**：具体 token 端点、scope 字符串、刷新机制 —— 文档正文未能渲染，不做推测。

**(e) 非官方 / 社区逆向方案**

- **christianeirich/huawei-health-to-health-connect**：从华为健康导出的 JSON 中取体重/体脂，经 Tasker 写入 Android Health Connect。范围很窄（仅体重/体脂），不是通用方案：<https://github.com/christianeirich/huawei-health-to-health-connect>
- **Gadgetbridge**（AGPLv3，开源，F-Droid 分发）**原生支持华为/Honor 手环与手表**，绕过官方 App 直接蓝牙通信，并支持同步步数、睡眠、心率、静息心率、SpO₂、压力、体温、HRV、VO₂Max、运动记录（含骑行功率、踏频、GPS 轨迹）：
  - 支持设备与功能清单：<https://gadgetbridge.org/basics/topics/huawei-honor/>
  - 华为/Honor 配对说明（无需恢复出厂设置）：<https://gadgetbridge.org/basics/pairing/huawei-honor-pairing/>
  - 已知限制（原文摘录）：HarmonyOS 5 以上才支持 TruSleep 睡眠分期，更早设备只有起止时间；「从 Gadgetbridge 发起运动」「实时数据」**尚不支持**；GPS 定位可能因缺少 aGPS 更新而需约 10 分钟
- 社区另有华为数据导出到 Health Connect 的讨论，见 V2EX：「国行小米手环同步到 Health Connect」帖，结论是国行设备普遍无法直接写 Health Connect，需要靠第三方工具中转：<https://global.v2ex.co/t/1161625>

**(f) 间接通路**

- **华为官方支持把数据推给第三方 App**（华为官网支持文档，列出各 App 内的绑定路径）：
  - <https://consumer.huawei.com/cn/support/content/zh-cn01115094/>（含咕咚、悦跑圈、**Keep**、蚂蚁阿福、京东健康的绑定路径）
  - <https://consumer.huawei.com/cn/support/content/zh-cn01057382/>
  - 注意：这是**华为 → 第三方**的单向推送，且需要用户在第三方 App 内主动绑定华为运动健康。
- **Apple Health / HealthKit**：华为有面向西班牙语的华为健康→Strava 支持文档 <https://consumer.huawei.com/es/support/content/es-es15919588/>，说明 Strava 是一条通路。
- **Android Health Connect**：**不支持**。第三方服务商 Count.It 的帮助中心明确写明：「Huawei Health no longer connects to Android Health as result of China-US regulatory issues」：<https://help.count.it/en/articles/12382830-how-do-i-connect-my-huawei-phone-to-count-it>

**(g) 手动导出通路**

- **华为隐私中心「获取您的数据副本」**（官方，面向用户）：
  - 入口一：手机「设置 > 华为帐号 > 隐私中心 > 管理您的数据 > 获取您的数据副本」
  - 入口二：网页 <https://privacy.consumer.huawei.com/tool?lang=zh-cn>
  - 可在页面勾选要下载的数据范围，设置单个文件最大体积；提交后**约 7 个工作日**可在隐私中心下载
  - 来源：<https://consumer.huawei.com/cn/support/content/zh-cn16044986/>
  - 在线自助**只提供近一年**数据；更早数据需通过隐私问题工单申请：<https://consumer.huawei.com/cn/support/content/zh-cn16056953/>
- 开发者侧 FAQ 另有一篇《如何获取运动健康全量数据副本》：<https://developer.huawei.com/consumer/cn/doc/doccenter-dev-faq/faqs-healthservice-6>（正文未能渲染）
- ⚠️ **未核实**：数据副本的具体文件格式（推测为 JSON/CSV 打包，未找到官方格式说明）。

---

### 2.2 硅基轻享（硅基仿生 / Sibionics CGM）

**先厘清产品线（本次调研确认）：**

| 产品 | Android 包名 | 说明 |
|---|---|---|
| 硅基**动感** | `com.sisensing.sisensingcgm` | 主力 CGM 产品线 |
| 硅基**轻享** | `com.sisensing.eco` | 另一款 CGM 消费级 App |

- 两者开发者均为**深圳硅基传感科技有限公司**：<https://app.mi.com/details?id=com.sisensing.eco> / <https://app.mi.com/details?id=com.sisensing.sisensingcgm>
- 硅基轻享也有 iOS 版：<https://apps.apple.com/cn/app/%E7%A1%85%E5%9F%BA%E8%BD%BB%E4%BA%AB/id6478903207>
- 公司官网：<https://www.sisensing.com/>（有中文站与英文站 en.sisensing.com）

**(a) 是否存在官方 API / 开放平台 / SDK？**

**未找到公开资料。** 官网 <https://www.sisensing.com/> 的导航只有「产品 / 服务 / 硅基医生 / 硅基互联网医院 / 抗糖社区 / 支持 / 品牌 / 企业」，**没有任何开发者、开放平台或 API 入口**。官网只提供合作邮箱（品牌合作 brand@sibionics.com、医院市场合作 pm@sibionics.com、零售市场 p.li@sibionics.com、国际市场 prcgm@sibionics.com），属于商务对接而非常规 API 申请。

**(b) 接入门槛**

**未找到公开资料**（因为不存在公开接入路径）。若需 официальный 数据对接，只能走商务合作（医院/品牌合作邮箱）。

**(c) 支持的数据类型**

来自小米应用商店的官方应用介绍（<https://app.mi.com/details?id=com.sisensing.eco>，该页为官方商店信息）：

- 14 天实时葡萄糖数据监测，全程免指血校准
- 蓝牙实时传输，无需手动扫描
- 高低血糖提醒、全维度数据分析
- 记录饮食 / 运动 / 药物等事件
- **亲友血糖远程共享**

**(d) 认证方式与授权模型**

**未找到公开资料**（无公开 API）。

**(e) 非官方 / 社区逆向方案（这是唯一现实通路）**

- **Juggluco**（开源 Android CGM 客户端）**直接支持硅基（Sibionics）传感器**：
  - 支持列表页：<https://www.juggluco.nl/Juggluco/sensors/>
  - 原文要点：扫描传感器包装上的 Data Matrix 二维码后，需要指定传感器型号：「EU、Hematonix、Chinese 或 **Sibionics 2/Split/Light**」；**Sibionics GS3（仅 GTIN 06972831642213）从 Juggluco 10.9.0 起支持**
  - GS3 有**账号绑定机制**：传感器绑定到某个账号 ID，换账号后传感器不工作，因此 Juggluco 需要用户输入硅基帐号密码，从硅基服务器取回该 ID：<https://www.juggluco.nl/Jugglucohelp/SibionicsServer.html>
  - 有 root 权限时也可以直接从官方 App 数据目录读到该 ID：`/data/data/com.sisensing.gs3/shared_prefs/sp_user.xml` 中的 `user_id`
  - ⚠️ **注意**：Juggluco 页面里 硅基官方 App 的包名是 `com.sisensing.gs3`，而小米商店里硅基动感是 `com.sisensing.sisensingcgm` —— 两者可能是不同区域/不同代次的包名，**未核实**。
  - ⚠️ **「Sibionics Light」是否就是「硅基轻享」**：命名高度吻合（Light ≈ 轻享），但**本次未找到直接证据，属推测**。
- **AndroidAPS 官方文档把 Sibionics CGM 列为兼容 CGM**，血糖源为「Juggluco 或 Patched SI App」：<http://wiki.aaps.app/en/latest/Getting-Started/CompatiblesCgms.html>
- **xDrip+ 社区讨论**：`Sibionics CGM / Companion APP`（Discussion #3063）<https://github.com/NightscoutFoundation/xDrip/discussions/3063>；`Errors in the operation of the active calibration plugin with the sensor Sibionics`（Discussion #3189）<https://github.com/NightscoutFoundation/xDrip/discussions/3189>
  - ⚠️ GitHub Discussion 正文由 JS 渲染，本次只取到页面骨架，**具体内容未逐条核实**。
- **风险**：CGM 传感器通常同时只允许一个蓝牙主设备连接。Juggluco 文档明确要求「强制停止之前连接该传感器的 App」——也就是说旁路方案会与官方 App 互斥（用户必须二选一）；GS3 的账号绑定还要求把硅基帐号密码交给第三方 App。

**(f) 间接通路（Health Connect / Apple Health / Nightscout 等）**

- **未找到**硅基官方 App 写入 Health Connect 或 Apple Health 的任何证据。
- 一条**弱推断证据**：硅基轻享在小米应用商店公开的 Android 权限清单中，**没有出现 `android.permission.health.*` 这类 Health Connect 权限**（清单见 <https://app.mi.com/details?id=com.sisensing.eco>）。这只是间接推断，不能作为否定结论。
- **可用的间接通路是反向的**：Juggluco → xDrip+ 广播 / Nightscout 上传 / AndroidAPS 闭环，再由自研 App 从 Nightscout REST API 读取。AndroidAPS 文档确认了这条链路：<https://wiki.aaps.app/de/latest/CompatibleCgms/Juggluco.html>
- Health Connect 本身**有 `BloodGlucose` 记录类型**（见 Gadgetbridge 支持列表，2.4 节的 Health Connect 章节），因此如果自研 App 走 Health Connect，是能承接血糖数据的——缺的是「谁来写」。

**(g) 手动导出通路**

- **未找到**硅基轻享/硅基动感 App 内的 CSV/JSON/Excel 导出功能或 WebDAV 导出。
- 官方商店介绍里的「亲友血糖远程共享」是**查看权限共享**，不是数据导出。
- ⚠️ **未核实**：官方 App 是否提供血糖报表 PDF 导出、是否提供网页版数据下载。本次未找到公开资料。

---

### 2.3 iGPSPORT（骑行码表 / 骑行台）

**(a) 是否存在官方公开 API？名称与入口**

**存在官方 API。**

- 官网 OpenAPI 页面（SPA，本次未能读取正文）：<https://www.igpsport.com/au/support/app/openapi>
- **官方 Postman 工作区**（社区在 intervals.icu 论坛贴出，域名 `postman.com/igpsport`，属官方组织）：<https://www.postman.com/igpsport/igpsport/overview>
- **官方 GitHub 组织仓库**：<https://github.com/igpsport/testIgpsportAuth>（仓库描述 "iGPSPORT connect"，是 OAuth 接入示例）
- 另有一个社区整理的 OpenAPI 规范（从官方接口逆向整理，含 TS 客户端）：<https://github.com/kamikadzem22/igpsport-unoffical-api>

**(b) 接入门槛**

- **未找到公开的自助申请入口**。官网 openapi 页面是 JS 渲染页面，本次无法确认其正文是否包含申请表单。
- 来自 intervals.icu 官方论坛的**一手社区证据**（2025-02 至 2026-02 的长贴）显示：骑友们**长期无法找到申请途径**。论坛管理员原话大意：「iGPSPORT 是（中国）最流行的码表品牌……他们提供 API，但 GitHub 上的示例代码已是 9 年前的」「你有没有申请入口的邮箱或说明？能有一个提供申请详情的页面会有很大帮助」。帖子里有用户建议集体发邮件给 iGPSPORT 官方邮箱推动对接：<https://forum.intervals.icu/t/request-to-add-igpsport-integration/91944>
- 结论：**官方 API 存在，但申请通道不透明，大概率需要商务/合作途径**。个人开发者能否获得凭据 —— **未核实**。

**(c) 支持的数据类型**

依据社区整理的 OpenAPI 规范（<https://raw.githubusercontent.com/kamikadzem22/igpsport-unoffical-api/master/openapi.yaml>，内容与官方接口对齐）：

- **活动列表** `/Activity/ActivityList`：RideId、标题、开始时间、骑行距离、总爬升、记录时长
- **活动详情** `/service/web-gateway/web-analyze/activity/queryActivityDetail/{activityId}`：平均速度、平均移动速度、最大速度、移动时间、总时间、距离、总爬升/下降、平均/最高/最低海拔、卡路里、上坡最大坡度、**功率相关指标（avgBalance / avgTQEffect / avgPedSmooth / avgPco）**、平均温度、设备信息、`fitUrl`、`dataSyncStravaStatus`
- **FIT 下载** `/service/web-gateway/web-analyze/activity/getDownloadUrl/{activityId}` → 返回 FIT 文件 URL
- **用户资料** `/service/mobile/api/user/userinfo`：身高体重、**FTP、最大心率 MHR、乳酸阈心率 LTHR、静息心率、VO₂max**、累计骑行时长/距离/卡路里、车轮周长
- **心率/功率/踏频区间** `/service/mobile/api/v2/User/UserIntervalInfo`（功率区间、心率区间、踏频区间、配速区间），且支持写回 `UpdatePersonalIntervalInfo`
- **自定义训练课程**（Workout，结构化步骤/重复组，含 FTP 百分比、心率、踏频目标）

> 说明：这些接口给的是**活动摘要 + FIT 文件**，**逐秒功率/踏频/心率数据在 FIT 文件里**，需要自行解析。活动详情里带 `fitUrl`。

**(d) 认证方式与授权模型**

同为上述逆向整理规范所记录（**非官方文档，需自行验证**）：

1. **旧式账号密码登录**：`POST https://i.igpsport.com/Auth/Login`（JSON `{username, password}`），token 通常通过 `Set-Cookie: loginToken=...` 返回
2. **OAuth2 密码模式**：`POST https://oauth.en.igpsport.com/connect/token`，client 凭据走 HTTP Basic 认证，body 为 `grant_type=password&username=...&password=...&scope=...`；示例 scope 为 `openid offline_access mobile.api user.api device.api activity.api IdentityServerApi`，返回 `access_token` / `refresh_token` / `expires_in` / `memberId`
3. 业务接口用 `Authorization: Bearer <JWT>` 或 `loginToken` Cookie

> ⚠️ 这套流程**基于对官方 App 的抓包逆向整理**，属于「官方 API 的非官方文档」。真实申请后拿到的凭据形态可能不同。另注意 `grant_type=password`（资源所有者密码模式）是 OAuth2 中已被主流弃用的模式。

**(e) 非官方 / 社区逆向方案**

- `kamikadzem22/igpsport-unoffical-api`：把官方 App 的网络请求整理成 OpenAPI 3.0.3 规范（含 Restfox 抓包来源、TS 客户端）：<https://github.com/kamikadzem22/igpsport-unoffical-api>
- `kvnZero/IGPSPORT2Xingzhe`：自动把 iGPSPORT / Garmin 骑行数据同步到**行者**平台：<https://github.com/kvnzero/igpsport2xingzhe>
- 用户脚本「iGPSPORT 运动记录下载助手」（Greasy Fork）：<https://greasyfork.org/ru/scripts/536319-igpsport%E8%BF%90%E5%8A%A8%E8%AE%B0%E5%BD%95%E4%B8%8B%E8%BD%BD%E5%8A%A9%E6%89%8B>
- **Gadgetbridge**：已支持 iGPSPORT 码表（PR #5211），可**免官方 App 配对**，功能包括活动抓取与解析、路线管理（上传 cnx/gpx/fit/tcx/xml）、通知、天气（iGS630/iGS630S/iGS800/BiNavi Air）。支持型号：BiNavi、BiNavi Air、BSC200、BSC200S、BSC300、BSC500、iGS630、iGS630S、iGS800：<https://gadgetbridge.org/gadgets/bike-computers/igpsport/>
  - 对比官方 App 的价值：**完全本地、免账号、免云端**，抓到的活动可再由 Gadgetbridge 写入 Health Connect

**(f) 间接通路（Strava / TP / 悦跑圈等）**

- **Strava**：iGPSPORT 活动详情返回体里有 `dataSyncStravaStatus` 字段，证明官方 App 内置 Strava 同步。intervals.icu 论坛里教练的通行建议就是「**可以用 Strava 做中转**」：<https://forum.intervals.icu/t/request-to-add-igpsport-integration/91944>
- **TrainingPeaks（TP）**：同帖中用户确认「**iGPSPORT 支持 TP**」，可行链路是 Intervals → TP → iGPSPORT（发送结构化训练）；反向（iGPSPORT → TP）由官方支持
- **行者**：社区项目 IGPSPORT2Xingzhe 证明可行（非官方）
- **Health Connect**：**未找到 iGPSPORT 官方 App 支持 Health Connect 的证据**。但 Gadgetbridge 路线可以把抓到的活动写入 Health Connect（见 2.4 节）

**(g) 手动导出通路**

- App / 网页端可下载活动 **FIT 文件**（活动详情接口即返回 `fitUrl`），这是骑行数据的事实标准格式，可用 `fitparse` / `fitdecode` 等库解析出逐秒记录、圈信息、GPS 轨迹
- 用户脚本「iGPSPORT 运动记录下载助手」可批量下载：<https://greasyfork.org/ru/scripts/536319-...>
- 码表本身**支持通过 USB 直接导出**：`iGS618` 说明书提到「通过蓝牙上传」：<http://global.igpsport.com/File/pdf/igs618-%e8%af%b4%e6%98%8e%e4%b9%a6%e4%b8%ad%e6%96%87%e7%89%88.pdf>
- ⚠️ **未核实**：网页端是否支持批量导出 CSV。

---

### 2.4 Keep

**(a) 是否存在官方公开 API / 开放平台？**

**未找到公开资料。**

本次调研的反向排查结论：
- 搜索「Keep 开放平台 / Keep 开发者 / keep.com 开放平台」未得到任何官方开放平台页面
- 搜索命中的 `open.kuaishou.com` 是**快手**开放平台，与 Keep 无关
- 搜索命中的 `keep.md`（<https://keep.md/docs/export>）是**另一个同名笔记应用**，与国内健身 App Keep 无关 —— 这是一个容易误引的坑，特别标注
- Keep 的运营主体是**北京卡路里科技有限公司 / 北京卡路里信息技术有限公司**

**(b) 接入门槛**

**未找到公开资料**（不存在公开 API 申请路径）。

**(c) 支持的数据类型（据 Keep 产品能力）**

- 跑步 / 骑行 / 健走等运动记录（含 GPS 轨迹）
- 健身课程/训练记录
- 心率：Keep 可作为数据接收方，绑定第三方数据源。**华为官网明确给出 Keep 侧的绑定路径**：`Keep > 运动 > 装备 > 本次运动装备 > 数据源 > 心率 > 添加设备 > 上滑选择第三方与服务 > 华为运动健康 > 去授权`（来源：<https://consumer.huawei.com/cn/support/content/zh-cn01115094/>）
- 步数、睡眠：依赖外部数据源写入
- **未找到体重/体成分数据类型的官方说明**

**(d) 认证方式与授权模型**

**未找到公开资料。**

**(e) 非官方 / 社区逆向方案**

**未找到公开的 API 级逆向项目。** 本次未做穷尽搜索，不能断言不存在；但至少没有像 iGPSPORT / 训记那样形成社区规范或 MCP/Skill 生态。

**(f) 间接通路**

- **华为运动健康 → Keep**：✅ 官方支持（用户在 Keep 内绑定华为运动健康）。来源同上华为支持文档。
- **Keep → Apple Health**：少数派文章提到「Keep、Nike Run Club 等运动 App 也可以接入 [Apple Health]」，并提醒「是否写入你看中数据，建议读者根据自身情况进一步核实」：<https://sspai.com/prime/story/how-to-obtain-data-for-agent-analysis>。**官方证据未找到。**
- **Keep → Health Connect**：**未找到任何证据。**
- **Health Connect → Keep**：**未找到任何证据。**
- 一个**容易误判的点**：Gadgetbridge 的支持设备列表里有一个叫 **「Keep Health」的可穿戴品牌**（<https://gadgetbridge.org/gadgets/wearables/keephealth/>）。这看起来是 Keep 生态的智能手环（或贴牌设备），与「Keep App 的数据接口」是两回事。**其与 Keep App 的关系未核实。**

**(g) 手动导出通路**

- **存在官方承诺**：Keep 隐私政策写明「您可以随时复制、导出个人账号名下的个人资料（包括用户名、头像、简介、手机号等）及您的运动记录，以方便将该内容用于非 Keep 服务」——引自 Keep 隐私政策版本演变分析报告 <https://termshub.cn/public/version/4410>
- 第三方文章介绍了导出方法，但内容质量低、无官方入口链接：<https://www.php.cn/faq/2162001.html>、<https://www.php.cn/faq/3140676.html>
- ⚠️ **未核实**：具体导出入口路径、文件格式（GPX/CSV/JSON）、是否支持批量历史导出。

---

### 2.5 训记（力量训练记录 App）

**(a) 是否存在官方公开 API？名称与入口**

**存在，而且是五个数据源里最开放的一个。**

- **官方 Open API v2**，基址 `https://trains.xunjiapp.cn`：
  - 读：`POST /api_trains_for_llm_v2`
  - 写：`POST /api_upsert_trains_for_llm_v2`
  - 请求体必须带 `schema_version: "train_open_api_v2"`
- 证据来源（一并交叉验证）：
  - 社区 Agent Skill 的源码，硬编码了上述 BASE_URL / API_PATH / SCHEMA_VERSION：<https://raw.githubusercontent.com/AkiraLan/xunji-skills/master/xunji/scripts/fetch_xunji_trains.py>
  - Skill 说明文档（含完整读写规则、限流、字段语义）：<https://raw.githubusercontent.com/AkiraLan/xunji-skills/master/xunji/SKILL.md>，仓库：<https://github.com/AkiraLan/xunji-skills>
  - 少数派文章（作者实测）：「**训记向买断用户提供 API Skill，入口在「我的」>「数据导出和导入」。这个 API 还支持回写，Agent 可以把训练记录写回 App。**」<https://sspai.com/prime/story/how-to-obtain-data-for-agent-analysis>
- 训记开发者的动作名标准库：<https://github.com/Foveluy/Xunji-movements>

**(b) 接入门槛**

- **不需要企业资质、不需要应用审核、不需要商务合作**。这是面向**终端用户本人**的接口，不是面向开发者的开放平台。
- **需要付费**：少数派明确说是「买断用户」；Skill 文档里记录了服务端会返回 `仅VIP可用` 错误。⇒ **需要有买断/VIP 权益的账号。**
- **有严格限流**：文档原文「the API rate-limits one read per training day to roughly once per 90 seconds」，错误信息形如 `too frequent, retry after 90s`。
- **有硬性请求上限**：单次调用最多 4 个训练，每个训练最多 15 个动作，每个动作最多 20 组，超出服务端拒绝。

**(c) 支持的数据类型**

依据 Skill 文档与解析代码：

- 训练日期（`datestr`，YYYY-MM-DD）
- 训练记录标识 `localid`、起止时间 `start`/`end`（毫秒时间戳）
- 训练标题（如「胸部训练」）、备注
- **动作名（中文，官方标准名）**
- **逐组数据：组序号、重量（kg）、次数、自重标记、单组时长（秒）**
- 有氧/计时/Tabata 动作的 `metrics`：**距离（m/km）、卡路里 kcal、心率 bpm、步数 steps**
- `--full` 模式额外返回：未勾选的组、**每组 RPE**、每组备注、动作备注
- 休息日（`rest_day`）

> 注意：**没有**训练组数/重量的图表化指标，但原始组数据齐全，可自行聚合 1RM/训练容量。

**(d) 认证方式与授权模型**

- **Bearer Token**：HTTP 头 `Authorization: Bearer <XUNJI_API_KEY>`（客户端也兼容 `x-api-key`）
- **用户级授权**：API Key 就是用户本人的凭据，读写的是该用户自己账号下的训练记录
- 写入使用 `client_request_id`（每次请求一个新的）做幂等；需要保留 `localid`/`start`/`end` 以更新既有记录
- ⚠️ 文档提醒：服务端 `dry_run: true` 在 2026-05-19 实测**仍会落库**，因此不要把它当安全校验

**(e) 非官方 / 社区逆向方案**

- **不需要逆向 —— 官方就是开放的**。
- 社区生态：`AkiraLan/xunji-skills`（Claude/Agent Skill，读写封装）、`Foveluy/Xunji-movements`（官方动作库）
- 少数派文章作者做了「训记 + Agent」的完整实践
- 风险很低（唯一风险是接口变更与限流），因为它本来就是官方提供给用户的口子

**(f) 间接通路**

- **未找到**训记支持 Health Connect、Apple Health、Strava 的证据。
- 台湾 PTT 论坛有用户专门发帖问「訓記可否連 STRAVA」，从标题看是在**询问**而非确认：<https://pttweb.tw/MuscleBeach/M.1754552812.A.44B>
- 结论：训记是**孤岛**，但它把官方 API 开出来了，反而是最好接的。

**(g) 手动导出通路**

- App 内「**我的 > 数据导出和导入**」（少数派实测入口）：<https://sspai.com/prime/story/how-to-obtain-data-for-agent-analysis>
- 该入口同时是 API Key / API Skill 的入口
- ⚠️ **未核实**：手动导出的具体文件格式（CSV/JSON）与字段。

---

## 3. 专题：Android Health Connect 在国内生态的实际覆盖

### 3.1 Health Connect 本身

- **自 Android 14 起并入 AOSP**：Gadgetbridge 官方文档原文——「Health Connect is a component integrated to AOSP (Android Open Source Project), so it is a part of Android since Android 14 and later, therefore no any proprietary application is required to have Health Connect feature on your device if you use these versions of Android.」<https://gadgetbridge.org/basics/integrations/health-connect/>
- Android 13 及以下需要从 Google Play 安装独立的 Health Connect 应用（该应用为专有软件）。
- **数据本地存储**：同页原文「all data stored in Health Connect stays inside the device, no data is sent to external servers (even to Google)」；应用必须被显式授权，权限可随时撤销。
- Android 官方文档（本次未能渲染正文，仅确认页面存在）：
  - 可用性：<https://developer.android.google.cn/health-and-fitness/health-connect/availability>
  - 常见问题：<https://developer.android.google.cn/health-and-fitness/guides/health-connect/develop/frequently-asked-questions>
  - 开发者入门：<https://developer.android.google.cn/health-and-fitness/health-connect/get-started>

### 3.2 五个数据源对 Health Connect 的支持情况

| 数据源 | 是否读写 Health Connect | 证据 |
|---|---|---|
| **华为运动健康** | ❌ **不支持，只走自家 HMS Health Kit** | Count.It 帮助中心明确：「Huawei Health no longer connects to Android Health as result of China-US regulatory issues」<https://help.count.it/en/articles/12382830-how-do-i-connect-my-huawei-phone-to-count-it> |
| **Keep** | ❓ **未找到任何证据**（既没找到写入，也没找到读取） | — |
| **训记** | ❓ **未找到任何证据** | — |
| **iGPSPORT** | ❓ **App 本身未找到证据**；但 **Gadgetbridge 可以**（见下） | <https://gadgetbridge.org/gadgets/bike-computers/igpsport/> |
| **硅基轻享** | ❓ 未找到证据；小米商店权限清单中无 `android.permission.health.*`（弱推断） | <https://app.mi.com/details?id=com.sisensing.eco> |

### 3.3 国内厂商的 Health Connect 现实

- **三星国行**：默认不写 Health Connect，需要手动开开发者模式、把 CSC 改成 US、MCC 改成 310(US)、HA Server 改成 DEV，才能出现「健康连接」选项 —— 说明**锁区是真实存在的**：<https://xice.cx/posts/openDevOnSamsungHelathCN/>
- **小米 / OPPO / vivo**：少数派作者整理的结论是「OPPO、vivo、小米等国内厂商的**国际版**，以及非国行的三星设备，都支持向 Health Connect 写入数据」，国行情况需实测；并明确提醒「我手上没有真机，无从逐一确认」：<https://sspai.com/prime/story/how-to-obtain-data-for-agent-analysis>
- **V2EX 实测帖**（2025-09）：国行小米手环 + 国行小米运动健康**无法**匹配 Play 版小米运动健康；登录小米账号后，「外区的号才能在三方数据管理里面分享给 Health Connect 之类的」。帖子给出的现实方案是「手环厂家的官方应用导出 log，再用 Notify for Mi Band 配对」：<https://global.v2ex.co/t/1161625>
- **华为**：走 HMS Health Kit，不走 Health Connect（见上）。

### 3.4 结论

**Health Connect 在国内是「能用但不普及」的状态。** 它作为 Android 14+ 的系统组件本身在，但**写入方**极度稀缺：五大目标数据源里，**没有一家被证实会写 Health Connect**。要让它真正变成中转站，必须自己往里面写——而 **Gadgetbridge 正是能干这件事的现成工具**。

### 3.5 开源统一健康数据聚合方案盘点

| 方案 | 定位 | 对本项目的价值 | 关键证据 |
|---|---|---|---|
| **Gadgetbridge** | 开源（AGPLv3）Android 设备管理 + 数据同步框架 | ⭐⭐⭐⭐⭐ **一家打通华为穿戴 + iGPSPORT 码表，并写入 Health Connect** | <https://gadgetbridge.org/>；<https://gadgetbridge.org/basics/integrations/health-connect/> |
| **Nightscout** | 自建 CGM 云端 + REST API，糖尿病社区事实标准 | ⭐⭐⭐⭐⭐ **承接硅基 CGM 数据的唯一靠谱落点** | Nightscout API（Swagger）：<https://app.unpkg.com/nightscout@0.12.8/files/swagger.yaml> |
| **Juggluco** | 开源 Android CGM 客户端，直连传感器 | ⭐⭐⭐⭐⭐ **直读 Sibionics GS1/GS3** | <https://www.juggluco.nl/Juggluco/sensors/> |
| **xDrip+** | 开源 CGM 采集/广播/上传 | ⭐⭐⭐⭐ 与 Juggluco 配合，广播给 AAPS，上传 Nightscout | <https://wiki.aaps.app/de/latest/CompatibleCgms/Juggluco.html> |
| **AndroidAPS (AAPS)** | 开源闭环胰岛素输注系统 | ⭐⭐⭐ 证明 Sibionics CGM 通路可用（但本项目不需要闭环） | <http://wiki.aaps.app/en/latest/Getting-Started/CompatiblesCgms.html> |
| **openScale + openScale sync** | 开源体重/体成分记录 | ⭐⭐ **只管体重体成分，不含 CGM**；但 sync 支持 Health Connect 双向、MQTT、InfluxDB、Webhook | <https://github.com/oliexdev/openScale>；<https://github.com/oliexdev/openScale-sync> |
| **health-connect-webhook** | 把 Health Connect 数据推送到自定义 webhook | ⭐⭐⭐ 自建服务端的现成推送端 | <https://github.com/mcnaveen/health-connect-webhook> |
| **Health Sync / Health Data Export** | 商业 Health Connect 导出工具（导到网盘/服务器/Google 表格） | ⭐⭐ 备选 | 见少数派整理：<https://sspai.com/prime/story/how-to-obtain-data-for-agent-analysis> |
| **Freddy (freddy.coach)** | 第三方健康数据中转服务 + MCP | ⭐⭐ 省事但数据在第三方服务器 | 同上 |
| **astrbot_plugin_body_monitor** | 国内实践：小米手环数据经 Health Connect Webhook 收进自建服务 | ⭐⭐ 可参考的国内落地方案 | <https://github.com/ludan0312/astrbot_plugin_body_monitor> |
| **华为→Health Connect (Tasker)** | 华为健康 JSON → Tasker → Health Connect，仅体重/体脂 | ⭐ 范围太窄 | <https://github.com/christianeirich/huawei-health-to-health-connect> |

---

## 4. 推荐架构

### 4.1 分层设计

```
┌───────────────────────── Layer 0 · 采集端（Android 手机为枢纽） ─────────────────────────┐
│                                                                                          │
│  华为穿戴设备 ──(蓝牙，免官方App)──► Gadgetbridge ──┐                                    │
│  iGPSPORT 码表 ─(蓝牙，免官方App)──► Gadgetbridge ──┤                                    │
│                                                    ├──► Android Health Connect（本地）  │
│  其他 Android 健康源 ───────────────────────────────┘                                    │
│                                                                                          │
│  硅基 CGM 传感器 ──(蓝牙)──► Juggluco ──► xDrip+ 广播 / Nightscout 上传                  │
│                                                                                          │
│  【正式路线】华为 Health Service Kit 云侧 API ──► 自建后端                                │
│  【正式路线】iGPSPORT 官方 API ──► 自建后端                                               │
│  【正式路线】训记 Open API v2 ──► 自建后端                                                │
│                                                                                          │
└──────────────────────────────────────────────────────────────────────────────────────────┘
                                        │
┌──────────────────────── Layer 1 · 中转层（自建，境内） ────────────────────────────────────┐
│  • 自建 Nightscout（CGM 时序数据 + REST 查询）                                            │
│  • 自建后端服务（Node/Python）：                                              │
│      - 统一内部数据模型（GlucoseSample / HeartRate / SleepSession / Exercise / StrengthSet）│
│      - 各源 Adapter：train-api / igpsport-api / huawei-healthkit / nightscout / csv-import │
│      - 去重、单位归一（mmol/L ↔ mg/dL）、时区归一                                        │
│  • SQLite / PostgreSQL 落库                                                              │
└──────────────────────────────────────────────────────────────────────────────────────────┘
                                        │
┌──────────────────────── Layer 2 · Flutter 应用 ───────────────────────────────────────────┐
│  Android：health 插件（pub.dev，支持 Health Connect 读写）──► 本地 Health Connect         │
│           + 直连自建后端 REST                                                             │
│  Windows/Linux：只走自建后端 REST + 本地文件导入（CSV/JSON/FIT）                          │
│  （桌面端没有 Health Connect，也没有 HMS Core，必须依赖后端）                              │
└──────────────────────────────────────────────────────────────────────────────────────────┘
```

### 4.2 逐源接入策略

| 数据源 | 首选方案 | 备选 | 说明 |
|---|---|---|---|
| **华为运动健康** | ①自用：**Gadgetbridge 直连穿戴设备** → Health Connect；②商用：**Health Service Kit 云侧 API**（走审核） | ③华为隐私中心数据副本手动导入（近一年） | 商用必须有资质，别指望绕过；Gadgetbridge 路线只对**华为自有穿戴设备**有效，拿不到华为健康 App 里由第三方写入的数据 |
| **硅基轻享** | **Juggluco → 自建 Nightscout → 后端 REST**（个人自用、且用户明确知情同意） | 用户手动在官方 App 里看、自研 App 手工录入 | ⚠️ 这是**唯一现实路径，但合规风险最高**；商用必须走商务合作 |
| **iGPSPORT** | 先尝试**官方 API 凭据**（联系官方）；拿不到就 **Strava 中转** | **Gadgetbridge 直连码表**（自用最干净）；FIT 文件批量导入 | Strava 中转会丢部分字段（如功率平衡/PCO），逐秒数据在 FIT 里 |
| **Keep** | **手动导入**（用户导出/截图） | 若用户有 iPhone：Keep → Apple Health → 导出中转 | 无官方自动化路径；不要在这上面投入工程预算 |
| **训记** | **官方 Open API v2**，服务端定时拉取（遵守 90 秒/训练日限流） | App 内手动导出导入 | 五个源里最省事，优先做 |

### 4.3 关键技术选型建议

1. **Flutter 侧**：Android 用 `health` 包（<https://pub.dev/packages/health>）读写 Health Connect；桌面端不要试图复用 `health`，直接走 HTTP + 文件导入。数据模型用一个 Dart 层的 `HealthRecord` 抽象统一。
2. **CGM 数据不要走 Health Connect**（写入方缺失），走 Nightscout REST 或后端自有 API。Health Connect 的 `BloodGlucose` 记录类型可作为未来的写入目标，用来给其他 App 共享。
3. **训练数据（训记/Keep）与运动数据（iGPSPORT/华为）分表存储**，不要硬套 Health Connect 的 `ExerciseSessionRecord` —— 力量训练的「组×重量×次数」在 Health Connect 里没有对应字段，会被压扁。
4. **后端部署在境内**，避免 CGM 数据出境带来的合规负担。
5. **幂等与去重**：同一份运动数据可能同时来自 Strava 和 iGPSPORT 官方 API，需按 `startTime + duration + distance` 做指纹去重。iGPSPORT 活动接口里的 `dataSyncStravaStatus` 可用于判断该活动是否已流向 Strava。

---

## 5. 风险与合规

### 5.1 逆向 API 的 ToS / 法律风险

1. **违反用户协议**：iGPSPORT、硅基等 App 的用户协议普遍禁止「使用非官方客户端访问服务」「反向工程」「爬取数据」。社区整理的 OpenAPI 规范（kamikadzem22）和抓包得到的 client 凭据，都属于此类。
2. **《反不正当竞争法》**：如果是在商业产品中使用逆向接口，且对原平台造成实质性替代或服务器负担，存在被主张不正当竞争的风险。
3. **《刑法》第 285/286 条边界**：单纯的协议分析与「侵入/破坏计算机信息系统」的界限，取决于是否绕过技术保护措施、是否造成系统干扰。**本报告不构成法律意见，商用前必须找律师。**
4. **账号风险**：逆向接口的凭据来自用户账号，一旦触发风控，**用户账号可能被封禁**，而这会直接伤害你的用户。
5. **接口不稳定**：非官方接口随时可能变更/加签/封禁，无 SLA。把它作为付费产品的主链路是危险的。
6. **iGPSPORT 的 `grant_type=password`**：OAuth2 密码模式已被 OAuth 2.1 弃用，且要求你把**用户的明文密码**交给后端或客户端。这在隐私合规上是重大减分项——**优先争取官方 client_credentials / authorization_code 凭据**。

### 5.2 数据隐私（CGM 属敏感医疗数据）

1. **法律定性**：CGM 连续葡萄糖数据在国内语境下属于**个人敏感信息 / 医疗健康数据**，受《个人信息保护法》《数据安全法》《网络安全法》规制。处理需：
   - **单独同意**（不能混在总隐私政策里）
   - 明确告知处理目的、方式、范围、保存期限
   - 最小必要原则：不要顺手把心率/睡眠也一起采了
   - 单独的**敏感个人信息处理规则**与撤回同意机制
2. **医疗器械合规边界（这条最容易被忽略）**：
   - 华为 Health Kit 的权限审核会查**药监处罚记录**（真实论坛案例）：<https://developer.huawei.com/consumer/cn/forum/topic/0201173017567466131>
   - 若你的 App 对血糖做**判读、报警、胰岛素建议、低血糖预警**，可能落入《医疗器械监督管理条例》下的医疗器械定义，需要注册/备案
   - 硅基官方 App 自己的免责声明就是「本软件仅提供数据收集展示，不能作为诊断依据，需要遵从医嘱」（小米商店页面）——**你的 App 也应照此措辞，并在产品设计上避免任何「诊断/治疗建议」类功能**，除非拿到器械资质
3. **第三方数据中转**：走 Nightscout / Freddy 这类第三方服务器时，要明确告知用户数据存放在哪里。**自建 Nightscout 是隐私上最优的**（数据在用户或你控制的服务器）。
4. **Juggluco 路线的特殊风险**：GS3 需要用户提供**硅基帐号密码**才能取回 account ID（<https://www.juggluco.nl/Jugglucohelp/SibionicsServer.html>）。让你的 App 收集用户第三方账号密码是**高风险的合规坑**——如果要走这条路，应让用户自己在 Juggluco 里完成，你的 App 只对接 Nightscout 的只读 token。
5. **数据出境**：若后端/中转使用境外服务（Google Fit、Strava、Freddy），需评估是否触发数据出境安全评估。
6. **开源许可**：Gadgetbridge 是 **AGPLv3**，openScale 是 **GPLv3**。**直接链接/修改其代码并分发会触发传染性开源义务**。把它们当作「用户自行安装的独立 App」，你的 App 只对接 Health Connect / Nightscout 的公开接口，则不受传染。

---

## 6. 未核实事项（诚实清单）

以下是我**没能确证**的点，请勿当作结论使用：

**华为**
1. Health Service Kit 文档正文未能渲染（`developer.huawei.com` 为 JS SPA），**《应用开发者申请资质说明》的具体材料清单、审核周期、scope 名称、云侧 token 端点全部未逐字核实**。
2. 「**个人开发者可以申请**」这一结论**只有少数派一个来源**，且原文措辞是「允许个人开发者申请，不一定需要公司主体」，未见华为官方确认。
3. 华为 Health Kit 的**血糖字段是否覆盖 CGM**（而非指尖血/手动录入）、第三方 CGM App 是否会写入华为健康 —— 未核实。
4. 「如何获取运动健康全量数据副本」（开发者 FAQ）正文未取到，数据副本的**文件格式**未知。
5. itying 论坛那份「资质材料清单」含明显的 AI 生成内容，**可信度低**，未采信为结论。

**iGPSPORT**
6. 官网 openapi 页面（<https://www.igpsport.com/au/support/app/openapi>）是 SPA，**正文未读取**，无法确认它是否包含申请表单或联系方式。
7. 官方 API 的**真实申请门槛**（个人能否申请、是否需要企业主体、是否有费用）未核实。
8. Postman 工作区（<https://www.postman.com/igpsport/igpsport/overview>）同样未能读取正文。
9. 官方 GitHub 示例 `testIgpsportAuth` 的 README 是 `application/octet-stream`，**未能读取**；论坛用户称该示例「已是 9 年前的代码」。

**硅基**
10. 「Juggluco 的 **Sibionics Light** 选项 = 硅基轻享」是**推测**，未找到直接证据。
11. Juggluco 文档里硅基官方 App 包名 `com.sisensing.gs3` 与小米商店的 `com.sisensing.sisensingcgm` / `com.sisensing.eco` **对不上**，三者的对应关系未核实。
12. 硅基官方 App 是否有**报表导出 / 网页版数据下载 / 是否有隐藏的开放接口**，未找到公开资料。
13. GitHub Discussions（xDrip #3063、#3189）正文为 JS 渲染，**只取到页面骨架**，社区方案细节未核实。

**Keep**
14. Keep 是否有任何**未公开的 B 端合作接口**，无法排除。
15. Keep 与 Apple Health 的对接、以及 Keep 与 Health Connect 的关系，**均未找到官方证据**。
16. Gadgetbridge 支持的 **「Keep Health」穿戴品牌**与 Keep App 的关系未核实。
17. Keep 手动导出的**入口路径与文件格式**未核实。

**训记**
18. 训记官方 API 的**官方文档页面**未直接找到 —— 结论来自社区 Skill 源码（含硬编码域名与路径）+ 少数派实测描述，属于**两个独立的间接来源交叉验证**，可信度高但非官方文档。
19. 训记「买断版」的**具体购买方式与价格**未核实。
20. 手动导出的**文件格式**未核实。

**Health Connect / 通用**
21. Google 官方「Health Connect 可用性」页面（<https://developer.android.google.cn/health-and-fitness/health-connect/availability>）**正文未能渲染**，因此**国行 ROM 的预装/可用性没有官方一手结论**，本报告中的相关判断来自第三方博客与论坛。
22. 小米 / OPPO / vivo **国行**设备是否写入 Health Connect，**无实测数据**。
23. 我未能实测任何一个接口（无账号、无设备、无凭据）。**所有接口行为均来自文档/社区，未做真实调用验证。**
24. 本次调研未穷尽搜索「Keep 逆向项目」和「华为健康 App 内部 API 逆向项目」，不能断言它们不存在。

---

## 7. 附：本次调研的主要来源清单

- 华为官方：<https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/health-service-kit-guide> · <https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/health-application-qualifications> · <https://developer.huawei.com/consumer/cn/doc/hmscore-guides/auth-example-0000001054581058> · <https://developer.huawei.com/consumer/cn/doc/HMSCore-Guides/blood-glucose-0000001177423531> · <https://consumer.huawei.com/cn/support/content/zh-cn16044986/> · <https://consumer.huawei.com/cn/support/content/zh-cn01115094/>
- 硅基：<https://www.sisensing.com/> · <https://app.mi.com/details?id=com.sisensing.eco> · <https://www.juggluco.nl/Juggluco/sensors/> · <https://www.juggluco.nl/Jugglucohelp/SibionicsServer.html> · <http://wiki.aaps.app/en/latest/Getting-Started/CompatiblesCgms.html>
- iGPSPORT：<https://www.igpsport.com/au/support/app/openapi> · <https://www.postman.com/igpsport/igpsport/overview> · <https://github.com/igpsport/testIgpsportAuth> · <https://github.com/kamikadzem22/igpsport-unoffical-api> · <https://forum.intervals.icu/t/request-to-add-igpsport-integration/91944>
- 训记：<https://github.com/AkiraLan/xunji-skills> · <https://raw.githubusercontent.com/AkiraLan/xunji-skills/master/xunji/scripts/fetch_xunji_trains.py> · <https://github.com/Foveluy/Xunji-movements>
- Health Connect / 聚合：<https://gadgetbridge.org/basics/integrations/health-connect/> · <https://gadgetbridge.org/gadgets/bike-computers/igpsport/> · <https://gadgetbridge.org/basics/topics/huawei-honor/> · <https://github.com/oliexdev/openScale-sync> · <https://github.com/mcnaveen/health-connect-webhook>
- 生态综述（第三方，可信度中高，作者标注了实测范围）：<https://sspai.com/prime/story/how-to-obtain-data-for-agent-analysis>
