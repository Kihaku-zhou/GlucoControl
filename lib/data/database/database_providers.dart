import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database.dart';

/// 全局数据库实例
AppDatabase? _globalDb;

/// 数据库实例 Provider
final databaseProvider = Provider<AppDatabase>((ref) {
  if (_globalDb != null) {
    return _globalDb!;
  }
  
  debugPrint('===== Initializing database =====');
  try {
    _globalDb = AppDatabase();
    debugPrint('Database created successfully');
    
    ref.onDispose(() {
      debugPrint('Database disposed');
      _globalDb?.close();
      _globalDb = null;
    });
    
    return _globalDb!;
  } catch (e, stack) {
    debugPrint('Database initialization FAILED: $e');
    debugPrint('Stack: $stack');
    rethrow;
  }
});

/// 强制重新创建数据库（用于错误恢复）
final recreateDatabaseProvider = Provider<void>((ref) {
  _globalDb?.close();
  _globalDb = null;
  ref.invalidate(databaseProvider);
});

/// SharedPreferences Provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('需要在 main.dart 中初始化');
});

///血糖相关 Providers = ==================== ===================

/// 血糖记录列表 Provider
final bloodSugarRecordsProvider = FutureProvider<List<BloodSugarRecord>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAllBloodSugarRecords();
});

/// 按日期范围获取血糖记录
final bloodSugarRecordsByDateRangeProvider = FutureProvider.family<List<BloodSugarRecord>, DateRange>((ref, range) async {
  final db = ref.watch(databaseProvider);
  return db.getBloodSugarRecordsByDateRange(range.start, range.end);
});

/// 日期范围类
class DateRange {
  final DateTime start;
  final DateTime end;
  
  DateRange({required this.start, required this.end});
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;
  
  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}

/// ==================== 运动相关 Providers ====================

/// 运动记录列表 Provider
final exerciseRecordsProvider = FutureProvider<List<ExerciseRecord>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAllExerciseRecords();
});

/// 运动目标 Providers
final weeklyExerciseGoalProvider = StateProvider<int>((ref) => 150); // 每周目标分钟数
final weeklyExerciseDaysGoalProvider = StateProvider<int>((ref) => 3); // 每周目标运动天数
final dailyCalorieGoalProvider = StateProvider<int>((ref) => 300); // 每日卡路里目标

/// 按日期范围获取运动记录
final exerciseRecordsByDateRangeProvider = FutureProvider.family<List<ExerciseRecord>, DateRange>((ref, range) async {
  final db = ref.watch(databaseProvider);
  return db.getExerciseRecordsByDateRange(range.start, range.end);
});

/// ==================== 训练计划 Providers ====================

/// 训练计划列表 Provider
final trainingPlansProvider = FutureProvider<List<TrainingPlan>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAllTrainingPlans();
});

/// 训练计划动作 Provider
final trainingPlanExercisesProvider = FutureProvider.family<List<TrainingPlanExercise>, int>((ref, planId) async {
  final db = ref.watch(databaseProvider);
  return db.getExercisesByPlanId(planId);
});

/// 当前选择的训练计划
final selectedTrainingPlanProvider = StateProvider<TrainingPlan?>((ref) => null);

/// ==================== 体测记录 Providers ====================

/// 体测记录列表 Provider
final bodyMeasurementsProvider = FutureProvider<List<BodyMeasurement>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAllBodyMeasurements();
});

/// 最新体测记录 Provider
final latestBodyMeasurementProvider = FutureProvider<BodyMeasurement?>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getLatestBodyMeasurement();
});

/// 按日期范围获取体测记录
final bodyMeasurementsByDateRangeProvider = FutureProvider.family<List<BodyMeasurement>, DateRange>((ref, range) async {
  final db = ref.watch(databaseProvider);
  return db.getBodyMeasurementsByDateRange(range.start, range.end);
});

/// ==================== 饮食相关 Providers ====================

/// 饮食记录列表 Provider
final mealRecordsProvider = FutureProvider<List<MealRecord>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAllMealRecords();
});

/// 按日期范围获取饮食记录
final mealRecordsByDateRangeProvider = FutureProvider.family<List<MealRecord>, DateRange>((ref, range) async {
  final db = ref.watch(databaseProvider);
  return db.getMealRecordsByDateRange(range.start, range.end);
});

/// ==================== 设置 Providers ====================

/// 血糖单位设置
final bloodSugarUnitProvider = StateProvider<String>((ref) => 'mg/dL');

/// 血糖安全范围最小值
final safeRangeMinProvider = StateProvider<double>((ref) => 70.0);

/// 血糖安全范围最大值
final safeRangeMaxProvider = StateProvider<double>((ref) => 140.0);

/// WebDAV 是否启用
final webdavEnabledProvider = StateProvider<bool>((ref) => false);

/// AI API 是否启用
final aiApiEnabledProvider = StateProvider<bool>((ref) => false);

/// 通知设置 Providers
final reminderEnabledProvider = StateProvider<bool>((ref) => false);
final morningReminderEnabledProvider = StateProvider<bool>((ref) => false);
final eveningReminderEnabledProvider = StateProvider<bool>((ref) => false);
final morningReminderTimeProvider = StateProvider<TimeOfDay>((ref) => const TimeOfDay(hour: 7, minute: 0));
final eveningReminderTimeProvider = StateProvider<TimeOfDay>((ref) => const TimeOfDay(hour: 21, minute: 0));
final afterMealReminderEnabledProvider = StateProvider<bool>((ref) => false);
final afterMealReminderHoursProvider = StateProvider<int>((ref) => 2);

/// 主题模式 Provider
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// AI 对话列表
final aiConversationsProvider = FutureProvider<List<AIConversation>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAIConversations();
});

/// AI 对话消息
final aiMessagesProvider = FutureProvider.family<List<AIMessage>, int>((ref, conversationId) async {
  final db = ref.watch(databaseProvider);
  return db.getAIMessages(conversationId);
});
