/// 外部健康文件导入的共用工具。
///
/// 覆盖真实导出文件里反复出现的三类麻烦：
///
/// 1. 编码——UTF-8 BOM、UTF-16（Excel「Unicode 文本」）、GBK 混杂；
/// 2. 表头——中英混排、单位写在括号里、全角字符与不规则空格；
/// 3. 单元格——数字带单位后缀或千分位、占位符（`--`、`N/A`）、日期有多种写法。
///
/// 另提供基于 sha1 的确定性幂等指纹 [buildExternalId]，以及运动品类归一化
/// [mapWorkoutCategoryKeyword]。
library;

import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:csv/csv.dart';
import 'package:xml/xml.dart';

import '../../../core/result.dart';
import '../../../domain/health/health_data_source.dart';
import '../../../domain/health/health_records.dart';
import '../../../domain/health/health_source.dart';
import 'gbk_table.dart';

// ---------------------------------------------------------------------------
// 编码
// ---------------------------------------------------------------------------

/// 把导出文件的原始字节解码为文本。
///
/// 依次尝试 UTF-8 BOM、UTF-16 BOM、严格 UTF-8、GBK，转码失败不影响调用方。
/// GBK 回退会做近似解码：无法映射的字节记为 U+FFFD，不会抛异常。
///
/// @param bytes 文件原始字节。
/// @returns 解码后的文本，BOM 已去除。
String decodeImportText(List<int> bytes) {
  if (bytes.isEmpty) return '';

  if (bytes.length >= 3 &&
      bytes[0] == 0xEF &&
      bytes[1] == 0xBB &&
      bytes[2] == 0xBF) {
    return _decodeStrictUtf8(bytes.sublist(3)) ?? _decodeGbk(bytes.sublist(3));
  }

  if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
    return _decodeUtf16(bytes.sublist(2), bigEndian: false);
  }
  if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
    return _decodeUtf16(bytes.sublist(2), bigEndian: true);
  }

  return _decodeStrictUtf8(bytes) ?? _decodeGbk(bytes);
}

/// 取文件头部若干字节，供表头嗅探使用。
///
/// 截断可能落在多字节字符中间，解码侧会把它记为 U+FFFD，不影响表头识别。
///
/// @param bytes 文件原始字节。
/// @param maxBytes 最多保留的字节数。
/// @returns 原字节或它的前缀。
List<int> headBytes(List<int> bytes, {int maxBytes = 8192}) =>
    bytes.length <= maxBytes ? bytes : bytes.sublist(0, maxBytes);

/// 严格按 UTF-8 解码。
///
/// @param bytes 待解码字节。
/// @returns 合法 UTF-8 对应的文本；含非法序列时返回 null。
String? _decodeStrictUtf8(List<int> bytes) {
  try {
    return const Utf8Decoder(allowMalformed: false).convert(bytes);
  } on FormatException {
    return null;
  }
}

/// 按 UTF-16 解码。
///
/// @param bytes 已去掉 BOM 的字节序列。
/// @param bigEndian 是否大端序。
/// @returns 解码后的文本；末尾残字节记为 U+FFFD。
String _decodeUtf16(List<int> bytes, {required bool bigEndian}) {
  final units = <int>[];
  for (var i = 0; i + 1 < bytes.length; i += 2) {
    units.add(bigEndian
        ? (bytes[i] << 8) | bytes[i + 1]
        : (bytes[i + 1] << 8) | bytes[i]);
  }
  if (bytes.length.isOdd) units.add(0xFFFD);
  return String.fromCharCodes(units);
}

/// 按 GBK（代码页 936）近似解码。
///
/// 单字节 0x00-0x7F 按 ASCII 处理，0x80 映射为欧元符号，其余按
/// [gbkTableIndex] 查表；查不到时写入 U+FFFD。
///
/// @param bytes 待解码字节。
/// @returns 解码后的文本。
String _decodeGbk(List<int> bytes) {
  final buffer = StringBuffer();
  var i = 0;
  while (i < bytes.length) {
    final first = bytes[i];
    if (first < 0x80) {
      buffer.writeCharCode(first);
      i++;
      continue;
    }
    if (first == 0x80) {
      buffer.writeCharCode(0x20AC);
      i++;
      continue;
    }
    if (first > 0xFE || i + 1 >= bytes.length) {
      buffer.writeCharCode(0xFFFD);
      i++;
      continue;
    }
    final second = bytes[i + 1];
    final validSecond = second >= 0x40 && second <= 0xFE && second != 0x7F;
    if (!validSecond) {
      buffer.writeCharCode(0xFFFD);
      i++;
      continue;
    }
    final index = gbkTableIndex(first, second);
    buffer.writeCharCode(
        index >= 0 && index < gbkTable.length ? gbkTable.codeUnitAt(index) : 0xFFFD);
    i += 2;
  }
  return buffer.toString();
}

// ---------------------------------------------------------------------------
// 文本归一化
// ---------------------------------------------------------------------------

/// 把全角字符转成半角。
///
/// 覆盖全角空格（U+3000）与全角 ASCII 区（U+FF01-U+FF5E），
/// 因此 `血糖（mmol／L）` 会变成 `血糖(mmol/L)`。
///
/// @param text 原始文本。
/// @returns 转换后的文本。
String toHalfWidth(String text) {
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    if (rune == 0x3000) {
      buffer.write(' ');
    } else if (rune >= 0xFF01 && rune <= 0xFF5E) {
      buffer.writeCharCode(rune - 0xFEE0);
    } else {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}

/// 归一化一个表头单元格，得到可用于比对的列名。
///
/// 处理顺序：去 BOM → 全角转半角 → 转小写 → 去掉括号内的单位 → 去掉空格与
/// 常见分隔符。例如 `血糖(mmol/L)`、` 血糖 ( mmol/L )`、`血糖【mmol/L】`
/// 都归一化为 `血糖`。
///
/// @param raw 原始列名。
/// @returns 归一化后的列名；无法得到有效字符时返回空串。
String normalizeHeaderKey(String raw) {
  var text = raw;
  if (text.isNotEmpty && text.codeUnitAt(0) == 0xFEFF) {
    text = text.substring(1);
  }
  text = toHalfWidth(text).toLowerCase();
  text = text.replaceAll(_bracketPattern, '');

  final buffer = StringBuffer();
  for (final rune in text.runes) {
    final char = String.fromCharCode(rune);
    if (_headerNoiseRunes.contains(char)) continue;
    buffer.write(char);
  }
  return buffer.toString();
}

/// 括号及其内容：`(kg)`、`[km]`、`{min}`，支持未闭合。
final RegExp _bracketPattern = RegExp(r'[({\[][^)}\]]*[)}\]]?');

/// 表头里不影响列名识别的字符。
const Set<String> _headerNoiseRunes = {
  ' ', '\t', '\n', '\r', '\u00a0', '\u3000', '_', '-', '—', '–', '.', '/', '\\',
  ':', ';', '*', '#', '|', '"', "'", '`', '【', '】', '、', '，', ',', '=', '+',
  '(', ')',
};

/// 括号内单位文本。
final RegExp _unitPattern = RegExp(r'[({\[]\s*([^)}\]]*)\s*[)}\]]');

// ---------------------------------------------------------------------------
// 单元格解析
// ---------------------------------------------------------------------------

/// 匹配单元格里的第一个数值，允许前后带单位、符号与千分位。
final RegExp _numericPattern = RegExp(r'[-+]?\d+(?:[.,]\d+)*');

/// 从单元格里解析浮点数。
///
/// 容忍单位后缀（`5.6 mmol/L`）、千分位（`1,234.5`）、前置比较符（`>7.8`）、
/// 空值与占位符（``、`--`、`N/A`、`null`）。
///
/// @param raw 单元格原值，可为 num 或 String。
/// @returns 解析出的数值；无有效数字时返回 null。
double? parseDoubleCell(Object? raw) {
  if (raw == null) return null;
  if (raw is num) {
    final value = raw.toDouble();
    return value.isFinite ? value : null;
  }
  if (raw is! String) return null;

  final match = _numericPattern.firstMatch(raw.trim());
  if (match == null) return null;

  final value = double.tryParse(_normalizeDecimalSeparators(match.group(0)!));
  if (value == null || !value.isFinite) return null;
  return value;
}

/// 从单元格里解析整数，小数按四舍五入取整。
///
/// @param raw 单元格原值。
/// @returns 解析出的整数；无有效数字时返回 null。
int? parseIntCell(Object? raw) => parseDoubleCell(raw)?.round();

/// 把数值字面量统一为 Dart 可解析的写法。
///
/// 同时出现 `.` 与 `,` 时，靠后者为小数点；只有 `,` 时，若其后每段都是 3 位
/// 则视为千分位，否则视为小数点。
///
/// @param literal 形如 `1,234.5`、`5,6`、`12` 的字面量。
/// @returns 可交给 [double.tryParse] 的字面量。
String _normalizeDecimalSeparators(String literal) {
  final lastDot = literal.lastIndexOf('.');
  final lastComma = literal.lastIndexOf(',');

  if (lastDot >= 0 && lastComma >= 0) {
    return lastDot > lastComma
        ? literal.replaceAll(',', '')
        : literal.replaceAll('.', '').replaceAll(',', '.');
  }
  if (lastComma >= 0) {
    final groups = literal.split(',');
    final isThousands =
        groups.length > 1 && groups.skip(1).every((g) => g.length == 3);
    if (isThousands) return literal.replaceAll(',', '');
    final head = groups.sublist(0, groups.length - 1).join();
    return '$head.${groups.last}';
  }
  return literal;
}

/// 解析导出文件中的日期时间文本。
///
/// 支持 ISO 8601（含 `Z` / `+08:00` 偏移）、`2025-01-02 08:30`、`2025/1/2 8:30`、
/// `2025年1月2日 8时30分`、`20250102`、纯日期等写法。
///
/// 带时区偏移的输入会被换算为本地时间；不带偏移的输入按本地时间解释。
///
/// @param raw 单元格原值。
/// @returns 解析出的时间；无法识别时返回 null。
DateTime? parseDateTimeCell(Object? raw) {
  if (raw == null) return null;
  final text = toHalfWidth(raw is String ? raw : raw.toString()).trim();
  if (text.isEmpty) return null;

  final iso = DateTime.tryParse(text);
  if (iso != null) return iso.isUtc ? iso.toLocal() : iso;

  final patterned = _parsePatternedDateTime(text);
  if (patterned != null) return patterned;

  return _parseCompactDateTime(text);
}

/// 按中英文日期分隔符 + 可选时间部分解析。
///
/// @param text 已转半角并去空白的文本。
/// @returns 解析结果；结构不匹配时返回 null。
DateTime? _parsePatternedDateTime(String text) {
  final match = _dateTimePattern.firstMatch(text);
  if (match == null) return null;
  return _buildDateTime(
    year: int.parse(match.group(1)!),
    month: int.parse(match.group(2)!),
    day: int.parse(match.group(3)!),
    hour: int.tryParse(match.group(4) ?? '') ?? 0,
    minute: int.tryParse(match.group(5) ?? '') ?? 0,
    second: int.tryParse(match.group(6) ?? '') ?? 0,
  );
}

/// 按 `yyyyMMdd` / `yyyyMMddHHmmss` 紧凑写法解析。
///
/// @param text 已转半角并去空白的文本。
/// @returns 解析结果；结构不匹配时返回 null。
DateTime? _parseCompactDateTime(String text) {
  final match = _compactDateTimePattern.firstMatch(text);
  if (match == null) return null;
  return _buildDateTime(
    year: int.parse(match.group(1)!),
    month: int.parse(match.group(2)!),
    day: int.parse(match.group(3)!),
    hour: int.tryParse(match.group(4) ?? '') ?? 0,
    minute: int.tryParse(match.group(5) ?? '') ?? 0,
    second: int.tryParse(match.group(6) ?? '') ?? 0,
  );
}

/// 校验各字段取值范围后构造本地时间。
///
/// @param year 四位年份。
/// @param month 月份 1-12。
/// @param day 日 1-31。
/// @param hour 时 0-23。
/// @param minute 分 0-59。
/// @param second 秒 0-59。
/// @returns 合法时返回本地时间，否则返回 null（不把 2 月 30 日顺延到 3 月）。
DateTime? _buildDateTime({
  required int year,
  required int month,
  required int day,
  required int hour,
  required int minute,
  required int second,
}) {
  if (month < 1 || month > 12) return null;
  if (day < 1 || day > 31) return null;
  if (hour > 23 || minute > 59 || second > 59) return null;
  final result = DateTime(year, month, day, hour, minute, second);
  if (result.month != month || result.day != day) return null;
  return result;
}

/// `yyyy-M-d` / `yyyy/M/d` / `yyyy.M.d` / `yyyy年M月d日` 加可选时间部分。
final RegExp _dateTimePattern = RegExp(
  r'(\d{4})\s*[-/.年]\s*(\d{1,2})\s*[-/.月]\s*(\d{1,2})\s*日?'
  r'(?:[T\s]+(\d{1,2})\s*[:：时]\s*(\d{1,2})'
  r'(?:\s*[:：分]\s*(\d{1,2}))?\s*秒?)?',
);

/// `yyyyMMdd` 或 `yyyyMMddHHmm[ss]`。
final RegExp _compactDateTimePattern =
    RegExp(r'^(\d{4})(\d{2})(\d{2})(?:(\d{2})(\d{2})(\d{2})?)?$');

/// 无单位数字时长的默认解释方式。
enum DurationUnitHint {
  /// 视为秒。
  seconds,

  /// 视为分钟。
  minutes,
}

/// 带单位标记的时长片段。
final RegExp _durationTokenPattern =
    RegExp(r'(\d+(?:[.,]\d+)?)\s*(小时|时|h|min|分钟|分|ms|秒|s)');

/// 冒号分隔的时长，如 `1:02:03`、`45:30`。
final RegExp _durationColonPattern = RegExp(r'^(\d{1,3}):([0-5]?\d)(?::([0-5]?\d))?$');

/// 解析导出文件中的时长文本。
///
/// 支持 `1:02:03`（时:分:秒）、`45:30`（分:秒）、`1小时30分`、`90分钟`、`45秒`，
/// 以及无单位纯数字（按 [hint] 解释）。
///
/// @param raw 单元格原值。
/// @param hint 纯数字时段的解释方式，默认按分钟。
/// @returns 解析出的时长；无法识别或为负时返回 null。
Duration? parseDurationCell(
  Object? raw, {
  DurationUnitHint hint = DurationUnitHint.minutes,
}) {
  if (raw == null) return null;
  final text = toHalfWidth(raw is String ? raw : raw.toString()).trim();
  if (text.isEmpty) return null;

  final colon = _durationColonPattern.firstMatch(text);
  if (colon != null) {
    final first = int.parse(colon.group(1)!);
    final second = int.parse(colon.group(2)!);
    final third = int.tryParse(colon.group(3) ?? '');
    return third == null
        ? Duration(minutes: first, seconds: second)
        : Duration(hours: first, minutes: second, seconds: third);
  }

  final tokens = _durationTokenPattern.allMatches(text).toList();
  if (tokens.isNotEmpty) {
    var total = Duration.zero;
    for (final token in tokens) {
      final amount = double.tryParse(
              _normalizeDecimalSeparators(token.group(1)!)) ??
          0;
      total += _durationForUnit(amount, token.group(2)!);
    }
    return total;
  }

  final plain = parseDoubleCell(text);
  if (plain == null || plain < 0) return null;
  return hint == DurationUnitHint.seconds
      ? Duration(milliseconds: (plain * 1000).round())
      : Duration(milliseconds: (plain * 60000).round());
}

/// 把「数值 + 单位标记」折算为 [Duration]。
///
/// @param amount 数值。
/// @param unit 单位标记，取自 [_durationTokenPattern] 的第二捕获组。
/// @returns 折算后的时长。
Duration _durationForUnit(double amount, String unit) {
  switch (unit) {
    case '小时':
    case '时':
    case 'h':
      return Duration(milliseconds: (amount * 3600000).round());
    case 'min':
    case '分钟':
    case '分':
      return Duration(milliseconds: (amount * 60000).round());
    default:
      return Duration(milliseconds: (amount * 1000).round());
  }
}

// ---------------------------------------------------------------------------
// 幂等指纹
// ---------------------------------------------------------------------------

/// 生成确定性的幂等标识。
///
/// 取「来源前缀 + 关键字段」的 sha1 摘要，同一份文件导入任意多次都会得到同一批
/// 标识；不使用随机数与当前时间，也不依赖设备时区——关键字段应传文件里的原始
/// 文本（例如时间单元格原文），而不是换算后的 [DateTime]。
///
/// @param sourceKey 来源前缀，用于区分不同导入器，例如 `sibionics`。
/// @param keyParts 参与摘要的关键字段，顺序必须稳定。
/// @returns 形如 `sibionics-<40 位十六进制>` 的标识。
String buildExternalId(String sourceKey, List<Object?> keyParts) {
  final joined = keyParts.map((part) => part?.toString().trim() ?? '').join('\u0001');
  final digest = sha1.convert(utf8.encode('$sourceKey\u0000$joined'));
  return '$sourceKey-$digest';
}

// ---------------------------------------------------------------------------
// 运动分类
// ---------------------------------------------------------------------------

/// 把各应用的品类名归一化为 [WorkoutCategory]。
///
/// 先转半角小写并去空格，再按关键字包含关系匹配。
///
/// @param text 原始品类名，可为 null。
/// @returns 归一化分类；未命中任何关键字时返回 [WorkoutCategory.other]。
WorkoutCategory mapWorkoutCategoryKeyword(String? text) {
  if (text == null) return WorkoutCategory.other;
  final key = toHalfWidth(text).toLowerCase().replaceAll(RegExp(r'\s+'), '');
  if (key.isEmpty) return WorkoutCategory.other;

  for (final entry in _categoryKeywords.entries) {
    for (final keyword in entry.value) {
      if (key.contains(keyword)) return entry.key;
    }
  }
  return WorkoutCategory.other;
}

/// 品类关键字表；匹配按声明顺序短路，越靠前的分类优先级越高。
const Map<WorkoutCategory, List<String>> _categoryKeywords = {
  WorkoutCategory.running: [
    '跑步', '慢跑', '快跑', '跑步机', '越野跑', 'run', 'jog', 'treadmill',
  ],
  WorkoutCategory.cycling: [
    '骑行', '单车', '自行车', '动感单车', 'cycle', 'bike', 'spinning', '骑',
  ],
  WorkoutCategory.walking: [
    '步行', '行走', '健走', '散步', '徒步', '远足', 'walk', 'hiking', 'hike',
    'trekking',
  ],
  WorkoutCategory.swimming: ['游泳', '泳池', '泳', 'swim'],
  WorkoutCategory.hiit: ['hiit', '高强度间歇', '间歇', 'tabata', '燃脂'],
  WorkoutCategory.yoga: ['瑜伽', '拉伸', '普拉提', 'yoga', 'stretch', 'pilates'],
  WorkoutCategory.strength: [
    '力量', '器械', '撸铁', '举铁', '抗阻', '深蹲', '卧推', '硬拉', '核心训练',
    'strength', 'weighttraining', 'fitnessequipment', 'training',
  ],
};

// ---------------------------------------------------------------------------
// 失败构造
// ---------------------------------------------------------------------------

/// 构造「文件结构无法识别」类失败。
///
/// 仅在整份文件没有可用表头或关键列时使用；单行脏数据只需跳过并计数。
///
/// @param message 面向用户的一句话说明。
/// @param code 稳定的机器可读标识。
/// @param cause 触发本次失败的底层异常。
/// @returns 归类为 [FailureKind.parsing] 的失败。
AppFailure importParsingFailure(String message, {String? code, Object? cause}) =>
    AppFailure(
      kind: FailureKind.parsing,
      message: message,
      code: code,
      cause: cause,
    );

/// 执行一次文件解析，把未预期异常收敛为 [FailureKind.parsing] 失败。
///
/// 解析主体通过抛出 [AppFailure] 表达结构不可识别，其余异常一律按解析失败归类，
/// 保证 [HealthFileImporter.parse] 的 `Result` 契约不被破坏。
///
/// @param code 失败码前缀，便于测试与日志聚合。
/// @param body 解析主体，返回归一化样本。
/// @returns 成功样本，或解析失败。
Future<Result<List<HealthSample>>> runImport(
  String code,
  List<HealthSample> Function() body,
) async {
  try {
    return Ok<List<HealthSample>>(body());
  } on AppFailure catch (failure) {
    return Err<List<HealthSample>>(failure);
  } catch (error) {
    return Err<List<HealthSample>>(importParsingFailure(
      '文件解析失败，可能不是该应用导出的文件',
      code: '${code}_failed',
      cause: error,
    ));
  }
}

/// 判断文件名是否带有所列扩展名之一（忽略大小写）。
///
/// @param fileName 文件名或路径。
/// @param extensions 不含点的小写扩展名。
/// @returns 命中任一扩展名时为 true。
bool hasFileExtension(String fileName, Iterable<String> extensions) {
  final lower = fileName.toLowerCase();
  for (final extension in extensions) {
    if (lower.endsWith('.${extension.toLowerCase()}')) return true;
  }
  return false;
}

// ---------------------------------------------------------------------------
// XML DOM
// ---------------------------------------------------------------------------

/// 深度优先收集 [root] 下本地名为 [localName] 的子元素。
///
/// 按 `name.local` 比对，因此带命名空间前缀的 GPX / TCX 同样可以解析。
///
/// @param root 起始元素，本身不参与匹配。
/// @param localName 目标元素的本地名。
/// @returns 按文档顺序排列的匹配元素。
Iterable<XmlElement> descendantElementsNamed(
  XmlElement root,
  String localName,
) sync* {
  for (final child in root.childElements) {
    if (child.localName == localName) yield child;
    yield* descendantElementsNamed(child, localName);
  }
}

/// 读取 [parent] 下第一个同名子元素的文本。
///
/// @param parent 父元素。
/// @param localName 子元素的本地名。
/// @returns 去空白的拼接文本；该子元素不存在时返回空串。
String childElementText(XmlElement parent, String localName) {
  for (final child in parent.childElements) {
    if (child.localName == localName) return elementText(child);
  }
  return '';
}

/// 递归拼接元素下所有文本节点。
///
/// @param node 起始节点。
/// @returns 去空白的拼接文本。
String elementText(XmlNode node) {
  final buffer = StringBuffer();
  for (final child in node.children) {
    if (child is XmlText) {
      buffer.write(child.value);
    } else if (child is XmlElement) {
      buffer.write(elementText(child));
    }
  }
  return buffer.toString().trim();
}

// ---------------------------------------------------------------------------
// 轨迹几何
// ---------------------------------------------------------------------------

/// 地球平均半径（米），用于 Haversine 距离。
const double earthMeanRadiusM = 6371008.8;

/// 海拔抖动门限（米），小于该值的正高差不计入累计爬升。
const double elevationNoiseFloorM = 1.0;

/// 计算两个经纬度点之间的大圆距离。
///
/// @param lat1 起点纬度（度）。
/// @param lon1 起点经度（度）。
/// @param lat2 终点纬度（度）。
/// @param lon2 终点经度（度）。
/// @returns 两点间距离（米）。
double haversineMeters(double lat1, double lon1, double lat2, double lon2) {
  final dLat = _toRadians(lat2 - lat1);
  final dLon = _toRadians(lon2 - lon1);
  final sinLat = math.sin(dLat / 2);
  final sinLon = math.sin(dLon / 2);
  final a = sinLat * sinLat +
      math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) * sinLon * sinLon;
  return 2 * earthMeanRadiusM * math.asin(math.min(1, math.sqrt(a)));
}

/// 把角度转换为弧度。
///
/// @param degrees 角度。
/// @returns 弧度值。
double _toRadians(double degrees) => degrees * math.pi / 180.0;

/// 由海拔序列累计爬升。
///
/// 只累加超过 [elevationNoiseFloorM] 的正向高差，滤掉定位与气压计的轻微抖动；
/// 空值点被跳过，不参与相邻比较。
///
/// @param elevations 按时间排列的海拔（米），null 表示该点缺测。
/// @param noiseFloorM 噪声门限（米）。
/// @returns 累计爬升（米）；有效点不足两个时返回 0。
double elevationGainMeters(
  Iterable<double?> elevations, {
  double noiseFloorM = elevationNoiseFloorM,
}) {
  double? previous;
  var gain = 0.0;
  for (final elevation in elevations) {
    if (elevation == null) continue;
    if (previous != null) {
      final delta = elevation - previous;
      if (delta > noiseFloorM) gain += delta;
    }
    previous = elevation;
  }
  return gain;
}

// ---------------------------------------------------------------------------
// CSV
// ---------------------------------------------------------------------------

/// 无单位换算的 CSV 转换器：单元格保持原文本，交由本文件的解析函数处理。
const CsvToListConverter _csvConverter = CsvToListConverter(
  fieldDelimiter: ',',
  eol: '\n',
  shouldParseNumbers: false,
);

/// 把 CSV 文本切分为行与列。
///
/// 统一换行符后按 RFC 4180 解析，单元格两侧空白被去掉，整行为空的行被丢弃，
/// 分隔符从逗号、制表符、分号中自动挑选。
///
/// @param text 已解码的 CSV 文本。
/// @returns 行与列的二维文本。
List<List<String>> parseCsvRows(String text) {
  final normalized = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final delimiter = detectCsvDelimiter(normalized);
  final raw = _csvConverter.convert(normalized, fieldDelimiter: delimiter);

  final rows = <List<String>>[];
  for (final row in raw) {
    final cells = row.map((cell) => cell?.toString().trim() ?? '').toList();
    if (cells.any((cell) => cell.isNotEmpty)) rows.add(cells);
  }
  return rows;
}

/// 猜测 CSV 分隔符。
///
/// 在逗号、制表符、分号中选取首个非空行里出现次数最多的一种；都不出现时按逗号。
///
/// @param text CSV 文本。
/// @returns 单个分隔符字符。
String detectCsvDelimiter(String text) {
  final firstLine = const LineSplitter()
      .convert(text)
      .firstWhere((line) => line.trim().isNotEmpty, orElse: () => '');

  var best = ',';
  var bestCount = 0;
  for (final candidate in const [',', '\t', ';']) {
    final count = firstLine.split(candidate).length - 1;
    if (count > bestCount) {
      best = candidate;
      bestCount = count;
    }
  }
  return best;
}

// ---------------------------------------------------------------------------
// 表头模型
// ---------------------------------------------------------------------------

/// 一个逻辑字段及其在表头中可能出现的写法。
class ImportColumn {
  /// 声明一个逻辑字段。
  ///
  /// @param field 逻辑字段名，供 [HeaderMatch] 取值使用。
  /// @param aliases 该字段的候选列名，写原始写法即可，比对前会归一化。
  const ImportColumn(this.field, this.aliases);

  /// 逻辑字段名。
  final String field;

  /// 候选列名。
  final List<String> aliases;
}

/// 归一化后的表头行。
class ImportHeader {
  /// 用原始列名构造表头。
  ///
  /// @param columns 表头行的原始单元格文本。
  ImportHeader(List<String> columns)
      : raw = List<String>.unmodifiable(columns),
        _keys = columns.map(normalizeHeaderKey).toList(growable: false);

  /// 原始列名，保留单位括号等原文。
  final List<String> raw;

  /// 归一化后的列名。
  final List<String> _keys;

  /// 列数。
  int get length => raw.length;

  /// 归一化后的列名快照。
  List<String> get keys => List<String>.unmodifiable(_keys);

  /// 读取某一列的原始表头文本。
  ///
  /// @param index 列下标。
  /// @returns 原始文本；越界时返回空串。
  String rawAt(int index) =>
      index >= 0 && index < raw.length ? raw[index] : '';

  /// 读取某一列表头括号中声明的单位。
  ///
  /// @param index 列下标。
  /// @returns 小写去空格的单位文本；表头没有括号时返回空串。
  String unitAt(int index) {
    final match = _unitPattern.firstMatch(toHalfWidth(rawAt(index)));
    return match?.group(1)?.replaceAll(' ', '').toLowerCase() ?? '';
  }

  /// 查找归一化列名与 [alias] 完全相同的列。
  ///
  /// @param alias 候选列名，写原始写法即可。
  /// @returns 第一个命中的列下标；没有则返回 null。
  int? indexOfKey(String alias) {
    final key = normalizeHeaderKey(alias);
    if (key.isEmpty) return null;
    for (var i = 0; i < _keys.length; i++) {
      if (_keys[i] == key) return i;
    }
    return null;
  }

  /// 查找归一化列名包含 [alias] 的列。
  ///
  /// 用于 `血糖值(mmol/L)` 命中别名 `血糖` 这类带前后缀的表头。
  ///
  /// @param alias 候选列名片段。
  /// @returns 第一个命中的列下标；没有则返回 null。
  int? indexOfKeyContaining(String alias) {
    final key = normalizeHeaderKey(alias);
    if (key.length < 2) return null;
    for (var i = 0; i < _keys.length; i++) {
      if (_keys[i].contains(key)) return i;
    }
    return null;
  }
}

/// 表头与列定义匹配后的结果。
class HeaderMatch {
  /// 用 [columns] 逐字段匹配 [header]。
  ///
  /// 先做归一化后完全相等的匹配，未命中的字段再退化为「列名包含别名」，
  /// 因此更精确的别名总是优先。
  ///
  /// @param header 归一化表头。
  /// @param columns 列定义。
  /// @returns 字段名到列下标的映射。
  factory HeaderMatch.resolve(ImportHeader header, List<ImportColumn> columns) {
    final indexes = <String, int>{};
    for (final column in columns) {
      for (final alias in column.aliases) {
        final index = header.indexOfKey(alias);
        if (index != null) {
          indexes[column.field] = index;
          break;
        }
      }
    }
    for (final column in columns) {
      if (indexes.containsKey(column.field)) continue;
      for (final alias in column.aliases) {
        final index = header.indexOfKeyContaining(alias);
        if (index != null) {
          indexes[column.field] = index;
          break;
        }
      }
    }
    return HeaderMatch._(header, indexes);
  }

  HeaderMatch._(this.header, this._indexes);

  /// 参与匹配的表头。
  final ImportHeader header;

  /// 字段名到列下标的映射。
  final Map<String, int> _indexes;

  /// 命中的逻辑字段数。
  int get matchedCount => _indexes.length;

  /// 读取某字段对应的列下标。
  ///
  /// @param field 逻辑字段名。
  /// @returns 列下标；该字段未命中时为 null。
  int? operator [](String field) => _indexes[field];

  /// 判断 [fields] 中是否至少命中一个。
  ///
  /// @param fields 逻辑字段名集合。
  /// @returns 至少命中一个时为 true。
  bool matchedAnyOf(Iterable<String> fields) =>
      fields.any(_indexes.containsKey);

  /// 判断 [fields] 是否全部命中。
  ///
  /// @param fields 逻辑字段名集合。
  /// @returns 全部命中时为 true。
  bool matchedAllOf(Iterable<String> fields) =>
      fields.every(_indexes.containsKey);

  /// 读取数据行中某字段的原始文本。
  ///
  /// @param row 数据行。
  /// @param field 逻辑字段名。
  /// @returns 去空白的单元格文本；字段未命中或该行缺列时返回空串。
  String cell(List<String> row, String field) {
    final index = _indexes[field];
    if (index == null || index < 0 || index >= row.length) return '';
    return row[index].trim();
  }
}

/// 在 CSV 行里定位到的表头及其匹配结果。
class CsvTable {
  CsvTable._(this.headerRowIndex, this.match, this.rows);

  /// 在前 [maxScanRows] 行内寻找表头行。
  ///
  /// 选出命中列数最多且不少于 [minMatches] 的一行；并列时取最靠前的一行，
  /// 这样导出文件顶部的「导出时间」等前言行不会被误判为表头。
  ///
  /// @param rows 已切分的 CSV 行。
  /// @param columns 列定义。
  /// @param maxScanRows 最多向下扫描的行数。
  /// @param minMatches 认定为表头所需的最少命中字段数。
  /// @returns 定位结果；没有合格表头行时返回 null。
  static CsvTable? tryLocate(
    List<List<String>> rows,
    List<ImportColumn> columns, {
    int maxScanRows = 20,
    int minMatches = 2,
  }) {
    CsvTable? best;
    final limit = rows.length < maxScanRows ? rows.length : maxScanRows;
    for (var i = 0; i < limit; i++) {
      final match = HeaderMatch.resolve(ImportHeader(rows[i]), columns);
      if (match.matchedCount < minMatches) continue;
      if (best == null || match.matchedCount > best.match.matchedCount) {
        best = CsvTable._(i, match, rows);
      }
    }
    return best;
  }

  /// 表头所在行号。
  final int headerRowIndex;

  /// 表头匹配结果。
  final HeaderMatch match;

  /// 完整行集合。
  final List<List<String>> rows;

  /// 匹配到的表头。
  ImportHeader get header => match.header;

  /// 表头之后的数据行。
  List<List<String>> get dataRows => rows.sublist(headerRowIndex + 1);
}

// ---------------------------------------------------------------------------
// 解析统计与基类
// ---------------------------------------------------------------------------

/// 一次文件解析的统计结果。
class ImportParseStats {
  /// 构造统计结果。
  ///
  /// @param rowsRead 读入的数据行数（不含表头）。
  /// @param samplesProduced 成功产出的样本数。
  /// @param rowsSkipped 被跳过的行数。
  /// @param skipReasons 跳过原因到次数的映射。
  const ImportParseStats({
    this.rowsRead = 0,
    this.samplesProduced = 0,
    this.rowsSkipped = 0,
    this.skipReasons = const <String, int>{},
  });

  /// 读入的数据行数。
  final int rowsRead;

  /// 成功产出的样本数。
  final int samplesProduced;

  /// 被跳过的行数。
  final int rowsSkipped;

  /// 跳过原因计数，便于界面给出可解释的提示。
  final Map<String, int> skipReasons;

  @override
  String toString() => 'ImportParseStats(read=$rowsRead, produced=$samplesProduced, '
      'skipped=$rowsSkipped, reasons=$skipReasons)';
}

/// 逐行累积跳过原因的小工具。
class ImportStatsBuilder {
  /// 开始一次新的统计。
  ImportStatsBuilder();

  int _rowsRead = 0;
  int _samplesProduced = 0;
  final Map<String, int> _skipReasons = <String, int>{};

  /// 记入一行已读入的数据行。
  void countRead() => _rowsRead++;

  /// 记入一行成功产出的样本。
  void countProduced() => _samplesProduced++;

  /// 记入一行被跳过的数据，并累加原因计数。
  ///
  /// @param reason 跳过原因，例如「缺少时间」。
  void countSkipped(String reason) {
    _skipReasons[reason] = (_skipReasons[reason] ?? 0) + 1;
  }

  /// 汇总为不可变统计。
  ///
  /// @returns 本次解析的统计结果。
  ImportParseStats build() => ImportParseStats(
        rowsRead: _rowsRead,
        samplesProduced: _samplesProduced,
        rowsSkipped: _skipReasons.values.fold(0, (sum, count) => sum + count),
        skipReasons: Map<String, int>.unmodifiable(_skipReasons),
      );
}

/// 文件导入器的公共基类。
///
/// 统一保存最近一次 [parse] 的统计口径，让界面可以提示「导入 N 条、跳过 M 行」
/// 而不必自己数行。
abstract class HealthFileImporterBase implements HealthFileImporter {
  ImportParseStats _lastStats = const ImportParseStats();

  /// 最近一次 [parse] 的统计结果。
  ImportParseStats get lastStats => _lastStats;

  /// 记录本次 [parse] 的统计结果。
  ///
  /// @param stats 解析统计。
  void recordStats(ImportParseStats stats) {
    _lastStats = stats;
  }
}
