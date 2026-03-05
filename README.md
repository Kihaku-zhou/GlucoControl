# GlucoControl - 血糖控制应用

一个跨平台的血糖控制应用，支持 Android、Windows 和 Linux。

## 功能特性

- 📊 **血糖记录**：记录空腹/餐后血糖，支持自定义时间点
- 📈 **血糖图表**：可视化血糖趋势，显示安全范围
- 🧮 **糖化血红蛋白计算**：根据血糖记录计算 HbA1c
- 🏋️ **健身追踪**：记录运动类型、时长、力量训练（器械、组数、次数）
- ❤️ **心率监测**：支持 BLE 心率广播（华为手环10等）
- 🍽️ **饮食记录**：手动录入食物，未来支持 AI 识图
- 🤖 **AI 分析**：基于饮食和运动分析血糖变化
- ☁️ **数据同步**：通过 WebDAV 同步到坚果云
- ⚙️ **自定义 API**：可配置 AI 分析 API

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
│   ├── router.dart        # 路由配置
│   └── ...
├── core/                  # 核心工具
│   ├── theme.dart         # 主题配置
│   ├── constants.dart     # 常量定义
│   └── ...
├── data/                  # 数据层
│   ├── database/          # 数据库配置
│   ├── repositories/      # 数据仓库
│   ├── api/              # API 客户端
│   └── webdav/           # WebDAV 同步
├── domain/                # 业务逻辑
│   ├── models/           # 数据模型
│   │   ├── blood_sugar.dart
│   │   ├── exercise.dart
│   │   ├── meal.dart
│   │   └── ...
│   └── repositories/      # 仓库接口
├── presentation/         # UI 层
│   ├── screens/          # 页面
│   │   ├── home_screen.dart
│   │   └── ...
│   ├── widgets/          # 可复用组件
│   └── ...
└── services/             # 服务层
    ├── ble/              # BLE 心率服务
    ├── ai/               # AI 分析服务
    └── notification/     # 通知服务
```

## 开发状态

### ✅ 已完成
- [x] 项目架构设计
- [x] 规格文档 (SPEC.md)
- [x] 基础 Flutter 项目搭建
- [x] 核心主题和常量
- [x] 数据模型定义
- [x] 基础路由配置
- [x] 主页面框架
- [x] Android 权限配置

### 🔄 进行中
- [ ] 数据库集成 (Drift)
- [ ] 血糖记录页面
- [ ] BLE 心率服务
- [ ] WebDAV 同步
- [ ] 图表显示

## 构建说明

### 环境要求
- Flutter 3.x
- Dart 3.x
- Android SDK (Android 6.0+)

### 运行应用
```bash
# 安装依赖
flutter pub get

# 生成代码
flutter pub run build_runner build --delete-conflicting-outputs

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
- 密码：应用密码

### AI API 配置
支持自定义 OpenAI 兼容 API：
- API 地址
- API Key
- 模型名称

## 许可

本项目仅供学习参考，请勿用于商业用途。

---
*开发中...*