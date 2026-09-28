/// 血糖单位换算。
///
/// 换算系数取自血糖仪厂商与临床实验室通用的 18.0182（葡萄糖分子量 180.156 g/mol）。
/// 应用内统一以 mmol/L 作为存储与计算单位，[GlucoseUnit.mgPerDl] 仅在展示与
/// 导入外部数据时出现。
library;

/// 支持展示的血糖单位。
enum GlucoseUnit {
  /// 中国、欧洲常用的毫摩尔每升。
  mmolPerL('mmol/L'),

  /// 美国常用的毫克每分升。
  mgPerDl('mg/dL');

  const GlucoseUnit(this.label);

  /// 单位符号，可直接用于界面与导出文件。
  final String label;

  /// 从持久化的单位符号还原枚举；未知符号回退到 [GlucoseUnit.mmolPerL]。
  static GlucoseUnit fromLabel(String? label) => switch (label) {
        'mg/dL' => GlucoseUnit.mgPerDl,
        _ => GlucoseUnit.mmolPerL,
      };
}

/// mmol/L 与 mg/dL 之间的换算系数：`mg/dL = mmol/L * 18.0182`。
const double kGlucoseMgPerDlPerMmolPerL = 18.0182;

/// 把 [value] 从 [from] 单位换算为 [to] 单位。
///
/// 单位相同时原样返回，不做浮点往返，避免精度损失。
double convertGlucose(double value, GlucoseUnit from, GlucoseUnit to) {
  if (from == to) return value;
  return from == GlucoseUnit.mmolPerL
      ? value * kGlucoseMgPerDlPerMmolPerL
      : value / kGlucoseMgPerDlPerMmolPerL;
}

/// 把 mmol/L 数值换算为 [unit]。
double mmolPerLTo(double mmolPerL, GlucoseUnit unit) =>
    convertGlucose(mmolPerL, GlucoseUnit.mmolPerL, unit);

/// 把 [unit] 下的数值换算为 mmol/L。
double toMmolPerL(double value, GlucoseUnit unit) =>
    convertGlucose(value, unit, GlucoseUnit.mmolPerL);

/// 血糖读数按采血时机的分类。
///
/// 用于把不同来源（硅基轻享 CGM、华为运动健康、手工录入）的读数归入同一套统计口径。
enum GlucoseContext {
  /// 空腹。
  fasting('fasting', '空腹'),

  /// 餐后。
  postMeal('post_meal', '餐后'),

  /// 随机/其他时点。
  random('random', '随机'),

  /// 由持续葡萄糖监测设备自动采样，没有明确的采血时机。
  continuous('continuous', '动态监测');

  const GlucoseContext(this.code, this.label);

  /// 持久化用的稳定编码。
  final String code;

  /// 界面展示名。
  final String label;

  /// 从持久化编码还原；未知编码回退到 [GlucoseContext.random]。
  static GlucoseContext fromCode(String? code) =>
      values.firstWhere((c) => c.code == code, orElse: () => GlucoseContext.random);
}
