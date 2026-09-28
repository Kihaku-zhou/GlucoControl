/// 外部健康数据源的统一标识与归一化样本信封。
///
/// 每个连接器（[HealthSourceId]）把自己 API 或导出文件的字段翻译成 [HealthSample]，
/// 上层只面对这一种结构。样本的领域含义由 [HealthSampleKind] 决定，载荷放在
/// [HealthSample.payload] 中，由 `health_records.dart` 里的类型化模型解释。
library;

/// 一个外部健康数据连接器。
///
/// 它描述的是「从哪里取数」，而不是「数据最初由谁产生」。例如经 Health Connect
/// 读到的 Keep 训练，其 `originApp` 会标注 Keep，但 [HealthSourceId] 仍是
/// [HealthSourceId.healthConnect]。
enum HealthSourceId {
  /// Android 系统级健康数据中枢，可读写多款应用写入的记录。
  healthConnect(
    'health_connect',
    'Health Connect',
    'Android 系统健康数据中枢，Keep、训记、iGPSPORT 等写入的数据在此汇总',
  ),

  /// 华为运动健康（Health Kit 开放数据），需在华为开发者联盟申请应用。
  huaweiHealth(
    'huawei_health',
    '华为运动健康',
    '华为 Health Kit 开放数据，覆盖步数、心率、睡眠、运动与血糖',
  ),

  /// 硅基仿生的消费级持续葡萄糖监测产品。
  sibionics(
    'sibionics',
    '硅基轻享',
    '硅基仿生 CGM 动态血糖，无公开 API，经导出文件接入',
  ),

  /// 骑行码表与骑行台。
  igpsport(
    'igpsport',
    'iGPSPORT',
    '骑行码表与骑行台，经 FIT / GPX 活动文件接入',
  ),

  /// 综合健身应用。
  keep(
    'keep',
    'Keep',
    '健身课程与运动记录，经 Health Connect 或导出文件接入',
  ),

  /// 力量训练记录应用。
  xunji(
    'xunji',
    '训记',
    '力量训练组次与容量，官方 Open API v2 可直接读取',
  ),

  /// 自建或第三方的 Nightscout 实例。
  ///
  /// 硅基轻享等 CGM 没有公开 API，社区通行的做法是用 Juggluco 直读传感器后
  /// 推送到 Nightscout，再由本连接器以只读 token 拉取。
  nightscout(
    'nightscout',
    'Nightscout',
    '自建 CGM 数据服务，接收 Juggluco 等采集端，本应用只读拉取',
  ),

  /// 用户手工选择的 CSV / GPX / TCX / FIT 文件。
  fileImport(
    'file_import',
    '文件导入',
    '手工选择导出文件，作为所有数据源的通用兜底通路',
  ),

  /// 应用内直接录入。
  manual(
    'manual',
    '手动录入',
    '在 GlucoControl 内直接记录，不依赖任何外部应用',
  );

  const HealthSourceId(this.code, this.displayName, this.description);

  /// 持久化与 AI 工具参数中使用的稳定编码。
  final String code;

  /// 界面展示名。
  final String displayName;

  /// 一句话说明该数据源覆盖什么。
  final String description;

  /// 从持久化编码还原；未知编码返回 null，由调用方决定如何降级。
  static HealthSourceId? tryFromCode(String? code) {
    for (final source in values) {
      if (source.code == code) return source;
    }
    return null;
  }

  /// 该数据源是否通过用户手工选择文件的方式取数。
  ///
  /// 文件型数据源没有后台自动同步，界面需要引导用户主动导入。
  bool get isFileBased =>
      this == HealthSourceId.fileImport || this == HealthSourceId.sibionics;

  /// 该数据源是否需要 OAuth 之类的在线授权。
  bool get requiresOnlineAuthorization =>
      this == HealthSourceId.healthConnect ||
      this == HealthSourceId.huaweiHealth;
}

/// 归一化样本的领域类别。
enum HealthSampleKind {
  /// 血糖读数（含 CGM 连续采样）。
  glucose('glucose', '血糖'),

  /// 一次训练/运动记录。
  workout('workout', '运动'),

  /// 一次身体成分测量。
  bodyComposition('body_composition', '体测'),

  /// 一段睡眠。
  sleep('sleep', '睡眠'),

  /// 某一天的活动汇总（步数、静息心率等）。
  dailyActivity('daily_activity', '日常活动');

  const HealthSampleKind(this.code, this.label);

  /// 持久化与 AI 工具参数中使用的稳定编码。
  final String code;

  /// 界面展示名。
  final String label;

  /// 从持久化编码还原；未知编码返回 null。
  static HealthSampleKind? tryFromCode(String? code) {
    for (final kind in values) {
      if (kind.code == code) return kind;
    }
    return null;
  }
}

/// 一个归一化后的外部健康样本。
///
/// [source] 与 [externalId] 共同构成幂等键：同一个源重复给出同一条记录时，
/// 入库阶段据此覆盖而不是追加。[payload] 承载领域字段，由类型化模型解释。
class HealthSample {
  /// 构造样本。
  const HealthSample({
    required this.source,
    required this.externalId,
    required this.kind,
    required this.startAt,
    this.endAt,
    this.title,
    this.originApp,
    this.payload = const <String, Object?>{},
  });

  /// 数据来自哪个连接器。
  final HealthSourceId source;

  /// 该连接器内部的稳定标识。用于幂等去重，必须是确定性的。
  final String externalId;

  /// 领域类别。
  final HealthSampleKind kind;

  /// 样本开始时间。
  final DateTime startAt;

  /// 样本结束时间；瞬时样本（血糖、体测）为 null。
  final DateTime? endAt;

  /// 一句话标题，用于界面列表与 AI 上下文。
  final String? title;

  /// 数据最初由哪个应用产生（仅经聚合源取数时有值，例如 Health Connect 中的 Keep）。
  final String? originApp;

  /// 领域字段，键为各类型化模型中定义的字段名。
  final Map<String, Object?> payload;

  /// 读取一个数值型载荷字段；缺失或类型不符时返回 null。
  double? doubleField(String key) {
    final raw = payload[key];
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw);
    return null;
  }

  /// 读取一个整型载荷字段；缺失或类型不符时返回 null。
  int? intField(String key) {
    final raw = payload[key];
    if (raw is int) return raw;
    if (raw is num) return raw.round();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  /// 读取一个字符串型载荷字段；缺失时返回 null。
  String? stringField(String key) {
    final raw = payload[key];
    return raw is String ? raw : null;
  }

  /// 读取一个布尔型载荷字段；缺失或类型不符时返回 null。
  bool? boolField(String key) {
    final raw = payload[key];
    if (raw is bool) return raw;
    if (raw is String) return raw.toLowerCase() == 'true';
    return null;
  }

  /// 该样本覆盖的时长；瞬时样本返回 null。
  Duration? get duration => endAt?.difference(startAt);

  @override
  String toString() =>
      'HealthSample(${source.code}/${kind.code} '
      '@${startAt.toIso8601String()} id=$externalId)';
}
