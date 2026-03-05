import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart' as drift;

import '../data/database/database.dart';

/// 数据导出/导入服务
class DataExportService {
  final AppDatabase db;
  
  DataExportService(this.db);
  
  /// 导出所有数据为 JSON
  Future<String> exportAllData() async {
    final data = <String, dynamic>{};
    
    // 导出血糖记录
    final bloodSugarRecords = await db.getAllBloodSugarRecords();
    data['blood_sugar'] = bloodSugarRecords.map((r) => {
      'id': r.id,
      'value': r.value,
      'unit': r.unit,
      'type': r.type,
      'recorded_at': r.recordedAt.toIso8601String(),
      'hours_after_meal': r.hoursAfterMeal,
      'meal_id': r.mealId,
      'note': r.note,
      'created_at': r.createdAt.toIso8601String(),
      'updated_at': r.updatedAt.toIso8601String(),
    }).toList();
    
    // 导出运动记录
    final exerciseRecords = await db.getAllExerciseRecords();
    data['exercise'] = exerciseRecords.map((r) => {
      'id': r.id,
      'type': r.type,
      'name': r.name,
      'duration': r.duration,
      'calories': r.calories,
      'heart_rate_avg': r.heartRateAvg,
      'heart_rate_max': r.heartRateMax,
      'started_at': r.startedAt.toIso8601String(),
      'ended_at': r.endedAt.toIso8601String(),
      'note': r.note,
      'created_at': r.createdAt.toIso8601String(),
    }).toList();
    
    // 导出饮食记录
    final mealRecords = await db.getAllMealRecords();
    data['meal'] = [];
    for (final meal in mealRecords) {
      final foods = await db.getFoodItemsByMealId(meal.id);
      (data['meal'] as List).add({
        'id': meal.id,
        'type': meal.type,
        'recorded_at': meal.recordedAt.toIso8601String(),
        'image_path': meal.imagePath,
        'note': meal.note,
        'created_at': meal.createdAt.toIso8601String(),
        'foods': foods.map((f) => {
          'name': f.name,
          'amount': f.amount,
          'unit': f.unit,
          'carbs': f.carbs,
        }).toList(),
      });
    }
    
    // 添加导出时间
    data['exported_at'] = DateTime.now().toIso8601String();
    data['app_version'] = '0.1.0';
    
    return const JsonEncoder.withIndent('  ').convert(data);
  }
  
  /// 保存导出文件
  Future<String> saveExportToFile() async {
    final jsonData = await exportAllData();
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${directory.path}/glucocontrol_export_$timestamp.json');
    await file.writeAsString(jsonData);
    debugPrint('数据已导出到: ${file.path}');
    return file.path;
  }
  
  /// 导入数据（从 JSON 字符串）
  Future<int> importFromJson(String jsonString) async {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    int importedCount = 0;
    
    // 导入血糖记录
    if (data['blood_sugar'] != null) {
      for (final record in data['blood_sugar'] as List) {
        try {
          await db.insertBloodSugarRecord(
            BloodSugarRecordsCompanion.insert(
              value: (record['value'] as num).toDouble(),
              type: record['type'] as String,
              recordedAt: DateTime.parse(record['recorded_at'] as String),
              hoursAfterMeal: drift.Value(record['hours_after_meal'] as double?),
              note: drift.Value(record['note'] as String?),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          importedCount++;
        } catch (e) {
          debugPrint('导入血糖记录失败: $e');
        }
      }
    }
    
    // 导入运动记录
    if (data['exercise'] != null) {
      for (final record in data['exercise'] as List) {
        try {
          await db.insertExerciseRecord(
            ExerciseRecordsCompanion.insert(
              type: record['type'] as String,
              name: record['name'] as String,
              duration: record['duration'] as int,
              calories: drift.Value(record['calories'] as int?),
              heartRateAvg: drift.Value(record['heart_rate_avg'] as int?),
              heartRateMax: drift.Value(record['heart_rate_max'] as int?),
              startedAt: DateTime.parse(record['started_at'] as String),
              endedAt: DateTime.parse(record['ended_at'] as String),
              note: drift.Value(record['note'] as String?),
              createdAt: DateTime.now(),
            ),
          );
          importedCount++;
        } catch (e) {
          debugPrint('导入运动记录失败: $e');
        }
      }
    }
    
    // 导入饮食记录
    if (data['meal'] != null) {
      for (final record in data['meal'] as List) {
        try {
          final mealId = await db.insertMealRecord(
            MealRecordsCompanion.insert(
              type: record['type'] as String,
              recordedAt: DateTime.parse(record['recorded_at'] as String),
              imagePath: drift.Value(record['image_path'] as String?),
              note: drift.Value(record['note'] as String?),
              createdAt: DateTime.now(),
            ),
          );
          
          // 导入食物项
          if (record['foods'] != null) {
            for (final food in record['foods'] as List) {
              await db.insertFoodItem(
                FoodItemsCompanion.insert(
                  mealId: mealId,
                  name: food['name'] as String,
                  amount: (food['amount'] as num).toDouble(),
                  carbs: drift.Value(food['carbs'] as double?),
                ),
              );
            }
          }
          importedCount++;
        } catch (e) {
          debugPrint('导入饮食记录失败: $e');
        }
      }
    }
    
    return importedCount;
  }
}
