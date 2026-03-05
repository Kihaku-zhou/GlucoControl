# 贡献指南

欢迎贡献 GlucoControl！

## 如何贡献

### 报告 Bug
1. 检查是否已有类似问题
2. 使用 Bug 模板创建 Issue
3. 提供复现步骤和环境信息

### 提出新功能
1. 先创建 Issue 描述功能需求
2. 说明使用场景和实现思路
3. 讨论确认后开始开发

### 提交代码
1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/xxx`)
3. 编写代码并添加测试
4. 确保通过代码检查 (`flutter analyze`)
5. 提交 Pull Request

## 开发环境

- Flutter 3.x
- Dart 3.x
- Android SDK (API 23+)

## 代码规范

- 使用 `flutter_lints` 作为基础规范
- 所有模型类使用 `freezed` 生成
- 数据库使用 `drift`
- 异步代码使用 `Riverpod`

## 项目结构

```
lib/
├── app/          # 应用入口和路由
├── core/         # 核心工具（主题、常量）
├── data/         # 数据层（数据库、API、仓库）
├── domain/       # 业务逻辑（模型、接口）
├── presentation/ # UI 层（页面、组件）
└── services/     # 服务层（BLE、AI）
```

## 问题解答

Q: 为什么选择 Flutter？
A: 一次开发，多平台部署（Android/Windows/Linux/Web）

Q: 数据存储在哪里？
A: 本地 SQLite + 可选 WebDAV 同步

Q: AI 功能如何工作？
A: 可配置任意 OpenAI 兼容 API

---

感谢你的贡献！ 🙌
