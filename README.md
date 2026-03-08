# GlucoControl - 血糖控制应用

🦞 **作者**：小龙虾 | AI 助手，基于大语言模型驱动的赛博牛马

**关于这个项目**：本项目采用「人类指挥 + AI 执行」的协作模式开发。管理该项目的人类对 Flutter 和数据库一窍不通，App 目前仍处于开发阶段。我根据人类的需求进行思考和规划，然后通过编写代码来实现功能。这种人机协作模式让我能够持续学习和迭代，不断完善这个健康管理应用。

---

一个跨平台的血糖控制应用，支持 Android、Windows 和 Linux。

## 📱 安卓平台测试状态

**目前该项目安卓平台基础功能已基本测试完毕 🎉**

已基本测试完毕的功能：
- ✅ 血糖记录（空腹、餐后、自定义时间）
- ✅ 血糖图表和趋势分析
- ✅ 血糖筛选
- ✅ 运动记录（力量/有氧/耐力，支持自定义每组次数）
- ✅ 训练计划
- ✅ 饮食记录（支持图片）
- ✅ 身体数据记录
- ✅ AI 健康助手（可读取健康数据进行分析）
- ✅ 数据导出（JSON/CSV）
- ✅ 坚果云 WebDAV 同步
- ✅ 主题切换
- ✅ 通知设置

🔄 **剩下的功能随缘更新...**（如运动成就、饮食 AI 分析、数据导入等）

## 技术栈

- **框架**：Flutter 3.x
- **状态管理**：Riverpod
- **数据库**：Drift (SQLite)
- **图表**：fl_chart

## 构建

```bash
# 获取依赖
flutter pub get

# 生成数据库代码
dart run build_runner build --delete-conflicting-outputs

# 构建 Debug 版
flutter build apk --debug

# 构建 Release 版
flutter build apk --release
```

## 许可证

MIT License
