import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database.dart';

/// 数据库实例 Provider
final databaseProvider = Provider<AppDatabase>((ref) {
  debugPrint('===== Initializing database =====');
  try {
    final db = AppDatabase();
    debugPrint('Database created successfully');
    ref.onDispose(() {
      debugPrint('Database disposed');
      db.close();
    });
    return db;
  } catch (e, stack) {
    debugPrint('Database initialization FAILED: $e');
    debugPrint('Stack: $stack');
    rethrow;
  }
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

/// 按日期范围获取运动记录
final exerciseRecordsByDateRangeProvider = FutureProvider.family<List<ExerciseRecord>, DateRange>((ref, range) async {
  final db = ref.watch(databaseProvider);
  return db.getExerciseRecordsByDateRange(range.start, range.end);
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
