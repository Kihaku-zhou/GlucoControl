/// `NightscoutDataSource` 静态解析逻辑与 HTTP 取数路径的单元测试。
///
/// 覆盖 `entriesOf` 的响应体容错、`parseEntry` 的 mg/dL → mmol/L 换算、
/// `direction` → [GlucoseTrend] 映射、幂等键兜底，以及经假 [HttpClientAdapter]
/// 验证的请求 URL、查询参数、api-secret 请求头与错误码分类。
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucocontrol/core/glucose_units.dart';
import 'package:glucocontrol/core/result.dart';
import 'package:glucocontrol/data/health/health_source_config.dart';
import 'package:glucocontrol/data/health/sources/nightscout_data_source.dart';
import 'package:glucocontrol/domain/health/health_data_source.dart';
import 'package:glucocontrol/domain/health/health_records.dart';
import 'package:glucocontrol/domain/health/health_source.dart';

/// 记录请求并返回预设响应的假 HTTP 适配器。
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.respond);

  final ResponseBody Function(RequestOptions options) respond;

  RequestOptions? lastOptions;
  int callCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    callCount++;
    lastOptions = options;
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(Object? body, int status) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );

void main() {
  group('entriesOf', () {
    test('顶层数组按字符串键归一化', () {
      final entries = NightscoutDataSource.entriesOf(<Object?>[
        <String, Object?>{'sgv': 100, '_id': 'a'},
        <Object?, Object?>{'sgv': 110, '_id': 'b'},
      ]);

      expect(entries.length, 2);
      expect(entries.first['sgv'], 100);
      expect(entries.last['_id'], 'b');
    });

    test('过滤数组中的非对象元素', () {
      final entries = NightscoutDataSource.entriesOf(<Object?>[
        <String, Object?>{'sgv': 100},
        'text',
        42,
        null,
      ]);

      expect(entries.length, 1);
      expect(entries.single['sgv'], 100);
    });

    test('JSON 字符串响应被解码后再取条目', () {
      final entries = NightscoutDataSource.entriesOf('[{"sgv":120,"_id":"c"}]');

      expect(entries.single['_id'], 'c');
      expect(entries.single['sgv'], 120);
    });

    test('非数组响应返回空列表', () {
      expect(NightscoutDataSource.entriesOf(null), isEmpty);
      expect(NightscoutDataSource.entriesOf(<String, Object?>{'status': 401}),
          isEmpty);
      expect(NightscoutDataSource.entriesOf(42), isEmpty);
      expect(NightscoutDataSource.entriesOf(<Object?>[]), isEmpty);
    });

    test('字符串不是合法 JSON 时抛出 FormatException', () {
      // 上游返回 HTML 错误页时会走到这里，调用方需要自行兜底。
      expect(() => NightscoutDataSource.entriesOf('<html>502</html>'),
          throwsFormatException);
    });
  });

  group('parseEntry 的字段映射', () {
    final recordedAt = DateTime.fromMillisecondsSinceEpoch(1700000000000);

    test('sgv 从 mg/dL 换算为 mmol/L 并保留原始值', () {
      final sample = NightscoutDataSource.parseEntry(<String, Object?>{
        'sgv': 100,
        '_id': 'abc',
        'date': 1700000000000,
        'device': 'juggluco',
      })!;

      expect(sample.source, HealthSourceId.nightscout);
      expect(sample.kind, HealthSampleKind.glucose);
      expect(sample.externalId, 'nightscout:abc');
      expect(sample.startAt, recordedAt);
      expect(sample.endAt, isNull);
      expect(sample.payload['mmolPerL'], closeTo(5.5499, 1e-4));
      expect(sample.payload['mgPerDl'], 100.0);
      expect(sample.payload['device'], 'juggluco');
      expect(sample.payload['context'], 'continuous');
      expect(sample.title, '动态监测血糖');
    });

    test('换算使用 18.0182 系数', () {
      final sample = NightscoutDataSource.parseEntry(<String, Object?>{
        'sgv': 180,
        'date': 1700000000000,
      })!;

      expect(
        sample.doubleField('mmolPerL'),
        closeTo(toMmolPerL(180, GlucoseUnit.mgPerDl), 1e-12),
      );
      expect(sample.doubleField('mmolPerL'), closeTo(9.9899, 1e-4));
    });

    test('mbg 与 glucose 也可作为血糖字段', () {
      expect(
        NightscoutDataSource.parseEntry(
            <String, Object?>{'mbg': 90, 'date': 1700000000000})!
            .doubleField('mmolPerL'),
        closeTo(4.9949, 1e-4),
      );
      expect(
        NightscoutDataSource.parseEntry(
            <String, Object?>{'glucose': 90, 'date': 1700000000000})!
            .doubleField('mgPerDl'),
        90.0,
      );
    });

    test('字符串型 sgv 也能解析', () {
      final sample = NightscoutDataSource.parseEntry(<String, Object?>{
        'sgv': '126',
        'date': 1700000000000,
      })!;

      expect(sample.doubleField('mgPerDl'), 126.0);
    });

    test('mbg 类型标记为随机时点，其余为动态监测', () {
      expect(
        NightscoutDataSource.parseEntry(
                <String, Object?>{'mbg': 90, 'type': 'mbg', 'date': 1700000000000})!
            .payload['context'],
        'random',
      );
      expect(
        NightscoutDataSource.parseEntry(<String, Object?>{
          'sgv': 90,
          'type': 'sgv',
          'date': 1700000000000,
        })!.payload['context'],
        'continuous',
      );
      // type 写错时按连续监测处理。
      expect(
        NightscoutDataSource.parseEntry(
                <String, Object?>{'sgv': 90, 'type': 'MBG', 'date': 1700000000000})!
            .payload['context'],
        'continuous',
      );
    });

    test('缺少 sgv 时返回 null', () {
      expect(
        NightscoutDataSource.parseEntry(<String, Object?>{
          'date': 1700000000000,
          'direction': 'Flat',
        }),
        isNull,
      );
    });

    test('非正血糖值按缺失处理', () {
      expect(
        NightscoutDataSource.parseEntry(
            <String, Object?>{'sgv': 0, 'date': 1700000000000}),
        isNull,
      );
      expect(
        NightscoutDataSource.parseEntry(
            <String, Object?>{'sgv': -5, 'date': 1700000000000}),
        isNull,
      );
      expect(
        NightscoutDataSource.parseEntry(
            <String, Object?>{'sgv': 'abc', 'date': 1700000000000}),
        isNull,
      );
    });

    test('direction 全量映射到 GlucoseTrend', () {
      GlucoseTrend? trendOf(Object? direction) {
        final sample = NightscoutDataSource.parseEntry(<String, Object?>{
          'sgv': 100,
          'date': 1700000000000,
          'direction': direction,
        })!;
        return GlucoseTrend.tryFromCode(sample.stringField('trend'));
      }

      expect(trendOf('DoubleUp'), GlucoseTrend.risingFast);
      expect(trendOf('SingleUp'), GlucoseTrend.rising);
      expect(trendOf('FortyFiveUp'), GlucoseTrend.rising);
      expect(trendOf('Flat'), GlucoseTrend.steady);
      expect(trendOf('FortyFiveDown'), GlucoseTrend.falling);
      expect(trendOf('SingleDown'), GlucoseTrend.falling);
      expect(trendOf('DoubleDown'), GlucoseTrend.fallingFast);
    });

    test('未知或非字符串 direction 不写入 trend 字段', () {
      for (final direction in <Object?>[null, 5, 'NONE', 'flat']) {
        final sample = NightscoutDataSource.parseEntry(<String, Object?>{
          'sgv': 100,
          'date': 1700000000000,
          'direction': direction,
        })!;
        expect(sample.payload.containsKey('trend'), isFalse,
            reason: 'direction=$direction 不应产生趋势');
      }
    });

    test('direction 两侧空白被忽略', () {
      final sample = NightscoutDataSource.parseEntry(<String, Object?>{
        'sgv': 100,
        'date': 1700000000000,
        'direction': '  DoubleUp  ',
      })!;

      expect(sample.payload['trend'], 'rising_fast');
    });

    test('_id 缺失时用时间戳兜底并保持稳定', () {
      final first = NightscoutDataSource.parseEntry(<String, Object?>{
        'sgv': 100,
        'date': 1700000000000,
      })!;
      final second = NightscoutDataSource.parseEntry(<String, Object?>{
        'sgv': 100,
        'date': 1700000000000,
      })!;

      expect(first.externalId, 'nightscout:1700000000000');
      expect(second.externalId, first.externalId);
    });

    test('_id 为空串时同样用时间戳兜底', () {
      final sample = NightscoutDataSource.parseEntry(<String, Object?>{
        'sgv': 100,
        '_id': '',
        'date': 1700000000000,
      })!;

      expect(sample.externalId, 'nightscout:1700000000000');
    });

    test('秒级时间戳被放大为毫秒', () {
      final sample = NightscoutDataSource.parseEntry(<String, Object?>{
        'sgv': 100,
        'date': 1700000000,
      })!;

      expect(sample.startAt.millisecondsSinceEpoch, 1700000000 * 1000);
      expect(sample.externalId, 'nightscout:1700000000000');
    });

    test('缺少 date 时退回 dateString', () {
      final sample = NightscoutDataSource.parseEntry(<String, Object?>{
        'sgv': 100,
        'dateString': '2024-03-01T08:30:00.000Z',
      })!;

      expect(sample.startAt, DateTime.parse('2024-03-01T08:30:00.000Z'));
    });

    test('时间字段完全缺失时使用当前时间兜底', () {
      final before = DateTime.now();
      final sample =
          NightscoutDataSource.parseEntry(<String, Object?>{'sgv': 100})!;
      final after = DateTime.now();

      expect(sample.startAt.isBefore(before), isFalse);
      expect(sample.startAt.isAfter(after), isFalse);
    });

    test('device 非字符串时不写入 payload', () {
      final sample = NightscoutDataSource.parseEntry(<String, Object?>{
        'sgv': 100,
        'date': 1700000000000,
        'device': 42,
      })!;

      expect(sample.payload.containsKey('device'), isFalse);
    });
  });

  group('checkAvailability', () {
    HealthSourceConfig config({
      String? baseUrl,
      String? accessToken,
      Map<String, String> extra = const <String, String>{},
    }) =>
        HealthSourceConfig(
          baseUrl: baseUrl,
          accessToken: accessToken,
          extra: extra,
        );

    test('缺少站点地址时要求先授权', () async {
      final source = NightscoutDataSource(config: config());

      final availability = (await source.checkAvailability()).requireValue();

      expect(availability.canFetch, isFalse);
      expect(availability.hint, contains('站点地址'));
    });

    test('地址只有空白时等同于未填写', () async {
      final source = NightscoutDataSource(config: config(baseUrl: '   '));

      expect((await source.checkAvailability()).requireValue().canFetch, isFalse);
    });

    test('缺少 secret 与 token 时要求先授权', () async {
      final source =
          NightscoutDataSource(config: config(baseUrl: 'https://ns.example.com'));

      final availability = (await source.checkAvailability()).requireValue();

      expect(availability.canFetch, isFalse);
      expect(availability.hint, contains('API secret'));
    });

    test('配置 accessToken 后可用', () async {
      final source = NightscoutDataSource(
        config: config(
          baseUrl: 'https://ns.example.com',
          accessToken: 'secret',
        ),
      );

      expect((await source.checkAvailability()).requireValue().canFetch, isTrue);
    });

    test('配置只读 token 后可用', () async {
      final source = NightscoutDataSource(
        config: config(
          baseUrl: 'https://ns.example.com',
          extra: <String, String>{'token': 'readonly-token'},
        ),
      );

      final availability = (await source.checkAvailability()).requireValue();

      expect(availability.canFetch, isTrue);
      expect(availability.isAuthorized, isTrue);
    });

    test('authorize 直接复用可用性探测', () async {
      final source = NightscoutDataSource(
        config: config(
          baseUrl: 'https://ns.example.com',
          accessToken: 'secret',
        ),
      );

      expect((await source.authorize()).requireValue().canFetch, isTrue);
    });

    test('id 与自动同步标记', () {
      final source = NightscoutDataSource(config: config());

      expect(source.id, HealthSourceId.nightscout);
      expect(source.supportsAutomaticSync, isTrue);
      expect(NightscoutDataSource.defaultCount, 2000);
    });
  });

  group('fetch 的请求构造与响应处理', () {
    final window = HealthFetchWindow(
      start: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      end: DateTime.fromMillisecondsSinceEpoch(1702592000000),
    );

    (NightscoutDataSource, _FakeAdapter) build({
      String baseUrl = 'https://ns.example.com',
      String? accessToken,
      Map<String, String> extra = const <String, String>{},
      required ResponseBody Function(RequestOptions options) respond,
    }) {
      final adapter = _FakeAdapter(respond);
      final dio = Dio(BaseOptions(validateStatus: (_) => true))
        ..httpClientAdapter = adapter;
      return (
        NightscoutDataSource(
          config: HealthSourceConfig(
            baseUrl: baseUrl,
            accessToken: accessToken,
            extra: extra,
          ),
          dio: dio,
        ),
        adapter,
      );
    }

    test('未配置地址时直接返回配置类失败，不发请求', () async {
      final (source, adapter) =
          build(baseUrl: '', respond: (options) => _jsonResponse(<Object?>[], 200));

      final result = await source.fetch(window);

      expect(result.isOk, isFalse);
      expect(result.failureOrNull!.kind, FailureKind.configuration);
      expect(result.failureOrNull!.code, 'nightscout.missing_url');
      expect(adapter.callCount, 0);
    });

    test('请求 URL 去掉基址尾部斜杠并带上窗口起点与条数上限', () async {
      final (source, adapter) = build(
        baseUrl: 'https://ns.example.com/',
        respond: (options) => _jsonResponse(<Object?>[], 200),
      );

      await source.fetch(window);

      expect(adapter.lastOptions!.path, 'https://ns.example.com/api/v1/entries.json');
      expect(adapter.lastOptions!.queryParameters['count'], 2000);
      expect(
        adapter.lastOptions!.queryParameters[r'find[date][$gte]'],
        window.start.millisecondsSinceEpoch,
      );
      expect(adapter.lastOptions!.queryParameters.containsKey('token'), isFalse);
    });

    test('配置只读 token 时作为查询参数发送', () async {
      final (source, adapter) = build(
        extra: <String, String>{'token': 'ro-token'},
        respond: (options) => _jsonResponse(<Object?>[], 200),
      );

      await source.fetch(window);

      expect(adapter.lastOptions!.queryParameters['token'], 'ro-token');
    });

    test('accessToken 经 SHA-1 后放入 api-secret 请求头', () async {
      final (source, adapter) = build(
        accessToken: 'my-secret',
        respond: (options) => _jsonResponse(<Object?>[], 200),
      );

      await source.fetch(window);

      final expected = sha1.convert(utf8.encode('my-secret')).toString();
      expect(adapter.lastOptions!.headers['api-secret'], expected);
      expect(adapter.lastOptions!.headers['Accept'], 'application/json');
    });

    test('没有 accessToken 时不发送 api-secret 头', () async {
      final (source, adapter) = build(
        extra: <String, String>{'token': 'ro-token'},
        respond: (options) => _jsonResponse(<Object?>[], 200),
      );

      await source.fetch(window);

      expect(adapter.lastOptions!.headers.containsKey('api-secret'), isFalse);
    });

    test('成功路径把条目归一化为样本', () async {
      final (source, _) = build(
        accessToken: 'secret',
        respond: (options) => _jsonResponse(<Object?>[
          <String, Object?>{
            'sgv': 100,
            '_id': 'a',
            'date': 1700000000000,
            'direction': 'Flat',
          },
          <String, Object?>{
            'sgv': 120,
            '_id': 'b',
            'date': 1700000300000,
            'direction': 'SingleUp',
          },
        ], 200),
      );

      final fetched = (await source.fetch(window)).requireValue();

      expect(fetched.samples.length, 2);
      expect(fetched.warnings, isEmpty);
      expect(fetched.samples.first.doubleField('mmolPerL'), closeTo(5.5499, 1e-4));
      expect(fetched.samples.first.payload['trend'], 'steady');
      expect(fetched.samples.last.payload['trend'], 'rising');
    });

    test('缺少血糖值的条目被跳过并计入告警', () async {
      final (source, _) = build(
        accessToken: 'secret',
        respond: (options) => _jsonResponse(<Object?>[
          <String, Object?>{'sgv': 100, '_id': 'a', 'date': 1700000000000},
          <String, Object?>{'direction': 'Flat', 'date': 1700000300000},
        ], 200),
      );

      final fetched = (await source.fetch(window)).requireValue();

      expect(fetched.samples.length, 1);
      expect(fetched.warnings.length, 1);
      expect(fetched.warnings.single, contains('缺少血糖值'));
    });

    test('鉴权失败映射为 authentication 失败', () async {
      final (source, _) = build(
        accessToken: 'bad',
        respond: (options) => _jsonResponse(<String, Object?>{'status': 401}, 401),
      );

      final result = await source.fetch(window);

      expect(result.isOk, isFalse);
      expect(result.failureOrNull!.kind, FailureKind.authentication);
      expect(result.failureOrNull!.code, 'nightscout.unauthorized');
      expect(result.failureOrNull!.isRetryable, isFalse);
    });

    test('403 同样视为鉴权失败', () async {
      final (source, _) = build(
        accessToken: 'bad',
        respond: (options) => _jsonResponse(<String, Object?>{'status': 403}, 403),
      );

      expect((await source.fetch(window)).failureOrNull!.code,
          'nightscout.unauthorized');
    });

    test('404 映射为配置类失败', () async {
      final (source, _) = build(
        accessToken: 'secret',
        respond: (options) => _jsonResponse('Not Found', 404),
      );

      final result = await source.fetch(window);

      expect(result.failureOrNull!.kind, FailureKind.configuration);
      expect(result.failureOrNull!.code, 'nightscout.not_found');
    });

    test('5xx 映射为可重试的网络失败', () async {
      final (source, _) = build(
        accessToken: 'secret',
        respond: (options) => _jsonResponse('boom', 503),
      );

      final result = await source.fetch(window);

      expect(result.failureOrNull!.kind, FailureKind.network);
      expect(result.failureOrNull!.code, 'nightscout.server_error');
      expect(result.failureOrNull!.message, contains('503'));
      expect(result.failureOrNull!.isRetryable, isTrue);
    });

    test('其他非 2xx 映射为未归类失败并带上状态码', () async {
      final (source, _) = build(
        accessToken: 'secret',
        respond: (options) => _jsonResponse('teapot', 418),
      );

      final result = await source.fetch(window);

      expect(result.failureOrNull!.kind, FailureKind.unknown);
      expect(result.failureOrNull!.code, 'nightscout.http_error');
      expect(result.failureOrNull!.message, contains('418'));
    });

    test('网络异常映射为 network 失败并保留 cause', () async {
      final (source, _) = build(
        accessToken: 'secret',
        respond: (options) => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          message: '连接被拒绝',
        ),
      );

      final result = await source.fetch(window);

      expect(result.failureOrNull!.kind, FailureKind.network);
      expect(result.failureOrNull!.code, 'nightscout.network');
      expect(result.failureOrNull!.message, contains('连接被拒绝'));
      expect(result.failureOrNull!.cause, isA<DioException>());
    });

    test('2xx 但响应体是对象时返回空样本', () async {
      final (source, _) = build(
        accessToken: 'secret',
        respond: (options) => _jsonResponse(<String, Object?>{'status': 'ok'}, 200),
      );

      final fetched = (await source.fetch(window)).requireValue();

      expect(fetched.samples, isEmpty);
      expect(fetched.warnings, isEmpty);
    });
  });
}
