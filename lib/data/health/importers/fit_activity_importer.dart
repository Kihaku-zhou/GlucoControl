/// FIT 活动文件导入器（iGPSPORT 码表等）。
///
/// API 依据 `fit_tool` 1.0.5 源码确认：
/// `FitFile.fromBytes(Uint8List, {checkCrc})`、`FitFile.records`、`Record.message`。
///
/// `SessionMessage` / `RecordMessage` 的 `timestamp`、`startTime` 字段在 fit_tool 中
/// 声明为 `scale: 0.001, offset: -631065600000`，取值与赋值都是 **Unix 毫秒**，而不是
/// FIT 规范里的 1989 纪元秒；`totalElapsedTime` / `totalTimerTime` 是秒，
/// `totalDistance` 与 `RecordMessage.distance`、`altitude` 是米，
/// `totalAscent`、`normalizedPower`、`totalCalories` 分别是米、瓦、千卡。
library;

import 'dart:typed_data';

import 'package:fit_tool/fit_tool.dart';

import '../../../core/result.dart';
import '../../../domain/health/health_records.dart';
import '../../../domain/health/health_source.dart';
import 'import_utils.dart';

/// 解析 FIT 活动文件。
///
/// 优先用 `Session` 消息汇总一条活动；缺失 `Session` 时退化为由 `Record` 消息流
/// 推断起止时间、距离与心率。全程本地解析，不访问网络。
class FitActivityImporter extends HealthFileImporterBase {
  /// 构造导入器。
  FitActivityImporter();

  @override
  HealthSourceId get id => HealthSourceId.fileImport;

  @override
  String get displayName => 'FIT 活动';

  @override
  List<String> get fileExtensions => const <String>['fit'];

  @override
  bool canHandle(String fileName, List<int> bytes) {
    if (!hasFileExtension(fileName, fileExtensions)) return false;
    if (bytes.length < 12) return false;
    final headerSize = bytes[0];
    if (headerSize != 12 && headerSize != 14) return false;
    return bytes[8] == 0x2E &&
        bytes[9] == 0x46 &&
        bytes[10] == 0x49 &&
        bytes[11] == 0x54;
  }

  @override
  Future<Result<List<HealthSample>>> parse({
    required String fileName,
    required List<int> bytes,
  }) {
    final builder = ImportStatsBuilder();
    return runImport('fit_activity', () {
      try {
        if (!canHandle(fileName, bytes)) {
          throw importParsingFailure(
            '文件不是 FIT 活动，文件头校验失败',
            code: 'fit_bad_header',
          );
        }

        // checkCrc: false —— 码表在断电或强制停止时可能写出 CRC 不符的尾部，
        // 此时仍可读出完整性较好的 Session/Record 数据。
        final fitFile = FitFile.fromBytes(
          Uint8List.fromList(bytes),
          checkCrc: false,
        );

        final sessions = <SessionMessage>[];
        final records = <RecordMessage>[];
        for (final record in fitFile.records) {
          final message = record.message;
          if (message is SessionMessage) {
            sessions.add(message);
          } else if (message is RecordMessage) {
            records.add(message);
          }
        }

        final samples = <HealthSample>[];
        for (final session in sessions) {
          builder.countRead();
          final sample = _sampleFromSession(session, records);
          if (sample == null) {
            builder.countSkipped('Session 缺少可用开始时间');
            continue;
          }
          samples.add(sample);
          builder.countProduced();
        }

        if (samples.isEmpty && records.isNotEmpty) {
          builder.countRead();
          final sample = _sampleFromRecords(records);
          if (sample != null) {
            samples.add(sample);
            builder.countProduced();
          }
        }

        if (samples.isEmpty) {
          throw importParsingFailure(
            'FIT 文件中没有可用的 Session 或 Record 数据',
            code: 'fit_no_data',
          );
        }
        return samples;
      } finally {
        recordStats(builder.build());
      }
    });
  }

  /// 由一条 `Session` 消息汇总活动。
  ///
  /// @param session Session 消息。
  /// @param records 文件中的全部 Record 消息，用于补齐 Session 未提供的字段。
  /// @returns 归一化样本；无法确定开始时间时返回 null。
  HealthSample? _sampleFromSession(
    SessionMessage session,
    List<RecordMessage> records,
  ) {
    final startMs = session.startTime ?? _firstTimestamp(records);
    if (startMs == null) return null;

    final durationSeconds =
        session.totalTimerTime ?? session.totalElapsedTime ?? 0;
    final startedAt = _fitDateTime(startMs);
    final endMs =
        durationSeconds > 0 ? startMs + (durationSeconds * 1000).round() : null;

    final window = records
        .where((record) =>
            record.timestamp != null &&
            record.timestamp! >= startMs &&
            (endMs == null || record.timestamp! <= endMs))
        .toList();

    var endedAt = endMs != null
        ? _fitDateTime(endMs)
        : startedAt;
    final lastRecordTime = _lastTimestamp(window);
    if (lastRecordTime != null) {
      final candidate = _fitDateTime(lastRecordTime);
      if (candidate.isAfter(endedAt)) endedAt = candidate;
    }

    final sportName = session.sport?.name ?? '';
    final category = mapWorkoutCategoryKeyword(sportName);
    final name = category == WorkoutCategory.other
        ? 'FIT 活动'
        : '${category.label}训练';

    final distanceM = session.totalDistance ?? _recordDistanceMeters(window);
    final ascent = session.totalAscent;
    final hasElevation =
        ascent != null || window.any((record) => _recordElevation(record) != null);

    final avgHeartRate = session.avgHeartRate ?? _averageHeartRate(window);
    final maxHeartRate = session.maxHeartRate ?? _maxHeartRate(window);
    final avgPower = session.avgPower ?? _averagePower(window);

    return HealthSample(
      source: id,
      externalId: buildExternalId('fit', <Object?>[
        startMs,
        endMs ?? '',
        sportName,
        distanceM,
      ]),
      kind: HealthSampleKind.workout,
      startAt: startedAt,
      endAt: endedAt,
      title: name,
      payload: <String, Object?>{
        'category': category.code,
        'name': name,
        if (distanceM > 0) 'distanceKm': distanceM / 1000.0,
        if (ascent != null)
          'elevationGainM': ascent.toDouble()
        else if (hasElevation)
          'elevationGainM': elevationGainMeters(
            window.map(_recordElevation),
          ),
        if (avgPower != null) 'avgPowerW': avgPower.toDouble(),
        if (session.normalizedPower != null)
          'normalizedPowerW': session.normalizedPower!.toDouble(),
        if (avgHeartRate != null) 'avgHeartRate': avgHeartRate,
        if (maxHeartRate != null) 'maxHeartRate': maxHeartRate,
        if (session.totalCalories != null) 'calories': session.totalCalories,
      },
    );
  }

  /// 在没有任何 `Session` 消息时，由 `Record` 消息流推断一条活动。
  ///
  /// @param records 文件中的 Record 消息。
  /// @returns 归一化样本；没有可用时间戳时返回 null。
  HealthSample? _sampleFromRecords(List<RecordMessage> records) {
    final startMs = _firstTimestamp(records);
    final lastMs = _lastTimestamp(records);
    if (startMs == null) return null;
    if (lastMs == null || lastMs <= startMs) return null;

    final startedAt = _fitDateTime(startMs);
    final endedAt = _fitDateTime(lastMs);
    final distanceM = _recordDistanceMeters(records);
    final hasElevation = records.any((record) => _recordElevation(record) != null);
    final avgHeartRate = _averageHeartRate(records);
    final maxHeartRate = _maxHeartRate(records);

    return HealthSample(
      source: id,
      externalId: buildExternalId('fit', <Object?>[
        startMs,
        lastMs,
        distanceM,
      ]),
      kind: HealthSampleKind.workout,
      startAt: startedAt,
      endAt: endedAt,
      title: 'FIT 活动',
      payload: <String, Object?>{
        'category': WorkoutCategory.other.code,
        'name': 'FIT 活动',
        if (distanceM > 0) 'distanceKm': distanceM / 1000.0,
        if (hasElevation)
          'elevationGainM': elevationGainMeters(records.map(_recordElevation)),
        if (avgHeartRate != null) 'avgHeartRate': avgHeartRate,
        if (maxHeartRate != null) 'maxHeartRate': maxHeartRate,
      },
    );
  }

  /// 把 fit_tool 的时间戳（Unix 毫秒，UTC）转为本地时间。
  ///
  /// @param milliseconds 自 1970-01-01T00:00:00Z 起的毫秒数。
  /// @returns 本地时间。
  DateTime _fitDateTime(int milliseconds) =>
      DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true).toLocal();

  /// 取第一条有时间戳的 Record 的时间。
  ///
  /// @param records Record 消息。
  /// @returns Unix 毫秒；没有可用时间戳时返回 null。
  int? _firstTimestamp(List<RecordMessage> records) {
    for (final record in records) {
      final timestamp = record.timestamp;
      if (timestamp != null) return timestamp;
    }
    return null;
  }

  /// 取最后一条有时间戳的 Record 的时间。
  ///
  /// @param records Record 消息。
  /// @returns Unix 毫秒；没有可用时间戳时返回 null。
  int? _lastTimestamp(List<RecordMessage> records) {
    int? result;
    for (final record in records) {
      final timestamp = record.timestamp;
      if (timestamp != null) result = timestamp;
    }
    return result;
  }

  /// 取 Record 的海拔，优先增强海拔字段。
  ///
  /// @param record Record 消息。
  /// @returns 海拔（米）；两字段都缺时为 null。
  double? _recordElevation(RecordMessage record) =>
      record.enhancedAltitude ?? record.altitude;

  /// 由 Record 的累计距离字段推断总距离。
  ///
  /// @param records Record 消息。
  /// @returns 总距离（米）；没有距离字段时退化为轨迹点的 Haversine 距离。
  double _recordDistanceMeters(List<RecordMessage> records) {
    double? first;
    double? last;
    for (final record in records) {
      final distance = record.distance;
      if (distance == null) continue;
      first ??= distance;
      last = distance;
    }
    if (first != null && last != null && last > first) return last - first;

    final located = records
        .where((record) =>
            record.positionLat != null && record.positionLong != null)
        .toList();
    var total = 0.0;
    for (var i = 1; i < located.length; i++) {
      total += haversineMeters(
        located[i - 1].positionLat!,
        located[i - 1].positionLong!,
        located[i].positionLat!,
        located[i].positionLong!,
      );
    }
    return total;
  }

  /// 计算 Record 心率的算术平均。
  ///
  /// @param records Record 消息。
  /// @returns 平均心率；无可用心率时返回 null。
  int? _averageHeartRate(List<RecordMessage> records) {
    final values =
        records.map((record) => record.heartRate).whereType<int>().toList();
    if (values.isEmpty) return null;
    final sum = values.fold<int>(0, (total, value) => total + value);
    return (sum / values.length).round();
  }

  /// 取 Record 心率的最大值。
  ///
  /// @param records Record 消息。
  /// @returns 最大心率；无可用心率时返回 null。
  int? _maxHeartRate(List<RecordMessage> records) {
    int? result;
    for (final record in records) {
      final heartRate = record.heartRate;
      if (heartRate != null && (result == null || heartRate > result)) {
        result = heartRate;
      }
    }
    return result;
  }

  /// 计算 Record 功率的算术平均。
  ///
  /// @param records Record 消息。
  /// @returns 平均功率（瓦）；无可用功率时返回 null。
  int? _averagePower(List<RecordMessage> records) {
    final values =
        records.map((record) => record.power).whereType<int>().toList();
    if (values.isEmpty) return null;
    final sum = values.fold<int>(0, (total, value) => total + value);
    return (sum / values.length).round();
  }
}
