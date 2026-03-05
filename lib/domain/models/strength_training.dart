import 'package:freezed_annotation/freezed_annotation.dart';

part 'strength_training.freezed.dart';

@freezed
class StrengthTraining with _$StrengthTraining {
  const factory StrengthTraining({
    int? id,
    required int exerciseId,
    required String device,
    required String movement,
    required int sets,
    required int reps,
    double? weight,
    int? restSeconds,
  }) = _StrengthTraining;

  factory StrengthTraining.create({
    required int exerciseId,
    required String device,
    required String movement,
    required int sets,
    required int reps,
    double? weight,
    int? restSeconds,
  }) {
    return StrengthTraining(
      id: null,
      exerciseId: exerciseId,
      device: device,
      movement: movement,
      sets: sets,
      reps: reps,
      weight: weight,
      restSeconds: restSeconds,
    );
  }
}