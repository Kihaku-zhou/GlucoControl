import 'package:freezed_annotation/freezed_annotation.dart';

part 'exercise.freezed.dart';

@freezed
class Exercise with _$Exercise {
  const factory Exercise({
    int? id,
    required String type,
    required String name,
    required int duration,
    int? calories,
    int? heartRateAvg,
    int? heartRateMax,
    required DateTime startedAt,
    required DateTime endedAt,
    String? note,
    DateTime? createdAt,
  }) = _Exercise;

  factory Exercise.create({
    required String type,
    required String name,
    required int duration,
    int? calories,
    int? heartRateAvg,
    int? heartRateMax,
    DateTime? startedAt,
    String? note,
  }) {
    final start = startedAt ?? DateTime.now();
    final end = start.add(Duration(minutes: duration));
    
    return Exercise(
      id: null,
      type: type,
      name: name,
      duration: duration,
      calories: calories,
      heartRateAvg: heartRateAvg,
      heartRateMax: heartRateMax,
      startedAt: start,
      endedAt: end,
      note: note,
      createdAt: DateTime.now(),
    );
  }
}