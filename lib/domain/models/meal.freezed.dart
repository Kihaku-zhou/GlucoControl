// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'meal.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Meal {
  int? get id;
  String get type;
  DateTime get recordedAt;
  List<FoodItem> get foods;
  String? get imagePath;
  String? get note;
  DateTime? get createdAt;

  /// Create a copy of Meal
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MealCopyWith<Meal> get copyWith =>
      _$MealCopyWithImpl<Meal>(this as Meal, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Meal &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.recordedAt, recordedAt) ||
                other.recordedAt == recordedAt) &&
            const DeepCollectionEquality().equals(other.foods, foods) &&
            (identical(other.imagePath, imagePath) ||
                other.imagePath == imagePath) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, type, recordedAt,
      const DeepCollectionEquality().hash(foods), imagePath, note, createdAt);

  @override
  String toString() {
    return 'Meal(id: $id, type: $type, recordedAt: $recordedAt, foods: $foods, imagePath: $imagePath, note: $note, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class $MealCopyWith<$Res> {
  factory $MealCopyWith(Meal value, $Res Function(Meal) _then) =
      _$MealCopyWithImpl;
  @useResult
  $Res call(
      {int? id,
      String type,
      DateTime recordedAt,
      List<FoodItem> foods,
      String? imagePath,
      String? note,
      DateTime? createdAt});
}

/// @nodoc
class _$MealCopyWithImpl<$Res> implements $MealCopyWith<$Res> {
  _$MealCopyWithImpl(this._self, this._then);

  final Meal _self;
  final $Res Function(Meal) _then;

  /// Create a copy of Meal
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? type = null,
    Object? recordedAt = null,
    Object? foods = null,
    Object? imagePath = freezed,
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
      recordedAt: null == recordedAt
          ? _self.recordedAt
          : recordedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      foods: null == foods
          ? _self.foods
          : foods // ignore: cast_nullable_to_non_nullable
              as List<FoodItem>,
      imagePath: freezed == imagePath
          ? _self.imagePath
          : imagePath // ignore: cast_nullable_to_non_nullable
              as String?,
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

class _Meal implements Meal {
  const _Meal(
      {this.id,
      required this.type,
      required this.recordedAt,
      required final List<FoodItem> foods,
      this.imagePath,
      this.note,
      this.createdAt})
      : _foods = foods;

  @override
  final int? id;
  @override
  final String type;
  @override
  final DateTime recordedAt;
  final List<FoodItem> _foods;
  @override
  List<FoodItem> get foods {
    if (_foods is EqualUnmodifiableListView) return _foods;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_foods);
  }

  @override
  final String? imagePath;
  @override
  final String? note;
  @override
  final DateTime? createdAt;

  /// Create a copy of Meal
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MealCopyWith<_Meal> get copyWith =>
      __$MealCopyWithImpl<_Meal>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Meal &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.recordedAt, recordedAt) ||
                other.recordedAt == recordedAt) &&
            const DeepCollectionEquality().equals(other._foods, _foods) &&
            (identical(other.imagePath, imagePath) ||
                other.imagePath == imagePath) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, type, recordedAt,
      const DeepCollectionEquality().hash(_foods), imagePath, note, createdAt);

  @override
  String toString() {
    return 'Meal(id: $id, type: $type, recordedAt: $recordedAt, foods: $foods, imagePath: $imagePath, note: $note, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class _$MealCopyWith<$Res> implements $MealCopyWith<$Res> {
  factory _$MealCopyWith(_Meal value, $Res Function(_Meal) _then) =
      __$MealCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int? id,
      String type,
      DateTime recordedAt,
      List<FoodItem> foods,
      String? imagePath,
      String? note,
      DateTime? createdAt});
}

/// @nodoc
class __$MealCopyWithImpl<$Res> implements _$MealCopyWith<$Res> {
  __$MealCopyWithImpl(this._self, this._then);

  final _Meal _self;
  final $Res Function(_Meal) _then;

  /// Create a copy of Meal
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = freezed,
    Object? type = null,
    Object? recordedAt = null,
    Object? foods = null,
    Object? imagePath = freezed,
    Object? note = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_Meal(
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      recordedAt: null == recordedAt
          ? _self.recordedAt
          : recordedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      foods: null == foods
          ? _self._foods
          : foods // ignore: cast_nullable_to_non_nullable
              as List<FoodItem>,
      imagePath: freezed == imagePath
          ? _self.imagePath
          : imagePath // ignore: cast_nullable_to_non_nullable
              as String?,
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
