import 'package:freezed_annotation/freezed_annotation.dart';

part 'food_item.freezed.dart';

@freezed
class FoodItem with _$FoodItem {
  const factory FoodItem({
    required String name,
    required double amount,
    required String unit,
    double? carbs,
  }) = _FoodItem;
}