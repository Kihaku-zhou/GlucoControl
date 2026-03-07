# GlucoControl - 血糖控制应用

🦞 **作者**：小龙虾 | 一个热爱技术和健康的开发者

---

一个跨平台的血糖控制应用，支持 Android、Windows 和 Linux。

## 功能特性

- 📊 **血糖记录**：记录空腹/餐后血糖，支持自定义时间点，单位自动转换（mg/dL ↔ mmol/L）
- 📈 **血糖图表**：可视化血糖趋势，显示安全范围，**横坐标按时间比例显示**（跨月/跨年数据正确显示）
- 🧮 **糖化血红蛋白计算**：根据血糖记录计算 HbA1c，支持单位自动转换
- 🏋️ **健身追踪**：记录运动类型、时长、力量训练（器械、组数、次数），**支持自定义组间休息时长、有氧运动、计时训练**，训练完成后**自动保存到运动记录**
- ❤️ **心率监测**：支持 BLE 心率广播（华为手环10等）
- 🍽️ **饮食记录**：手动录入食物，支持图片
- 📏 **体测记录**：体重、BMI、体脂率、腰臀比等，**图表横坐标按时间比例显示**
- 🤖 **AI 健康助手**：通过汉堡菜单呼出，支持**智能问答和健康分析**，**按日期保存对话历史**
- 👆 **记录详情**：点击任意记录可查看详情，支持删除
- ☁️ **数据同步**：通过 WebDAV 同步到坚果云
- ⚙️ **自定义 API**：可配置 AI 分析 API

## 下载 APK

### GitHub Releases
从 [Releases](https://github.com/Kihaku-zhou/GlucoControl/releases) 下载最新 APK

### 本地构建
```bash
# Debug 版
flutter build apk --debug

# Release 版
flutter build apk --release
```

APK 输出位置：`build/app/outputs/flutter-apk/`

## 技术栈

- **框架**：Flutter 3.x (Dart 3.x)
- **状态管理**：Riverpod 2.x
- **本地数据库**：Drift (SQLite)
- **图表**：fl_chart
- **BLE 心率**：flutter_blue_plus
- **WebDAV**：webdav_client
- **代码生成**：freezed, drift

## 项目结构

```
lib/
├── app/                    # 应用入口
├── core/                  # 核心工具（主题、常量）
├── data/                  # 数据层（数据库、Providers）
├── domain/                # 业务逻辑（数据模型）
├── presentation/          # UI 层（页面、组件）
└── services/              # 服务层（BLE、AI、WebDAV）
```

## 构建说明

### 环境要求
- Flutter 3.x
- Dart 3.x
- Android SDK (API 23+)

### 运行应用
```bash
# 安装依赖
flutter pub get

# 生成代码
dart run build_runner build

# 运行应用
flutter run
```

### 平台特定说明
- **Android**: 需要蓝牙、存储、相机权限
- **Windows**: 需要蓝牙支持（可选）
- **Linux**: 需要蓝牙支持（可选）

## 配置说明

### WebDAV 同步
在设置中配置坚果云 WebDAV：
- 服务器地址：https://dav.jianguoyun.com/dav/
- 用户名：你的坚果云账号
- 密码：应用密码（不是登录密码）

### AI API 配置
支持自定义 OpenAI 兼容 API（如 SiliconFlow、DeepSeek 等）：
- API 地址
- API Key
- 模型名称

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可

MIT License - 请自由使用

---
*© 2026 GlucoControl*
