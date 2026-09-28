/// `health_source_config.dart` 的单元测试。
///
/// 覆盖 [HealthSourceConfig] 的 JSON 往返与字段可选性、`isEmpty` 的判空语义，
/// 以及 [HealthConfigStore] 基于 [SharedPreferences] 的读写与非法数据降级。
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:glucocontrol/data/health/health_source_config.dart';
import 'package:glucocontrol/domain/health/health_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HealthSourceConfig 的 JSON 往返', () {
    test('全部字段齐全时往返守恒', () {
      const config = HealthSourceConfig(
        baseUrl: 'https://nightscout.example.com',
        apiKey: 'key-1',
        accessToken: 'secret-1',
        clientId: 'client-1',
        clientSecret: 'client-secret-1',
        extra: <String, String>{'token': 'read-only', 'region': 'cn'},
      );

      final json = config.toJson();
      final restored = HealthSourceConfig.fromJson(json);

      expect(restored.baseUrl, config.baseUrl);
      expect(restored.apiKey, config.apiKey);
      expect(restored.accessToken, config.accessToken);
      expect(restored.clientId, config.clientId);
      expect(restored.clientSecret, config.clientSecret);
      expect(restored.extra, config.extra);
    });

    test('toJson 省略未填写的字段而不是写入 null', () {
      const config = HealthSourceConfig(baseUrl: 'https://x.example.com');

      final json = config.toJson();

      expect(json.keys.toSet(), <String>{'baseUrl'});
      expect(json.containsKey('apiKey'), isFalse);
      expect(json.containsKey('extra'), isFalse);
      expect(json['baseUrl'], 'https://x.example.com');
    });

    test('空配置序列化为空映射，反序列化得到空配置', () {
      const config = HealthSourceConfig();

      expect(config.toJson(), isEmpty);
      expect(HealthSourceConfig.fromJson(const <String, Object?>{}).isEmpty, isTrue);
    });

    test('fromJson 缺失字段时取 null 与空映射默认值', () {
      final config = HealthSourceConfig.fromJson(const <String, Object?>{
        'apiKey': 'only-key',
      });

      expect(config.apiKey, 'only-key');
      expect(config.baseUrl, isNull);
      expect(config.accessToken, isNull);
      expect(config.clientId, isNull);
      expect(config.clientSecret, isNull);
      expect(config.extra, isEmpty);
    });

    test('extra 的非字符串值被统一转成字符串', () {
      final config = HealthSourceConfig.fromJson(const <String, Object?>{
        'extra': <String, Object?>{'count': 20, 'enabled': true},
      });

      expect(config.extra, <String, String>{'count': '20', 'enabled': 'true'});
    });

    test('extra 为空时 toJson 不写入该键', () {
      expect(
        const HealthSourceConfig(apiKey: 'k', extra: <String, String>{}).toJson(),
        <String, Object?>{'apiKey': 'k'},
      );
    });

    test('JSON 编码后再解码仍守恒', () {
      const config = HealthSourceConfig(
        baseUrl: 'https://trains.xunjiapp.cn',
        apiKey: 'abc',
        extra: <String, String>{'page': '1'},
      );

      final decoded =
          jsonDecode(jsonEncode(config.toJson())) as Map<String, Object?>;

      expect(HealthSourceConfig.fromJson(decoded).apiKey, 'abc');
      expect(HealthSourceConfig.fromJson(decoded).extra['page'], '1');
    });
  });

  group('HealthSourceConfig.isEmpty 的判空语义', () {
    test('所有字段都为 null 时为空配置', () {
      expect(const HealthSourceConfig().isEmpty, isTrue);
    });

    test('任意一个必填字段有值就不算空', () {
      expect(const HealthSourceConfig(baseUrl: 'https://x').isEmpty, isFalse);
      expect(const HealthSourceConfig(apiKey: 'k').isEmpty, isFalse);
      expect(const HealthSourceConfig(accessToken: 't').isEmpty, isFalse);
      expect(const HealthSourceConfig(clientId: 'c').isEmpty, isFalse);
      expect(const HealthSourceConfig(clientSecret: 's').isEmpty, isFalse);
      expect(
        const HealthSourceConfig(extra: <String, String>{'token': 't'}).isEmpty,
        isFalse,
      );
    });

    test('空字符串等价于未填写', () {
      expect(
        const HealthSourceConfig(baseUrl: '', apiKey: '', accessToken: '')
            .isEmpty,
        isTrue,
      );
    });

    test('只含空白的字段视为未填写', () {
      expect(const HealthSourceConfig(baseUrl: '   ').isEmpty, isTrue);
      expect(const HealthSourceConfig(apiKey: '\t').isEmpty, isTrue);
      expect(const HealthSourceConfig(apiKey: '\n').isEmpty, isTrue);
      expect(
        const HealthSourceConfig(clientSecret: '  ').isEmpty,
        isTrue,
      );
    });

    test('只要有一个字段含非空白字符就不算空', () {
      expect(const HealthSourceConfig(baseUrl: '   ').isEmpty, isTrue);
      expect(
        const HealthSourceConfig(baseUrl: '   ', apiKey: 'k').isEmpty,
        isFalse,
      );
      expect(
        const HealthSourceConfig(
          extra: <String, String>{'token': 't'},
        ).isEmpty,
        isFalse,
      );
    });
  });

  group('HealthSourceConfig.copyWith', () {
    test('只替换传入的字段', () {
      const original = HealthSourceConfig(
        baseUrl: 'https://a.example.com',
        apiKey: 'k1',
        extra: <String, String>{'token': 't1'},
      );

      final updated = original.copyWith(apiKey: 'k2');

      expect(updated.apiKey, 'k2');
      expect(updated.baseUrl, 'https://a.example.com');
      expect(updated.extra, <String, String>{'token': 't1'});
    });

    test('传入 null 时保留原值（无法显式清空单个字段）', () {
      const original = HealthSourceConfig(baseUrl: 'https://a', apiKey: 'k');

      final updated = original.copyWith();

      expect(updated.baseUrl, 'https://a');
      expect(updated.apiKey, 'k');
    });

    test('可以整体替换 extra', () {
      const original = HealthSourceConfig(
        apiKey: 'k',
        extra: <String, String>{'a': '1'},
      );

      final updated = original.copyWith(extra: <String, String>{'b': '2'});

      expect(updated.extra, <String, String>{'b': '2'});
    });
  });

  group('HealthConfigStore', () {
    late SharedPreferences preferences;
    late HealthConfigStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      preferences = await SharedPreferences.getInstance();
      store = HealthConfigStore(preferences);
    });

    test('未配置时读取到空配置', () {
      expect(store.read(HealthSourceId.nightscout).isEmpty, isTrue);
    });

    test('写入后可以原样读回', () async {
      const config = HealthSourceConfig(
        baseUrl: 'https://ns.example.com',
        accessToken: 'secret',
        extra: <String, String>{'token': 'readonly'},
      );

      await store.write(HealthSourceId.nightscout, config);
      final restored = store.read(HealthSourceId.nightscout);

      expect(restored.baseUrl, 'https://ns.example.com');
      expect(restored.accessToken, 'secret');
      expect(restored.extra['token'], 'readonly');
    });

    test('不同数据源的配置互不干扰', () async {
      await store.write(
        HealthSourceId.nightscout,
        const HealthSourceConfig(baseUrl: 'https://ns'),
      );
      await store.write(
        HealthSourceId.xunji,
        const HealthSourceConfig(apiKey: 'xj'),
      );

      expect(store.read(HealthSourceId.nightscout).baseUrl, 'https://ns');
      expect(store.read(HealthSourceId.nightscout).apiKey, isNull);
      expect(store.read(HealthSourceId.xunji).apiKey, 'xj');
      expect(store.read(HealthSourceId.xunji).baseUrl, isNull);
      expect(store.read(HealthSourceId.keep).isEmpty, isTrue);
    });

    test('存储键带固定前缀加数据源编码', () async {
      await store.write(
        HealthSourceId.healthConnect,
        const HealthSourceConfig(apiKey: 'hc-key'),
      );

      expect(
        preferences.getString('health_source_config_health_connect'),
        contains('hc-key'),
      );
      expect(
        preferences.containsKey('health_source_config_${HealthSourceId.huaweiHealth.code}'),
        isFalse,
      );
    });

    test('clear 之后回到未配置状态', () async {
      await store.write(
        HealthSourceId.xunji,
        const HealthSourceConfig(apiKey: 'xj'),
      );
      expect(store.read(HealthSourceId.xunji).isEmpty, isFalse);

      await store.clear(HealthSourceId.xunji);

      expect(store.read(HealthSourceId.xunji).isEmpty, isTrue);
    });

    test('写入空配置会覆盖已有配置', () async {
      await store.write(
        HealthSourceId.xunji,
        const HealthSourceConfig(apiKey: 'xj'),
      );

      await store.write(HealthSourceId.xunji, const HealthSourceConfig());

      expect(store.read(HealthSourceId.xunji).isEmpty, isTrue);
    });

    test('存储中是非法 JSON 时降级为空配置', () async {
      await preferences.setString(
        'health_source_config_nightscout',
        '{不是 JSON',
      );

      expect(store.read(HealthSourceId.nightscout).isEmpty, isTrue);
    });

    test('存储中是非对象 JSON 时降级为空配置', () async {
      await preferences.setString('health_source_config_nightscout', '[1,2,3]');
      expect(store.read(HealthSourceId.nightscout).isEmpty, isTrue);

      await preferences.setString('health_source_config_nightscout', '"text"');
      expect(store.read(HealthSourceId.nightscout).isEmpty, isTrue);
    });

    test('存储中是空串时按未配置处理', () async {
      await preferences.setString('health_source_config_nightscout', '');

      expect(store.read(HealthSourceId.nightscout).isEmpty, isTrue);
    });
  });
}
