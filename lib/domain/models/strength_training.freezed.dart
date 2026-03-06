// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'strength_training.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StrengthTraining {
  int? get id;
  int get exerciseId;
  String get device;
  String get movement;
  int get sets;
  int get reps;
  double? get weight;
  int? get restSeconds;

  /// Create a copy of StrengthTraining
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $StrengthTrainingCopyWith<StrengthTraining> get copyWith =>
      _$StrengthTrainingCopyWithImpl<StrengthTraining>(
          this as StrengthTraining, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is StrengthTraining &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.exerciseId, exerciseId) ||
                other.exerciseId == exerciseId) &&
            (identical(other.device, device) || other.device == device) &&
            (identical(other.movement, movement) ||
                other.movement == movement) &&
            (identical(other.sets, sets) || other.sets == sets) &&
            (identical(other.reps, reps) || other.reps == reps) &&
            (identical(other.weight, weight) || other.weight == weight) &&
            (identical(other.restSeconds, restSeconds) ||
                other.restSeconds == restSeconds));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, exerciseId, device, movement,
      sets, reps, weight, restSeconds);

  @override
  String toString() {
    return 'StrengthTraining(id: $id, exerciseId: $exerciseId, device: $device, movement: $movement, sets: $sets, reps: $reps, weight: $weight, restSeconds: $restSeconds)';
  }
}

/// @nodoc
abstract mixin class $StrengthTrainingCopyWith<$Res> {
  factory $StrengthTrainingCopyWith(
          StrengthTraining value, $Res Function(StrengthTraining) _then) =
      _$StrengthTrainingCopyWithImpl;
  @useResult
  $Res call(
      {int? id,
      int exerciseId,
      String device,
      String movement,
      int sets,
      int reps,
      double? weight,
      int? restSeconds});
}

/// @nodoc
class _$StrengthTrainingCopyWithImpl<$Res>
    implements $StrengthTrainingCopyWith<$Res> {
  _$StrengthTrainingCopyWithImpl(this._self, this._then);

  final StrengthTraining _self;
  final $Res Function(StrengthTraining) _then;

  /// Create a copy of StrengthTraining
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? exerciseId = null,
    Object? device = null,
    Object? movement = null,
    Object? sets = null,
    Object? reps = null,
    Object? weight = freezed,
    Object? restSeconds = freezed,
  }) {
    return _then(_self.copyWith(
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      exerciseId: null == exerciseId
          ? _self.exerciseId
          : exerciseId // ignore: cast_nullable_to_non_nullable
              as int,
      device: null == device
          ? _self.device
          : device // ignore: cast_nullable_to_non_nullable
              as String,
      movement: null == movement
          ? _self.movement
          : movement // ignore: cast_nullable_to_non_nullable
              as String,
      sets: null == sets
          ? _self.sets
          : sets // ignore: cast_nullable_to_non_nullable
              as int,
      reps: null == reps
          ? _self.reps
          : reps // ignore: cast_nullable_to_non_nullable
              as int,
      weight: freezed == weight
          ? _self.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as double?,
      restSeconds: freezed == restSeconds
          ? _self.restSeconds
          : restSeconds // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc

class _StrengthTraining implements StrengthTraining {
  const _StrengthTraining(
      {this.id,
      required this.exerciseId,
      required this.device,
      required this.movement,
      required this.sets,
      required this.reps,
      this.weight,
      this.restSeconds});

  @override
  final int? id;
  @override
  final int exerciseId;
  @override
  final String device;
  @override
  final String movement;
  @override
  final int sets;
  @override
  final int reps;
  @override
  final double? weight;
  @override
  final int? restSeconds;

  /// Create a copy of StrengthTraining
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$StrengthTrainingCopyWith<_StrengthTraining> get copyWith =>
      __$StrengthTrainingCopyWithImpl<_StrengthTraining>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _StrengthTraining &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.exerciseId, exerciseId) ||
                other.exerciseId == exerciseId) &&
            (identical(other.device, device) || other.device == device) &&
            (identical(other.movement, movement) ||
                other.movement == movement) &&
            (identical(other.sets, sets) || other.sets == sets) &&
            (identical(other.reps, reps) || other.reps == reps) &&
            (identical(other.weight, weight) || other.weight == weight) &&
            (identical(other.restSeconds, restSeconds) ||
                other.restSeconds == restSeconds));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, exerciseId, device, movement,
      sets, reps, weight, restSeconds);

  @override
  String toString() {
    return 'StrengthTraining(id: $id, exerciseId: $exerciseId, device: $device, movement: $movement, sets: $sets, reps: $reps, weight: $weight, restSeconds: $restSeconds)';
  }
}

/// @nodoc
abstract mixin class _$StrengthTrainingCopyWith<$Res>
    implements $StrengthTrainingCopyWith<$Res> {
  factory _$StrengthTrainingCopyWith(
          _StrengthTraining value, $Res Function(_StrengthTraining) _then) =
      __$StrengthTrainingCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int? id,
      int exerciseId,
      String device,
      String movement,
      int sets,
      int reps,
      double? weight,
      int? restSeconds});
}

/// @nodoc
class __$StrengthTrainingCopyWithImpl<$Res>
    implements _$StrengthTrainingCopyWith<$Res> {
  __$StrengthTrainingCopyWithImpl(this._self, this._then);

  final _StrengthTraining _self;
  final $Res Function(_StrengthTraining) _then;

  /// Create a copy of StrengthTraining
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = freezed,
    Object? exerciseId = null,
    Object? device = null,
    Object? movement = null,
    Object? sets = null,
    Object? reps = null,
    Object? weight = freezed,
    Object? restSeconds = freezed,
  }) {
    return _then(_StrengthTraining(
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      exerciseId: null == exerciseId
          ? _self.exerciseId
          : exerciseId // ignore: cast_nullable_to_non_nullable
              as int,
      device: null == device
          ? _self.device
          : device // ignore: cast_nullable_to_non_nullable
              as String,
      movement: null == movement
          ? _self.movement
          : movement // ignore: cast_nullable_to_non_nullable
              as String,
      sets: null == sets
          ? _self.sets
          : sets // ignore: cast_nullable_to_non_nullable
              as int,
      reps: null == reps
          ? _self.reps
          : reps // ignore: cast_nullable_to_non_nullable
              as int,
      weight: freezed == weight
          ? _self.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as double?,
      restSeconds: freezed == restSeconds
          ? _self.restSeconds
          : restSeconds // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

// dart format on
