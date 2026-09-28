// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $BloodSugarRecordsTable extends BloodSugarRecords
    with TableInfo<$BloodSugarRecordsTable, BloodSugarRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BloodSugarRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
      'value', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('mmol/L'));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _recordedAtMeta =
      const VerificationMeta('recordedAt');
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
      'recorded_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _hoursAfterMealMeta =
      const VerificationMeta('hoursAfterMeal');
  @override
  late final GeneratedColumn<double> hoursAfterMeal = GeneratedColumn<double>(
      'hours_after_meal', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _mealIdMeta = const VerificationMeta('mealId');
  @override
  late final GeneratedColumn<int> mealId = GeneratedColumn<int>(
      'meal_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        value,
        unit,
        type,
        recordedAt,
        hoursAfterMeal,
        mealId,
        note,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'blood_sugar_records';
  @override
  VerificationContext validateIntegrity(Insertable<BloodSugarRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
          _recordedAtMeta,
          recordedAt.isAcceptableOrUnknown(
              data['recorded_at']!, _recordedAtMeta));
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('hours_after_meal')) {
      context.handle(
          _hoursAfterMealMeta,
          hoursAfterMeal.isAcceptableOrUnknown(
              data['hours_after_meal']!, _hoursAfterMealMeta));
    }
    if (data.containsKey('meal_id')) {
      context.handle(_mealIdMeta,
          mealId.isAcceptableOrUnknown(data['meal_id']!, _mealIdMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BloodSugarRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BloodSugarRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}value'])!,
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      recordedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}recorded_at'])!,
      hoursAfterMeal: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}hours_after_meal']),
      mealId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}meal_id']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $BloodSugarRecordsTable createAlias(String alias) {
    return $BloodSugarRecordsTable(attachedDatabase, alias);
  }
}

class BloodSugarRecord extends DataClass
    implements Insertable<BloodSugarRecord> {
  final int id;
  final double value;
  final String unit;
  final String type;
  final DateTime recordedAt;
  final double? hoursAfterMeal;
  final int? mealId;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  const BloodSugarRecord(
      {required this.id,
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
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['value'] = Variable<double>(value);
    map['unit'] = Variable<String>(unit);
    map['type'] = Variable<String>(type);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    if (!nullToAbsent || hoursAfterMeal != null) {
      map['hours_after_meal'] = Variable<double>(hoursAfterMeal);
    }
    if (!nullToAbsent || mealId != null) {
      map['meal_id'] = Variable<int>(mealId);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BloodSugarRecordsCompanion toCompanion(bool nullToAbsent) {
    return BloodSugarRecordsCompanion(
      id: Value(id),
      value: Value(value),
      unit: Value(unit),
      type: Value(type),
      recordedAt: Value(recordedAt),
      hoursAfterMeal: hoursAfterMeal == null && nullToAbsent
          ? const Value.absent()
          : Value(hoursAfterMeal),
      mealId:
          mealId == null && nullToAbsent ? const Value.absent() : Value(mealId),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BloodSugarRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BloodSugarRecord(
      id: serializer.fromJson<int>(json['id']),
      value: serializer.fromJson<double>(json['value']),
      unit: serializer.fromJson<String>(json['unit']),
      type: serializer.fromJson<String>(json['type']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      hoursAfterMeal: serializer.fromJson<double?>(json['hoursAfterMeal']),
      mealId: serializer.fromJson<int?>(json['mealId']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'value': serializer.toJson<double>(value),
      'unit': serializer.toJson<String>(unit),
      'type': serializer.toJson<String>(type),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'hoursAfterMeal': serializer.toJson<double?>(hoursAfterMeal),
      'mealId': serializer.toJson<int?>(mealId),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BloodSugarRecord copyWith(
          {int? id,
          double? value,
          String? unit,
          String? type,
          DateTime? recordedAt,
          Value<double?> hoursAfterMeal = const Value.absent(),
          Value<int?> mealId = const Value.absent(),
          Value<String?> note = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      BloodSugarRecord(
        id: id ?? this.id,
        value: value ?? this.value,
        unit: unit ?? this.unit,
        type: type ?? this.type,
        recordedAt: recordedAt ?? this.recordedAt,
        hoursAfterMeal:
            hoursAfterMeal.present ? hoursAfterMeal.value : this.hoursAfterMeal,
        mealId: mealId.present ? mealId.value : this.mealId,
        note: note.present ? note.value : this.note,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  BloodSugarRecord copyWithCompanion(BloodSugarRecordsCompanion data) {
    return BloodSugarRecord(
      id: data.id.present ? data.id.value : this.id,
      value: data.value.present ? data.value.value : this.value,
      unit: data.unit.present ? data.unit.value : this.unit,
      type: data.type.present ? data.type.value : this.type,
      recordedAt:
          data.recordedAt.present ? data.recordedAt.value : this.recordedAt,
      hoursAfterMeal: data.hoursAfterMeal.present
          ? data.hoursAfterMeal.value
          : this.hoursAfterMeal,
      mealId: data.mealId.present ? data.mealId.value : this.mealId,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BloodSugarRecord(')
          ..write('id: $id, ')
          ..write('value: $value, ')
          ..write('unit: $unit, ')
          ..write('type: $type, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('hoursAfterMeal: $hoursAfterMeal, ')
          ..write('mealId: $mealId, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, value, unit, type, recordedAt,
      hoursAfterMeal, mealId, note, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BloodSugarRecord &&
          other.id == this.id &&
          other.value == this.value &&
          other.unit == this.unit &&
          other.type == this.type &&
          other.recordedAt == this.recordedAt &&
          other.hoursAfterMeal == this.hoursAfterMeal &&
          other.mealId == this.mealId &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BloodSugarRecordsCompanion extends UpdateCompanion<BloodSugarRecord> {
  final Value<int> id;
  final Value<double> value;
  final Value<String> unit;
  final Value<String> type;
  final Value<DateTime> recordedAt;
  final Value<double?> hoursAfterMeal;
  final Value<int?> mealId;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const BloodSugarRecordsCompanion({
    this.id = const Value.absent(),
    this.value = const Value.absent(),
    this.unit = const Value.absent(),
    this.type = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.hoursAfterMeal = const Value.absent(),
    this.mealId = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  BloodSugarRecordsCompanion.insert({
    this.id = const Value.absent(),
    required double value,
    this.unit = const Value.absent(),
    required String type,
    required DateTime recordedAt,
    this.hoursAfterMeal = const Value.absent(),
    this.mealId = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  })  : value = Value(value),
        type = Value(type),
        recordedAt = Value(recordedAt),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<BloodSugarRecord> custom({
    Expression<int>? id,
    Expression<double>? value,
    Expression<String>? unit,
    Expression<String>? type,
    Expression<DateTime>? recordedAt,
    Expression<double>? hoursAfterMeal,
    Expression<int>? mealId,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (value != null) 'value': value,
      if (unit != null) 'unit': unit,
      if (type != null) 'type': type,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (hoursAfterMeal != null) 'hours_after_meal': hoursAfterMeal,
      if (mealId != null) 'meal_id': mealId,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  BloodSugarRecordsCompanion copyWith(
      {Value<int>? id,
      Value<double>? value,
      Value<String>? unit,
      Value<String>? type,
      Value<DateTime>? recordedAt,
      Value<double?>? hoursAfterMeal,
      Value<int?>? mealId,
      Value<String?>? note,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return BloodSugarRecordsCompanion(
      id: id ?? this.id,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      type: type ?? this.type,
      recordedAt: recordedAt ?? this.recordedAt,
      hoursAfterMeal: hoursAfterMeal ?? this.hoursAfterMeal,
      mealId: mealId ?? this.mealId,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (hoursAfterMeal.present) {
      map['hours_after_meal'] = Variable<double>(hoursAfterMeal.value);
    }
    if (mealId.present) {
      map['meal_id'] = Variable<int>(mealId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BloodSugarRecordsCompanion(')
          ..write('id: $id, ')
          ..write('value: $value, ')
          ..write('unit: $unit, ')
          ..write('type: $type, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('hoursAfterMeal: $hoursAfterMeal, ')
          ..write('mealId: $mealId, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ExerciseRecordsTable extends ExerciseRecords
    with TableInfo<$ExerciseRecordsTable, ExerciseRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExerciseRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _durationMeta =
      const VerificationMeta('duration');
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
      'duration', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _distanceMeta =
      const VerificationMeta('distance');
  @override
  late final GeneratedColumn<double> distance = GeneratedColumn<double>(
      'distance', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _elevationMeta =
      const VerificationMeta('elevation');
  @override
  late final GeneratedColumn<double> elevation = GeneratedColumn<double>(
      'elevation', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _powerMeta = const VerificationMeta('power');
  @override
  late final GeneratedColumn<double> power = GeneratedColumn<double>(
      'power', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _setsMeta = const VerificationMeta('sets');
  @override
  late final GeneratedColumn<int> sets = GeneratedColumn<int>(
      'sets', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
      'weight', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _secondsMeta =
      const VerificationMeta('seconds');
  @override
  late final GeneratedColumn<int> seconds = GeneratedColumn<int>(
      'seconds', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _repsListMeta =
      const VerificationMeta('repsList');
  @override
  late final GeneratedColumn<String> repsList = GeneratedColumn<String>(
      'reps_list', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _caloriesMeta =
      const VerificationMeta('calories');
  @override
  late final GeneratedColumn<int> calories = GeneratedColumn<int>(
      'calories', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _heartRateAvgMeta =
      const VerificationMeta('heartRateAvg');
  @override
  late final GeneratedColumn<int> heartRateAvg = GeneratedColumn<int>(
      'heart_rate_avg', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _heartRateMaxMeta =
      const VerificationMeta('heartRateMax');
  @override
  late final GeneratedColumn<int> heartRateMax = GeneratedColumn<int>(
      'heart_rate_max', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
      'started_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endedAtMeta =
      const VerificationMeta('endedAt');
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
      'ended_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        type,
        name,
        duration,
        distance,
        elevation,
        power,
        sets,
        weight,
        seconds,
        repsList,
        calories,
        heartRateAvg,
        heartRateMax,
        startedAt,
        endedAt,
        note,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_records';
  @override
  VerificationContext validateIntegrity(Insertable<ExerciseRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('duration')) {
      context.handle(_durationMeta,
          duration.isAcceptableOrUnknown(data['duration']!, _durationMeta));
    } else if (isInserting) {
      context.missing(_durationMeta);
    }
    if (data.containsKey('distance')) {
      context.handle(_distanceMeta,
          distance.isAcceptableOrUnknown(data['distance']!, _distanceMeta));
    }
    if (data.containsKey('elevation')) {
      context.handle(_elevationMeta,
          elevation.isAcceptableOrUnknown(data['elevation']!, _elevationMeta));
    }
    if (data.containsKey('power')) {
      context.handle(
          _powerMeta, power.isAcceptableOrUnknown(data['power']!, _powerMeta));
    }
    if (data.containsKey('sets')) {
      context.handle(
          _setsMeta, sets.isAcceptableOrUnknown(data['sets']!, _setsMeta));
    }
    if (data.containsKey('weight')) {
      context.handle(_weightMeta,
          weight.isAcceptableOrUnknown(data['weight']!, _weightMeta));
    }
    if (data.containsKey('seconds')) {
      context.handle(_secondsMeta,
          seconds.isAcceptableOrUnknown(data['seconds']!, _secondsMeta));
    }
    if (data.containsKey('reps_list')) {
      context.handle(_repsListMeta,
          repsList.isAcceptableOrUnknown(data['reps_list']!, _repsListMeta));
    }
    if (data.containsKey('calories')) {
      context.handle(_caloriesMeta,
          calories.isAcceptableOrUnknown(data['calories']!, _caloriesMeta));
    }
    if (data.containsKey('heart_rate_avg')) {
      context.handle(
          _heartRateAvgMeta,
          heartRateAvg.isAcceptableOrUnknown(
              data['heart_rate_avg']!, _heartRateAvgMeta));
    }
    if (data.containsKey('heart_rate_max')) {
      context.handle(
          _heartRateMaxMeta,
          heartRateMax.isAcceptableOrUnknown(
              data['heart_rate_max']!, _heartRateMaxMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(_endedAtMeta,
          endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta));
    } else if (isInserting) {
      context.missing(_endedAtMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExerciseRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      duration: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration'])!,
      distance: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}distance']),
      elevation: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}elevation']),
      power: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}power']),
      sets: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sets']),
      weight: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}weight']),
      seconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}seconds']),
      repsList: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reps_list']),
      calories: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}calories']),
      heartRateAvg: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}heart_rate_avg']),
      heartRateMax: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}heart_rate_max']),
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}started_at'])!,
      endedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}ended_at'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ExerciseRecordsTable createAlias(String alias) {
    return $ExerciseRecordsTable(attachedDatabase, alias);
  }
}

class ExerciseRecord extends DataClass implements Insertable<ExerciseRecord> {
  final int id;
  final String type;
  final String name;
  final int duration;
  final double? distance;
  final double? elevation;
  final double? power;
  final int? sets;
  final double? weight;
  final int? seconds;
  final String? repsList;
  final int? calories;
  final int? heartRateAvg;
  final int? heartRateMax;
  final DateTime startedAt;
  final DateTime endedAt;
  final String? note;
  final DateTime createdAt;
  const ExerciseRecord(
      {required this.id,
      required this.type,
      required this.name,
      required this.duration,
      this.distance,
      this.elevation,
      this.power,
      this.sets,
      this.weight,
      this.seconds,
      this.repsList,
      this.calories,
      this.heartRateAvg,
      this.heartRateMax,
      required this.startedAt,
      required this.endedAt,
      this.note,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    map['name'] = Variable<String>(name);
    map['duration'] = Variable<int>(duration);
    if (!nullToAbsent || distance != null) {
      map['distance'] = Variable<double>(distance);
    }
    if (!nullToAbsent || elevation != null) {
      map['elevation'] = Variable<double>(elevation);
    }
    if (!nullToAbsent || power != null) {
      map['power'] = Variable<double>(power);
    }
    if (!nullToAbsent || sets != null) {
      map['sets'] = Variable<int>(sets);
    }
    if (!nullToAbsent || weight != null) {
      map['weight'] = Variable<double>(weight);
    }
    if (!nullToAbsent || seconds != null) {
      map['seconds'] = Variable<int>(seconds);
    }
    if (!nullToAbsent || repsList != null) {
      map['reps_list'] = Variable<String>(repsList);
    }
    if (!nullToAbsent || calories != null) {
      map['calories'] = Variable<int>(calories);
    }
    if (!nullToAbsent || heartRateAvg != null) {
      map['heart_rate_avg'] = Variable<int>(heartRateAvg);
    }
    if (!nullToAbsent || heartRateMax != null) {
      map['heart_rate_max'] = Variable<int>(heartRateMax);
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    map['ended_at'] = Variable<DateTime>(endedAt);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ExerciseRecordsCompanion toCompanion(bool nullToAbsent) {
    return ExerciseRecordsCompanion(
      id: Value(id),
      type: Value(type),
      name: Value(name),
      duration: Value(duration),
      distance: distance == null && nullToAbsent
          ? const Value.absent()
          : Value(distance),
      elevation: elevation == null && nullToAbsent
          ? const Value.absent()
          : Value(elevation),
      power:
          power == null && nullToAbsent ? const Value.absent() : Value(power),
      sets: sets == null && nullToAbsent ? const Value.absent() : Value(sets),
      weight:
          weight == null && nullToAbsent ? const Value.absent() : Value(weight),
      seconds: seconds == null && nullToAbsent
          ? const Value.absent()
          : Value(seconds),
      repsList: repsList == null && nullToAbsent
          ? const Value.absent()
          : Value(repsList),
      calories: calories == null && nullToAbsent
          ? const Value.absent()
          : Value(calories),
      heartRateAvg: heartRateAvg == null && nullToAbsent
          ? const Value.absent()
          : Value(heartRateAvg),
      heartRateMax: heartRateMax == null && nullToAbsent
          ? const Value.absent()
          : Value(heartRateMax),
      startedAt: Value(startedAt),
      endedAt: Value(endedAt),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory ExerciseRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseRecord(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      name: serializer.fromJson<String>(json['name']),
      duration: serializer.fromJson<int>(json['duration']),
      distance: serializer.fromJson<double?>(json['distance']),
      elevation: serializer.fromJson<double?>(json['elevation']),
      power: serializer.fromJson<double?>(json['power']),
      sets: serializer.fromJson<int?>(json['sets']),
      weight: serializer.fromJson<double?>(json['weight']),
      seconds: serializer.fromJson<int?>(json['seconds']),
      repsList: serializer.fromJson<String?>(json['repsList']),
      calories: serializer.fromJson<int?>(json['calories']),
      heartRateAvg: serializer.fromJson<int?>(json['heartRateAvg']),
      heartRateMax: serializer.fromJson<int?>(json['heartRateMax']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime>(json['endedAt']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'name': serializer.toJson<String>(name),
      'duration': serializer.toJson<int>(duration),
      'distance': serializer.toJson<double?>(distance),
      'elevation': serializer.toJson<double?>(elevation),
      'power': serializer.toJson<double?>(power),
      'sets': serializer.toJson<int?>(sets),
      'weight': serializer.toJson<double?>(weight),
      'seconds': serializer.toJson<int?>(seconds),
      'repsList': serializer.toJson<String?>(repsList),
      'calories': serializer.toJson<int?>(calories),
      'heartRateAvg': serializer.toJson<int?>(heartRateAvg),
      'heartRateMax': serializer.toJson<int?>(heartRateMax),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime>(endedAt),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ExerciseRecord copyWith(
          {int? id,
          String? type,
          String? name,
          int? duration,
          Value<double?> distance = const Value.absent(),
          Value<double?> elevation = const Value.absent(),
          Value<double?> power = const Value.absent(),
          Value<int?> sets = const Value.absent(),
          Value<double?> weight = const Value.absent(),
          Value<int?> seconds = const Value.absent(),
          Value<String?> repsList = const Value.absent(),
          Value<int?> calories = const Value.absent(),
          Value<int?> heartRateAvg = const Value.absent(),
          Value<int?> heartRateMax = const Value.absent(),
          DateTime? startedAt,
          DateTime? endedAt,
          Value<String?> note = const Value.absent(),
          DateTime? createdAt}) =>
      ExerciseRecord(
        id: id ?? this.id,
        type: type ?? this.type,
        name: name ?? this.name,
        duration: duration ?? this.duration,
        distance: distance.present ? distance.value : this.distance,
        elevation: elevation.present ? elevation.value : this.elevation,
        power: power.present ? power.value : this.power,
        sets: sets.present ? sets.value : this.sets,
        weight: weight.present ? weight.value : this.weight,
        seconds: seconds.present ? seconds.value : this.seconds,
        repsList: repsList.present ? repsList.value : this.repsList,
        calories: calories.present ? calories.value : this.calories,
        heartRateAvg:
            heartRateAvg.present ? heartRateAvg.value : this.heartRateAvg,
        heartRateMax:
            heartRateMax.present ? heartRateMax.value : this.heartRateMax,
        startedAt: startedAt ?? this.startedAt,
        endedAt: endedAt ?? this.endedAt,
        note: note.present ? note.value : this.note,
        createdAt: createdAt ?? this.createdAt,
      );
  ExerciseRecord copyWithCompanion(ExerciseRecordsCompanion data) {
    return ExerciseRecord(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      name: data.name.present ? data.name.value : this.name,
      duration: data.duration.present ? data.duration.value : this.duration,
      distance: data.distance.present ? data.distance.value : this.distance,
      elevation: data.elevation.present ? data.elevation.value : this.elevation,
      power: data.power.present ? data.power.value : this.power,
      sets: data.sets.present ? data.sets.value : this.sets,
      weight: data.weight.present ? data.weight.value : this.weight,
      seconds: data.seconds.present ? data.seconds.value : this.seconds,
      repsList: data.repsList.present ? data.repsList.value : this.repsList,
      calories: data.calories.present ? data.calories.value : this.calories,
      heartRateAvg: data.heartRateAvg.present
          ? data.heartRateAvg.value
          : this.heartRateAvg,
      heartRateMax: data.heartRateMax.present
          ? data.heartRateMax.value
          : this.heartRateMax,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseRecord(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('duration: $duration, ')
          ..write('distance: $distance, ')
          ..write('elevation: $elevation, ')
          ..write('power: $power, ')
          ..write('sets: $sets, ')
          ..write('weight: $weight, ')
          ..write('seconds: $seconds, ')
          ..write('repsList: $repsList, ')
          ..write('calories: $calories, ')
          ..write('heartRateAvg: $heartRateAvg, ')
          ..write('heartRateMax: $heartRateMax, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      type,
      name,
      duration,
      distance,
      elevation,
      power,
      sets,
      weight,
      seconds,
      repsList,
      calories,
      heartRateAvg,
      heartRateMax,
      startedAt,
      endedAt,
      note,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseRecord &&
          other.id == this.id &&
          other.type == this.type &&
          other.name == this.name &&
          other.duration == this.duration &&
          other.distance == this.distance &&
          other.elevation == this.elevation &&
          other.power == this.power &&
          other.sets == this.sets &&
          other.weight == this.weight &&
          other.seconds == this.seconds &&
          other.repsList == this.repsList &&
          other.calories == this.calories &&
          other.heartRateAvg == this.heartRateAvg &&
          other.heartRateMax == this.heartRateMax &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class ExerciseRecordsCompanion extends UpdateCompanion<ExerciseRecord> {
  final Value<int> id;
  final Value<String> type;
  final Value<String> name;
  final Value<int> duration;
  final Value<double?> distance;
  final Value<double?> elevation;
  final Value<double?> power;
  final Value<int?> sets;
  final Value<double?> weight;
  final Value<int?> seconds;
  final Value<String?> repsList;
  final Value<int?> calories;
  final Value<int?> heartRateAvg;
  final Value<int?> heartRateMax;
  final Value<DateTime> startedAt;
  final Value<DateTime> endedAt;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  const ExerciseRecordsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.name = const Value.absent(),
    this.duration = const Value.absent(),
    this.distance = const Value.absent(),
    this.elevation = const Value.absent(),
    this.power = const Value.absent(),
    this.sets = const Value.absent(),
    this.weight = const Value.absent(),
    this.seconds = const Value.absent(),
    this.repsList = const Value.absent(),
    this.calories = const Value.absent(),
    this.heartRateAvg = const Value.absent(),
    this.heartRateMax = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ExerciseRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    required String name,
    required int duration,
    this.distance = const Value.absent(),
    this.elevation = const Value.absent(),
    this.power = const Value.absent(),
    this.sets = const Value.absent(),
    this.weight = const Value.absent(),
    this.seconds = const Value.absent(),
    this.repsList = const Value.absent(),
    this.calories = const Value.absent(),
    this.heartRateAvg = const Value.absent(),
    this.heartRateMax = const Value.absent(),
    required DateTime startedAt,
    required DateTime endedAt,
    this.note = const Value.absent(),
    required DateTime createdAt,
  })  : type = Value(type),
        name = Value(name),
        duration = Value(duration),
        startedAt = Value(startedAt),
        endedAt = Value(endedAt),
        createdAt = Value(createdAt);
  static Insertable<ExerciseRecord> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<String>? name,
    Expression<int>? duration,
    Expression<double>? distance,
    Expression<double>? elevation,
    Expression<double>? power,
    Expression<int>? sets,
    Expression<double>? weight,
    Expression<int>? seconds,
    Expression<String>? repsList,
    Expression<int>? calories,
    Expression<int>? heartRateAvg,
    Expression<int>? heartRateMax,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (name != null) 'name': name,
      if (duration != null) 'duration': duration,
      if (distance != null) 'distance': distance,
      if (elevation != null) 'elevation': elevation,
      if (power != null) 'power': power,
      if (sets != null) 'sets': sets,
      if (weight != null) 'weight': weight,
      if (seconds != null) 'seconds': seconds,
      if (repsList != null) 'reps_list': repsList,
      if (calories != null) 'calories': calories,
      if (heartRateAvg != null) 'heart_rate_avg': heartRateAvg,
      if (heartRateMax != null) 'heart_rate_max': heartRateMax,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ExerciseRecordsCompanion copyWith(
      {Value<int>? id,
      Value<String>? type,
      Value<String>? name,
      Value<int>? duration,
      Value<double?>? distance,
      Value<double?>? elevation,
      Value<double?>? power,
      Value<int?>? sets,
      Value<double?>? weight,
      Value<int?>? seconds,
      Value<String?>? repsList,
      Value<int?>? calories,
      Value<int?>? heartRateAvg,
      Value<int?>? heartRateMax,
      Value<DateTime>? startedAt,
      Value<DateTime>? endedAt,
      Value<String?>? note,
      Value<DateTime>? createdAt}) {
    return ExerciseRecordsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      duration: duration ?? this.duration,
      distance: distance ?? this.distance,
      elevation: elevation ?? this.elevation,
      power: power ?? this.power,
      sets: sets ?? this.sets,
      weight: weight ?? this.weight,
      seconds: seconds ?? this.seconds,
      repsList: repsList ?? this.repsList,
      calories: calories ?? this.calories,
      heartRateAvg: heartRateAvg ?? this.heartRateAvg,
      heartRateMax: heartRateMax ?? this.heartRateMax,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (distance.present) {
      map['distance'] = Variable<double>(distance.value);
    }
    if (elevation.present) {
      map['elevation'] = Variable<double>(elevation.value);
    }
    if (power.present) {
      map['power'] = Variable<double>(power.value);
    }
    if (sets.present) {
      map['sets'] = Variable<int>(sets.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (seconds.present) {
      map['seconds'] = Variable<int>(seconds.value);
    }
    if (repsList.present) {
      map['reps_list'] = Variable<String>(repsList.value);
    }
    if (calories.present) {
      map['calories'] = Variable<int>(calories.value);
    }
    if (heartRateAvg.present) {
      map['heart_rate_avg'] = Variable<int>(heartRateAvg.value);
    }
    if (heartRateMax.present) {
      map['heart_rate_max'] = Variable<int>(heartRateMax.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseRecordsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('duration: $duration, ')
          ..write('distance: $distance, ')
          ..write('elevation: $elevation, ')
          ..write('power: $power, ')
          ..write('sets: $sets, ')
          ..write('weight: $weight, ')
          ..write('seconds: $seconds, ')
          ..write('repsList: $repsList, ')
          ..write('calories: $calories, ')
          ..write('heartRateAvg: $heartRateAvg, ')
          ..write('heartRateMax: $heartRateMax, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $StrengthTrainingsTable extends StrengthTrainings
    with TableInfo<$StrengthTrainingsTable, StrengthTraining> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StrengthTrainingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _exerciseIdMeta =
      const VerificationMeta('exerciseId');
  @override
  late final GeneratedColumn<int> exerciseId = GeneratedColumn<int>(
      'exercise_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES exercise_records (id)'));
  static const VerificationMeta _deviceMeta = const VerificationMeta('device');
  @override
  late final GeneratedColumn<String> device = GeneratedColumn<String>(
      'device', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _movementMeta =
      const VerificationMeta('movement');
  @override
  late final GeneratedColumn<String> movement = GeneratedColumn<String>(
      'movement', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _setsMeta = const VerificationMeta('sets');
  @override
  late final GeneratedColumn<int> sets = GeneratedColumn<int>(
      'sets', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
      'reps', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
      'weight', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _restSecondsMeta =
      const VerificationMeta('restSeconds');
  @override
  late final GeneratedColumn<int> restSeconds = GeneratedColumn<int>(
      'rest_seconds', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _trainingTypeMeta =
      const VerificationMeta('trainingType');
  @override
  late final GeneratedColumn<String> trainingType = GeneratedColumn<String>(
      'training_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('strength'));
  static const VerificationMeta _durationSecondsMeta =
      const VerificationMeta('durationSeconds');
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
      'duration_seconds', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        exerciseId,
        device,
        movement,
        sets,
        reps,
        weight,
        restSeconds,
        trainingType,
        durationSeconds
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'strength_trainings';
  @override
  VerificationContext validateIntegrity(Insertable<StrengthTraining> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
          _exerciseIdMeta,
          exerciseId.isAcceptableOrUnknown(
              data['exercise_id']!, _exerciseIdMeta));
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('device')) {
      context.handle(_deviceMeta,
          device.isAcceptableOrUnknown(data['device']!, _deviceMeta));
    } else if (isInserting) {
      context.missing(_deviceMeta);
    }
    if (data.containsKey('movement')) {
      context.handle(_movementMeta,
          movement.isAcceptableOrUnknown(data['movement']!, _movementMeta));
    } else if (isInserting) {
      context.missing(_movementMeta);
    }
    if (data.containsKey('sets')) {
      context.handle(
          _setsMeta, sets.isAcceptableOrUnknown(data['sets']!, _setsMeta));
    } else if (isInserting) {
      context.missing(_setsMeta);
    }
    if (data.containsKey('reps')) {
      context.handle(
          _repsMeta, reps.isAcceptableOrUnknown(data['reps']!, _repsMeta));
    } else if (isInserting) {
      context.missing(_repsMeta);
    }
    if (data.containsKey('weight')) {
      context.handle(_weightMeta,
          weight.isAcceptableOrUnknown(data['weight']!, _weightMeta));
    }
    if (data.containsKey('rest_seconds')) {
      context.handle(
          _restSecondsMeta,
          restSeconds.isAcceptableOrUnknown(
              data['rest_seconds']!, _restSecondsMeta));
    }
    if (data.containsKey('training_type')) {
      context.handle(
          _trainingTypeMeta,
          trainingType.isAcceptableOrUnknown(
              data['training_type']!, _trainingTypeMeta));
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
          _durationSecondsMeta,
          durationSeconds.isAcceptableOrUnknown(
              data['duration_seconds']!, _durationSecondsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StrengthTraining map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StrengthTraining(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      exerciseId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}exercise_id'])!,
      device: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device'])!,
      movement: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}movement'])!,
      sets: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sets'])!,
      reps: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}reps'])!,
      weight: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}weight']),
      restSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rest_seconds']),
      trainingType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}training_type'])!,
      durationSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_seconds']),
    );
  }

  @override
  $StrengthTrainingsTable createAlias(String alias) {
    return $StrengthTrainingsTable(attachedDatabase, alias);
  }
}

class StrengthTraining extends DataClass
    implements Insertable<StrengthTraining> {
  final int id;
  final int exerciseId;
  final String device;
  final String movement;
  final int sets;
  final int reps;
  final double? weight;
  final int? restSeconds;
  final String trainingType;
  final int? durationSeconds;
  const StrengthTraining(
      {required this.id,
      required this.exerciseId,
      required this.device,
      required this.movement,
      required this.sets,
      required this.reps,
      this.weight,
      this.restSeconds,
      required this.trainingType,
      this.durationSeconds});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['exercise_id'] = Variable<int>(exerciseId);
    map['device'] = Variable<String>(device);
    map['movement'] = Variable<String>(movement);
    map['sets'] = Variable<int>(sets);
    map['reps'] = Variable<int>(reps);
    if (!nullToAbsent || weight != null) {
      map['weight'] = Variable<double>(weight);
    }
    if (!nullToAbsent || restSeconds != null) {
      map['rest_seconds'] = Variable<int>(restSeconds);
    }
    map['training_type'] = Variable<String>(trainingType);
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    return map;
  }

  StrengthTrainingsCompanion toCompanion(bool nullToAbsent) {
    return StrengthTrainingsCompanion(
      id: Value(id),
      exerciseId: Value(exerciseId),
      device: Value(device),
      movement: Value(movement),
      sets: Value(sets),
      reps: Value(reps),
      weight:
          weight == null && nullToAbsent ? const Value.absent() : Value(weight),
      restSeconds: restSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(restSeconds),
      trainingType: Value(trainingType),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
    );
  }

  factory StrengthTraining.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StrengthTraining(
      id: serializer.fromJson<int>(json['id']),
      exerciseId: serializer.fromJson<int>(json['exerciseId']),
      device: serializer.fromJson<String>(json['device']),
      movement: serializer.fromJson<String>(json['movement']),
      sets: serializer.fromJson<int>(json['sets']),
      reps: serializer.fromJson<int>(json['reps']),
      weight: serializer.fromJson<double?>(json['weight']),
      restSeconds: serializer.fromJson<int?>(json['restSeconds']),
      trainingType: serializer.fromJson<String>(json['trainingType']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'exerciseId': serializer.toJson<int>(exerciseId),
      'device': serializer.toJson<String>(device),
      'movement': serializer.toJson<String>(movement),
      'sets': serializer.toJson<int>(sets),
      'reps': serializer.toJson<int>(reps),
      'weight': serializer.toJson<double?>(weight),
      'restSeconds': serializer.toJson<int?>(restSeconds),
      'trainingType': serializer.toJson<String>(trainingType),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
    };
  }

  StrengthTraining copyWith(
          {int? id,
          int? exerciseId,
          String? device,
          String? movement,
          int? sets,
          int? reps,
          Value<double?> weight = const Value.absent(),
          Value<int?> restSeconds = const Value.absent(),
          String? trainingType,
          Value<int?> durationSeconds = const Value.absent()}) =>
      StrengthTraining(
        id: id ?? this.id,
        exerciseId: exerciseId ?? this.exerciseId,
        device: device ?? this.device,
        movement: movement ?? this.movement,
        sets: sets ?? this.sets,
        reps: reps ?? this.reps,
        weight: weight.present ? weight.value : this.weight,
        restSeconds: restSeconds.present ? restSeconds.value : this.restSeconds,
        trainingType: trainingType ?? this.trainingType,
        durationSeconds: durationSeconds.present
            ? durationSeconds.value
            : this.durationSeconds,
      );
  StrengthTraining copyWithCompanion(StrengthTrainingsCompanion data) {
    return StrengthTraining(
      id: data.id.present ? data.id.value : this.id,
      exerciseId:
          data.exerciseId.present ? data.exerciseId.value : this.exerciseId,
      device: data.device.present ? data.device.value : this.device,
      movement: data.movement.present ? data.movement.value : this.movement,
      sets: data.sets.present ? data.sets.value : this.sets,
      reps: data.reps.present ? data.reps.value : this.reps,
      weight: data.weight.present ? data.weight.value : this.weight,
      restSeconds:
          data.restSeconds.present ? data.restSeconds.value : this.restSeconds,
      trainingType: data.trainingType.present
          ? data.trainingType.value
          : this.trainingType,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StrengthTraining(')
          ..write('id: $id, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('device: $device, ')
          ..write('movement: $movement, ')
          ..write('sets: $sets, ')
          ..write('reps: $reps, ')
          ..write('weight: $weight, ')
          ..write('restSeconds: $restSeconds, ')
          ..write('trainingType: $trainingType, ')
          ..write('durationSeconds: $durationSeconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, exerciseId, device, movement, sets, reps,
      weight, restSeconds, trainingType, durationSeconds);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StrengthTraining &&
          other.id == this.id &&
          other.exerciseId == this.exerciseId &&
          other.device == this.device &&
          other.movement == this.movement &&
          other.sets == this.sets &&
          other.reps == this.reps &&
          other.weight == this.weight &&
          other.restSeconds == this.restSeconds &&
          other.trainingType == this.trainingType &&
          other.durationSeconds == this.durationSeconds);
}

class StrengthTrainingsCompanion extends UpdateCompanion<StrengthTraining> {
  final Value<int> id;
  final Value<int> exerciseId;
  final Value<String> device;
  final Value<String> movement;
  final Value<int> sets;
  final Value<int> reps;
  final Value<double?> weight;
  final Value<int?> restSeconds;
  final Value<String> trainingType;
  final Value<int?> durationSeconds;
  const StrengthTrainingsCompanion({
    this.id = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.device = const Value.absent(),
    this.movement = const Value.absent(),
    this.sets = const Value.absent(),
    this.reps = const Value.absent(),
    this.weight = const Value.absent(),
    this.restSeconds = const Value.absent(),
    this.trainingType = const Value.absent(),
    this.durationSeconds = const Value.absent(),
  });
  StrengthTrainingsCompanion.insert({
    this.id = const Value.absent(),
    required int exerciseId,
    required String device,
    required String movement,
    required int sets,
    required int reps,
    this.weight = const Value.absent(),
    this.restSeconds = const Value.absent(),
    this.trainingType = const Value.absent(),
    this.durationSeconds = const Value.absent(),
  })  : exerciseId = Value(exerciseId),
        device = Value(device),
        movement = Value(movement),
        sets = Value(sets),
        reps = Value(reps);
  static Insertable<StrengthTraining> custom({
    Expression<int>? id,
    Expression<int>? exerciseId,
    Expression<String>? device,
    Expression<String>? movement,
    Expression<int>? sets,
    Expression<int>? reps,
    Expression<double>? weight,
    Expression<int>? restSeconds,
    Expression<String>? trainingType,
    Expression<int>? durationSeconds,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (device != null) 'device': device,
      if (movement != null) 'movement': movement,
      if (sets != null) 'sets': sets,
      if (reps != null) 'reps': reps,
      if (weight != null) 'weight': weight,
      if (restSeconds != null) 'rest_seconds': restSeconds,
      if (trainingType != null) 'training_type': trainingType,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
    });
  }

  StrengthTrainingsCompanion copyWith(
      {Value<int>? id,
      Value<int>? exerciseId,
      Value<String>? device,
      Value<String>? movement,
      Value<int>? sets,
      Value<int>? reps,
      Value<double?>? weight,
      Value<int?>? restSeconds,
      Value<String>? trainingType,
      Value<int?>? durationSeconds}) {
    return StrengthTrainingsCompanion(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      device: device ?? this.device,
      movement: movement ?? this.movement,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      restSeconds: restSeconds ?? this.restSeconds,
      trainingType: trainingType ?? this.trainingType,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<int>(exerciseId.value);
    }
    if (device.present) {
      map['device'] = Variable<String>(device.value);
    }
    if (movement.present) {
      map['movement'] = Variable<String>(movement.value);
    }
    if (sets.present) {
      map['sets'] = Variable<int>(sets.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (restSeconds.present) {
      map['rest_seconds'] = Variable<int>(restSeconds.value);
    }
    if (trainingType.present) {
      map['training_type'] = Variable<String>(trainingType.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StrengthTrainingsCompanion(')
          ..write('id: $id, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('device: $device, ')
          ..write('movement: $movement, ')
          ..write('sets: $sets, ')
          ..write('reps: $reps, ')
          ..write('weight: $weight, ')
          ..write('restSeconds: $restSeconds, ')
          ..write('trainingType: $trainingType, ')
          ..write('durationSeconds: $durationSeconds')
          ..write(')'))
        .toString();
  }
}

class $MealRecordsTable extends MealRecords
    with TableInfo<$MealRecordsTable, MealRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _recordedAtMeta =
      const VerificationMeta('recordedAt');
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
      'recorded_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _imagePathsMeta =
      const VerificationMeta('imagePaths');
  @override
  late final GeneratedColumn<String> imagePaths = GeneratedColumn<String>(
      'image_paths', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, type, recordedAt, imagePaths, note, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_records';
  @override
  VerificationContext validateIntegrity(Insertable<MealRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
          _recordedAtMeta,
          recordedAt.isAcceptableOrUnknown(
              data['recorded_at']!, _recordedAtMeta));
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('image_paths')) {
      context.handle(
          _imagePathsMeta,
          imagePaths.isAcceptableOrUnknown(
              data['image_paths']!, _imagePathsMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MealRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      recordedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}recorded_at'])!,
      imagePaths: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_paths']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $MealRecordsTable createAlias(String alias) {
    return $MealRecordsTable(attachedDatabase, alias);
  }
}

class MealRecord extends DataClass implements Insertable<MealRecord> {
  final int id;
  final String type;
  final DateTime recordedAt;
  final String? imagePaths;
  final String? note;
  final DateTime createdAt;
  const MealRecord(
      {required this.id,
      required this.type,
      required this.recordedAt,
      this.imagePaths,
      this.note,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    if (!nullToAbsent || imagePaths != null) {
      map['image_paths'] = Variable<String>(imagePaths);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MealRecordsCompanion toCompanion(bool nullToAbsent) {
    return MealRecordsCompanion(
      id: Value(id),
      type: Value(type),
      recordedAt: Value(recordedAt),
      imagePaths: imagePaths == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePaths),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory MealRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealRecord(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      imagePaths: serializer.fromJson<String?>(json['imagePaths']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'imagePaths': serializer.toJson<String?>(imagePaths),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MealRecord copyWith(
          {int? id,
          String? type,
          DateTime? recordedAt,
          Value<String?> imagePaths = const Value.absent(),
          Value<String?> note = const Value.absent(),
          DateTime? createdAt}) =>
      MealRecord(
        id: id ?? this.id,
        type: type ?? this.type,
        recordedAt: recordedAt ?? this.recordedAt,
        imagePaths: imagePaths.present ? imagePaths.value : this.imagePaths,
        note: note.present ? note.value : this.note,
        createdAt: createdAt ?? this.createdAt,
      );
  MealRecord copyWithCompanion(MealRecordsCompanion data) {
    return MealRecord(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      recordedAt:
          data.recordedAt.present ? data.recordedAt.value : this.recordedAt,
      imagePaths:
          data.imagePaths.present ? data.imagePaths.value : this.imagePaths,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealRecord(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('imagePaths: $imagePaths, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, type, recordedAt, imagePaths, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealRecord &&
          other.id == this.id &&
          other.type == this.type &&
          other.recordedAt == this.recordedAt &&
          other.imagePaths == this.imagePaths &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class MealRecordsCompanion extends UpdateCompanion<MealRecord> {
  final Value<int> id;
  final Value<String> type;
  final Value<DateTime> recordedAt;
  final Value<String?> imagePaths;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  const MealRecordsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.imagePaths = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  MealRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    required DateTime recordedAt,
    this.imagePaths = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime createdAt,
  })  : type = Value(type),
        recordedAt = Value(recordedAt),
        createdAt = Value(createdAt);
  static Insertable<MealRecord> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<DateTime>? recordedAt,
    Expression<String>? imagePaths,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (imagePaths != null) 'image_paths': imagePaths,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  MealRecordsCompanion copyWith(
      {Value<int>? id,
      Value<String>? type,
      Value<DateTime>? recordedAt,
      Value<String?>? imagePaths,
      Value<String?>? note,
      Value<DateTime>? createdAt}) {
    return MealRecordsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      recordedAt: recordedAt ?? this.recordedAt,
      imagePaths: imagePaths ?? this.imagePaths,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (imagePaths.present) {
      map['image_paths'] = Variable<String>(imagePaths.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealRecordsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('imagePaths: $imagePaths, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $FoodItemsTable extends FoodItems
    with TableInfo<$FoodItemsTable, FoodItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoodItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _mealIdMeta = const VerificationMeta('mealId');
  @override
  late final GeneratedColumn<int> mealId = GeneratedColumn<int>(
      'meal_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES meal_records (id)'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('g'));
  static const VerificationMeta _carbsMeta = const VerificationMeta('carbs');
  @override
  late final GeneratedColumn<double> carbs = GeneratedColumn<double>(
      'carbs', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, mealId, name, amount, unit, carbs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'food_items';
  @override
  VerificationContext validateIntegrity(Insertable<FoodItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('meal_id')) {
      context.handle(_mealIdMeta,
          mealId.isAcceptableOrUnknown(data['meal_id']!, _mealIdMeta));
    } else if (isInserting) {
      context.missing(_mealIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    }
    if (data.containsKey('carbs')) {
      context.handle(
          _carbsMeta, carbs.isAcceptableOrUnknown(data['carbs']!, _carbsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FoodItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FoodItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      mealId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}meal_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      carbs: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}carbs']),
    );
  }

  @override
  $FoodItemsTable createAlias(String alias) {
    return $FoodItemsTable(attachedDatabase, alias);
  }
}

class FoodItem extends DataClass implements Insertable<FoodItem> {
  final int id;
  final int mealId;
  final String name;
  final double amount;
  final String unit;
  final double? carbs;
  const FoodItem(
      {required this.id,
      required this.mealId,
      required this.name,
      required this.amount,
      required this.unit,
      this.carbs});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['meal_id'] = Variable<int>(mealId);
    map['name'] = Variable<String>(name);
    map['amount'] = Variable<double>(amount);
    map['unit'] = Variable<String>(unit);
    if (!nullToAbsent || carbs != null) {
      map['carbs'] = Variable<double>(carbs);
    }
    return map;
  }

  FoodItemsCompanion toCompanion(bool nullToAbsent) {
    return FoodItemsCompanion(
      id: Value(id),
      mealId: Value(mealId),
      name: Value(name),
      amount: Value(amount),
      unit: Value(unit),
      carbs:
          carbs == null && nullToAbsent ? const Value.absent() : Value(carbs),
    );
  }

  factory FoodItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FoodItem(
      id: serializer.fromJson<int>(json['id']),
      mealId: serializer.fromJson<int>(json['mealId']),
      name: serializer.fromJson<String>(json['name']),
      amount: serializer.fromJson<double>(json['amount']),
      unit: serializer.fromJson<String>(json['unit']),
      carbs: serializer.fromJson<double?>(json['carbs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'mealId': serializer.toJson<int>(mealId),
      'name': serializer.toJson<String>(name),
      'amount': serializer.toJson<double>(amount),
      'unit': serializer.toJson<String>(unit),
      'carbs': serializer.toJson<double?>(carbs),
    };
  }

  FoodItem copyWith(
          {int? id,
          int? mealId,
          String? name,
          double? amount,
          String? unit,
          Value<double?> carbs = const Value.absent()}) =>
      FoodItem(
        id: id ?? this.id,
        mealId: mealId ?? this.mealId,
        name: name ?? this.name,
        amount: amount ?? this.amount,
        unit: unit ?? this.unit,
        carbs: carbs.present ? carbs.value : this.carbs,
      );
  FoodItem copyWithCompanion(FoodItemsCompanion data) {
    return FoodItem(
      id: data.id.present ? data.id.value : this.id,
      mealId: data.mealId.present ? data.mealId.value : this.mealId,
      name: data.name.present ? data.name.value : this.name,
      amount: data.amount.present ? data.amount.value : this.amount,
      unit: data.unit.present ? data.unit.value : this.unit,
      carbs: data.carbs.present ? data.carbs.value : this.carbs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FoodItem(')
          ..write('id: $id, ')
          ..write('mealId: $mealId, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('unit: $unit, ')
          ..write('carbs: $carbs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, mealId, name, amount, unit, carbs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoodItem &&
          other.id == this.id &&
          other.mealId == this.mealId &&
          other.name == this.name &&
          other.amount == this.amount &&
          other.unit == this.unit &&
          other.carbs == this.carbs);
}

class FoodItemsCompanion extends UpdateCompanion<FoodItem> {
  final Value<int> id;
  final Value<int> mealId;
  final Value<String> name;
  final Value<double> amount;
  final Value<String> unit;
  final Value<double?> carbs;
  const FoodItemsCompanion({
    this.id = const Value.absent(),
    this.mealId = const Value.absent(),
    this.name = const Value.absent(),
    this.amount = const Value.absent(),
    this.unit = const Value.absent(),
    this.carbs = const Value.absent(),
  });
  FoodItemsCompanion.insert({
    this.id = const Value.absent(),
    required int mealId,
    required String name,
    required double amount,
    this.unit = const Value.absent(),
    this.carbs = const Value.absent(),
  })  : mealId = Value(mealId),
        name = Value(name),
        amount = Value(amount);
  static Insertable<FoodItem> custom({
    Expression<int>? id,
    Expression<int>? mealId,
    Expression<String>? name,
    Expression<double>? amount,
    Expression<String>? unit,
    Expression<double>? carbs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mealId != null) 'meal_id': mealId,
      if (name != null) 'name': name,
      if (amount != null) 'amount': amount,
      if (unit != null) 'unit': unit,
      if (carbs != null) 'carbs': carbs,
    });
  }

  FoodItemsCompanion copyWith(
      {Value<int>? id,
      Value<int>? mealId,
      Value<String>? name,
      Value<double>? amount,
      Value<String>? unit,
      Value<double?>? carbs}) {
    return FoodItemsCompanion(
      id: id ?? this.id,
      mealId: mealId ?? this.mealId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      carbs: carbs ?? this.carbs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (mealId.present) {
      map['meal_id'] = Variable<int>(mealId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (carbs.present) {
      map['carbs'] = Variable<double>(carbs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoodItemsCompanion(')
          ..write('id: $id, ')
          ..write('mealId: $mealId, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('unit: $unit, ')
          ..write('carbs: $carbs')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(Insertable<AppSetting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final int id;
  final String key;
  final String value;
  const AppSetting({required this.id, required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      key: Value(key),
      value: Value(value),
    );
  }

  factory AppSetting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      id: serializer.fromJson<int>(json['id']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({int? id, String? key, String? value}) => AppSetting(
        id: id ?? this.id,
        key: key ?? this.key,
        value: value ?? this.value,
      );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      id: data.id.present ? data.id.value : this.id,
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.id == this.id &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<int> id;
  final Value<String> key;
  final Value<String> value;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    required String key,
    required String value,
  })  : key = Value(key),
        value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<int>? id,
    Expression<String>? key,
    Expression<String>? value,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
    });
  }

  AppSettingsCompanion copyWith(
      {Value<int>? id, Value<String>? key, Value<String>? value}) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      key: key ?? this.key,
      value: value ?? this.value,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }
}

class $TrainingPlansTable extends TrainingPlans
    with TableInfo<$TrainingPlansTable, TrainingPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrainingPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, description, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'training_plans';
  @override
  VerificationContext validateIntegrity(Insertable<TrainingPlan> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrainingPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrainingPlan(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $TrainingPlansTable createAlias(String alias) {
    return $TrainingPlansTable(attachedDatabase, alias);
  }
}

class TrainingPlan extends DataClass implements Insertable<TrainingPlan> {
  final int id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  const TrainingPlan(
      {required this.id,
      required this.name,
      this.description,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TrainingPlansCompanion toCompanion(bool nullToAbsent) {
    return TrainingPlansCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TrainingPlan.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrainingPlan(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TrainingPlan copyWith(
          {int? id,
          String? name,
          Value<String?> description = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      TrainingPlan(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description.present ? description.value : this.description,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  TrainingPlan copyWithCompanion(TrainingPlansCompanion data) {
    return TrainingPlan(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrainingPlan(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, description, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrainingPlan &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TrainingPlansCompanion extends UpdateCompanion<TrainingPlan> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const TrainingPlansCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  TrainingPlansCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  })  : name = Value(name),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<TrainingPlan> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  TrainingPlansCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String?>? description,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return TrainingPlansCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrainingPlansCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TrainingPlanExercisesTable extends TrainingPlanExercises
    with TableInfo<$TrainingPlanExercisesTable, TrainingPlanExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrainingPlanExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<int> planId = GeneratedColumn<int>(
      'plan_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES training_plans (id)'));
  static const VerificationMeta _deviceMeta = const VerificationMeta('device');
  @override
  late final GeneratedColumn<String> device = GeneratedColumn<String>(
      'device', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _movementMeta =
      const VerificationMeta('movement');
  @override
  late final GeneratedColumn<String> movement = GeneratedColumn<String>(
      'movement', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _targetSetsMeta =
      const VerificationMeta('targetSets');
  @override
  late final GeneratedColumn<int> targetSets = GeneratedColumn<int>(
      'target_sets', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _targetRepsMeta =
      const VerificationMeta('targetReps');
  @override
  late final GeneratedColumn<int> targetReps = GeneratedColumn<int>(
      'target_reps', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _targetRepsListMeta =
      const VerificationMeta('targetRepsList');
  @override
  late final GeneratedColumn<String> targetRepsList = GeneratedColumn<String>(
      'target_reps_list', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _targetWeightMeta =
      const VerificationMeta('targetWeight');
  @override
  late final GeneratedColumn<double> targetWeight = GeneratedColumn<double>(
      'target_weight', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _restSecondsMeta =
      const VerificationMeta('restSeconds');
  @override
  late final GeneratedColumn<int> restSeconds = GeneratedColumn<int>(
      'rest_seconds', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _trainingTypeMeta =
      const VerificationMeta('trainingType');
  @override
  late final GeneratedColumn<String> trainingType = GeneratedColumn<String>(
      'training_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('strength'));
  static const VerificationMeta _orderIndexMeta =
      const VerificationMeta('orderIndex');
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
      'order_index', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        planId,
        device,
        movement,
        targetSets,
        targetReps,
        targetRepsList,
        targetWeight,
        restSeconds,
        trainingType,
        orderIndex
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'training_plan_exercises';
  @override
  VerificationContext validateIntegrity(
      Insertable<TrainingPlanExercise> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('plan_id')) {
      context.handle(_planIdMeta,
          planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta));
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('device')) {
      context.handle(_deviceMeta,
          device.isAcceptableOrUnknown(data['device']!, _deviceMeta));
    } else if (isInserting) {
      context.missing(_deviceMeta);
    }
    if (data.containsKey('movement')) {
      context.handle(_movementMeta,
          movement.isAcceptableOrUnknown(data['movement']!, _movementMeta));
    } else if (isInserting) {
      context.missing(_movementMeta);
    }
    if (data.containsKey('target_sets')) {
      context.handle(
          _targetSetsMeta,
          targetSets.isAcceptableOrUnknown(
              data['target_sets']!, _targetSetsMeta));
    } else if (isInserting) {
      context.missing(_targetSetsMeta);
    }
    if (data.containsKey('target_reps')) {
      context.handle(
          _targetRepsMeta,
          targetReps.isAcceptableOrUnknown(
              data['target_reps']!, _targetRepsMeta));
    } else if (isInserting) {
      context.missing(_targetRepsMeta);
    }
    if (data.containsKey('target_reps_list')) {
      context.handle(
          _targetRepsListMeta,
          targetRepsList.isAcceptableOrUnknown(
              data['target_reps_list']!, _targetRepsListMeta));
    }
    if (data.containsKey('target_weight')) {
      context.handle(
          _targetWeightMeta,
          targetWeight.isAcceptableOrUnknown(
              data['target_weight']!, _targetWeightMeta));
    }
    if (data.containsKey('rest_seconds')) {
      context.handle(
          _restSecondsMeta,
          restSeconds.isAcceptableOrUnknown(
              data['rest_seconds']!, _restSecondsMeta));
    }
    if (data.containsKey('training_type')) {
      context.handle(
          _trainingTypeMeta,
          trainingType.isAcceptableOrUnknown(
              data['training_type']!, _trainingTypeMeta));
    }
    if (data.containsKey('order_index')) {
      context.handle(
          _orderIndexMeta,
          orderIndex.isAcceptableOrUnknown(
              data['order_index']!, _orderIndexMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrainingPlanExercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrainingPlanExercise(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      planId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}plan_id'])!,
      device: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device'])!,
      movement: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}movement'])!,
      targetSets: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target_sets'])!,
      targetReps: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target_reps'])!,
      targetRepsList: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}target_reps_list']),
      targetWeight: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}target_weight']),
      restSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rest_seconds']),
      trainingType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}training_type'])!,
      orderIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order_index'])!,
    );
  }

  @override
  $TrainingPlanExercisesTable createAlias(String alias) {
    return $TrainingPlanExercisesTable(attachedDatabase, alias);
  }
}

class TrainingPlanExercise extends DataClass
    implements Insertable<TrainingPlanExercise> {
  final int id;
  final int planId;
  final String device;
  final String movement;
  final int targetSets;
  final int targetReps;
  final String? targetRepsList;
  final double? targetWeight;
  final int? restSeconds;
  final String trainingType;
  final int orderIndex;
  const TrainingPlanExercise(
      {required this.id,
      required this.planId,
      required this.device,
      required this.movement,
      required this.targetSets,
      required this.targetReps,
      this.targetRepsList,
      this.targetWeight,
      this.restSeconds,
      required this.trainingType,
      required this.orderIndex});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['plan_id'] = Variable<int>(planId);
    map['device'] = Variable<String>(device);
    map['movement'] = Variable<String>(movement);
    map['target_sets'] = Variable<int>(targetSets);
    map['target_reps'] = Variable<int>(targetReps);
    if (!nullToAbsent || targetRepsList != null) {
      map['target_reps_list'] = Variable<String>(targetRepsList);
    }
    if (!nullToAbsent || targetWeight != null) {
      map['target_weight'] = Variable<double>(targetWeight);
    }
    if (!nullToAbsent || restSeconds != null) {
      map['rest_seconds'] = Variable<int>(restSeconds);
    }
    map['training_type'] = Variable<String>(trainingType);
    map['order_index'] = Variable<int>(orderIndex);
    return map;
  }

  TrainingPlanExercisesCompanion toCompanion(bool nullToAbsent) {
    return TrainingPlanExercisesCompanion(
      id: Value(id),
      planId: Value(planId),
      device: Value(device),
      movement: Value(movement),
      targetSets: Value(targetSets),
      targetReps: Value(targetReps),
      targetRepsList: targetRepsList == null && nullToAbsent
          ? const Value.absent()
          : Value(targetRepsList),
      targetWeight: targetWeight == null && nullToAbsent
          ? const Value.absent()
          : Value(targetWeight),
      restSeconds: restSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(restSeconds),
      trainingType: Value(trainingType),
      orderIndex: Value(orderIndex),
    );
  }

  factory TrainingPlanExercise.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrainingPlanExercise(
      id: serializer.fromJson<int>(json['id']),
      planId: serializer.fromJson<int>(json['planId']),
      device: serializer.fromJson<String>(json['device']),
      movement: serializer.fromJson<String>(json['movement']),
      targetSets: serializer.fromJson<int>(json['targetSets']),
      targetReps: serializer.fromJson<int>(json['targetReps']),
      targetRepsList: serializer.fromJson<String?>(json['targetRepsList']),
      targetWeight: serializer.fromJson<double?>(json['targetWeight']),
      restSeconds: serializer.fromJson<int?>(json['restSeconds']),
      trainingType: serializer.fromJson<String>(json['trainingType']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'planId': serializer.toJson<int>(planId),
      'device': serializer.toJson<String>(device),
      'movement': serializer.toJson<String>(movement),
      'targetSets': serializer.toJson<int>(targetSets),
      'targetReps': serializer.toJson<int>(targetReps),
      'targetRepsList': serializer.toJson<String?>(targetRepsList),
      'targetWeight': serializer.toJson<double?>(targetWeight),
      'restSeconds': serializer.toJson<int?>(restSeconds),
      'trainingType': serializer.toJson<String>(trainingType),
      'orderIndex': serializer.toJson<int>(orderIndex),
    };
  }

  TrainingPlanExercise copyWith(
          {int? id,
          int? planId,
          String? device,
          String? movement,
          int? targetSets,
          int? targetReps,
          Value<String?> targetRepsList = const Value.absent(),
          Value<double?> targetWeight = const Value.absent(),
          Value<int?> restSeconds = const Value.absent(),
          String? trainingType,
          int? orderIndex}) =>
      TrainingPlanExercise(
        id: id ?? this.id,
        planId: planId ?? this.planId,
        device: device ?? this.device,
        movement: movement ?? this.movement,
        targetSets: targetSets ?? this.targetSets,
        targetReps: targetReps ?? this.targetReps,
        targetRepsList:
            targetRepsList.present ? targetRepsList.value : this.targetRepsList,
        targetWeight:
            targetWeight.present ? targetWeight.value : this.targetWeight,
        restSeconds: restSeconds.present ? restSeconds.value : this.restSeconds,
        trainingType: trainingType ?? this.trainingType,
        orderIndex: orderIndex ?? this.orderIndex,
      );
  TrainingPlanExercise copyWithCompanion(TrainingPlanExercisesCompanion data) {
    return TrainingPlanExercise(
      id: data.id.present ? data.id.value : this.id,
      planId: data.planId.present ? data.planId.value : this.planId,
      device: data.device.present ? data.device.value : this.device,
      movement: data.movement.present ? data.movement.value : this.movement,
      targetSets:
          data.targetSets.present ? data.targetSets.value : this.targetSets,
      targetReps:
          data.targetReps.present ? data.targetReps.value : this.targetReps,
      targetRepsList: data.targetRepsList.present
          ? data.targetRepsList.value
          : this.targetRepsList,
      targetWeight: data.targetWeight.present
          ? data.targetWeight.value
          : this.targetWeight,
      restSeconds:
          data.restSeconds.present ? data.restSeconds.value : this.restSeconds,
      trainingType: data.trainingType.present
          ? data.trainingType.value
          : this.trainingType,
      orderIndex:
          data.orderIndex.present ? data.orderIndex.value : this.orderIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrainingPlanExercise(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('device: $device, ')
          ..write('movement: $movement, ')
          ..write('targetSets: $targetSets, ')
          ..write('targetReps: $targetReps, ')
          ..write('targetRepsList: $targetRepsList, ')
          ..write('targetWeight: $targetWeight, ')
          ..write('restSeconds: $restSeconds, ')
          ..write('trainingType: $trainingType, ')
          ..write('orderIndex: $orderIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      planId,
      device,
      movement,
      targetSets,
      targetReps,
      targetRepsList,
      targetWeight,
      restSeconds,
      trainingType,
      orderIndex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrainingPlanExercise &&
          other.id == this.id &&
          other.planId == this.planId &&
          other.device == this.device &&
          other.movement == this.movement &&
          other.targetSets == this.targetSets &&
          other.targetReps == this.targetReps &&
          other.targetRepsList == this.targetRepsList &&
          other.targetWeight == this.targetWeight &&
          other.restSeconds == this.restSeconds &&
          other.trainingType == this.trainingType &&
          other.orderIndex == this.orderIndex);
}

class TrainingPlanExercisesCompanion
    extends UpdateCompanion<TrainingPlanExercise> {
  final Value<int> id;
  final Value<int> planId;
  final Value<String> device;
  final Value<String> movement;
  final Value<int> targetSets;
  final Value<int> targetReps;
  final Value<String?> targetRepsList;
  final Value<double?> targetWeight;
  final Value<int?> restSeconds;
  final Value<String> trainingType;
  final Value<int> orderIndex;
  const TrainingPlanExercisesCompanion({
    this.id = const Value.absent(),
    this.planId = const Value.absent(),
    this.device = const Value.absent(),
    this.movement = const Value.absent(),
    this.targetSets = const Value.absent(),
    this.targetReps = const Value.absent(),
    this.targetRepsList = const Value.absent(),
    this.targetWeight = const Value.absent(),
    this.restSeconds = const Value.absent(),
    this.trainingType = const Value.absent(),
    this.orderIndex = const Value.absent(),
  });
  TrainingPlanExercisesCompanion.insert({
    this.id = const Value.absent(),
    required int planId,
    required String device,
    required String movement,
    required int targetSets,
    required int targetReps,
    this.targetRepsList = const Value.absent(),
    this.targetWeight = const Value.absent(),
    this.restSeconds = const Value.absent(),
    this.trainingType = const Value.absent(),
    this.orderIndex = const Value.absent(),
  })  : planId = Value(planId),
        device = Value(device),
        movement = Value(movement),
        targetSets = Value(targetSets),
        targetReps = Value(targetReps);
  static Insertable<TrainingPlanExercise> custom({
    Expression<int>? id,
    Expression<int>? planId,
    Expression<String>? device,
    Expression<String>? movement,
    Expression<int>? targetSets,
    Expression<int>? targetReps,
    Expression<String>? targetRepsList,
    Expression<double>? targetWeight,
    Expression<int>? restSeconds,
    Expression<String>? trainingType,
    Expression<int>? orderIndex,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planId != null) 'plan_id': planId,
      if (device != null) 'device': device,
      if (movement != null) 'movement': movement,
      if (targetSets != null) 'target_sets': targetSets,
      if (targetReps != null) 'target_reps': targetReps,
      if (targetRepsList != null) 'target_reps_list': targetRepsList,
      if (targetWeight != null) 'target_weight': targetWeight,
      if (restSeconds != null) 'rest_seconds': restSeconds,
      if (trainingType != null) 'training_type': trainingType,
      if (orderIndex != null) 'order_index': orderIndex,
    });
  }

  TrainingPlanExercisesCompanion copyWith(
      {Value<int>? id,
      Value<int>? planId,
      Value<String>? device,
      Value<String>? movement,
      Value<int>? targetSets,
      Value<int>? targetReps,
      Value<String?>? targetRepsList,
      Value<double?>? targetWeight,
      Value<int?>? restSeconds,
      Value<String>? trainingType,
      Value<int>? orderIndex}) {
    return TrainingPlanExercisesCompanion(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      device: device ?? this.device,
      movement: movement ?? this.movement,
      targetSets: targetSets ?? this.targetSets,
      targetReps: targetReps ?? this.targetReps,
      targetRepsList: targetRepsList ?? this.targetRepsList,
      targetWeight: targetWeight ?? this.targetWeight,
      restSeconds: restSeconds ?? this.restSeconds,
      trainingType: trainingType ?? this.trainingType,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<int>(planId.value);
    }
    if (device.present) {
      map['device'] = Variable<String>(device.value);
    }
    if (movement.present) {
      map['movement'] = Variable<String>(movement.value);
    }
    if (targetSets.present) {
      map['target_sets'] = Variable<int>(targetSets.value);
    }
    if (targetReps.present) {
      map['target_reps'] = Variable<int>(targetReps.value);
    }
    if (targetRepsList.present) {
      map['target_reps_list'] = Variable<String>(targetRepsList.value);
    }
    if (targetWeight.present) {
      map['target_weight'] = Variable<double>(targetWeight.value);
    }
    if (restSeconds.present) {
      map['rest_seconds'] = Variable<int>(restSeconds.value);
    }
    if (trainingType.present) {
      map['training_type'] = Variable<String>(trainingType.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrainingPlanExercisesCompanion(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('device: $device, ')
          ..write('movement: $movement, ')
          ..write('targetSets: $targetSets, ')
          ..write('targetReps: $targetReps, ')
          ..write('targetRepsList: $targetRepsList, ')
          ..write('targetWeight: $targetWeight, ')
          ..write('restSeconds: $restSeconds, ')
          ..write('trainingType: $trainingType, ')
          ..write('orderIndex: $orderIndex')
          ..write(')'))
        .toString();
  }
}

class $BodyMeasurementsTable extends BodyMeasurements
    with TableInfo<$BodyMeasurementsTable, BodyMeasurement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BodyMeasurementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
      'weight', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<double> height = GeneratedColumn<double>(
      'height', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _bodyFatMeta =
      const VerificationMeta('bodyFat');
  @override
  late final GeneratedColumn<double> bodyFat = GeneratedColumn<double>(
      'body_fat', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _muscleMassMeta =
      const VerificationMeta('muscleMass');
  @override
  late final GeneratedColumn<double> muscleMass = GeneratedColumn<double>(
      'muscle_mass', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _chestMeta = const VerificationMeta('chest');
  @override
  late final GeneratedColumn<double> chest = GeneratedColumn<double>(
      'chest', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _waistMeta = const VerificationMeta('waist');
  @override
  late final GeneratedColumn<double> waist = GeneratedColumn<double>(
      'waist', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _hipMeta = const VerificationMeta('hip');
  @override
  late final GeneratedColumn<double> hip = GeneratedColumn<double>(
      'hip', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _thighLeftMeta =
      const VerificationMeta('thighLeft');
  @override
  late final GeneratedColumn<double> thighLeft = GeneratedColumn<double>(
      'thigh_left', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _thighRightMeta =
      const VerificationMeta('thighRight');
  @override
  late final GeneratedColumn<double> thighRight = GeneratedColumn<double>(
      'thigh_right', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _armLeftMeta =
      const VerificationMeta('armLeft');
  @override
  late final GeneratedColumn<double> armLeft = GeneratedColumn<double>(
      'arm_left', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _armRightMeta =
      const VerificationMeta('armRight');
  @override
  late final GeneratedColumn<double> armRight = GeneratedColumn<double>(
      'arm_right', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _neckMeta = const VerificationMeta('neck');
  @override
  late final GeneratedColumn<double> neck = GeneratedColumn<double>(
      'neck', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _bmiMeta = const VerificationMeta('bmi');
  @override
  late final GeneratedColumn<double> bmi = GeneratedColumn<double>(
      'bmi', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _waistHipRatioMeta =
      const VerificationMeta('waistHipRatio');
  @override
  late final GeneratedColumn<double> waistHipRatio = GeneratedColumn<double>(
      'waist_hip_ratio', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _imagePathMeta =
      const VerificationMeta('imagePath');
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
      'image_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _measuredAtMeta =
      const VerificationMeta('measuredAt');
  @override
  late final GeneratedColumn<DateTime> measuredAt = GeneratedColumn<DateTime>(
      'measured_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        weight,
        height,
        bodyFat,
        muscleMass,
        chest,
        waist,
        hip,
        thighLeft,
        thighRight,
        armLeft,
        armRight,
        neck,
        bmi,
        waistHipRatio,
        note,
        imagePath,
        measuredAt,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'body_measurements';
  @override
  VerificationContext validateIntegrity(Insertable<BodyMeasurement> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('weight')) {
      context.handle(_weightMeta,
          weight.isAcceptableOrUnknown(data['weight']!, _weightMeta));
    }
    if (data.containsKey('height')) {
      context.handle(_heightMeta,
          height.isAcceptableOrUnknown(data['height']!, _heightMeta));
    }
    if (data.containsKey('body_fat')) {
      context.handle(_bodyFatMeta,
          bodyFat.isAcceptableOrUnknown(data['body_fat']!, _bodyFatMeta));
    }
    if (data.containsKey('muscle_mass')) {
      context.handle(
          _muscleMassMeta,
          muscleMass.isAcceptableOrUnknown(
              data['muscle_mass']!, _muscleMassMeta));
    }
    if (data.containsKey('chest')) {
      context.handle(
          _chestMeta, chest.isAcceptableOrUnknown(data['chest']!, _chestMeta));
    }
    if (data.containsKey('waist')) {
      context.handle(
          _waistMeta, waist.isAcceptableOrUnknown(data['waist']!, _waistMeta));
    }
    if (data.containsKey('hip')) {
      context.handle(
          _hipMeta, hip.isAcceptableOrUnknown(data['hip']!, _hipMeta));
    }
    if (data.containsKey('thigh_left')) {
      context.handle(_thighLeftMeta,
          thighLeft.isAcceptableOrUnknown(data['thigh_left']!, _thighLeftMeta));
    }
    if (data.containsKey('thigh_right')) {
      context.handle(
          _thighRightMeta,
          thighRight.isAcceptableOrUnknown(
              data['thigh_right']!, _thighRightMeta));
    }
    if (data.containsKey('arm_left')) {
      context.handle(_armLeftMeta,
          armLeft.isAcceptableOrUnknown(data['arm_left']!, _armLeftMeta));
    }
    if (data.containsKey('arm_right')) {
      context.handle(_armRightMeta,
          armRight.isAcceptableOrUnknown(data['arm_right']!, _armRightMeta));
    }
    if (data.containsKey('neck')) {
      context.handle(
          _neckMeta, neck.isAcceptableOrUnknown(data['neck']!, _neckMeta));
    }
    if (data.containsKey('bmi')) {
      context.handle(
          _bmiMeta, bmi.isAcceptableOrUnknown(data['bmi']!, _bmiMeta));
    }
    if (data.containsKey('waist_hip_ratio')) {
      context.handle(
          _waistHipRatioMeta,
          waistHipRatio.isAcceptableOrUnknown(
              data['waist_hip_ratio']!, _waistHipRatioMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('image_path')) {
      context.handle(_imagePathMeta,
          imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta));
    }
    if (data.containsKey('measured_at')) {
      context.handle(
          _measuredAtMeta,
          measuredAt.isAcceptableOrUnknown(
              data['measured_at']!, _measuredAtMeta));
    } else if (isInserting) {
      context.missing(_measuredAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BodyMeasurement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BodyMeasurement(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      weight: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}weight']),
      height: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}height']),
      bodyFat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}body_fat']),
      muscleMass: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}muscle_mass']),
      chest: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}chest']),
      waist: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}waist']),
      hip: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}hip']),
      thighLeft: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}thigh_left']),
      thighRight: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}thigh_right']),
      armLeft: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}arm_left']),
      armRight: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}arm_right']),
      neck: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}neck']),
      bmi: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}bmi']),
      waistHipRatio: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}waist_hip_ratio']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      imagePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_path']),
      measuredAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}measured_at'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $BodyMeasurementsTable createAlias(String alias) {
    return $BodyMeasurementsTable(attachedDatabase, alias);
  }
}

class BodyMeasurement extends DataClass implements Insertable<BodyMeasurement> {
  final int id;
  final double? weight;
  final double? height;
  final double? bodyFat;
  final double? muscleMass;
  final double? chest;
  final double? waist;
  final double? hip;
  final double? thighLeft;
  final double? thighRight;
  final double? armLeft;
  final double? armRight;
  final double? neck;
  final double? bmi;
  final double? waistHipRatio;
  final String? note;
  final String? imagePath;
  final DateTime measuredAt;
  final DateTime createdAt;
  const BodyMeasurement(
      {required this.id,
      this.weight,
      this.height,
      this.bodyFat,
      this.muscleMass,
      this.chest,
      this.waist,
      this.hip,
      this.thighLeft,
      this.thighRight,
      this.armLeft,
      this.armRight,
      this.neck,
      this.bmi,
      this.waistHipRatio,
      this.note,
      this.imagePath,
      required this.measuredAt,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || weight != null) {
      map['weight'] = Variable<double>(weight);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<double>(height);
    }
    if (!nullToAbsent || bodyFat != null) {
      map['body_fat'] = Variable<double>(bodyFat);
    }
    if (!nullToAbsent || muscleMass != null) {
      map['muscle_mass'] = Variable<double>(muscleMass);
    }
    if (!nullToAbsent || chest != null) {
      map['chest'] = Variable<double>(chest);
    }
    if (!nullToAbsent || waist != null) {
      map['waist'] = Variable<double>(waist);
    }
    if (!nullToAbsent || hip != null) {
      map['hip'] = Variable<double>(hip);
    }
    if (!nullToAbsent || thighLeft != null) {
      map['thigh_left'] = Variable<double>(thighLeft);
    }
    if (!nullToAbsent || thighRight != null) {
      map['thigh_right'] = Variable<double>(thighRight);
    }
    if (!nullToAbsent || armLeft != null) {
      map['arm_left'] = Variable<double>(armLeft);
    }
    if (!nullToAbsent || armRight != null) {
      map['arm_right'] = Variable<double>(armRight);
    }
    if (!nullToAbsent || neck != null) {
      map['neck'] = Variable<double>(neck);
    }
    if (!nullToAbsent || bmi != null) {
      map['bmi'] = Variable<double>(bmi);
    }
    if (!nullToAbsent || waistHipRatio != null) {
      map['waist_hip_ratio'] = Variable<double>(waistHipRatio);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    map['measured_at'] = Variable<DateTime>(measuredAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BodyMeasurementsCompanion toCompanion(bool nullToAbsent) {
    return BodyMeasurementsCompanion(
      id: Value(id),
      weight:
          weight == null && nullToAbsent ? const Value.absent() : Value(weight),
      height:
          height == null && nullToAbsent ? const Value.absent() : Value(height),
      bodyFat: bodyFat == null && nullToAbsent
          ? const Value.absent()
          : Value(bodyFat),
      muscleMass: muscleMass == null && nullToAbsent
          ? const Value.absent()
          : Value(muscleMass),
      chest:
          chest == null && nullToAbsent ? const Value.absent() : Value(chest),
      waist:
          waist == null && nullToAbsent ? const Value.absent() : Value(waist),
      hip: hip == null && nullToAbsent ? const Value.absent() : Value(hip),
      thighLeft: thighLeft == null && nullToAbsent
          ? const Value.absent()
          : Value(thighLeft),
      thighRight: thighRight == null && nullToAbsent
          ? const Value.absent()
          : Value(thighRight),
      armLeft: armLeft == null && nullToAbsent
          ? const Value.absent()
          : Value(armLeft),
      armRight: armRight == null && nullToAbsent
          ? const Value.absent()
          : Value(armRight),
      neck: neck == null && nullToAbsent ? const Value.absent() : Value(neck),
      bmi: bmi == null && nullToAbsent ? const Value.absent() : Value(bmi),
      waistHipRatio: waistHipRatio == null && nullToAbsent
          ? const Value.absent()
          : Value(waistHipRatio),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      measuredAt: Value(measuredAt),
      createdAt: Value(createdAt),
    );
  }

  factory BodyMeasurement.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BodyMeasurement(
      id: serializer.fromJson<int>(json['id']),
      weight: serializer.fromJson<double?>(json['weight']),
      height: serializer.fromJson<double?>(json['height']),
      bodyFat: serializer.fromJson<double?>(json['bodyFat']),
      muscleMass: serializer.fromJson<double?>(json['muscleMass']),
      chest: serializer.fromJson<double?>(json['chest']),
      waist: serializer.fromJson<double?>(json['waist']),
      hip: serializer.fromJson<double?>(json['hip']),
      thighLeft: serializer.fromJson<double?>(json['thighLeft']),
      thighRight: serializer.fromJson<double?>(json['thighRight']),
      armLeft: serializer.fromJson<double?>(json['armLeft']),
      armRight: serializer.fromJson<double?>(json['armRight']),
      neck: serializer.fromJson<double?>(json['neck']),
      bmi: serializer.fromJson<double?>(json['bmi']),
      waistHipRatio: serializer.fromJson<double?>(json['waistHipRatio']),
      note: serializer.fromJson<String?>(json['note']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      measuredAt: serializer.fromJson<DateTime>(json['measuredAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'weight': serializer.toJson<double?>(weight),
      'height': serializer.toJson<double?>(height),
      'bodyFat': serializer.toJson<double?>(bodyFat),
      'muscleMass': serializer.toJson<double?>(muscleMass),
      'chest': serializer.toJson<double?>(chest),
      'waist': serializer.toJson<double?>(waist),
      'hip': serializer.toJson<double?>(hip),
      'thighLeft': serializer.toJson<double?>(thighLeft),
      'thighRight': serializer.toJson<double?>(thighRight),
      'armLeft': serializer.toJson<double?>(armLeft),
      'armRight': serializer.toJson<double?>(armRight),
      'neck': serializer.toJson<double?>(neck),
      'bmi': serializer.toJson<double?>(bmi),
      'waistHipRatio': serializer.toJson<double?>(waistHipRatio),
      'note': serializer.toJson<String?>(note),
      'imagePath': serializer.toJson<String?>(imagePath),
      'measuredAt': serializer.toJson<DateTime>(measuredAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  BodyMeasurement copyWith(
          {int? id,
          Value<double?> weight = const Value.absent(),
          Value<double?> height = const Value.absent(),
          Value<double?> bodyFat = const Value.absent(),
          Value<double?> muscleMass = const Value.absent(),
          Value<double?> chest = const Value.absent(),
          Value<double?> waist = const Value.absent(),
          Value<double?> hip = const Value.absent(),
          Value<double?> thighLeft = const Value.absent(),
          Value<double?> thighRight = const Value.absent(),
          Value<double?> armLeft = const Value.absent(),
          Value<double?> armRight = const Value.absent(),
          Value<double?> neck = const Value.absent(),
          Value<double?> bmi = const Value.absent(),
          Value<double?> waistHipRatio = const Value.absent(),
          Value<String?> note = const Value.absent(),
          Value<String?> imagePath = const Value.absent(),
          DateTime? measuredAt,
          DateTime? createdAt}) =>
      BodyMeasurement(
        id: id ?? this.id,
        weight: weight.present ? weight.value : this.weight,
        height: height.present ? height.value : this.height,
        bodyFat: bodyFat.present ? bodyFat.value : this.bodyFat,
        muscleMass: muscleMass.present ? muscleMass.value : this.muscleMass,
        chest: chest.present ? chest.value : this.chest,
        waist: waist.present ? waist.value : this.waist,
        hip: hip.present ? hip.value : this.hip,
        thighLeft: thighLeft.present ? thighLeft.value : this.thighLeft,
        thighRight: thighRight.present ? thighRight.value : this.thighRight,
        armLeft: armLeft.present ? armLeft.value : this.armLeft,
        armRight: armRight.present ? armRight.value : this.armRight,
        neck: neck.present ? neck.value : this.neck,
        bmi: bmi.present ? bmi.value : this.bmi,
        waistHipRatio:
            waistHipRatio.present ? waistHipRatio.value : this.waistHipRatio,
        note: note.present ? note.value : this.note,
        imagePath: imagePath.present ? imagePath.value : this.imagePath,
        measuredAt: measuredAt ?? this.measuredAt,
        createdAt: createdAt ?? this.createdAt,
      );
  BodyMeasurement copyWithCompanion(BodyMeasurementsCompanion data) {
    return BodyMeasurement(
      id: data.id.present ? data.id.value : this.id,
      weight: data.weight.present ? data.weight.value : this.weight,
      height: data.height.present ? data.height.value : this.height,
      bodyFat: data.bodyFat.present ? data.bodyFat.value : this.bodyFat,
      muscleMass:
          data.muscleMass.present ? data.muscleMass.value : this.muscleMass,
      chest: data.chest.present ? data.chest.value : this.chest,
      waist: data.waist.present ? data.waist.value : this.waist,
      hip: data.hip.present ? data.hip.value : this.hip,
      thighLeft: data.thighLeft.present ? data.thighLeft.value : this.thighLeft,
      thighRight:
          data.thighRight.present ? data.thighRight.value : this.thighRight,
      armLeft: data.armLeft.present ? data.armLeft.value : this.armLeft,
      armRight: data.armRight.present ? data.armRight.value : this.armRight,
      neck: data.neck.present ? data.neck.value : this.neck,
      bmi: data.bmi.present ? data.bmi.value : this.bmi,
      waistHipRatio: data.waistHipRatio.present
          ? data.waistHipRatio.value
          : this.waistHipRatio,
      note: data.note.present ? data.note.value : this.note,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      measuredAt:
          data.measuredAt.present ? data.measuredAt.value : this.measuredAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BodyMeasurement(')
          ..write('id: $id, ')
          ..write('weight: $weight, ')
          ..write('height: $height, ')
          ..write('bodyFat: $bodyFat, ')
          ..write('muscleMass: $muscleMass, ')
          ..write('chest: $chest, ')
          ..write('waist: $waist, ')
          ..write('hip: $hip, ')
          ..write('thighLeft: $thighLeft, ')
          ..write('thighRight: $thighRight, ')
          ..write('armLeft: $armLeft, ')
          ..write('armRight: $armRight, ')
          ..write('neck: $neck, ')
          ..write('bmi: $bmi, ')
          ..write('waistHipRatio: $waistHipRatio, ')
          ..write('note: $note, ')
          ..write('imagePath: $imagePath, ')
          ..write('measuredAt: $measuredAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      weight,
      height,
      bodyFat,
      muscleMass,
      chest,
      waist,
      hip,
      thighLeft,
      thighRight,
      armLeft,
      armRight,
      neck,
      bmi,
      waistHipRatio,
      note,
      imagePath,
      measuredAt,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BodyMeasurement &&
          other.id == this.id &&
          other.weight == this.weight &&
          other.height == this.height &&
          other.bodyFat == this.bodyFat &&
          other.muscleMass == this.muscleMass &&
          other.chest == this.chest &&
          other.waist == this.waist &&
          other.hip == this.hip &&
          other.thighLeft == this.thighLeft &&
          other.thighRight == this.thighRight &&
          other.armLeft == this.armLeft &&
          other.armRight == this.armRight &&
          other.neck == this.neck &&
          other.bmi == this.bmi &&
          other.waistHipRatio == this.waistHipRatio &&
          other.note == this.note &&
          other.imagePath == this.imagePath &&
          other.measuredAt == this.measuredAt &&
          other.createdAt == this.createdAt);
}

class BodyMeasurementsCompanion extends UpdateCompanion<BodyMeasurement> {
  final Value<int> id;
  final Value<double?> weight;
  final Value<double?> height;
  final Value<double?> bodyFat;
  final Value<double?> muscleMass;
  final Value<double?> chest;
  final Value<double?> waist;
  final Value<double?> hip;
  final Value<double?> thighLeft;
  final Value<double?> thighRight;
  final Value<double?> armLeft;
  final Value<double?> armRight;
  final Value<double?> neck;
  final Value<double?> bmi;
  final Value<double?> waistHipRatio;
  final Value<String?> note;
  final Value<String?> imagePath;
  final Value<DateTime> measuredAt;
  final Value<DateTime> createdAt;
  const BodyMeasurementsCompanion({
    this.id = const Value.absent(),
    this.weight = const Value.absent(),
    this.height = const Value.absent(),
    this.bodyFat = const Value.absent(),
    this.muscleMass = const Value.absent(),
    this.chest = const Value.absent(),
    this.waist = const Value.absent(),
    this.hip = const Value.absent(),
    this.thighLeft = const Value.absent(),
    this.thighRight = const Value.absent(),
    this.armLeft = const Value.absent(),
    this.armRight = const Value.absent(),
    this.neck = const Value.absent(),
    this.bmi = const Value.absent(),
    this.waistHipRatio = const Value.absent(),
    this.note = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.measuredAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  BodyMeasurementsCompanion.insert({
    this.id = const Value.absent(),
    this.weight = const Value.absent(),
    this.height = const Value.absent(),
    this.bodyFat = const Value.absent(),
    this.muscleMass = const Value.absent(),
    this.chest = const Value.absent(),
    this.waist = const Value.absent(),
    this.hip = const Value.absent(),
    this.thighLeft = const Value.absent(),
    this.thighRight = const Value.absent(),
    this.armLeft = const Value.absent(),
    this.armRight = const Value.absent(),
    this.neck = const Value.absent(),
    this.bmi = const Value.absent(),
    this.waistHipRatio = const Value.absent(),
    this.note = const Value.absent(),
    this.imagePath = const Value.absent(),
    required DateTime measuredAt,
    required DateTime createdAt,
  })  : measuredAt = Value(measuredAt),
        createdAt = Value(createdAt);
  static Insertable<BodyMeasurement> custom({
    Expression<int>? id,
    Expression<double>? weight,
    Expression<double>? height,
    Expression<double>? bodyFat,
    Expression<double>? muscleMass,
    Expression<double>? chest,
    Expression<double>? waist,
    Expression<double>? hip,
    Expression<double>? thighLeft,
    Expression<double>? thighRight,
    Expression<double>? armLeft,
    Expression<double>? armRight,
    Expression<double>? neck,
    Expression<double>? bmi,
    Expression<double>? waistHipRatio,
    Expression<String>? note,
    Expression<String>? imagePath,
    Expression<DateTime>? measuredAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (weight != null) 'weight': weight,
      if (height != null) 'height': height,
      if (bodyFat != null) 'body_fat': bodyFat,
      if (muscleMass != null) 'muscle_mass': muscleMass,
      if (chest != null) 'chest': chest,
      if (waist != null) 'waist': waist,
      if (hip != null) 'hip': hip,
      if (thighLeft != null) 'thigh_left': thighLeft,
      if (thighRight != null) 'thigh_right': thighRight,
      if (armLeft != null) 'arm_left': armLeft,
      if (armRight != null) 'arm_right': armRight,
      if (neck != null) 'neck': neck,
      if (bmi != null) 'bmi': bmi,
      if (waistHipRatio != null) 'waist_hip_ratio': waistHipRatio,
      if (note != null) 'note': note,
      if (imagePath != null) 'image_path': imagePath,
      if (measuredAt != null) 'measured_at': measuredAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  BodyMeasurementsCompanion copyWith(
      {Value<int>? id,
      Value<double?>? weight,
      Value<double?>? height,
      Value<double?>? bodyFat,
      Value<double?>? muscleMass,
      Value<double?>? chest,
      Value<double?>? waist,
      Value<double?>? hip,
      Value<double?>? thighLeft,
      Value<double?>? thighRight,
      Value<double?>? armLeft,
      Value<double?>? armRight,
      Value<double?>? neck,
      Value<double?>? bmi,
      Value<double?>? waistHipRatio,
      Value<String?>? note,
      Value<String?>? imagePath,
      Value<DateTime>? measuredAt,
      Value<DateTime>? createdAt}) {
    return BodyMeasurementsCompanion(
      id: id ?? this.id,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      bodyFat: bodyFat ?? this.bodyFat,
      muscleMass: muscleMass ?? this.muscleMass,
      chest: chest ?? this.chest,
      waist: waist ?? this.waist,
      hip: hip ?? this.hip,
      thighLeft: thighLeft ?? this.thighLeft,
      thighRight: thighRight ?? this.thighRight,
      armLeft: armLeft ?? this.armLeft,
      armRight: armRight ?? this.armRight,
      neck: neck ?? this.neck,
      bmi: bmi ?? this.bmi,
      waistHipRatio: waistHipRatio ?? this.waistHipRatio,
      note: note ?? this.note,
      imagePath: imagePath ?? this.imagePath,
      measuredAt: measuredAt ?? this.measuredAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    if (height.present) {
      map['height'] = Variable<double>(height.value);
    }
    if (bodyFat.present) {
      map['body_fat'] = Variable<double>(bodyFat.value);
    }
    if (muscleMass.present) {
      map['muscle_mass'] = Variable<double>(muscleMass.value);
    }
    if (chest.present) {
      map['chest'] = Variable<double>(chest.value);
    }
    if (waist.present) {
      map['waist'] = Variable<double>(waist.value);
    }
    if (hip.present) {
      map['hip'] = Variable<double>(hip.value);
    }
    if (thighLeft.present) {
      map['thigh_left'] = Variable<double>(thighLeft.value);
    }
    if (thighRight.present) {
      map['thigh_right'] = Variable<double>(thighRight.value);
    }
    if (armLeft.present) {
      map['arm_left'] = Variable<double>(armLeft.value);
    }
    if (armRight.present) {
      map['arm_right'] = Variable<double>(armRight.value);
    }
    if (neck.present) {
      map['neck'] = Variable<double>(neck.value);
    }
    if (bmi.present) {
      map['bmi'] = Variable<double>(bmi.value);
    }
    if (waistHipRatio.present) {
      map['waist_hip_ratio'] = Variable<double>(waistHipRatio.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (measuredAt.present) {
      map['measured_at'] = Variable<DateTime>(measuredAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BodyMeasurementsCompanion(')
          ..write('id: $id, ')
          ..write('weight: $weight, ')
          ..write('height: $height, ')
          ..write('bodyFat: $bodyFat, ')
          ..write('muscleMass: $muscleMass, ')
          ..write('chest: $chest, ')
          ..write('waist: $waist, ')
          ..write('hip: $hip, ')
          ..write('thighLeft: $thighLeft, ')
          ..write('thighRight: $thighRight, ')
          ..write('armLeft: $armLeft, ')
          ..write('armRight: $armRight, ')
          ..write('neck: $neck, ')
          ..write('bmi: $bmi, ')
          ..write('waistHipRatio: $waistHipRatio, ')
          ..write('note: $note, ')
          ..write('imagePath: $imagePath, ')
          ..write('measuredAt: $measuredAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $AIConversationsTable extends AIConversations
    with TableInfo<$AIConversationsTable, AIConversation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AIConversationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, title, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'a_i_conversations';
  @override
  VerificationContext validateIntegrity(Insertable<AIConversation> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AIConversation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AIConversation(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $AIConversationsTable createAlias(String alias) {
    return $AIConversationsTable(attachedDatabase, alias);
  }
}

class AIConversation extends DataClass implements Insertable<AIConversation> {
  final int id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  const AIConversation(
      {required this.id,
      required this.title,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AIConversationsCompanion toCompanion(bool nullToAbsent) {
    return AIConversationsCompanion(
      id: Value(id),
      title: Value(title),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AIConversation.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AIConversation(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AIConversation copyWith(
          {int? id, String? title, DateTime? createdAt, DateTime? updatedAt}) =>
      AIConversation(
        id: id ?? this.id,
        title: title ?? this.title,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AIConversation copyWithCompanion(AIConversationsCompanion data) {
    return AIConversation(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AIConversation(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AIConversation &&
          other.id == this.id &&
          other.title == this.title &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AIConversationsCompanion extends UpdateCompanion<AIConversation> {
  final Value<int> id;
  final Value<String> title;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const AIConversationsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AIConversationsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required DateTime createdAt,
    required DateTime updatedAt,
  })  : title = Value(title),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<AIConversation> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AIConversationsCompanion copyWith(
      {Value<int>? id,
      Value<String>? title,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return AIConversationsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AIConversationsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $AIMessagesTable extends AIMessages
    with TableInfo<$AIMessagesTable, AIMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AIMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _conversationIdMeta =
      const VerificationMeta('conversationId');
  @override
  late final GeneratedColumn<int> conversationId = GeneratedColumn<int>(
      'conversation_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES a_i_conversations (id)'));
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, conversationId, role, content, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'a_i_messages';
  @override
  VerificationContext validateIntegrity(Insertable<AIMessage> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
          _conversationIdMeta,
          conversationId.isAcceptableOrUnknown(
              data['conversation_id']!, _conversationIdMeta));
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AIMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AIMessage(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      conversationId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}conversation_id'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $AIMessagesTable createAlias(String alias) {
    return $AIMessagesTable(attachedDatabase, alias);
  }
}

class AIMessage extends DataClass implements Insertable<AIMessage> {
  final int id;
  final int conversationId;
  final String role;
  final String content;
  final DateTime createdAt;
  const AIMessage(
      {required this.id,
      required this.conversationId,
      required this.role,
      required this.content,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['conversation_id'] = Variable<int>(conversationId);
    map['role'] = Variable<String>(role);
    map['content'] = Variable<String>(content);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AIMessagesCompanion toCompanion(bool nullToAbsent) {
    return AIMessagesCompanion(
      id: Value(id),
      conversationId: Value(conversationId),
      role: Value(role),
      content: Value(content),
      createdAt: Value(createdAt),
    );
  }

  factory AIMessage.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AIMessage(
      id: serializer.fromJson<int>(json['id']),
      conversationId: serializer.fromJson<int>(json['conversationId']),
      role: serializer.fromJson<String>(json['role']),
      content: serializer.fromJson<String>(json['content']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'conversationId': serializer.toJson<int>(conversationId),
      'role': serializer.toJson<String>(role),
      'content': serializer.toJson<String>(content),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AIMessage copyWith(
          {int? id,
          int? conversationId,
          String? role,
          String? content,
          DateTime? createdAt}) =>
      AIMessage(
        id: id ?? this.id,
        conversationId: conversationId ?? this.conversationId,
        role: role ?? this.role,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
      );
  AIMessage copyWithCompanion(AIMessagesCompanion data) {
    return AIMessage(
      id: data.id.present ? data.id.value : this.id,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      role: data.role.present ? data.role.value : this.role,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AIMessage(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, conversationId, role, content, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AIMessage &&
          other.id == this.id &&
          other.conversationId == this.conversationId &&
          other.role == this.role &&
          other.content == this.content &&
          other.createdAt == this.createdAt);
}

class AIMessagesCompanion extends UpdateCompanion<AIMessage> {
  final Value<int> id;
  final Value<int> conversationId;
  final Value<String> role;
  final Value<String> content;
  final Value<DateTime> createdAt;
  const AIMessagesCompanion({
    this.id = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.role = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AIMessagesCompanion.insert({
    this.id = const Value.absent(),
    required int conversationId,
    required String role,
    required String content,
    required DateTime createdAt,
  })  : conversationId = Value(conversationId),
        role = Value(role),
        content = Value(content),
        createdAt = Value(createdAt);
  static Insertable<AIMessage> custom({
    Expression<int>? id,
    Expression<int>? conversationId,
    Expression<String>? role,
    Expression<String>? content,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (conversationId != null) 'conversation_id': conversationId,
      if (role != null) 'role': role,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AIMessagesCompanion copyWith(
      {Value<int>? id,
      Value<int>? conversationId,
      Value<String>? role,
      Value<String>? content,
      Value<DateTime>? createdAt}) {
    return AIMessagesCompanion(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<int>(conversationId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AIMessagesCompanion(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BloodSugarRecordsTable bloodSugarRecords =
      $BloodSugarRecordsTable(this);
  late final $ExerciseRecordsTable exerciseRecords =
      $ExerciseRecordsTable(this);
  late final $StrengthTrainingsTable strengthTrainings =
      $StrengthTrainingsTable(this);
  late final $MealRecordsTable mealRecords = $MealRecordsTable(this);
  late final $FoodItemsTable foodItems = $FoodItemsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $TrainingPlansTable trainingPlans = $TrainingPlansTable(this);
  late final $TrainingPlanExercisesTable trainingPlanExercises =
      $TrainingPlanExercisesTable(this);
  late final $BodyMeasurementsTable bodyMeasurements =
      $BodyMeasurementsTable(this);
  late final $AIConversationsTable aIConversations =
      $AIConversationsTable(this);
  late final $AIMessagesTable aIMessages = $AIMessagesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        bloodSugarRecords,
        exerciseRecords,
        strengthTrainings,
        mealRecords,
        foodItems,
        appSettings,
        trainingPlans,
        trainingPlanExercises,
        bodyMeasurements,
        aIConversations,
        aIMessages
      ];
}

typedef $$BloodSugarRecordsTableCreateCompanionBuilder
    = BloodSugarRecordsCompanion Function({
  Value<int> id,
  required double value,
  Value<String> unit,
  required String type,
  required DateTime recordedAt,
  Value<double?> hoursAfterMeal,
  Value<int?> mealId,
  Value<String?> note,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$BloodSugarRecordsTableUpdateCompanionBuilder
    = BloodSugarRecordsCompanion Function({
  Value<int> id,
  Value<double> value,
  Value<String> unit,
  Value<String> type,
  Value<DateTime> recordedAt,
  Value<double?> hoursAfterMeal,
  Value<int?> mealId,
  Value<String?> note,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$BloodSugarRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $BloodSugarRecordsTable> {
  $$BloodSugarRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get hoursAfterMeal => $composableBuilder(
      column: $table.hoursAfterMeal,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get mealId => $composableBuilder(
      column: $table.mealId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$BloodSugarRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $BloodSugarRecordsTable> {
  $$BloodSugarRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get hoursAfterMeal => $composableBuilder(
      column: $table.hoursAfterMeal,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get mealId => $composableBuilder(
      column: $table.mealId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$BloodSugarRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BloodSugarRecordsTable> {
  $$BloodSugarRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => column);

  GeneratedColumn<double> get hoursAfterMeal => $composableBuilder(
      column: $table.hoursAfterMeal, builder: (column) => column);

  GeneratedColumn<int> get mealId =>
      $composableBuilder(column: $table.mealId, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BloodSugarRecordsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BloodSugarRecordsTable,
    BloodSugarRecord,
    $$BloodSugarRecordsTableFilterComposer,
    $$BloodSugarRecordsTableOrderingComposer,
    $$BloodSugarRecordsTableAnnotationComposer,
    $$BloodSugarRecordsTableCreateCompanionBuilder,
    $$BloodSugarRecordsTableUpdateCompanionBuilder,
    (
      BloodSugarRecord,
      BaseReferences<_$AppDatabase, $BloodSugarRecordsTable, BloodSugarRecord>
    ),
    BloodSugarRecord,
    PrefetchHooks Function()> {
  $$BloodSugarRecordsTableTableManager(
      _$AppDatabase db, $BloodSugarRecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BloodSugarRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BloodSugarRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BloodSugarRecordsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<double> value = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<DateTime> recordedAt = const Value.absent(),
            Value<double?> hoursAfterMeal = const Value.absent(),
            Value<int?> mealId = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              BloodSugarRecordsCompanion(
            id: id,
            value: value,
            unit: unit,
            type: type,
            recordedAt: recordedAt,
            hoursAfterMeal: hoursAfterMeal,
            mealId: mealId,
            note: note,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required double value,
            Value<String> unit = const Value.absent(),
            required String type,
            required DateTime recordedAt,
            Value<double?> hoursAfterMeal = const Value.absent(),
            Value<int?> mealId = const Value.absent(),
            Value<String?> note = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
          }) =>
              BloodSugarRecordsCompanion.insert(
            id: id,
            value: value,
            unit: unit,
            type: type,
            recordedAt: recordedAt,
            hoursAfterMeal: hoursAfterMeal,
            mealId: mealId,
            note: note,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BloodSugarRecordsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BloodSugarRecordsTable,
    BloodSugarRecord,
    $$BloodSugarRecordsTableFilterComposer,
    $$BloodSugarRecordsTableOrderingComposer,
    $$BloodSugarRecordsTableAnnotationComposer,
    $$BloodSugarRecordsTableCreateCompanionBuilder,
    $$BloodSugarRecordsTableUpdateCompanionBuilder,
    (
      BloodSugarRecord,
      BaseReferences<_$AppDatabase, $BloodSugarRecordsTable, BloodSugarRecord>
    ),
    BloodSugarRecord,
    PrefetchHooks Function()>;
typedef $$ExerciseRecordsTableCreateCompanionBuilder = ExerciseRecordsCompanion
    Function({
  Value<int> id,
  required String type,
  required String name,
  required int duration,
  Value<double?> distance,
  Value<double?> elevation,
  Value<double?> power,
  Value<int?> sets,
  Value<double?> weight,
  Value<int?> seconds,
  Value<String?> repsList,
  Value<int?> calories,
  Value<int?> heartRateAvg,
  Value<int?> heartRateMax,
  required DateTime startedAt,
  required DateTime endedAt,
  Value<String?> note,
  required DateTime createdAt,
});
typedef $$ExerciseRecordsTableUpdateCompanionBuilder = ExerciseRecordsCompanion
    Function({
  Value<int> id,
  Value<String> type,
  Value<String> name,
  Value<int> duration,
  Value<double?> distance,
  Value<double?> elevation,
  Value<double?> power,
  Value<int?> sets,
  Value<double?> weight,
  Value<int?> seconds,
  Value<String?> repsList,
  Value<int?> calories,
  Value<int?> heartRateAvg,
  Value<int?> heartRateMax,
  Value<DateTime> startedAt,
  Value<DateTime> endedAt,
  Value<String?> note,
  Value<DateTime> createdAt,
});

final class $$ExerciseRecordsTableReferences extends BaseReferences<
    _$AppDatabase, $ExerciseRecordsTable, ExerciseRecord> {
  $$ExerciseRecordsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$StrengthTrainingsTable, List<StrengthTraining>>
      _strengthTrainingsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.strengthTrainings,
              aliasName: $_aliasNameGenerator(
                  db.exerciseRecords.id, db.strengthTrainings.exerciseId));

  $$StrengthTrainingsTableProcessedTableManager get strengthTrainingsRefs {
    final manager =
        $$StrengthTrainingsTableTableManager($_db, $_db.strengthTrainings)
            .filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_strengthTrainingsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ExerciseRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $ExerciseRecordsTable> {
  $$ExerciseRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get distance => $composableBuilder(
      column: $table.distance, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get elevation => $composableBuilder(
      column: $table.elevation, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get power => $composableBuilder(
      column: $table.power, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sets => $composableBuilder(
      column: $table.sets, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get seconds => $composableBuilder(
      column: $table.seconds, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get repsList => $composableBuilder(
      column: $table.repsList, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get calories => $composableBuilder(
      column: $table.calories, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get heartRateAvg => $composableBuilder(
      column: $table.heartRateAvg, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get heartRateMax => $composableBuilder(
      column: $table.heartRateMax, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
      column: $table.endedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> strengthTrainingsRefs(
      Expression<bool> Function($$StrengthTrainingsTableFilterComposer f) f) {
    final $$StrengthTrainingsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.strengthTrainings,
        getReferencedColumn: (t) => t.exerciseId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$StrengthTrainingsTableFilterComposer(
              $db: $db,
              $table: $db.strengthTrainings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ExerciseRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExerciseRecordsTable> {
  $$ExerciseRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get distance => $composableBuilder(
      column: $table.distance, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get elevation => $composableBuilder(
      column: $table.elevation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get power => $composableBuilder(
      column: $table.power, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sets => $composableBuilder(
      column: $table.sets, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get seconds => $composableBuilder(
      column: $table.seconds, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get repsList => $composableBuilder(
      column: $table.repsList, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get calories => $composableBuilder(
      column: $table.calories, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get heartRateAvg => $composableBuilder(
      column: $table.heartRateAvg,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get heartRateMax => $composableBuilder(
      column: $table.heartRateMax,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
      column: $table.endedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$ExerciseRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExerciseRecordsTable> {
  $$ExerciseRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<double> get distance =>
      $composableBuilder(column: $table.distance, builder: (column) => column);

  GeneratedColumn<double> get elevation =>
      $composableBuilder(column: $table.elevation, builder: (column) => column);

  GeneratedColumn<double> get power =>
      $composableBuilder(column: $table.power, builder: (column) => column);

  GeneratedColumn<int> get sets =>
      $composableBuilder(column: $table.sets, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<int> get seconds =>
      $composableBuilder(column: $table.seconds, builder: (column) => column);

  GeneratedColumn<String> get repsList =>
      $composableBuilder(column: $table.repsList, builder: (column) => column);

  GeneratedColumn<int> get calories =>
      $composableBuilder(column: $table.calories, builder: (column) => column);

  GeneratedColumn<int> get heartRateAvg => $composableBuilder(
      column: $table.heartRateAvg, builder: (column) => column);

  GeneratedColumn<int> get heartRateMax => $composableBuilder(
      column: $table.heartRateMax, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> strengthTrainingsRefs<T extends Object>(
      Expression<T> Function($$StrengthTrainingsTableAnnotationComposer a) f) {
    final $$StrengthTrainingsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.strengthTrainings,
            getReferencedColumn: (t) => t.exerciseId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$StrengthTrainingsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.strengthTrainings,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$ExerciseRecordsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ExerciseRecordsTable,
    ExerciseRecord,
    $$ExerciseRecordsTableFilterComposer,
    $$ExerciseRecordsTableOrderingComposer,
    $$ExerciseRecordsTableAnnotationComposer,
    $$ExerciseRecordsTableCreateCompanionBuilder,
    $$ExerciseRecordsTableUpdateCompanionBuilder,
    (ExerciseRecord, $$ExerciseRecordsTableReferences),
    ExerciseRecord,
    PrefetchHooks Function({bool strengthTrainingsRefs})> {
  $$ExerciseRecordsTableTableManager(
      _$AppDatabase db, $ExerciseRecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExerciseRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExerciseRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExerciseRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> duration = const Value.absent(),
            Value<double?> distance = const Value.absent(),
            Value<double?> elevation = const Value.absent(),
            Value<double?> power = const Value.absent(),
            Value<int?> sets = const Value.absent(),
            Value<double?> weight = const Value.absent(),
            Value<int?> seconds = const Value.absent(),
            Value<String?> repsList = const Value.absent(),
            Value<int?> calories = const Value.absent(),
            Value<int?> heartRateAvg = const Value.absent(),
            Value<int?> heartRateMax = const Value.absent(),
            Value<DateTime> startedAt = const Value.absent(),
            Value<DateTime> endedAt = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              ExerciseRecordsCompanion(
            id: id,
            type: type,
            name: name,
            duration: duration,
            distance: distance,
            elevation: elevation,
            power: power,
            sets: sets,
            weight: weight,
            seconds: seconds,
            repsList: repsList,
            calories: calories,
            heartRateAvg: heartRateAvg,
            heartRateMax: heartRateMax,
            startedAt: startedAt,
            endedAt: endedAt,
            note: note,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String type,
            required String name,
            required int duration,
            Value<double?> distance = const Value.absent(),
            Value<double?> elevation = const Value.absent(),
            Value<double?> power = const Value.absent(),
            Value<int?> sets = const Value.absent(),
            Value<double?> weight = const Value.absent(),
            Value<int?> seconds = const Value.absent(),
            Value<String?> repsList = const Value.absent(),
            Value<int?> calories = const Value.absent(),
            Value<int?> heartRateAvg = const Value.absent(),
            Value<int?> heartRateMax = const Value.absent(),
            required DateTime startedAt,
            required DateTime endedAt,
            Value<String?> note = const Value.absent(),
            required DateTime createdAt,
          }) =>
              ExerciseRecordsCompanion.insert(
            id: id,
            type: type,
            name: name,
            duration: duration,
            distance: distance,
            elevation: elevation,
            power: power,
            sets: sets,
            weight: weight,
            seconds: seconds,
            repsList: repsList,
            calories: calories,
            heartRateAvg: heartRateAvg,
            heartRateMax: heartRateMax,
            startedAt: startedAt,
            endedAt: endedAt,
            note: note,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ExerciseRecordsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({strengthTrainingsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (strengthTrainingsRefs) db.strengthTrainings
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (strengthTrainingsRefs)
                    await $_getPrefetchedData<ExerciseRecord,
                            $ExerciseRecordsTable, StrengthTraining>(
                        currentTable: table,
                        referencedTable: $$ExerciseRecordsTableReferences
                            ._strengthTrainingsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ExerciseRecordsTableReferences(db, table, p0)
                                .strengthTrainingsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.exerciseId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ExerciseRecordsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ExerciseRecordsTable,
    ExerciseRecord,
    $$ExerciseRecordsTableFilterComposer,
    $$ExerciseRecordsTableOrderingComposer,
    $$ExerciseRecordsTableAnnotationComposer,
    $$ExerciseRecordsTableCreateCompanionBuilder,
    $$ExerciseRecordsTableUpdateCompanionBuilder,
    (ExerciseRecord, $$ExerciseRecordsTableReferences),
    ExerciseRecord,
    PrefetchHooks Function({bool strengthTrainingsRefs})>;
typedef $$StrengthTrainingsTableCreateCompanionBuilder
    = StrengthTrainingsCompanion Function({
  Value<int> id,
  required int exerciseId,
  required String device,
  required String movement,
  required int sets,
  required int reps,
  Value<double?> weight,
  Value<int?> restSeconds,
  Value<String> trainingType,
  Value<int?> durationSeconds,
});
typedef $$StrengthTrainingsTableUpdateCompanionBuilder
    = StrengthTrainingsCompanion Function({
  Value<int> id,
  Value<int> exerciseId,
  Value<String> device,
  Value<String> movement,
  Value<int> sets,
  Value<int> reps,
  Value<double?> weight,
  Value<int?> restSeconds,
  Value<String> trainingType,
  Value<int?> durationSeconds,
});

final class $$StrengthTrainingsTableReferences extends BaseReferences<
    _$AppDatabase, $StrengthTrainingsTable, StrengthTraining> {
  $$StrengthTrainingsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ExerciseRecordsTable _exerciseIdTable(_$AppDatabase db) =>
      db.exerciseRecords.createAlias($_aliasNameGenerator(
          db.strengthTrainings.exerciseId, db.exerciseRecords.id));

  $$ExerciseRecordsTableProcessedTableManager get exerciseId {
    final $_column = $_itemColumn<int>('exercise_id')!;

    final manager =
        $$ExerciseRecordsTableTableManager($_db, $_db.exerciseRecords)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$StrengthTrainingsTableFilterComposer
    extends Composer<_$AppDatabase, $StrengthTrainingsTable> {
  $$StrengthTrainingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get device => $composableBuilder(
      column: $table.device, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get movement => $composableBuilder(
      column: $table.movement, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sets => $composableBuilder(
      column: $table.sets, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reps => $composableBuilder(
      column: $table.reps, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get restSeconds => $composableBuilder(
      column: $table.restSeconds, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get trainingType => $composableBuilder(
      column: $table.trainingType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnFilters(column));

  $$ExerciseRecordsTableFilterComposer get exerciseId {
    final $$ExerciseRecordsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exerciseRecords,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExerciseRecordsTableFilterComposer(
              $db: $db,
              $table: $db.exerciseRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$StrengthTrainingsTableOrderingComposer
    extends Composer<_$AppDatabase, $StrengthTrainingsTable> {
  $$StrengthTrainingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get device => $composableBuilder(
      column: $table.device, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get movement => $composableBuilder(
      column: $table.movement, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sets => $composableBuilder(
      column: $table.sets, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reps => $composableBuilder(
      column: $table.reps, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get restSeconds => $composableBuilder(
      column: $table.restSeconds, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get trainingType => $composableBuilder(
      column: $table.trainingType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnOrderings(column));

  $$ExerciseRecordsTableOrderingComposer get exerciseId {
    final $$ExerciseRecordsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exerciseRecords,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExerciseRecordsTableOrderingComposer(
              $db: $db,
              $table: $db.exerciseRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$StrengthTrainingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StrengthTrainingsTable> {
  $$StrengthTrainingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get device =>
      $composableBuilder(column: $table.device, builder: (column) => column);

  GeneratedColumn<String> get movement =>
      $composableBuilder(column: $table.movement, builder: (column) => column);

  GeneratedColumn<int> get sets =>
      $composableBuilder(column: $table.sets, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<int> get restSeconds => $composableBuilder(
      column: $table.restSeconds, builder: (column) => column);

  GeneratedColumn<String> get trainingType => $composableBuilder(
      column: $table.trainingType, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds, builder: (column) => column);

  $$ExerciseRecordsTableAnnotationComposer get exerciseId {
    final $$ExerciseRecordsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.exerciseId,
        referencedTable: $db.exerciseRecords,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ExerciseRecordsTableAnnotationComposer(
              $db: $db,
              $table: $db.exerciseRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$StrengthTrainingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StrengthTrainingsTable,
    StrengthTraining,
    $$StrengthTrainingsTableFilterComposer,
    $$StrengthTrainingsTableOrderingComposer,
    $$StrengthTrainingsTableAnnotationComposer,
    $$StrengthTrainingsTableCreateCompanionBuilder,
    $$StrengthTrainingsTableUpdateCompanionBuilder,
    (StrengthTraining, $$StrengthTrainingsTableReferences),
    StrengthTraining,
    PrefetchHooks Function({bool exerciseId})> {
  $$StrengthTrainingsTableTableManager(
      _$AppDatabase db, $StrengthTrainingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StrengthTrainingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StrengthTrainingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StrengthTrainingsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> exerciseId = const Value.absent(),
            Value<String> device = const Value.absent(),
            Value<String> movement = const Value.absent(),
            Value<int> sets = const Value.absent(),
            Value<int> reps = const Value.absent(),
            Value<double?> weight = const Value.absent(),
            Value<int?> restSeconds = const Value.absent(),
            Value<String> trainingType = const Value.absent(),
            Value<int?> durationSeconds = const Value.absent(),
          }) =>
              StrengthTrainingsCompanion(
            id: id,
            exerciseId: exerciseId,
            device: device,
            movement: movement,
            sets: sets,
            reps: reps,
            weight: weight,
            restSeconds: restSeconds,
            trainingType: trainingType,
            durationSeconds: durationSeconds,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int exerciseId,
            required String device,
            required String movement,
            required int sets,
            required int reps,
            Value<double?> weight = const Value.absent(),
            Value<int?> restSeconds = const Value.absent(),
            Value<String> trainingType = const Value.absent(),
            Value<int?> durationSeconds = const Value.absent(),
          }) =>
              StrengthTrainingsCompanion.insert(
            id: id,
            exerciseId: exerciseId,
            device: device,
            movement: movement,
            sets: sets,
            reps: reps,
            weight: weight,
            restSeconds: restSeconds,
            trainingType: trainingType,
            durationSeconds: durationSeconds,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$StrengthTrainingsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({exerciseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (exerciseId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.exerciseId,
                    referencedTable:
                        $$StrengthTrainingsTableReferences._exerciseIdTable(db),
                    referencedColumn: $$StrengthTrainingsTableReferences
                        ._exerciseIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$StrengthTrainingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $StrengthTrainingsTable,
    StrengthTraining,
    $$StrengthTrainingsTableFilterComposer,
    $$StrengthTrainingsTableOrderingComposer,
    $$StrengthTrainingsTableAnnotationComposer,
    $$StrengthTrainingsTableCreateCompanionBuilder,
    $$StrengthTrainingsTableUpdateCompanionBuilder,
    (StrengthTraining, $$StrengthTrainingsTableReferences),
    StrengthTraining,
    PrefetchHooks Function({bool exerciseId})>;
typedef $$MealRecordsTableCreateCompanionBuilder = MealRecordsCompanion
    Function({
  Value<int> id,
  required String type,
  required DateTime recordedAt,
  Value<String?> imagePaths,
  Value<String?> note,
  required DateTime createdAt,
});
typedef $$MealRecordsTableUpdateCompanionBuilder = MealRecordsCompanion
    Function({
  Value<int> id,
  Value<String> type,
  Value<DateTime> recordedAt,
  Value<String?> imagePaths,
  Value<String?> note,
  Value<DateTime> createdAt,
});

final class $$MealRecordsTableReferences
    extends BaseReferences<_$AppDatabase, $MealRecordsTable, MealRecord> {
  $$MealRecordsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$FoodItemsTable, List<FoodItem>>
      _foodItemsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.foodItems,
              aliasName:
                  $_aliasNameGenerator(db.mealRecords.id, db.foodItems.mealId));

  $$FoodItemsTableProcessedTableManager get foodItemsRefs {
    final manager = $$FoodItemsTableTableManager($_db, $_db.foodItems)
        .filter((f) => f.mealId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_foodItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$MealRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $MealRecordsTable> {
  $$MealRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imagePaths => $composableBuilder(
      column: $table.imagePaths, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> foodItemsRefs(
      Expression<bool> Function($$FoodItemsTableFilterComposer f) f) {
    final $$FoodItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.foodItems,
        getReferencedColumn: (t) => t.mealId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FoodItemsTableFilterComposer(
              $db: $db,
              $table: $db.foodItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$MealRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $MealRecordsTable> {
  $$MealRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imagePaths => $composableBuilder(
      column: $table.imagePaths, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$MealRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealRecordsTable> {
  $$MealRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => column);

  GeneratedColumn<String> get imagePaths => $composableBuilder(
      column: $table.imagePaths, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> foodItemsRefs<T extends Object>(
      Expression<T> Function($$FoodItemsTableAnnotationComposer a) f) {
    final $$FoodItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.foodItems,
        getReferencedColumn: (t) => t.mealId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FoodItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.foodItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$MealRecordsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MealRecordsTable,
    MealRecord,
    $$MealRecordsTableFilterComposer,
    $$MealRecordsTableOrderingComposer,
    $$MealRecordsTableAnnotationComposer,
    $$MealRecordsTableCreateCompanionBuilder,
    $$MealRecordsTableUpdateCompanionBuilder,
    (MealRecord, $$MealRecordsTableReferences),
    MealRecord,
    PrefetchHooks Function({bool foodItemsRefs})> {
  $$MealRecordsTableTableManager(_$AppDatabase db, $MealRecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<DateTime> recordedAt = const Value.absent(),
            Value<String?> imagePaths = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              MealRecordsCompanion(
            id: id,
            type: type,
            recordedAt: recordedAt,
            imagePaths: imagePaths,
            note: note,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String type,
            required DateTime recordedAt,
            Value<String?> imagePaths = const Value.absent(),
            Value<String?> note = const Value.absent(),
            required DateTime createdAt,
          }) =>
              MealRecordsCompanion.insert(
            id: id,
            type: type,
            recordedAt: recordedAt,
            imagePaths: imagePaths,
            note: note,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$MealRecordsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({foodItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (foodItemsRefs) db.foodItems],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (foodItemsRefs)
                    await $_getPrefetchedData<MealRecord, $MealRecordsTable,
                            FoodItem>(
                        currentTable: table,
                        referencedTable: $$MealRecordsTableReferences
                            ._foodItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$MealRecordsTableReferences(db, table, p0)
                                .foodItemsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.mealId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$MealRecordsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MealRecordsTable,
    MealRecord,
    $$MealRecordsTableFilterComposer,
    $$MealRecordsTableOrderingComposer,
    $$MealRecordsTableAnnotationComposer,
    $$MealRecordsTableCreateCompanionBuilder,
    $$MealRecordsTableUpdateCompanionBuilder,
    (MealRecord, $$MealRecordsTableReferences),
    MealRecord,
    PrefetchHooks Function({bool foodItemsRefs})>;
typedef $$FoodItemsTableCreateCompanionBuilder = FoodItemsCompanion Function({
  Value<int> id,
  required int mealId,
  required String name,
  required double amount,
  Value<String> unit,
  Value<double?> carbs,
});
typedef $$FoodItemsTableUpdateCompanionBuilder = FoodItemsCompanion Function({
  Value<int> id,
  Value<int> mealId,
  Value<String> name,
  Value<double> amount,
  Value<String> unit,
  Value<double?> carbs,
});

final class $$FoodItemsTableReferences
    extends BaseReferences<_$AppDatabase, $FoodItemsTable, FoodItem> {
  $$FoodItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MealRecordsTable _mealIdTable(_$AppDatabase db) =>
      db.mealRecords.createAlias(
          $_aliasNameGenerator(db.foodItems.mealId, db.mealRecords.id));

  $$MealRecordsTableProcessedTableManager get mealId {
    final $_column = $_itemColumn<int>('meal_id')!;

    final manager = $$MealRecordsTableTableManager($_db, $_db.mealRecords)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_mealIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$FoodItemsTableFilterComposer
    extends Composer<_$AppDatabase, $FoodItemsTable> {
  $$FoodItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get carbs => $composableBuilder(
      column: $table.carbs, builder: (column) => ColumnFilters(column));

  $$MealRecordsTableFilterComposer get mealId {
    final $$MealRecordsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.mealId,
        referencedTable: $db.mealRecords,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MealRecordsTableFilterComposer(
              $db: $db,
              $table: $db.mealRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$FoodItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $FoodItemsTable> {
  $$FoodItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get carbs => $composableBuilder(
      column: $table.carbs, builder: (column) => ColumnOrderings(column));

  $$MealRecordsTableOrderingComposer get mealId {
    final $$MealRecordsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.mealId,
        referencedTable: $db.mealRecords,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MealRecordsTableOrderingComposer(
              $db: $db,
              $table: $db.mealRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$FoodItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoodItemsTable> {
  $$FoodItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<double> get carbs =>
      $composableBuilder(column: $table.carbs, builder: (column) => column);

  $$MealRecordsTableAnnotationComposer get mealId {
    final $$MealRecordsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.mealId,
        referencedTable: $db.mealRecords,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MealRecordsTableAnnotationComposer(
              $db: $db,
              $table: $db.mealRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$FoodItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FoodItemsTable,
    FoodItem,
    $$FoodItemsTableFilterComposer,
    $$FoodItemsTableOrderingComposer,
    $$FoodItemsTableAnnotationComposer,
    $$FoodItemsTableCreateCompanionBuilder,
    $$FoodItemsTableUpdateCompanionBuilder,
    (FoodItem, $$FoodItemsTableReferences),
    FoodItem,
    PrefetchHooks Function({bool mealId})> {
  $$FoodItemsTableTableManager(_$AppDatabase db, $FoodItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoodItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoodItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoodItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> mealId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<double?> carbs = const Value.absent(),
          }) =>
              FoodItemsCompanion(
            id: id,
            mealId: mealId,
            name: name,
            amount: amount,
            unit: unit,
            carbs: carbs,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int mealId,
            required String name,
            required double amount,
            Value<String> unit = const Value.absent(),
            Value<double?> carbs = const Value.absent(),
          }) =>
              FoodItemsCompanion.insert(
            id: id,
            mealId: mealId,
            name: name,
            amount: amount,
            unit: unit,
            carbs: carbs,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$FoodItemsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({mealId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (mealId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.mealId,
                    referencedTable:
                        $$FoodItemsTableReferences._mealIdTable(db),
                    referencedColumn:
                        $$FoodItemsTableReferences._mealIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$FoodItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FoodItemsTable,
    FoodItem,
    $$FoodItemsTableFilterComposer,
    $$FoodItemsTableOrderingComposer,
    $$FoodItemsTableAnnotationComposer,
    $$FoodItemsTableCreateCompanionBuilder,
    $$FoodItemsTableUpdateCompanionBuilder,
    (FoodItem, $$FoodItemsTableReferences),
    FoodItem,
    PrefetchHooks Function({bool mealId})>;
typedef $$AppSettingsTableCreateCompanionBuilder = AppSettingsCompanion
    Function({
  Value<int> id,
  required String key,
  required String value,
});
typedef $$AppSettingsTableUpdateCompanionBuilder = AppSettingsCompanion
    Function({
  Value<int> id,
  Value<String> key,
  Value<String> value,
});

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (AppSetting, BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>),
    AppSetting,
    PrefetchHooks Function()> {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
          }) =>
              AppSettingsCompanion(
            id: id,
            key: key,
            value: value,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String key,
            required String value,
          }) =>
              AppSettingsCompanion.insert(
            id: id,
            key: key,
            value: value,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppSettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (AppSetting, BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>),
    AppSetting,
    PrefetchHooks Function()>;
typedef $$TrainingPlansTableCreateCompanionBuilder = TrainingPlansCompanion
    Function({
  Value<int> id,
  required String name,
  Value<String?> description,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$TrainingPlansTableUpdateCompanionBuilder = TrainingPlansCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<String?> description,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$TrainingPlansTableReferences
    extends BaseReferences<_$AppDatabase, $TrainingPlansTable, TrainingPlan> {
  $$TrainingPlansTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TrainingPlanExercisesTable,
      List<TrainingPlanExercise>> _trainingPlanExercisesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.trainingPlanExercises,
          aliasName: $_aliasNameGenerator(
              db.trainingPlans.id, db.trainingPlanExercises.planId));

  $$TrainingPlanExercisesTableProcessedTableManager
      get trainingPlanExercisesRefs {
    final manager = $$TrainingPlanExercisesTableTableManager(
            $_db, $_db.trainingPlanExercises)
        .filter((f) => f.planId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_trainingPlanExercisesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TrainingPlansTableFilterComposer
    extends Composer<_$AppDatabase, $TrainingPlansTable> {
  $$TrainingPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> trainingPlanExercisesRefs(
      Expression<bool> Function($$TrainingPlanExercisesTableFilterComposer f)
          f) {
    final $$TrainingPlanExercisesTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.trainingPlanExercises,
            getReferencedColumn: (t) => t.planId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$TrainingPlanExercisesTableFilterComposer(
                  $db: $db,
                  $table: $db.trainingPlanExercises,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$TrainingPlansTableOrderingComposer
    extends Composer<_$AppDatabase, $TrainingPlansTable> {
  $$TrainingPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$TrainingPlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrainingPlansTable> {
  $$TrainingPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> trainingPlanExercisesRefs<T extends Object>(
      Expression<T> Function($$TrainingPlanExercisesTableAnnotationComposer a)
          f) {
    final $$TrainingPlanExercisesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.trainingPlanExercises,
            getReferencedColumn: (t) => t.planId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$TrainingPlanExercisesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.trainingPlanExercises,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$TrainingPlansTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TrainingPlansTable,
    TrainingPlan,
    $$TrainingPlansTableFilterComposer,
    $$TrainingPlansTableOrderingComposer,
    $$TrainingPlansTableAnnotationComposer,
    $$TrainingPlansTableCreateCompanionBuilder,
    $$TrainingPlansTableUpdateCompanionBuilder,
    (TrainingPlan, $$TrainingPlansTableReferences),
    TrainingPlan,
    PrefetchHooks Function({bool trainingPlanExercisesRefs})> {
  $$TrainingPlansTableTableManager(_$AppDatabase db, $TrainingPlansTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrainingPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrainingPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrainingPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              TrainingPlansCompanion(
            id: id,
            name: name,
            description: description,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String?> description = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
          }) =>
              TrainingPlansCompanion.insert(
            id: id,
            name: name,
            description: description,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TrainingPlansTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({trainingPlanExercisesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (trainingPlanExercisesRefs) db.trainingPlanExercises
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (trainingPlanExercisesRefs)
                    await $_getPrefetchedData<TrainingPlan, $TrainingPlansTable,
                            TrainingPlanExercise>(
                        currentTable: table,
                        referencedTable: $$TrainingPlansTableReferences
                            ._trainingPlanExercisesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TrainingPlansTableReferences(db, table, p0)
                                .trainingPlanExercisesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.planId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$TrainingPlansTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TrainingPlansTable,
    TrainingPlan,
    $$TrainingPlansTableFilterComposer,
    $$TrainingPlansTableOrderingComposer,
    $$TrainingPlansTableAnnotationComposer,
    $$TrainingPlansTableCreateCompanionBuilder,
    $$TrainingPlansTableUpdateCompanionBuilder,
    (TrainingPlan, $$TrainingPlansTableReferences),
    TrainingPlan,
    PrefetchHooks Function({bool trainingPlanExercisesRefs})>;
typedef $$TrainingPlanExercisesTableCreateCompanionBuilder
    = TrainingPlanExercisesCompanion Function({
  Value<int> id,
  required int planId,
  required String device,
  required String movement,
  required int targetSets,
  required int targetReps,
  Value<String?> targetRepsList,
  Value<double?> targetWeight,
  Value<int?> restSeconds,
  Value<String> trainingType,
  Value<int> orderIndex,
});
typedef $$TrainingPlanExercisesTableUpdateCompanionBuilder
    = TrainingPlanExercisesCompanion Function({
  Value<int> id,
  Value<int> planId,
  Value<String> device,
  Value<String> movement,
  Value<int> targetSets,
  Value<int> targetReps,
  Value<String?> targetRepsList,
  Value<double?> targetWeight,
  Value<int?> restSeconds,
  Value<String> trainingType,
  Value<int> orderIndex,
});

final class $$TrainingPlanExercisesTableReferences extends BaseReferences<
    _$AppDatabase, $TrainingPlanExercisesTable, TrainingPlanExercise> {
  $$TrainingPlanExercisesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $TrainingPlansTable _planIdTable(_$AppDatabase db) =>
      db.trainingPlans.createAlias($_aliasNameGenerator(
          db.trainingPlanExercises.planId, db.trainingPlans.id));

  $$TrainingPlansTableProcessedTableManager get planId {
    final $_column = $_itemColumn<int>('plan_id')!;

    final manager = $$TrainingPlansTableTableManager($_db, $_db.trainingPlans)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_planIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TrainingPlanExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $TrainingPlanExercisesTable> {
  $$TrainingPlanExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get device => $composableBuilder(
      column: $table.device, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get movement => $composableBuilder(
      column: $table.movement, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetSets => $composableBuilder(
      column: $table.targetSets, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetReps => $composableBuilder(
      column: $table.targetReps, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get targetRepsList => $composableBuilder(
      column: $table.targetRepsList,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get targetWeight => $composableBuilder(
      column: $table.targetWeight, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get restSeconds => $composableBuilder(
      column: $table.restSeconds, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get trainingType => $composableBuilder(
      column: $table.trainingType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnFilters(column));

  $$TrainingPlansTableFilterComposer get planId {
    final $$TrainingPlansTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.planId,
        referencedTable: $db.trainingPlans,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TrainingPlansTableFilterComposer(
              $db: $db,
              $table: $db.trainingPlans,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TrainingPlanExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $TrainingPlanExercisesTable> {
  $$TrainingPlanExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get device => $composableBuilder(
      column: $table.device, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get movement => $composableBuilder(
      column: $table.movement, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetSets => $composableBuilder(
      column: $table.targetSets, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetReps => $composableBuilder(
      column: $table.targetReps, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get targetRepsList => $composableBuilder(
      column: $table.targetRepsList,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get targetWeight => $composableBuilder(
      column: $table.targetWeight,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get restSeconds => $composableBuilder(
      column: $table.restSeconds, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get trainingType => $composableBuilder(
      column: $table.trainingType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnOrderings(column));

  $$TrainingPlansTableOrderingComposer get planId {
    final $$TrainingPlansTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.planId,
        referencedTable: $db.trainingPlans,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TrainingPlansTableOrderingComposer(
              $db: $db,
              $table: $db.trainingPlans,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TrainingPlanExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrainingPlanExercisesTable> {
  $$TrainingPlanExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get device =>
      $composableBuilder(column: $table.device, builder: (column) => column);

  GeneratedColumn<String> get movement =>
      $composableBuilder(column: $table.movement, builder: (column) => column);

  GeneratedColumn<int> get targetSets => $composableBuilder(
      column: $table.targetSets, builder: (column) => column);

  GeneratedColumn<int> get targetReps => $composableBuilder(
      column: $table.targetReps, builder: (column) => column);

  GeneratedColumn<String> get targetRepsList => $composableBuilder(
      column: $table.targetRepsList, builder: (column) => column);

  GeneratedColumn<double> get targetWeight => $composableBuilder(
      column: $table.targetWeight, builder: (column) => column);

  GeneratedColumn<int> get restSeconds => $composableBuilder(
      column: $table.restSeconds, builder: (column) => column);

  GeneratedColumn<String> get trainingType => $composableBuilder(
      column: $table.trainingType, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => column);

  $$TrainingPlansTableAnnotationComposer get planId {
    final $$TrainingPlansTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.planId,
        referencedTable: $db.trainingPlans,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TrainingPlansTableAnnotationComposer(
              $db: $db,
              $table: $db.trainingPlans,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TrainingPlanExercisesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TrainingPlanExercisesTable,
    TrainingPlanExercise,
    $$TrainingPlanExercisesTableFilterComposer,
    $$TrainingPlanExercisesTableOrderingComposer,
    $$TrainingPlanExercisesTableAnnotationComposer,
    $$TrainingPlanExercisesTableCreateCompanionBuilder,
    $$TrainingPlanExercisesTableUpdateCompanionBuilder,
    (TrainingPlanExercise, $$TrainingPlanExercisesTableReferences),
    TrainingPlanExercise,
    PrefetchHooks Function({bool planId})> {
  $$TrainingPlanExercisesTableTableManager(
      _$AppDatabase db, $TrainingPlanExercisesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrainingPlanExercisesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$TrainingPlanExercisesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrainingPlanExercisesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> planId = const Value.absent(),
            Value<String> device = const Value.absent(),
            Value<String> movement = const Value.absent(),
            Value<int> targetSets = const Value.absent(),
            Value<int> targetReps = const Value.absent(),
            Value<String?> targetRepsList = const Value.absent(),
            Value<double?> targetWeight = const Value.absent(),
            Value<int?> restSeconds = const Value.absent(),
            Value<String> trainingType = const Value.absent(),
            Value<int> orderIndex = const Value.absent(),
          }) =>
              TrainingPlanExercisesCompanion(
            id: id,
            planId: planId,
            device: device,
            movement: movement,
            targetSets: targetSets,
            targetReps: targetReps,
            targetRepsList: targetRepsList,
            targetWeight: targetWeight,
            restSeconds: restSeconds,
            trainingType: trainingType,
            orderIndex: orderIndex,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int planId,
            required String device,
            required String movement,
            required int targetSets,
            required int targetReps,
            Value<String?> targetRepsList = const Value.absent(),
            Value<double?> targetWeight = const Value.absent(),
            Value<int?> restSeconds = const Value.absent(),
            Value<String> trainingType = const Value.absent(),
            Value<int> orderIndex = const Value.absent(),
          }) =>
              TrainingPlanExercisesCompanion.insert(
            id: id,
            planId: planId,
            device: device,
            movement: movement,
            targetSets: targetSets,
            targetReps: targetReps,
            targetRepsList: targetRepsList,
            targetWeight: targetWeight,
            restSeconds: restSeconds,
            trainingType: trainingType,
            orderIndex: orderIndex,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TrainingPlanExercisesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({planId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (planId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.planId,
                    referencedTable:
                        $$TrainingPlanExercisesTableReferences._planIdTable(db),
                    referencedColumn: $$TrainingPlanExercisesTableReferences
                        ._planIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$TrainingPlanExercisesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $TrainingPlanExercisesTable,
        TrainingPlanExercise,
        $$TrainingPlanExercisesTableFilterComposer,
        $$TrainingPlanExercisesTableOrderingComposer,
        $$TrainingPlanExercisesTableAnnotationComposer,
        $$TrainingPlanExercisesTableCreateCompanionBuilder,
        $$TrainingPlanExercisesTableUpdateCompanionBuilder,
        (TrainingPlanExercise, $$TrainingPlanExercisesTableReferences),
        TrainingPlanExercise,
        PrefetchHooks Function({bool planId})>;
typedef $$BodyMeasurementsTableCreateCompanionBuilder
    = BodyMeasurementsCompanion Function({
  Value<int> id,
  Value<double?> weight,
  Value<double?> height,
  Value<double?> bodyFat,
  Value<double?> muscleMass,
  Value<double?> chest,
  Value<double?> waist,
  Value<double?> hip,
  Value<double?> thighLeft,
  Value<double?> thighRight,
  Value<double?> armLeft,
  Value<double?> armRight,
  Value<double?> neck,
  Value<double?> bmi,
  Value<double?> waistHipRatio,
  Value<String?> note,
  Value<String?> imagePath,
  required DateTime measuredAt,
  required DateTime createdAt,
});
typedef $$BodyMeasurementsTableUpdateCompanionBuilder
    = BodyMeasurementsCompanion Function({
  Value<int> id,
  Value<double?> weight,
  Value<double?> height,
  Value<double?> bodyFat,
  Value<double?> muscleMass,
  Value<double?> chest,
  Value<double?> waist,
  Value<double?> hip,
  Value<double?> thighLeft,
  Value<double?> thighRight,
  Value<double?> armLeft,
  Value<double?> armRight,
  Value<double?> neck,
  Value<double?> bmi,
  Value<double?> waistHipRatio,
  Value<String?> note,
  Value<String?> imagePath,
  Value<DateTime> measuredAt,
  Value<DateTime> createdAt,
});

class $$BodyMeasurementsTableFilterComposer
    extends Composer<_$AppDatabase, $BodyMeasurementsTable> {
  $$BodyMeasurementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get bodyFat => $composableBuilder(
      column: $table.bodyFat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get muscleMass => $composableBuilder(
      column: $table.muscleMass, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get chest => $composableBuilder(
      column: $table.chest, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get waist => $composableBuilder(
      column: $table.waist, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get hip => $composableBuilder(
      column: $table.hip, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get thighLeft => $composableBuilder(
      column: $table.thighLeft, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get thighRight => $composableBuilder(
      column: $table.thighRight, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get armLeft => $composableBuilder(
      column: $table.armLeft, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get armRight => $composableBuilder(
      column: $table.armRight, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get neck => $composableBuilder(
      column: $table.neck, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get bmi => $composableBuilder(
      column: $table.bmi, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get waistHipRatio => $composableBuilder(
      column: $table.waistHipRatio, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get measuredAt => $composableBuilder(
      column: $table.measuredAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$BodyMeasurementsTableOrderingComposer
    extends Composer<_$AppDatabase, $BodyMeasurementsTable> {
  $$BodyMeasurementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weight => $composableBuilder(
      column: $table.weight, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get bodyFat => $composableBuilder(
      column: $table.bodyFat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get muscleMass => $composableBuilder(
      column: $table.muscleMass, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get chest => $composableBuilder(
      column: $table.chest, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get waist => $composableBuilder(
      column: $table.waist, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get hip => $composableBuilder(
      column: $table.hip, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get thighLeft => $composableBuilder(
      column: $table.thighLeft, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get thighRight => $composableBuilder(
      column: $table.thighRight, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get armLeft => $composableBuilder(
      column: $table.armLeft, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get armRight => $composableBuilder(
      column: $table.armRight, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get neck => $composableBuilder(
      column: $table.neck, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get bmi => $composableBuilder(
      column: $table.bmi, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get waistHipRatio => $composableBuilder(
      column: $table.waistHipRatio,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get measuredAt => $composableBuilder(
      column: $table.measuredAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$BodyMeasurementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BodyMeasurementsTable> {
  $$BodyMeasurementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  GeneratedColumn<double> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<double> get bodyFat =>
      $composableBuilder(column: $table.bodyFat, builder: (column) => column);

  GeneratedColumn<double> get muscleMass => $composableBuilder(
      column: $table.muscleMass, builder: (column) => column);

  GeneratedColumn<double> get chest =>
      $composableBuilder(column: $table.chest, builder: (column) => column);

  GeneratedColumn<double> get waist =>
      $composableBuilder(column: $table.waist, builder: (column) => column);

  GeneratedColumn<double> get hip =>
      $composableBuilder(column: $table.hip, builder: (column) => column);

  GeneratedColumn<double> get thighLeft =>
      $composableBuilder(column: $table.thighLeft, builder: (column) => column);

  GeneratedColumn<double> get thighRight => $composableBuilder(
      column: $table.thighRight, builder: (column) => column);

  GeneratedColumn<double> get armLeft =>
      $composableBuilder(column: $table.armLeft, builder: (column) => column);

  GeneratedColumn<double> get armRight =>
      $composableBuilder(column: $table.armRight, builder: (column) => column);

  GeneratedColumn<double> get neck =>
      $composableBuilder(column: $table.neck, builder: (column) => column);

  GeneratedColumn<double> get bmi =>
      $composableBuilder(column: $table.bmi, builder: (column) => column);

  GeneratedColumn<double> get waistHipRatio => $composableBuilder(
      column: $table.waistHipRatio, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<DateTime> get measuredAt => $composableBuilder(
      column: $table.measuredAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$BodyMeasurementsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BodyMeasurementsTable,
    BodyMeasurement,
    $$BodyMeasurementsTableFilterComposer,
    $$BodyMeasurementsTableOrderingComposer,
    $$BodyMeasurementsTableAnnotationComposer,
    $$BodyMeasurementsTableCreateCompanionBuilder,
    $$BodyMeasurementsTableUpdateCompanionBuilder,
    (
      BodyMeasurement,
      BaseReferences<_$AppDatabase, $BodyMeasurementsTable, BodyMeasurement>
    ),
    BodyMeasurement,
    PrefetchHooks Function()> {
  $$BodyMeasurementsTableTableManager(
      _$AppDatabase db, $BodyMeasurementsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BodyMeasurementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BodyMeasurementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BodyMeasurementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<double?> weight = const Value.absent(),
            Value<double?> height = const Value.absent(),
            Value<double?> bodyFat = const Value.absent(),
            Value<double?> muscleMass = const Value.absent(),
            Value<double?> chest = const Value.absent(),
            Value<double?> waist = const Value.absent(),
            Value<double?> hip = const Value.absent(),
            Value<double?> thighLeft = const Value.absent(),
            Value<double?> thighRight = const Value.absent(),
            Value<double?> armLeft = const Value.absent(),
            Value<double?> armRight = const Value.absent(),
            Value<double?> neck = const Value.absent(),
            Value<double?> bmi = const Value.absent(),
            Value<double?> waistHipRatio = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String?> imagePath = const Value.absent(),
            Value<DateTime> measuredAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              BodyMeasurementsCompanion(
            id: id,
            weight: weight,
            height: height,
            bodyFat: bodyFat,
            muscleMass: muscleMass,
            chest: chest,
            waist: waist,
            hip: hip,
            thighLeft: thighLeft,
            thighRight: thighRight,
            armLeft: armLeft,
            armRight: armRight,
            neck: neck,
            bmi: bmi,
            waistHipRatio: waistHipRatio,
            note: note,
            imagePath: imagePath,
            measuredAt: measuredAt,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<double?> weight = const Value.absent(),
            Value<double?> height = const Value.absent(),
            Value<double?> bodyFat = const Value.absent(),
            Value<double?> muscleMass = const Value.absent(),
            Value<double?> chest = const Value.absent(),
            Value<double?> waist = const Value.absent(),
            Value<double?> hip = const Value.absent(),
            Value<double?> thighLeft = const Value.absent(),
            Value<double?> thighRight = const Value.absent(),
            Value<double?> armLeft = const Value.absent(),
            Value<double?> armRight = const Value.absent(),
            Value<double?> neck = const Value.absent(),
            Value<double?> bmi = const Value.absent(),
            Value<double?> waistHipRatio = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String?> imagePath = const Value.absent(),
            required DateTime measuredAt,
            required DateTime createdAt,
          }) =>
              BodyMeasurementsCompanion.insert(
            id: id,
            weight: weight,
            height: height,
            bodyFat: bodyFat,
            muscleMass: muscleMass,
            chest: chest,
            waist: waist,
            hip: hip,
            thighLeft: thighLeft,
            thighRight: thighRight,
            armLeft: armLeft,
            armRight: armRight,
            neck: neck,
            bmi: bmi,
            waistHipRatio: waistHipRatio,
            note: note,
            imagePath: imagePath,
            measuredAt: measuredAt,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BodyMeasurementsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BodyMeasurementsTable,
    BodyMeasurement,
    $$BodyMeasurementsTableFilterComposer,
    $$BodyMeasurementsTableOrderingComposer,
    $$BodyMeasurementsTableAnnotationComposer,
    $$BodyMeasurementsTableCreateCompanionBuilder,
    $$BodyMeasurementsTableUpdateCompanionBuilder,
    (
      BodyMeasurement,
      BaseReferences<_$AppDatabase, $BodyMeasurementsTable, BodyMeasurement>
    ),
    BodyMeasurement,
    PrefetchHooks Function()>;
typedef $$AIConversationsTableCreateCompanionBuilder = AIConversationsCompanion
    Function({
  Value<int> id,
  required String title,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$AIConversationsTableUpdateCompanionBuilder = AIConversationsCompanion
    Function({
  Value<int> id,
  Value<String> title,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$AIConversationsTableReferences extends BaseReferences<
    _$AppDatabase, $AIConversationsTable, AIConversation> {
  $$AIConversationsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AIMessagesTable, List<AIMessage>>
      _aIMessagesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.aIMessages,
              aliasName: $_aliasNameGenerator(
                  db.aIConversations.id, db.aIMessages.conversationId));

  $$AIMessagesTableProcessedTableManager get aIMessagesRefs {
    final manager = $$AIMessagesTableTableManager($_db, $_db.aIMessages)
        .filter((f) => f.conversationId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_aIMessagesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$AIConversationsTableFilterComposer
    extends Composer<_$AppDatabase, $AIConversationsTable> {
  $$AIConversationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> aIMessagesRefs(
      Expression<bool> Function($$AIMessagesTableFilterComposer f) f) {
    final $$AIMessagesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.aIMessages,
        getReferencedColumn: (t) => t.conversationId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AIMessagesTableFilterComposer(
              $db: $db,
              $table: $db.aIMessages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AIConversationsTableOrderingComposer
    extends Composer<_$AppDatabase, $AIConversationsTable> {
  $$AIConversationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$AIConversationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AIConversationsTable> {
  $$AIConversationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> aIMessagesRefs<T extends Object>(
      Expression<T> Function($$AIMessagesTableAnnotationComposer a) f) {
    final $$AIMessagesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.aIMessages,
        getReferencedColumn: (t) => t.conversationId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AIMessagesTableAnnotationComposer(
              $db: $db,
              $table: $db.aIMessages,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AIConversationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AIConversationsTable,
    AIConversation,
    $$AIConversationsTableFilterComposer,
    $$AIConversationsTableOrderingComposer,
    $$AIConversationsTableAnnotationComposer,
    $$AIConversationsTableCreateCompanionBuilder,
    $$AIConversationsTableUpdateCompanionBuilder,
    (AIConversation, $$AIConversationsTableReferences),
    AIConversation,
    PrefetchHooks Function({bool aIMessagesRefs})> {
  $$AIConversationsTableTableManager(
      _$AppDatabase db, $AIConversationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AIConversationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AIConversationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AIConversationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              AIConversationsCompanion(
            id: id,
            title: title,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String title,
            required DateTime createdAt,
            required DateTime updatedAt,
          }) =>
              AIConversationsCompanion.insert(
            id: id,
            title: title,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$AIConversationsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({aIMessagesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (aIMessagesRefs) db.aIMessages],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (aIMessagesRefs)
                    await $_getPrefetchedData<AIConversation,
                            $AIConversationsTable, AIMessage>(
                        currentTable: table,
                        referencedTable: $$AIConversationsTableReferences
                            ._aIMessagesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AIConversationsTableReferences(db, table, p0)
                                .aIMessagesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.conversationId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$AIConversationsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AIConversationsTable,
    AIConversation,
    $$AIConversationsTableFilterComposer,
    $$AIConversationsTableOrderingComposer,
    $$AIConversationsTableAnnotationComposer,
    $$AIConversationsTableCreateCompanionBuilder,
    $$AIConversationsTableUpdateCompanionBuilder,
    (AIConversation, $$AIConversationsTableReferences),
    AIConversation,
    PrefetchHooks Function({bool aIMessagesRefs})>;
typedef $$AIMessagesTableCreateCompanionBuilder = AIMessagesCompanion Function({
  Value<int> id,
  required int conversationId,
  required String role,
  required String content,
  required DateTime createdAt,
});
typedef $$AIMessagesTableUpdateCompanionBuilder = AIMessagesCompanion Function({
  Value<int> id,
  Value<int> conversationId,
  Value<String> role,
  Value<String> content,
  Value<DateTime> createdAt,
});

final class $$AIMessagesTableReferences
    extends BaseReferences<_$AppDatabase, $AIMessagesTable, AIMessage> {
  $$AIMessagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AIConversationsTable _conversationIdTable(_$AppDatabase db) =>
      db.aIConversations.createAlias($_aliasNameGenerator(
          db.aIMessages.conversationId, db.aIConversations.id));

  $$AIConversationsTableProcessedTableManager get conversationId {
    final $_column = $_itemColumn<int>('conversation_id')!;

    final manager =
        $$AIConversationsTableTableManager($_db, $_db.aIConversations)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_conversationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$AIMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $AIMessagesTable> {
  $$AIMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$AIConversationsTableFilterComposer get conversationId {
    final $$AIConversationsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.conversationId,
        referencedTable: $db.aIConversations,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AIConversationsTableFilterComposer(
              $db: $db,
              $table: $db.aIConversations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AIMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $AIMessagesTable> {
  $$AIMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$AIConversationsTableOrderingComposer get conversationId {
    final $$AIConversationsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.conversationId,
        referencedTable: $db.aIConversations,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AIConversationsTableOrderingComposer(
              $db: $db,
              $table: $db.aIConversations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AIMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AIMessagesTable> {
  $$AIMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$AIConversationsTableAnnotationComposer get conversationId {
    final $$AIConversationsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.conversationId,
        referencedTable: $db.aIConversations,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AIConversationsTableAnnotationComposer(
              $db: $db,
              $table: $db.aIConversations,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AIMessagesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AIMessagesTable,
    AIMessage,
    $$AIMessagesTableFilterComposer,
    $$AIMessagesTableOrderingComposer,
    $$AIMessagesTableAnnotationComposer,
    $$AIMessagesTableCreateCompanionBuilder,
    $$AIMessagesTableUpdateCompanionBuilder,
    (AIMessage, $$AIMessagesTableReferences),
    AIMessage,
    PrefetchHooks Function({bool conversationId})> {
  $$AIMessagesTableTableManager(_$AppDatabase db, $AIMessagesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AIMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AIMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AIMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> conversationId = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              AIMessagesCompanion(
            id: id,
            conversationId: conversationId,
            role: role,
            content: content,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int conversationId,
            required String role,
            required String content,
            required DateTime createdAt,
          }) =>
              AIMessagesCompanion.insert(
            id: id,
            conversationId: conversationId,
            role: role,
            content: content,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$AIMessagesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({conversationId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (conversationId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.conversationId,
                    referencedTable:
                        $$AIMessagesTableReferences._conversationIdTable(db),
                    referencedColumn:
                        $$AIMessagesTableReferences._conversationIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$AIMessagesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AIMessagesTable,
    AIMessage,
    $$AIMessagesTableFilterComposer,
    $$AIMessagesTableOrderingComposer,
    $$AIMessagesTableAnnotationComposer,
    $$AIMessagesTableCreateCompanionBuilder,
    $$AIMessagesTableUpdateCompanionBuilder,
    (AIMessage, $$AIMessagesTableReferences),
    AIMessage,
    PrefetchHooks Function({bool conversationId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BloodSugarRecordsTableTableManager get bloodSugarRecords =>
      $$BloodSugarRecordsTableTableManager(_db, _db.bloodSugarRecords);
  $$ExerciseRecordsTableTableManager get exerciseRecords =>
      $$ExerciseRecordsTableTableManager(_db, _db.exerciseRecords);
  $$StrengthTrainingsTableTableManager get strengthTrainings =>
      $$StrengthTrainingsTableTableManager(_db, _db.strengthTrainings);
  $$MealRecordsTableTableManager get mealRecords =>
      $$MealRecordsTableTableManager(_db, _db.mealRecords);
  $$FoodItemsTableTableManager get foodItems =>
      $$FoodItemsTableTableManager(_db, _db.foodItems);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$TrainingPlansTableTableManager get trainingPlans =>
      $$TrainingPlansTableTableManager(_db, _db.trainingPlans);
  $$TrainingPlanExercisesTableTableManager get trainingPlanExercises =>
      $$TrainingPlanExercisesTableTableManager(_db, _db.trainingPlanExercises);
  $$BodyMeasurementsTableTableManager get bodyMeasurements =>
      $$BodyMeasurementsTableTableManager(_db, _db.bodyMeasurements);
  $$AIConversationsTableTableManager get aIConversations =>
      $$AIConversationsTableTableManager(_db, _db.aIConversations);
  $$AIMessagesTableTableManager get aIMessages =>
      $$AIMessagesTableTableManager(_db, _db.aIMessages);
}
