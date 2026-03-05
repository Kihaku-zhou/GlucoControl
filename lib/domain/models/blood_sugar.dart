import 'package:freezed_annotation/freezed_annotation.dart';

part 'blood_sugar.freezed.dart';

@freezed
class BloodSugar with _$BloodSugar {
  const factory BloodSugar({
    int? id,
    required double value,
    required String unit,
    required String type,
    required DateTime recordedAt,
    double? hoursAfterMeal,
    int? mealId,
    String? note,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _BloodSugar;

  factory BloodSugar.create({
    required double value,
    required String unit,
    required String type,
    DateTime? recordedAt,
    double? hoursAfterMeal,
    int? mealId,
    String? note,
  }) {
    final now = DateTime.now();
    return BloodSugar(
      id: null,
      value: value,
      unit: unit,
      type: type,
      recordedAt: recordedAt ?? now,
      hoursAfterMeal: hoursAfterMeal,
      mealId: mealId,
      note: note,
      createdAt: now,
      updatedAt: now,
    );
  }
  
  /// 检查是否为正常范围
  bool isNormal(double min, double max) {
    return value >= min && value <= max;
  }
  
  /// 转换为另一种单位
  BloodSugar convertUnit(String newUnit) {
    if (unit == newUnit) return this;
    
    double newValue;
    if (unit == 'mg/dL' && newUnit == 'mmol/L') {
      newValue = value / 18.0182;
    } else if (unit == 'mmol/L' && newUnit == 'mg/dL') {
      newValue = value * 18.0182;
    } else {
      throw ArgumentError('不支持的单位转换: $unit -> $newUnit');
    }
    
    return copyWith(value: newValue, unit: newUnit);
  }
}