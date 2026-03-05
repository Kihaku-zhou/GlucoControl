import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

/// 血糖记录表
class BloodSugarRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get value => real()();
  TextColumn get unit => text().withDefault(const Constant('mg/dL'))();
  TextColumn get type => text()(); // fasting, post_meal, custom
  DateTimeColumn get recordedAt => dateTime()();
  RealColumn get hoursAfterMeal => real().nullable()();
  IntColumn get mealId => integer().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// 运动记录表
class ExerciseRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // aerobic, anaerobic
  TextColumn get name => text()();
  IntColumn get duration => integer()(); // 分钟
  IntColumn get calories => integer().nullable()();
  IntColumn get heartRateAvg => integer().nullable()();
  IntColumn get heartRateMax => integer().nullable()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

/// 力量训练表
class StrengthTrainings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get exerciseId => integer().references(ExerciseRecords, #id)();
  TextColumn get device => text()(); // 哑铃、杠铃、器械等
  TextColumn get movement => text()(); // 动作名称
  IntColumn get sets => integer()();
  IntColumn get reps => integer()();
  RealColumn get weight => real().nullable()();
  IntColumn get restSeconds => integer().nullable()();
  TextColumn get trainingType => text().withDefault(const Constant('strength'))(); // strength: 力量, endurance: 计时耐力
  IntColumn get durationSeconds => integer().nullable()(); // 计时耐力训练的时长（秒）
}

/// 训练计划表
class TrainingPlans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()(); // 计划名称
  TextColumn get description => text().nullable()(); // 计划描述
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// 训练计划动作表
class TrainingPlanExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get planId => integer().references(TrainingPlans, #id)();
  TextColumn get device => text()(); // 器械类型
  TextColumn get movement => text()(); // 动作名称
  IntColumn get targetSets => integer()(); // 目标组数
  IntColumn get targetReps => integer()(); // 目标次数
  RealColumn get targetWeight => real().nullable()(); // 目标重量
  IntColumn get restSeconds => integer().nullable()(); // 休息时间
  TextColumn get trainingType => text().withDefault(const Constant('strength'))(); // strength/endurance
  IntColumn get orderIndex => integer().withDefault(const Constant(0))(); // 排序
}

/// 饮食记录表
class MealRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // breakfast, lunch, dinner, snack
  DateTimeColumn get recordedAt => dateTime()();
  TextColumn get imagePath => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

/// 食物项表
class FoodItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get mealId => integer().references(MealRecords, #id)();
  TextColumn get name => text()();
  RealColumn get amount => real()();
  TextColumn get unit => text().withDefault(const Constant('g'))();
  RealColumn get carbs => real().nullable()(); // 碳水克数
}

/// 应用设置表
class AppSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text().unique()();
  TextColumn get value => text()();
}

@DriftDatabase(tables: [
  BloodSugarRecords,
  ExerciseRecords,
  StrengthTrainings,
  MealRecords,
  FoodItems,
  AppSettings,
  TrainingPlans,
  TrainingPlanExercises,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ==================== 血糖记录 CRUD ====================
  
  Future<List<BloodSugarRecord>> getAllBloodSugarRecords() =>
      select(bloodSugarRecords).get();

  Future<List<BloodSugarRecord>> getBloodSugarRecordsByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return (select(bloodSugarRecords)
          ..where((t) => t.recordedAt.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)]))
        .get();
  }

  Future<int> insertBloodSugarRecord(BloodSugarRecordsCompanion record) =>
      into(bloodSugarRecords).insert(record);

  Future<bool> updateBloodSugarRecord(BloodSugarRecord record) =>
      update(bloodSugarRecords).replace(record);

  Future<int> deleteBloodSugarRecord(int id) =>
      (delete(bloodSugarRecords)..where((t) => t.id.equals(id))).go();

  // ==================== 运动记录 CRUD ====================
  
  Future<List<ExerciseRecord>> getAllExerciseRecords() =>
      select(exerciseRecords).get();

  Future<List<ExerciseRecord>> getExerciseRecordsByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return (select(exerciseRecords)
          ..where((t) => t.startedAt.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .get();
  }

  Future<int> insertExerciseRecord(ExerciseRecordsCompanion record) =>
      into(exerciseRecords).insert(record);

  Future<bool> updateExerciseRecord(ExerciseRecord record) =>
      update(exerciseRecords).replace(record);

  Future<int> deleteExerciseRecord(int id) =>
      (delete(exerciseRecords)..where((t) => t.id.equals(id))).go();

  // ==================== 力量训练 CRUD ====================
  
  Future<List<StrengthTraining>> getStrengthTrainingsByExerciseId(int exerciseId) {
    return (select(strengthTrainings)
          ..where((t) => t.exerciseId.equals(exerciseId)))
        .get();
  }

  Future<int> insertStrengthTraining(StrengthTrainingsCompanion record) =>
      into(strengthTrainings).insert(record);

  Future<int> deleteStrengthTraining(int id) =>
      (delete(strengthTrainings)..where((t) => t.id.equals(id))).go();

  // ==================== 饮食记录 CRUD ====================
  
  Future<List<MealRecord>> getAllMealRecords() =>
      select(mealRecords).get();

  Future<List<MealRecord>> getMealRecordsByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return (select(mealRecords)
          ..where((t) => t.recordedAt.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)]))
        .get();
  }

  Future<int> insertMealRecord(MealRecordsCompanion record) =>
      into(mealRecords).insert(record);

  Future<bool> updateMealRecord(MealRecord record) =>
      update(mealRecords).replace(record);

  Future<int> deleteMealRecord(int id) =>
      (delete(mealRecords)..where((t) => t.id.equals(id))).go();

  // ==================== 食物项 CRUD ====================
  
  Future<List<FoodItem>> getFoodItemsByMealId(int mealId) {
    return (select(foodItems)..where((t) => t.mealId.equals(mealId))).get();
  }

  Future<int> insertFoodItem(FoodItemsCompanion item) =>
      into(foodItems).insert(item);

  Future<int> deleteFoodItemsByMealId(int mealId) =>
      (delete(foodItems)..where((t) => t.mealId.equals(mealId))).go();

  // ==================== 训练计划 CRUD ====================
  
  Future<List<TrainingPlan>> getAllTrainingPlans() =>
      (select(trainingPlans)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();

  Future<int> insertTrainingPlan(TrainingPlansCompanion plan) =>
      into(trainingPlans).insert(plan);

  Future<bool> updateTrainingPlan(TrainingPlan plan) =>
      update(trainingPlans).replace(plan);

  Future<int> deleteTrainingPlan(int id) async {
    // 先删除计划中的动作
    await (delete(trainingPlanExercises)..where((t) => t.planId.equals(id))).go();
    // 再删除计划
    return (delete(trainingPlans)..where((t) => t.id.equals(id))).go();
  }

  // ==================== 训练计划动作 CRUD ====================
  
  Future<List<TrainingPlanExercise>> getExercisesByPlanId(int planId) =>
      (select(trainingPlanExercises)
        ..where((t) => t.planId.equals(planId))
        ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
      .get();

  Future<int> insertTrainingPlanExercise(TrainingPlanExercisesCompanion exercise) =>
      into(trainingPlanExercises).insert(exercise);

  Future<int> deleteTrainingPlanExercise(int id) =>
      (delete(trainingPlanExercises)..where((t) => t.id.equals(id))).go();

  Future<int> deleteExercisesByPlanId(int planId) =>
      (delete(trainingPlanExercises)..where((t) => t.planId.equals(planId))).go();

  // ==================== 设置 ====================
  
  Future<String?> getSetting(String key) async {
    final result = await (select(appSettings)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return result?.value;
  }

  Future<void> setSetting(String key, String value) async {
    await into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion(
        key: Value(key),
        value: Value(value),
      ),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    if (kIsWeb) {
      // Web 平台使用内存数据库（仅供测试 UI）
      // 实际项目中可以用 Firebase 或其他 Web 数据库
      throw UnimplementedError('Web 平台请使用 WebDatabaseStub');
    }
    
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'glucocontrol.db'));
    return NativeDatabase.createInBackground(file);
  });
}
