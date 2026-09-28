/// [GlucoseUnit]/[convertGlucose]/[toMmolPerL]/[mmolPerLTo]/[GlucoseContext] 的单元测试。
///
/// 覆盖 mmol/L ↔ mg/dL 的换算系数与往返精度、同单位不做换算、以及从持久化
/// 标签/编码还原枚举时的未知值降级。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:glucocontrol/core/glucose_units.dart';

void main() {
  group('GlucoseUnit', () {
    test('单位标签与枚举一一对应', () {
      expect(GlucoseUnit.mmolPerL.label, 'mmol/L');
      expect(GlucoseUnit.mgPerDl.label, 'mg/dL');
      expect(GlucoseUnit.values.length, 2);
    });

    test('fromLabel 能还原两个已知标签', () {
      expect(GlucoseUnit.fromLabel('mmol/L'), GlucoseUnit.mmolPerL);
      expect(GlucoseUnit.fromLabel('mg/dL'), GlucoseUnit.mgPerDl);
    });

    test('fromLabel 对未知标签与 null 降级为 mmol/L', () {
      expect(GlucoseUnit.fromLabel('mg/dl'), GlucoseUnit.mmolPerL);
      expect(GlucoseUnit.fromLabel('MMOL/L'), GlucoseUnit.mmolPerL);
      expect(GlucoseUnit.fromLabel(''), GlucoseUnit.mmolPerL);
      expect(GlucoseUnit.fromLabel(null), GlucoseUnit.mmolPerL);
    });
  });

  group('convertGlucose', () {
    test('mmol/L 转 mg/dL 使用 18.0182 系数', () {
      expect(
        convertGlucose(5.5, GlucoseUnit.mmolPerL, GlucoseUnit.mgPerDl),
        closeTo(5.5 * 18.0182, 1e-9),
      );
      expect(kGlucoseMgPerDlPerMmolPerL, 18.0182);
    });

    test('mg/dL 转 mmol/L 使用同一系数的倒数', () {
      expect(
        convertGlucose(100, GlucoseUnit.mgPerDl, GlucoseUnit.mmolPerL),
        closeTo(100 / 18.0182, 1e-12),
      );
      // 100 mg/dL 约为 5.55 mmol/L。
      expect(
        convertGlucose(100, GlucoseUnit.mgPerDl, GlucoseUnit.mmolPerL),
        closeTo(5.5499, 1e-4),
      );
    });

    test('同单位换算原样返回，不做浮点往返', () {
      // 若实现走了乘法再除法，0.1+0.2 的二进制尾数会被抹掉。
      const noisy = 0.1 + 0.2;
      expect(noisy, isNot(0.3));
      expect(convertGlucose(noisy, GlucoseUnit.mmolPerL, GlucoseUnit.mmolPerL), noisy);
      expect(convertGlucose(noisy, GlucoseUnit.mgPerDl, GlucoseUnit.mgPerDl), noisy);
      expect(convertGlucose(5.5, GlucoseUnit.mmolPerL, GlucoseUnit.mmolPerL), 5.5);
    });

    test('往返换算在浮点容差内还原原值', () {
      for (final value in <double>[3.9, 5.5, 7.0, 10.0, 22.3]) {
        final roundTrip = convertGlucose(
          convertGlucose(value, GlucoseUnit.mmolPerL, GlucoseUnit.mgPerDl),
          GlucoseUnit.mgPerDl,
          GlucoseUnit.mmolPerL,
        );
        expect(roundTrip, closeTo(value, 1e-9));
      }
    });

    test('零与负值也按同一规则线性换算', () {
      expect(convertGlucose(0, GlucoseUnit.mmolPerL, GlucoseUnit.mgPerDl), 0);
      expect(
        convertGlucose(-5.55, GlucoseUnit.mmolPerL, GlucoseUnit.mgPerDl),
        closeTo(-5.55 * 18.0182, 1e-9),
      );
      expect(
        convertGlucose(-100, GlucoseUnit.mgPerDl, GlucoseUnit.mmolPerL),
        closeTo(-100 / 18.0182, 1e-12),
      );
    });
  });

  group('toMmolPerL 与 mmolPerLTo', () {
    test('toMmolPerL 把 mg/dL 归一化为 mmol/L', () {
      expect(toMmolPerL(180, GlucoseUnit.mgPerDl), closeTo(9.9899, 1e-4));
    });

    test('toMmolPerL 对 mmol/L 输入原样返回', () {
      expect(toMmolPerL(6.1, GlucoseUnit.mmolPerL), 6.1);
    });

    test('mmolPerLTo 按目标单位换算', () {
      expect(mmolPerLTo(6.1, GlucoseUnit.mmolPerL), 6.1);
      expect(mmolPerLTo(6.1, GlucoseUnit.mgPerDl), closeTo(109.91, 1e-2));
    });

    test('两者互为逆运算', () {
      final mgPerDl = mmolPerLTo(7.2, GlucoseUnit.mgPerDl);
      expect(toMmolPerL(mgPerDl, GlucoseUnit.mgPerDl), closeTo(7.2, 1e-9));
    });
  });

  group('GlucoseContext', () {
    test('每个枚举都带稳定编码与展示名', () {
      expect(GlucoseContext.fasting.code, 'fasting');
      expect(GlucoseContext.fasting.label, '空腹');
      expect(GlucoseContext.postMeal.code, 'post_meal');
      expect(GlucoseContext.postMeal.label, '餐后');
      expect(GlucoseContext.random.code, 'random');
      expect(GlucoseContext.continuous.code, 'continuous');
      expect(GlucoseContext.continuous.label, '动态监测');
      expect(GlucoseContext.values.length, 4);
    });

    test('fromCode 能还原全部已知编码', () {
      for (final context in GlucoseContext.values) {
        expect(GlucoseContext.fromCode(context.code), context);
      }
    });

    test('fromCode 对未知编码与 null 降级为随机', () {
      expect(GlucoseContext.fromCode('postmeal'), GlucoseContext.random);
      expect(GlucoseContext.fromCode(''), GlucoseContext.random);
      expect(GlucoseContext.fromCode(null), GlucoseContext.random);
      // 大小写必须完全匹配，不做归一化。
      expect(GlucoseContext.fromCode('Fasting'), GlucoseContext.random);
    });
  });
}
