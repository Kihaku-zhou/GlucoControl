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
  TextColumn get type => text()(); // aerobic, anaerobic, endurance
  TextColumn get name => text()();
  IntColumn get duration => integer()(); // 分钟
  RealColumn get distance => real().nullable()(); // 距离(公里)
  RealColumn get elevation => real().nullable()(); // 爬升(米)
  RealColumn get power => real().nullable()(); // 平均功率(瓦)
  IntColumn get sets => integer().nullable()(); // 组数
  RealColumn get weight => real().nullable()(); // 重量(kg)
  IntColumn get seconds => integer().nullable()(); // 耐力训练时长(秒)
  TextColumn get repsList => text().nullable()(); // 每组次数，逗号分隔，如 "12,10,8,6"
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
  IntColumn get targetReps => integer()(); // 目标次数（保留兼容）
  TextColumn get targetRepsList => text().nullable()(); // 每组次数列表，JSON格式如 "[12,10,8,6]"
  RealColumn get targetWeight => real().nullable()(); // 目标重量
  IntColumn get restSeconds => integer().nullable()(); // 休息时间
  TextColumn get trainingType => text().withDefault(const Constant('strength'))(); // strength/endurance
  IntColumn get orderIndex => integer().withDefault(const Constant(0))(); // 排序
}

/// 体测记录表
class BodyMeasurements extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get weight => real().nullable()(); // 体重 (kg)
  RealColumn get height => real().nullable()(); // 身高 (cm)
  RealColumn get bodyFat => real().nullable()(); // 体脂率 (%)
  RealColumn get muscleMass => real().nullable()(); // 肌肉量 (kg)
  RealColumn get chest => real().nullable()(); // 胸围 (cm)
  RealColumn get waist => real().nullable()(); // 腰围 (cm)
  RealColumn get hip => real().nullable()(); // 臀围 (cm)
  RealColumn get thighLeft => real().nullable()(); // 左大腿围 (cm)
  RealColumn get thighRight => real().nullable()(); // 右大腿围 (cm)
  RealColumn get armLeft => real().nullable()(); // 左臂围 (cm)
  RealColumn get armRight => real().nullable()(); // 右臂围 (cm)
  RealColumn get neck => real().nullable()(); // 颈围 (cm)
  RealColumn get bmi => real().nullable()(); // BMI (自动计算)
  RealColumn get waistHipRatio => real().nullable()(); // 腰臀比 (自动计算)
  TextColumn get note => text().nullable()(); // 备注
  TextColumn get imagePath => text().nullable()(); // 图片路径
  DateTimeColumn get measuredAt => dateTime()(); // 测量时间
  DateTimeColumn get createdAt => dateTime()();
}

/// 饮食记录表
class MealRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // breakfast, lunch, dinner, snack
  DateTimeColumn get recordedAt => dateTime()();
  TextColumn get imagePaths => text().nullable()(); // 多张图片，逗号分隔
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

/// AI 对话表
class AIConversations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

/// AI 消息表
class AIMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get conversationId => integer().references(AIConversations, #id)();
  TextColumn get role => text()(); // user, assistant
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime()();
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
  BodyMeasurements,
  AIConversations,
  AIMessages,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // 创建训练计划表
          await m.createTable(trainingPlans);
          await m.createTable(trainingPlanExercises);
          // 创建体测记录表
          await m.createTable(bodyMeasurements);
        }
      },
    );
  }

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

  /// 批量转换血糖单位
  Future<int> convertBloodSugarUnit(String fromUnit, String toUnit) async {
    if (fromUnit == toUnit) return 0;
    
    final records = await getAllBloodSugarRecords();
    int count = 0;
    
    for (final record in records) {
      double newValue = record.value;
      
      // mg/dL 转 mmol/L: /18.0182
      if (fromUnit == 'mg/dL' && toUnit == 'mmol/L') {
        newValue = record.value / 18.0182;
      }
      // mmol/L 转 mg/dL: *18.0182
      else if (fromUnit == 'mmol/L' && toUnit == 'mg/dL') {
        newValue = record.value * 18.0182;
      }
      else {
        continue;
      }
      
      await updateBloodSugarRecord(record.copyWith(
        value: newValue,
        unit: toUnit,
        updatedAt: DateTime.now(),
      ));
      count++;
    }
    
    return count;
  }

  Future<int> insertBloodSugarRecord(BloodSugarRecordsCompanion record) =>
      into(bloodSugarRecords).insert(record);

  Future<bool> updateBloodSugarRecord(BloodSugarRecord record) =>
      update(bloodSugarRecords).replace(record);

  Future<int> deleteBloodSugarRecord(int id) =>
      (delete(bloodSugarRecords)..where((t) => t.id.equals(id))).go();

  /// 清理指定日期之前的所有数据
  Future<int> clearRecordsBeforeDate(DateTime date) async {
    int count = 0;
    
    // 删除血糖记录
    count += await (delete(bloodSugarRecords)
      ..where((t) => t.recordedAt.isSmallerThanValue(date)))
        .go();
    
    // 删除运动记录
    count += await (delete(exerciseRecords)
      ..where((t) => t.startedAt.isSmallerThanValue(date)))
        .go();
    
    // 删除饮食记录
    count += await (delete(mealRecords)
      ..where((t) => t.recordedAt.isSmallerThanValue(date)))
        .go();
    
    return count;
  }

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

  // ==================== 体测记录 CRUD ====================
  
  Future<List<BodyMeasurement>> getAllBodyMeasurements() =>
      (select(bodyMeasurements)..orderBy([(t) => OrderingTerm.desc(t.measuredAt)])).get();

  Future<List<BodyMeasurement>> getBodyMeasurementsByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return (select(bodyMeasurements)
          ..where((t) => t.measuredAt.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.desc(t.measuredAt)]))
        .get();
  }

  /// 获取最新的体测记录
  Future<BodyMeasurement?> getLatestBodyMeasurement() async {
    final results = await (select(bodyMeasurements)
          ..orderBy([(t) => OrderingTerm.desc(t.measuredAt)])
          ..limit(1))
        .get();
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> insertBodyMeasurement(BodyMeasurementsCompanion record) =>
      into(bodyMeasurements).insert(record);

  Future<bool> updateBodyMeasurement(BodyMeasurement record) =>
      update(bodyMeasurements).replace(record);

  Future<int> deleteBodyMeasurement(int id) =>
      (delete(bodyMeasurements)..where((t) => t.id.equals(id))).go();

  // ==================== AI 对话 ====================
  
  Future<int> insertAIConversation(AIConversationsCompanion conversation) =>
      into(aIConversations).insert(conversation);

  Future<List<AIConversation>> getAIConversations() =>
      (select(aIConversations)..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).get();

  Future<AIConversation?> getAIConversation(int id) =>
      (select(aIConversations)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<bool> updateAIConversation(AIConversation conversation) =>
      update(aIConversations).replace(conversation);

  Future<int> deleteAIConversation(int id) async {
    // 先删除对话中的所有消息
    await (delete(aIMessages)..where((t) => t.conversationId.equals(id))).go();
    // 再删除对话
    return (delete(aIConversations)..where((t) => t.id.equals(id))).go();
  }

  Future<int> insertAIMessage(AIMessagesCompanion message) =>
      into(aIMessages).insert(message);

  Future<List<AIMessage>> getAIMessages(int conversationId) =>
      (select(aIMessages)
            ..where((t) => t.conversationId.equals(conversationId))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  Future<int> deleteAIMessages(int conversationId) =>
      (delete(aIMessages)..where((t) => t.conversationId.equals(conversationId))).go();

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
