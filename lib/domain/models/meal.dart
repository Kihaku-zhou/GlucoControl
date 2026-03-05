import 'package:freezed_annotation/freezed_annotation.dart';

import 'food_item.dart';

part 'meal.freezed.dart';

@freezed
class Meal with _$Meal {
  const factory Meal({
    int? id,
    required String type,
    required DateTime recordedAt,
    required List<FoodItem> foods,
    String? imagePath,
    String? note,
    DateTime? createdAt,
  }) = _Meal;

  factory Meal.create({
    required String type,
    List<FoodItem>? foods,
    String? imagePath,
    String? note,
    DateTime? recordedAt,
  }) {
    return Meal(
      id: null,
      type: type,
      recordedAt: recordedAt ?? DateTime.now(),
      foods: foods ?? [],
      imagePath: imagePath,
      note: note,
      createdAt: DateTime.now(),
    );
  }
  
  /// 计算总碳水
  static double calculateTotalCarbs(List<FoodItem> foods) {
    return foods.fold(0.0, (sum, food) => sum + (food.carbs ?? 0));
  }
}