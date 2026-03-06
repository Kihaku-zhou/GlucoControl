// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exercise.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Exercise {
  int? get id;
  String get type;
  String get name;
  int get duration;
  int? get calories;
  int? get heartRateAvg;
  int? get heartRateMax;
  DateTime get startedAt;
  DateTime get endedAt;
  String? get note;
  DateTime? get createdAt;

  /// Create a copy of Exercise
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ExerciseCopyWith<Exercise> get copyWith =>
      _$ExerciseCopyWithImpl<Exercise>(this as Exercise, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Exercise &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.calories, calories) ||
                other.calories == calories) &&
            (identical(other.heartRateAvg, heartRateAvg) ||
                other.heartRateAvg == heartRateAvg) &&
            (identical(other.heartRateMax, heartRateMax) ||
                other.heartRateMax == heartRateMax) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.endedAt, endedAt) || other.endedAt == endedAt) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      type,
      name,
      duration,
      calories,
      heartRateAvg,
      heartRateMax,
      startedAt,
      endedAt,
      note,
      createdAt);

  @override
  String toString() {
    return 'Exercise(id: $id, type: $type, name: $name, duration: $duration, calories: $calories, heartRateAvg: $heartRateAvg, heartRateMax: $heartRateMax, startedAt: $startedAt, endedAt: $endedAt, note: $note, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class $ExerciseCopyWith<$Res> {
  factory $ExerciseCopyWith(Exercise value, $Res Function(Exercise) _then) =
      _$ExerciseCopyWithImpl;
  @useResult
  $Res call(
      {int? id,
      String type,
      String name,
      int duration,
      int? calories,
      int? heartRateAvg,
      int? heartRateMax,
      DateTime startedAt,
      DateTime endedAt,
      String? note,
      DateTime? createdAt});
}

/// @nodoc
class _$ExerciseCopyWithImpl<$Res> implements $ExerciseCopyWith<$Res> {
  _$ExerciseCopyWithImpl(this._self, this._then);

  final Exercise _self;
  final $Res Function(Exercise) _then;

  /// Create a copy of Exercise
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? type = null,
    Object? name = null,
    Object? duration = null,
    Object? calories = freezed,
    Object? heartRateAvg = freezed,
    Object? heartRateMax = freezed,
    Object? startedAt = null,
    Object? endedAt = null,
    Object? note = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_self.copyWith(
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      duration: null == duration
          ? _self.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as int,
      calories: freezed == calories
          ? _self.calories
          : calories // ignore: cast_nullable_to_non_nullable
              as int?,
      heartRateAvg: freezed == heartRateAvg
          ? _self.heartRateAvg
          : heartRateAvg // ignore: cast_nullable_to_non_nullable
              as int?,
      heartRateMax: freezed == heartRateMax
          ? _self.heartRateMax
          : heartRateMax // ignore: cast_nullable_to_non_nullable
              as int?,
      startedAt: null == startedAt
          ? _self.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endedAt: null == endedAt
          ? _self.endedAt
          : endedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      note: freezed == note
          ? _self.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc

class _Exercise implements Exercise {
  const _Exercise(
      {this.id,
      required this.type,
      required this.name,
      required this.duration,
      this.calories,
      this.heartRateAvg,
      this.heartRateMax,
      required this.startedAt,
      required this.endedAt,
      this.note,
      this.createdAt});

  @override
  final int? id;
  @override
  final String type;
  @override
  final String name;
  @override
  final int duration;
  @override
  final int? calories;
  @override
  final int? heartRateAvg;
  @override
  final int? heartRateMax;
  @override
  final DateTime startedAt;
  @override
  final DateTime endedAt;
  @override
  final String? note;
  @override
  final DateTime? createdAt;

  /// Create a copy of Exercise
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ExerciseCopyWith<_Exercise> get copyWith =>
      __$ExerciseCopyWithImpl<_Exercise>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Exercise &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.calories, calories) ||
                other.calories == calories) &&
            (identical(other.heartRateAvg, heartRateAvg) ||
                other.heartRateAvg == heartRateAvg) &&
            (identical(other.heartRateMax, heartRateMax) ||
                other.heartRateMax == heartRateMax) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.endedAt, endedAt) || other.endedAt == endedAt) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      type,
      name,
      duration,
      calories,
      heartRateAvg,
      heartRateMax,
      startedAt,
      endedAt,
      note,
      createdAt);

  @override
  String toString() {
    return 'Exercise(id: $id, type: $type, name: $name, duration: $duration, calories: $calories, heartRateAvg: $heartRateAvg, heartRateMax: $heartRateMax, startedAt: $startedAt, endedAt: $endedAt, note: $note, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class _$ExerciseCopyWith<$Res>
    implements $ExerciseCopyWith<$Res> {
  factory _$ExerciseCopyWith(_Exercise value, $Res Function(_Exercise) _then) =
      __$ExerciseCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int? id,
      String type,
      String name,
      int duration,
      int? calories,
      int? heartRateAvg,
      int? heartRateMax,
      DateTime startedAt,
      DateTime endedAt,
      String? note,
      DateTime? createdAt});
}

/// @nodoc
class __$ExerciseCopyWithImpl<$Res> implements _$ExerciseCopyWith<$Res> {
  __$ExerciseCopyWithImpl(this._self, this._then);

  final _Exercise _self;
  final $Res Function(_Exercise) _then;

  /// Create a copy of Exercise
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = freezed,
    Object? type = null,
    Object? name = null,
    Object? duration = null,
    Object? calories = freezed,
    Object? heartRateAvg = freezed,
    Object? heartRateMax = freezed,
    Object? startedAt = null,
    Object? endedAt = null,
    Object? note = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_Exercise(
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      duration: null == duration
          ? _self.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as int,
      calories: freezed == calories
          ? _self.calories
          : calories // ignore: cast_nullable_to_non_nullable
              as int?,
      heartRateAvg: freezed == heartRateAvg
          ? _self.heartRateAvg
          : heartRateAvg // ignore: cast_nullable_to_non_nullable
              as int?,
      heartRateMax: freezed == heartRateMax
          ? _self.heartRateMax
          : heartRateMax // ignore: cast_nullable_to_non_nullable
              as int?,
      startedAt: null == startedAt
          ? _self.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endedAt: null == endedAt
          ? _self.endedAt
          : endedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      note: freezed == note
          ? _self.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
