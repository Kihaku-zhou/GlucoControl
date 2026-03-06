// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'food_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FoodItem {
  String get name;
  double get amount;
  String get unit;
  double? get carbs;

  /// Create a copy of FoodItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FoodItemCopyWith<FoodItem> get copyWith =>
      _$FoodItemCopyWithImpl<FoodItem>(this as FoodItem, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FoodItem &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.carbs, carbs) || other.carbs == carbs));
  }

  @override
  int get hashCode => Object.hash(runtimeType, name, amount, unit, carbs);

  @override
  String toString() {
    return 'FoodItem(name: $name, amount: $amount, unit: $unit, carbs: $carbs)';
  }
}

/// @nodoc
abstract mixin class $FoodItemCopyWith<$Res> {
  factory $FoodItemCopyWith(FoodItem value, $Res Function(FoodItem) _then) =
      _$FoodItemCopyWithImpl;
  @useResult
  $Res call({String name, double amount, String unit, double? carbs});
}

/// @nodoc
class _$FoodItemCopyWithImpl<$Res> implements $FoodItemCopyWith<$Res> {
  _$FoodItemCopyWithImpl(this._self, this._then);

  final FoodItem _self;
  final $Res Function(FoodItem) _then;

  /// Create a copy of FoodItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? amount = null,
    Object? unit = null,
    Object? carbs = freezed,
  }) {
    return _then(_self.copyWith(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _self.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      unit: null == unit
          ? _self.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      carbs: freezed == carbs
          ? _self.carbs
          : carbs // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// @nodoc

class _FoodItem implements FoodItem {
  const _FoodItem(
      {required this.name,
      required this.amount,
      required this.unit,
      this.carbs});

  @override
  final String name;
  @override
  final double amount;
  @override
  final String unit;
  @override
  final double? carbs;

  /// Create a copy of FoodItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$FoodItemCopyWith<_FoodItem> get copyWith =>
      __$FoodItemCopyWithImpl<_FoodItem>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _FoodItem &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.carbs, carbs) || other.carbs == carbs));
  }

  @override
  int get hashCode => Object.hash(runtimeType, name, amount, unit, carbs);

  @override
  String toString() {
    return 'FoodItem(name: $name, amount: $amount, unit: $unit, carbs: $carbs)';
  }
}

/// @nodoc
abstract mixin class _$FoodItemCopyWith<$Res>
    implements $FoodItemCopyWith<$Res> {
  factory _$FoodItemCopyWith(_FoodItem value, $Res Function(_FoodItem) _then) =
      __$FoodItemCopyWithImpl;
  @override
  @useResult
  $Res call({String name, double amount, String unit, double? carbs});
}

/// @nodoc
class __$FoodItemCopyWithImpl<$Res> implements _$FoodItemCopyWith<$Res> {
  __$FoodItemCopyWithImpl(this._self, this._then);

  final _FoodItem _self;
  final $Res Function(_FoodItem) _then;

  /// Create a copy of FoodItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? name = null,
    Object? amount = null,
    Object? unit = null,
    Object? carbs = freezed,
  }) {
    return _then(_FoodItem(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _self.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      unit: null == unit
          ? _self.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      carbs: freezed == carbs
          ? _self.carbs
          : carbs // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

// dart format on
