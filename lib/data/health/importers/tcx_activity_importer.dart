/// TCX 活动文件导入器（Garmin Training Center XML）。
library;

import 'package:xml/xml.dart';

import '../../../core/result.dart';
import '../../../domain/health/health_records.dart';
import '../../../domain/health/health_source.dart';
import 'import_utils.dart';

/// 解析 TCX 活动文件。
///
/// 每条 `<Activity>` 产出一条 [HealthSampleKind.workout] 样本，汇总其全部 `<Lap>`
/// 的时长、距离、卡路里与心率；轨迹点的 `<AltitudeMeters>` 用于累计爬升，
/// 没有 Lap 距离时改用轨迹点的 Haversine 距离。全过程为本地解析。
class TcxActivityImporter extends HealthFileImporterBase {
  /// 构造导入器。
  TcxActivityImporter();

  @override
  HealthSourceId get id => HealthSourceId.fileImport;

  @override
  String get displayName => 'TCX 活动';

  @override
  List<String> get fileExtensions => const <String>['tcx'];

  @override
  bool canHandle(String fileName, List<int> bytes) {
    if (!hasFileExtension(fileName, fileExtensions)) return false;
    final text = decodeImportText(headBytes(bytes, maxBytes: 4096));
    return _looksLikeTcx(text);
  }

  @override
  Future<Result<List<HealthSample>>> parse({
    required String fileName,
    required List<int> bytes,
  }) {
    final builder = ImportStatsBuilder();
    return runImport('tcx_activity', () {
      try {
        final text = decodeImportText(bytes);
        if (!_looksLikeTcx(text)) {
          throw importParsingFailure(
            '文件不是 TCX 活动，缺少 TrainingCenterDatabase 根元素',
            code: 'tcx_no_root',
          );
        }

        final document = XmlDocument.parse(text);
        final activities =
            descendantElementsNamed(document.rootElement, 'Activity').toList();
        if (activities.isEmpty) {
          throw importParsingFailure(
            'TCX 文件中没有 <Activity> 记录',
            code: 'tcx_no_activity',
          );
        }

        final samples = <HealthSample>[];
        for (final activity in activities) {
          builder.countRead();
          final sample = _parseActivity(activity);
          if (sample == null) {
            builder.countSkipped('活动缺少可用时间');
            continue;
          }
          samples.add(sample);
          builder.countProduced();
        }

        if (samples.isEmpty) {
          throw importParsingFailure(
            'TCX 文件中没有可用活动',
            code: 'tcx_empty',
          );
        }
        return samples;
      } finally {
        recordStats(builder.build());
      }
    });
  }

  /// 判断文本是否具备 TCX 的结构特征。
  ///
  /// @param text 文件文本。
  /// @returns 含 `TrainingCenterDatabase` 根元素特征时为 true。
  bool _looksLikeTcx(String text) => text.contains('TrainingCenterDatabase');

  /// 解析一条 `<Activity>`。
  ///
  /// @param activity 活动元素。
  /// @returns 归一化样本；没有任何可用时间时返回 null。
  HealthSample? _parseActivity(XmlElement activity) {
    final laps = activity.childElements
        .where((element) => element.localName == 'Lap')
        .toList();

    final trackPoints = <_TcxTrackPoint>[];
    for (final lap in laps) {
      for (final point in descendantElementsNamed(lap, 'Trackpoint')) {
        trackPoints.add(_parseTrackPoint(point));
      }
    }

    final timedPoints =
        trackPoints.where((point) => point.time != null).toList();
    final startTimeText = childElementText(activity, 'Id');
    final lapStartTimes = laps
        .map((lap) => lap.getAttribute('StartTime')?.trim() ?? '')
        .where((value) => value.isNotEmpty)
        .toList();

    DateTime? startedAt = timedPoints.isEmpty ? null : timedPoints.first.time;
    startedAt ??= parseDateTimeCell(startTimeText);
    if (startedAt == null && lapStartTimes.isNotEmpty) {
      startedAt = parseDateTimeCell(lapStartTimes.first);
    }
    if (startedAt == null) return null;

    final totalSeconds = laps.fold<double>(
      0,
      (sum, lap) => sum + (parseDoubleCell(childElementText(lap, 'TotalTimeSeconds')) ?? 0),
    );
    final lapDistanceM = laps.fold<double>(
      0,
      (sum, lap) => sum + (parseDoubleCell(childElementText(lap, 'DistanceMeters')) ?? 0),
    );
    final distanceM = lapDistanceM > 0
        ? lapDistanceM
        : _trackDistanceMeters(trackPoints);

    final calories = laps
        .map((lap) => parseIntCell(childElementText(lap, 'Calories')))
        .fold<int>(0, (sum, value) => sum + (value ?? 0));

    final avgHeartRate = _averageHeartRate(laps, trackPoints);
    final maxHeartRate = _maxHeartRate(laps, trackPoints);
    final hasElevation =
        trackPoints.any((point) => point.elevationM != null);
    final gainM =
        elevationGainMeters(trackPoints.map((point) => point.elevationM));

    var endedAt = timedPoints.isEmpty ? null : timedPoints.last.time;
    if (endedAt == null || !endedAt.isAfter(startedAt)) {
      endedAt = totalSeconds > 0
          ? startedAt.add(
              Duration(milliseconds: (totalSeconds * 1000).round()))
          : startedAt;
    }

    final sport = activity.getAttribute('Sport')?.trim() ?? '';
    final notes = childElementText(activity, 'Notes');
    final name = notes.isNotEmpty
        ? notes
        : (sport.isEmpty ? 'TCX 活动' : 'TCX $sport');

    return HealthSample(
      source: id,
      externalId: buildExternalId('tcx', <Object?>[
        startTimeText.isNotEmpty
            ? startTimeText
            : (timedPoints.isEmpty ? '' : timedPoints.first.rawTime),
        sport,
        laps.length,
        distanceM,
      ]),
      kind: HealthSampleKind.workout,
      startAt: startedAt,
      endAt: endedAt,
      title: name,
      payload: <String, Object?>{
        'category': mapWorkoutCategoryKeyword(sport).code,
        'name': name,
        'distanceKm': distanceM / 1000.0,
        if (hasElevation) 'elevationGainM': gainM,
        if (calories > 0) 'calories': calories,
        if (avgHeartRate != null) 'avgHeartRate': avgHeartRate,
        if (maxHeartRate != null) 'maxHeartRate': maxHeartRate,
      },
    );
  }

  /// 解析一个 `<Trackpoint>`。
  ///
  /// @param point 轨迹点元素。
  /// @returns 提取出的轨迹点；缺失字段保留为 null。
  _TcxTrackPoint _parseTrackPoint(XmlElement point) {
    XmlElement? position;
    for (final child in point.childElements) {
      if (child.localName == 'Position') {
        position = child;
        break;
      }
    }
    return _TcxTrackPoint(
      time: parseDateTimeCell(childElementText(point, 'Time')),
      rawTime: childElementText(point, 'Time'),
      latitude: position == null
          ? null
          : parseDoubleCell(childElementText(position, 'LatitudeDegrees')),
      longitude: position == null
          ? null
          : parseDoubleCell(childElementText(position, 'LongitudeDegrees')),
      elevationM: parseDoubleCell(childElementText(point, 'AltitudeMeters')),
      heartRate: _heartRateValue(point, 'HeartRateBpm'),
    );
  }

  /// 读取形如 `<HeartRateBpm><Value>140</Value></HeartRateBpm>` 的心率值。
  ///
  /// @param element 含该包装子元素的节点。
  /// @param wrapperName 包装子元素的本地名，如 `HeartRateBpm`。
  /// @returns 心率值；包装子元素或 `<Value>` 缺失时返回 null。
  int? _heartRateValue(XmlElement element, String wrapperName) {
    for (final child in element.childElements) {
      if (child.localName != wrapperName) continue;
      return parseIntCell(childElementText(child, 'Value'));
    }
    return null;
  }

  /// 用相邻轨迹点的 Haversine 距离累加轨迹总长。
  ///
  /// @param points 轨迹点。
  /// @returns 总距离（米）；坐标不足两点时返回 0。
  double _trackDistanceMeters(List<_TcxTrackPoint> points) {
    final located = points
        .where((point) => point.latitude != null && point.longitude != null)
        .toList();
    var distanceM = 0.0;
    for (var i = 1; i < located.length; i++) {
      distanceM += haversineMeters(
        located[i - 1].latitude!,
        located[i - 1].longitude!,
        located[i].latitude!,
        located[i].longitude!,
      );
    }
    return distanceM;
  }

  /// 计算平均心率。
  ///
  /// 优先按各 Lap 的时长对 `<AverageHeartRateBpm>` 加权；Lap 未提供时退化为
  /// 全部轨迹点心率的算术平均。
  ///
  /// @param laps Lap 元素。
  /// @param points 轨迹点。
  /// @returns 平均心率；无可用心率时返回 null。
  int? _averageHeartRate(List<XmlElement> laps, List<_TcxTrackPoint> points) {
    var weighted = 0.0;
    var totalWeight = 0.0;
    for (final lap in laps) {
      final average = _heartRateValue(lap, 'AverageHeartRateBpm');
      if (average == null) continue;
      final seconds =
          parseDoubleCell(childElementText(lap, 'TotalTimeSeconds')) ?? 0;
      final weight = seconds > 0 ? seconds : 1.0;
      weighted += average * weight;
      totalWeight += weight;
    }
    if (totalWeight > 0) return (weighted / totalWeight).round();

    final samples = points
        .map((point) => point.heartRate)
        .whereType<int>()
        .toList();
    if (samples.isEmpty) return null;
    final sum = samples.fold<int>(0, (total, value) => total + value);
    return (sum / samples.length).round();
  }

  /// 计算最大心率。
  ///
  /// 取各 Lap `<MaximumHeartRateBpm>` 与全部轨迹点心率的最大值。
  ///
  /// @param laps Lap 元素。
  /// @param points 轨迹点。
  /// @returns 最大心率；无可用心率时返回 null。
  int? _maxHeartRate(List<XmlElement> laps, List<_TcxTrackPoint> points) {
    int? result;
    for (final lap in laps) {
      final maximum = _heartRateValue(lap, 'MaximumHeartRateBpm');
      if (maximum != null && (result == null || maximum > result)) {
        result = maximum;
      }
    }
    for (final point in points) {
      final heartRate = point.heartRate;
      if (heartRate != null && (result == null || heartRate > result)) {
        result = heartRate;
      }
    }
    return result;
  }
}

/// TCX 中的一个轨迹点。
class _TcxTrackPoint {
  const _TcxTrackPoint({
    required this.time,
    required this.rawTime,
    required this.latitude,
    required this.longitude,
    required this.elevationM,
    required this.heartRate,
  });

  /// 解析后的时间；无法解析时为 null。
  final DateTime? time;

  /// 原始 `<Time>` 文本。
  final String rawTime;

  /// 纬度（度）。
  final double? latitude;

  /// 经度（度）。
  final double? longitude;

  /// 海拔（米）。
  final double? elevationM;

  /// 心率（次/分）。
  final int? heartRate;
}
