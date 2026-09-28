/// GPX 轨迹文件导入器（iGPSPORT、Keep 等）。
library;

import 'package:xml/xml.dart';

import '../../../core/result.dart';
import '../../../domain/health/health_source.dart';
import 'import_utils.dart';

/// 解析 GPX 1.0 / 1.1 轨迹文件。
///
/// 每条 `<trk>` 产出一条 [HealthSampleKind.workout] 样本：距离由相邻轨迹点的
/// Haversine 距离累加，累计爬升由 `<ele>` 正高差累加，起止时间取自 `<time>`。
/// 全过程为本地解析，不访问网络。
class GpxTrackImporter extends HealthFileImporterBase {
  /// 构造导入器。
  GpxTrackImporter();

  @override
  HealthSourceId get id => HealthSourceId.fileImport;

  @override
  String get displayName => 'GPX 轨迹';

  @override
  List<String> get fileExtensions => const <String>['gpx'];

  @override
  bool canHandle(String fileName, List<int> bytes) {
    if (!hasFileExtension(fileName, fileExtensions)) return false;
    return _looksLikeGpx(decodeImportText(headBytes(bytes, maxBytes: 4096)));
  }

  @override
  Future<Result<List<HealthSample>>> parse({
    required String fileName,
    required List<int> bytes,
  }) {
    final builder = ImportStatsBuilder();
    return runImport('gpx_track', () {
      try {
        final text = decodeImportText(bytes);
        if (!_looksLikeGpx(text)) {
          throw importParsingFailure(
            '文件不是 GPX 轨迹，缺少 <gpx> 根元素',
            code: 'gpx_no_root',
          );
        }

        final document = XmlDocument.parse(text);
        final tracks =
            descendantElementsNamed(document.rootElement, 'trk').toList();
        if (tracks.isEmpty) {
          throw importParsingFailure(
            'GPX 文件中没有 <trk> 轨迹段',
            code: 'gpx_no_track',
          );
        }

        final samples = <HealthSample>[];
        for (final track in tracks) {
          builder.countRead();
          final sample = _parseTrack(track);
          if (sample == null) {
            builder.countSkipped('轨迹缺少可用坐标或时间');
            continue;
          }
          samples.add(sample);
          builder.countProduced();
        }

        if (samples.isEmpty) {
          throw importParsingFailure(
            'GPX 文件中没有可用轨迹',
            code: 'gpx_empty',
          );
        }
        return samples;
      } finally {
        recordStats(builder.build());
      }
    });
  }

  /// 判断文本是否具备 GPX 的结构特征。
  ///
  /// 要求 `<gpx` 根标签出现在前面一小段内（允许 XML 声明、注释与命名空间前缀），
  /// 避免为无关字节流先建整棵 XML 树。
  ///
  /// @param text 文件文本。
  /// @returns 具备 GPX 根元素特征时为 true。
  bool _looksLikeGpx(String text) {
    final head = text.trimLeft().toLowerCase();
    if (head.isEmpty) return false;
    final index = head.indexOf('<gpx');
    return index >= 0 && index < 512;
  }

  /// 解析一条 `<trk>`。
  ///
  /// @param track 轨迹元素。
  /// @returns 归一化样本；没有可用坐标或时间时返回 null。
  HealthSample? _parseTrack(XmlElement track) {
    final points = <_GpxPoint>[];
    for (final point in descendantElementsNamed(track, 'trkpt')) {
      final rawLat = point.getAttribute('lat')?.trim() ?? '';
      final rawLon = point.getAttribute('lon')?.trim() ?? '';
      final lat = parseDoubleCell(rawLat);
      final lon = parseDoubleCell(rawLon);
      if (lat == null || lon == null) continue;

      final rawTime = _childText(point, 'time');
      points.add(_GpxPoint(
        lat: lat,
        lon: lon,
        elevationM: parseDoubleCell(_childText(point, 'ele')),
        time: parseDateTimeCell(rawTime),
        rawLat: rawLat,
        rawLon: rawLon,
        rawTime: rawTime,
      ));
    }
    if (points.isEmpty) return null;

    final timed = points.where((point) => point.time != null).toList();
    if (timed.isEmpty) return null;

    var distanceM = 0.0;
    for (var i = 1; i < points.length; i++) {
      distanceM += haversineMeters(
        points[i - 1].lat,
        points[i - 1].lon,
        points[i].lat,
        points[i].lon,
      );
    }

    final hasElevation = points.any((point) => point.elevationM != null);
    final gainM = elevationGainMeters(points.map((point) => point.elevationM));

    final name = _childText(track, 'name');
    final title = name.isEmpty ? 'GPX 轨迹' : name;
    final category = mapWorkoutCategoryKeyword(_childText(track, 'type'));
    final startedAt = timed.first.time!;
    final endedAt = timed.last.time!;

    return HealthSample(
      source: id,
      externalId: buildExternalId('gpx', <Object?>[
        title,
        points.first.rawTime,
        points.first.rawLat,
        points.first.rawLon,
        points.length,
      ]),
      kind: HealthSampleKind.workout,
      startAt: startedAt,
      endAt: endedAt,
      title: title,
      payload: <String, Object?>{
        'category': category.code,
        'name': title,
        'distanceKm': distanceM / 1000.0,
        if (hasElevation) 'elevationGainM': gainM,
      },
    );
  }

  /// 读取 [parent] 下第一个同名的子元素文本。
  ///
  /// @param parent 父元素。
  /// @param localName 子元素的本地名。
  /// @returns 去空白的文本；不存在时返回空串。
  String _childText(XmlElement parent, String localName) =>
      childElementText(parent, localName);
}

/// GPX 中的一个轨迹点。
class _GpxPoint {
  const _GpxPoint({
    required this.lat,
    required this.lon,
    required this.elevationM,
    required this.time,
    required this.rawLat,
    required this.rawLon,
    required this.rawTime,
  });

  /// 纬度（度）。
  final double lat;

  /// 经度（度）。
  final double lon;

  /// 海拔（米）；缺测时为 null。
  final double? elevationM;

  /// 解析后的时间；无法解析时为 null。
  final DateTime? time;

  /// 原始 `lat` 属性文本，用于构造稳定的幂等键。
  final String rawLat;

  /// 原始 `lon` 属性文本，用于构造稳定的幂等键。
  final String rawLon;

  /// 原始 `<time>` 文本，用于构造稳定的幂等键。
  final String rawTime;
}
