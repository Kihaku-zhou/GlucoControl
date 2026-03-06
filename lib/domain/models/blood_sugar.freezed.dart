// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'blood_sugar.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BloodSugar {
  int? get id;
  double get value;
  String get unit;
  String get type;
  DateTime get recordedAt;
  double? get hoursAfterMeal;
  int? get mealId;
  String? get note;
  DateTime get createdAt;
  DateTime get updatedAt;

  /// Create a copy of BloodSugar
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BloodSugarCopyWith<BloodSugar> get copyWith =>
      _$BloodSugarCopyWithImpl<BloodSugar>(this as BloodSugar, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BloodSugar &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.recordedAt, recordedAt) ||
                other.recordedAt == recordedAt) &&
            (identical(other.hoursAfterMeal, hoursAfterMeal) ||
                other.hoursAfterMeal == hoursAfterMeal) &&
            (identical(other.mealId, mealId) || other.mealId == mealId) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, value, unit, type,
      recordedAt, hoursAfterMeal, mealId, note, createdAt, updatedAt);

  @override
  String toString() {
    return 'BloodSugar(id: $id, value: $value, unit: $unit, type: $type, recordedAt: $recordedAt, hoursAfterMeal: $hoursAfterMeal, mealId: $mealId, note: $note, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class $BloodSugarCopyWith<$Res> {
  factory $BloodSugarCopyWith(
          BloodSugar value, $Res Function(BloodSugar) _then) =
      _$BloodSugarCopyWithImpl;
  @useResult
  $Res call(
      {int? id,
      double value,
      String unit,
      String type,
      DateTime recordedAt,
      double? hoursAfterMeal,
      int? mealId,
      String? note,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class _$BloodSugarCopyWithImpl<$Res> implements $BloodSugarCopyWith<$Res> {
  _$BloodSugarCopyWithImpl(this._self, this._then);

  final BloodSugar _self;
  final $Res Function(BloodSugar) _then;

  /// Create a copy of BloodSugar
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? value = null,
    Object? unit = null,
    Object? type = null,
    Object? recordedAt = null,
    Object? hoursAfterMeal = freezed,
    Object? mealId = freezed,
    Object? note = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_self.copyWith(
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      value: null == value
          ? _self.value
          : value // ignore: cast_nullable_to_non_nullable
              as double,
      unit: null == unit
          ? _self.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      recordedAt: null == recordedAt
          ? _self.recordedAt
          : recordedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      hoursAfterMeal: freezed == hoursAfterMeal
          ? _self.hoursAfterMeal
          : hoursAfterMeal // ignore: cast_nullable_to_non_nullable
              as double?,
      mealId: freezed == mealId
          ? _self.mealId
          : mealId // ignore: cast_nullable_to_non_nullable
              as int?,
      note: freezed == note
          ? _self.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc

class _BloodSugar implements BloodSugar {
  const _BloodSugar(
      {this.id,
      required this.value,
      required this.unit,
      required this.type,
      required this.recordedAt,
      this.hoursAfterMeal,
      this.mealId,
      this.note,
      required this.createdAt,
      required this.updatedAt});

  @override
  final int? id;
  @override
  final double value;
  @override
  final String unit;
  @override
  final String type;
  @override
  final DateTime recordedAt;
  @override
  final double? hoursAfterMeal;
  @override
  final int? mealId;
  @override
  final String? note;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  /// Create a copy of BloodSugar
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BloodSugarCopyWith<_BloodSugar> get copyWith =>
      __$BloodSugarCopyWithImpl<_BloodSugar>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BloodSugar &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.recordedAt, recordedAt) ||
                other.recordedAt == recordedAt) &&
            (identical(other.hoursAfterMeal, hoursAfterMeal) ||
                other.hoursAfterMeal == hoursAfterMeal) &&
            (identical(other.mealId, mealId) || other.mealId == mealId) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, value, unit, type,
      recordedAt, hoursAfterMeal, mealId, note, createdAt, updatedAt);

  @override
  String toString() {
    return 'BloodSugar(id: $id, value: $value, unit: $unit, type: $type, recordedAt: $recordedAt, hoursAfterMeal: $hoursAfterMeal, mealId: $mealId, note: $note, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$BloodSugarCopyWith<$Res>
    implements $BloodSugarCopyWith<$Res> {
  factory _$BloodSugarCopyWith(
          _BloodSugar value, $Res Function(_BloodSugar) _then) =
      __$BloodSugarCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int? id,
      double value,
      String unit,
      String type,
      DateTime recordedAt,
      double? hoursAfterMeal,
      int? mealId,
      String? note,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class __$BloodSugarCopyWithImpl<$Res> implements _$BloodSugarCopyWith<$Res> {
  __$BloodSugarCopyWithImpl(this._self, this._then);

  final _BloodSugar _self;
  final $Res Function(_BloodSugar) _then;

  /// Create a copy of BloodSugar
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = freezed,
    Object? value = null,
    Object? unit = null,
    Object? type = null,
    Object? recordedAt = null,
    Object? hoursAfterMeal = freezed,
    Object? mealId = freezed,
    Object? note = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_BloodSugar(
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      value: null == value
          ? _self.value
          : value // ignore: cast_nullable_to_non_nullable
              as double,
      unit: null == unit
          ? _self.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      recordedAt: null == recordedAt
          ? _self.recordedAt
          : recordedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      hoursAfterMeal: freezed == hoursAfterMeal
          ? _self.hoursAfterMeal
          : hoursAfterMeal // ignore: cast_nullable_to_non_nullable
              as double?,
      mealId: freezed == mealId
          ? _self.mealId
          : mealId // ignore: cast_nullable_to_non_nullable
              as int?,
      note: freezed == note
          ? _self.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

// dart format on
