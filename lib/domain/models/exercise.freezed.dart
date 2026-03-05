// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exercise.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Exercise {
  int? get id => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get duration => throw _privateConstructorUsedError;
  int? get calories => throw _privateConstructorUsedError;
  int? get heartRateAvg => throw _privateConstructorUsedError;
  int? get heartRateMax => throw _privateConstructorUsedError;
  DateTime get startedAt => throw _privateConstructorUsedError;
  DateTime get endedAt => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Create a copy of Exercise
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExerciseCopyWith<Exercise> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExerciseCopyWith<$Res> {
  factory $ExerciseCopyWith(Exercise value, $Res Function(Exercise) then) =
      _$ExerciseCopyWithImpl<$Res, Exercise>;
  @useResult
  $Res call({
    int? id,
    String type,
    String name,
    int duration,
    int? calories,
    int? heartRateAvg,
    int? heartRateMax,
    DateTime startedAt,
    DateTime endedAt,
    String? note,
    DateTime? createdAt,
  });
}

/// @nodoc
class _$ExerciseCopyWithImpl<$Res, $Val extends Exercise>
    implements $ExerciseCopyWith<$Res> {
  _$ExerciseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

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
    return _then(
      _value.copyWith(
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int?,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            duration: null == duration
                ? _value.duration
                : duration // ignore: cast_nullable_to_non_nullable
                      as int,
            calories: freezed == calories
                ? _value.calories
                : calories // ignore: cast_nullable_to_non_nullable
                      as int?,
            heartRateAvg: freezed == heartRateAvg
                ? _value.heartRateAvg
                : heartRateAvg // ignore: cast_nullable_to_non_nullable
                      as int?,
            heartRateMax: freezed == heartRateMax
                ? _value.heartRateMax
                : heartRateMax // ignore: cast_nullable_to_non_nullable
                      as int?,
            startedAt: null == startedAt
                ? _value.startedAt
                : startedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            endedAt: null == endedAt
                ? _value.endedAt
                : endedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            note: freezed == note
                ? _value.note
                : note // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ExerciseImplCopyWith<$Res>
    implements $ExerciseCopyWith<$Res> {
  factory _$$ExerciseImplCopyWith(
    _$ExerciseImpl value,
    $Res Function(_$ExerciseImpl) then,
  ) = __$$ExerciseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int? id,
    String type,
    String name,
    int duration,
    int? calories,
    int? heartRateAvg,
    int? heartRateMax,
    DateTime startedAt,
    DateTime endedAt,
    String? note,
    DateTime? createdAt,
  });
}

/// @nodoc
class __$$ExerciseImplCopyWithImpl<$Res>
    extends _$ExerciseCopyWithImpl<$Res, _$ExerciseImpl>
    implements _$$ExerciseImplCopyWith<$Res> {
  __$$ExerciseImplCopyWithImpl(
    _$ExerciseImpl _value,
    $Res Function(_$ExerciseImpl) _then,
  ) : super(_value, _then);

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
    return _then(
      _$ExerciseImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int?,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        duration: null == duration
            ? _value.duration
            : duration // ignore: cast_nullable_to_non_nullable
                  as int,
        calories: freezed == calories
            ? _value.calories
            : calories // ignore: cast_nullable_to_non_nullable
                  as int?,
        heartRateAvg: freezed == heartRateAvg
            ? _value.heartRateAvg
            : heartRateAvg // ignore: cast_nullable_to_non_nullable
                  as int?,
        heartRateMax: freezed == heartRateMax
            ? _value.heartRateMax
            : heartRateMax // ignore: cast_nullable_to_non_nullable
                  as int?,
        startedAt: null == startedAt
            ? _value.startedAt
            : startedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        endedAt: null == endedAt
            ? _value.endedAt
            : endedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        note: freezed == note
            ? _value.note
            : note // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc

class _$ExerciseImpl implements _Exercise {
  const _$ExerciseImpl({
    this.id,
    required this.type,
    required this.name,
    required this.duration,
    this.calories,
    this.heartRateAvg,
    this.heartRateMax,
    required this.startedAt,
    required this.endedAt,
    this.note,
    this.createdAt,
  });

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

  @override
  String toString() {
    return 'Exercise(id: $id, type: $type, name: $name, duration: $duration, calories: $calories, heartRateAvg: $heartRateAvg, heartRateMax: $heartRateMax, startedAt: $startedAt, endedAt: $endedAt, note: $note, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExerciseImpl &&
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
    createdAt,
  );

  /// Create a copy of Exercise
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExerciseImplCopyWith<_$ExerciseImpl> get copyWith =>
      __$$ExerciseImplCopyWithImpl<_$ExerciseImpl>(this, _$identity);
}

abstract class _Exercise implements Exercise {
  const factory _Exercise({
    final int? id,
    required final String type,
    required final String name,
    required final int duration,
    final int? calories,
    final int? heartRateAvg,
    final int? heartRateMax,
    required final DateTime startedAt,
    required final DateTime endedAt,
    final String? note,
    final DateTime? createdAt,
  }) = _$ExerciseImpl;

  @override
  int? get id;
  @override
  String get type;
  @override
  String get name;
  @override
  int get duration;
  @override
  int? get calories;
  @override
  int? get heartRateAvg;
  @override
  int? get heartRateMax;
  @override
  DateTime get startedAt;
  @override
  DateTime get endedAt;
  @override
  String? get note;
  @override
  DateTime? get createdAt;

  /// Create a copy of Exercise
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExerciseImplCopyWith<_$ExerciseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
