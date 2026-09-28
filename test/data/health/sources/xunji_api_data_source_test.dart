/// `XunjiApiDataSource` 的单元测试。
///
/// 覆盖 `extractTrains` 对三种响应形态的兼容、`parseTrain` 的容量/组次/心率
/// 汇总与幂等键稳定性，以及经假 [HttpClientAdapter] 验证的请求体、鉴权头、
/// 限流告警与错误码分类。
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucocontrol/core/result.dart';
import 'package:glucocontrol/data/health/health_source_config.dart';
import 'package:glucocontrol/data/health/sources/xunji_api_data_source.dart';
import 'package:glucocontrol/domain/health/health_data_source.dart';
import 'package:glucocontrol/domain/health/health_records.dart';
import 'package:glucocontrol/domain/health/health_source.dart';

/// 记录请求并返回预设响应的假 HTTP 适配器。
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.respond);

  final ResponseBody Function(RequestOptions options) respond;

  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
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

final DateTime _origin = DateTime(2026, 3, 14);

void main() {
  group('extractTrains 的响应形态兼容', () {
    test('兼容 res.trains 包装形态', () {
      final trains = XunjiApiDataSource.extractTrains(<String, Object?>{
        'res': <String, Object?>{
          'trains': <Object?>[
            <String, Object?>{'localid': 'a'},
            <String, Object?>{'localid': 'b'},
          ],
        },
      });

      expect(trains.length, 2);
      expect(trains.first['localid'], 'a');
    });

    test('兼容顶层 trains 形态', () {
      final trains = XunjiApiDataSource.extractTrains(<String, Object?>{
        'trains': <Object?>[
          <String, Object?>{'localid': 'c'},
        ],
      });

      expect(trains.single['localid'], 'c');
    });

    test('兼容顶层数组形态', () {
      final trains = XunjiApiDataSource.extractTrains(<Object?>[
        <String, Object?>{'localid': 'd'},
        <Object?, Object?>{'localid': 'e'},
      ]);

      expect(trains.map((train) => train['localid']).toList(), <String>['d', 'e']);
    });

    test('res.trains 优先于顶层 trains', () {
      final trains = XunjiApiDataSource.extractTrains(<String, Object?>{
        'res': <String, Object?>{
          'trains': <Object?>[
            <String, Object?>{'localid': 'inner'},
          ],
        },
        'trains': <Object?>[
          <String, Object?>{'localid': 'outer'},
        ],
      });

      expect(trains.single['localid'], 'inner');
    });

    test('过滤数组中的非对象元素', () {
      final trains = XunjiApiDataSource.extractTrains(<Object?>[
        <String, Object?>{'localid': 'a'},
        'text',
        7,
      ]);

      expect(trains.length, 1);
    });

    test('结构不符时返回空列表', () {
      expect(XunjiApiDataSource.extractTrains(null), isEmpty);
      expect(XunjiApiDataSource.extractTrains('nope'), isEmpty);
      expect(
        XunjiApiDataSource.extractTrains(<String, Object?>{'res': 'nope'}),
        isEmpty,
      );
      expect(
        XunjiApiDataSource.extractTrains(<String, Object?>{
          'res': <String, Object?>{'trains': 'nope'},
        }),
        isEmpty,
      );
      expect(XunjiApiDataSource.extractTrains(<String, Object?>{}), isEmpty);
    });

    test('gzip 字节流形式的响应体也能解码', () {
      final bytes = utf8.encode(jsonEncode(<String, Object?>{
        'res': <String, Object?>{
          'trains': <Object?>[
            <String, Object?>{'localid': 'gzip'},
          ],
        },
      }));

      final trains = XunjiApiDataSource.extractTrains(bytes);

      expect(trains.single['localid'], 'gzip');
    });

    test('字节流不是合法 JSON 时返回空列表', () {
      expect(
        XunjiApiDataSource.extractTrains(<int>[0x00, 0x01, 0x02]),
        isEmpty,
      );
    });
  });

  group('parseTrain 的字段汇总', () {
    test('容量按重量×次数求和，组数与次数分别合计', () {
      final sample = XunjiApiDataSource.parseTrain(
        <String, Object?>{
          'localid': 'x1',
          'title': '推日',
          'movements': <Object?>[
            <String, Object?>{
              'sets': <Object?>[
                <String, Object?>{'weight': 60, 'reps': 10},
                <String, Object?>{'weight': 60, 'reps': 8},
                <String, Object?>{'weight': '65', 'reps': '6'},
              ],
            },
            <String, Object?>{
              'sets': <Object?>[
                <String, Object?>{'weightKg': 20.5, 'count': 12},
              ],
            },
          ],
        },
        originDate: _origin,
      )!;

      expect(sample.payload['totalVolumeKg'],
          closeTo(60 * 10 + 60 * 8 + 65 * 6 + 20.5 * 12, 1e-9));
      expect(sample.payload['totalVolumeKg'], closeTo(1716.0, 1e-9));
      expect(sample.payload['totalSets'], 4);
      expect(sample.payload['totalReps'], 36);
    });

    test('没有组数据时容量/组数/次数为 null 而不是 0', () {
      final sample = XunjiApiDataSource.parseTrain(
        <String, Object?>{'localid': 'x2', 'movements': <Object?>[]},
        originDate: _origin,
      )!;

      expect(sample.payload.containsKey('totalVolumeKg'), isFalse);
      expect(sample.payload.containsKey('totalSets'), isFalse);
      expect(sample.payload.containsKey('totalReps'), isFalse);
    });

    test('只有重量或只有次数时不累计容量但仍标记为力量训练', () {
      final sample = XunjiApiDataSource.parseTrain(
        <String, Object?>{
          'localid': 'x3',
          'movements': <Object?>[
            <String, Object?>{
              'sets': <Object?>[
                <String, Object?>{'weight': 50},
                <String, Object?>{'reps': 10},
              ],
            },
          ],
        },
        originDate: _origin,
      )!;

      expect(sample.payload['totalSets'], 2);
      expect(sample.payload['totalReps'], 10);
      expect(sample.doubleField('totalVolumeKg'), 0.0);
      expect(sample.payload['category'], 'strength');
    });

    test('movements 的别名 actions/items 与 sets 的别名 groups 均被识别', () {
      final sample = XunjiApiDataSource.parseTrain(
        <String, Object?>{
          'localid': 'x4',
          'actions': <Object?>[
            <String, Object?>{
              'groups': <Object?>[
                <String, Object?>{'weight': 40, 'reps': 5},
              ],
            },
          ],
        },
        originDate: _origin,
      )!;

      expect(sample.payload['totalSets'], 1);
      expect(sample.doubleField('totalVolumeKg'), 200.0);
    });

    test('有距离指标时分类为 other 并汇总公里数', () {
      final sample = XunjiApiDataSource.parseTrain(
        <String, Object?>{
          'localid': 'x5',
          'movements': <Object?>[
            <String, Object?>{
              'sets': <Object?>[
                <String, Object?>{
                  'metrics': <String, Object?>{'distance': '5km'},
                },
                <String, Object?>{
                  'metrics': <String, Object?>{'distance': '2000m'},
                },
                <String, Object?>{
                  'metrics': <String, Object?>{'distanceKm': 1.5},
                },
              ],
            },
          ],
        },
        originDate: _origin,
      )!;

      expect(sample.payload['category'], 'other');
      expect(sample.doubleField('distanceKm'), closeTo(8.5, 1e-9));
    });

    test('无单位的距离字符串按米处理', () {
      final sample = XunjiApiDataSource.parseTrain(
        <String, Object?>{
          'localid': 'x6',
          'movements': <Object?>[
            <String, Object?>{
              'sets': <Object?>[
                <String, Object?>{
                  'metrics': <String, Object?>{'distance': '3000'},
                },
              ],
            },
          ],
        },
        originDate: _origin,
      )!;

      expect(sample.doubleField('distanceKm'), closeTo(3.0, 1e-9));
    });

    test('数字型距离被当作公里原样使用（与字符串口径不一致）', () {
      final sample = XunjiApiDataSource.parseTrain(
        <String, Object?>{
          'localid': 'x7',
          'movements': <Object?>[
            <String, Object?>{
              'sets': <Object?>[
                <String, Object?>{
                  'metrics': <String, Object?>{'distance': 3000},
                },
              ],
            },
          ],
        },
        originDate: _origin,
      )!;

      // 同一个物理量写成数字时不会被除以 1000。
      expect(sample.doubleField('distanceKm'), 3000.0);
    });

    test('数字型距离应按米换算（期望语义，当前未实现）', () {
      final sample = XunjiApiDataSource.parseTrain(
        <String, Object?>{
          'localid': 'x8',
          'movements': <Object?>[
            <String, Object?>{
              'sets': <Object?>[
                <String, Object?>{
                  'metrics': <String, Object?>{'distance': 3000},
                },
              ],
            },
          ],
        },
        originDate: _origin,
      )!;

      expect(sample.doubleField('distanceKm'), 3.0);
    },
        skip: '_readDistanceKm 对 num 直接原样返回，对无单位字符串却除以 1000；'
            '文档注释称「纯数字米」，两处口径不一致。若上游确实给米，'
            '数字型距离会放大 1000 倍。');

    test('热耗与心率按组汇总', () {
      final sample = XunjiApiDataSource.parseTrain(
        <String, Object?>{
          'localid': 'x9',
          'movements': <Object?>[
            <String, Object?>{
              'sets': <Object?>[
                <String, Object?>{
                  'metrics': <String, Object?>{'kcal': 100, 'bpm': 130},
                },
                <String, Object?>{
                  'metrics': <String, Object?>{'calories': 50, 'heartRate': 150},
                },
              ],
            },
          ],
        },
        originDate: _origin,
      )!;

      expect(sample.payload['calories'], 150);
      expect(sample.payload['avgHeartRate'], 140);
      expect(sample.payload['maxHeartRate'], 150);
    });

    test('备注字段按 remark/note/comments 顺序取第一个非空值', () {
      expect(
        XunjiApiDataSource.parseTrain(
          <String, Object?>{'localid': 'x10', 'remark': '状态不错'},
          originDate: _origin,
        )!.payload['note'],
        '状态不错',
      );
      expect(
        XunjiApiDataSource.parseTrain(
          <String, Object?>{'localid': 'x11', 'note': '腿有点酸'},
          originDate: _origin,
        )!.payload['note'],
        '腿有点酸',
      );
      expect(
        XunjiApiDataSource.parseTrain(
          <String, Object?>{'localid': 'x12', 'comments': '睡得少'},
          originDate: _origin,
        )!.payload['note'],
        '睡得少',
      );
      expect(
        XunjiApiDataSource.parseTrain(
          <String, Object?>{'localid': 'x13'},
          originDate: _origin,
        )!.payload.containsKey('note'),
        isFalse,
      );
    });

    test('缺少开始时间时用请求日当地零点兜底，结束时间默认加一小时', () {
      final sample = XunjiApiDataSource.parseTrain(
        <String, Object?>{'localid': 'x14'},
        originDate: _origin,
      )!;

      expect(sample.startAt, DateTime(2026, 3, 14));
      expect(sample.endAt, DateTime(2026, 3, 14, 1));
      expect(WorkoutSession.tryFromSample(sample)!.durationMinutes, 60.0);
    });

    test('ISO 字符串与秒级时间戳均可作为开始时间', () {
      final iso = XunjiApiDataSource.parseTrain(
        <String, Object?>{
          'localid': 'x15',
          'start': '2026-03-14T18:30:00.000',
          'end': '2026-03-14T19:15:00.000',
        },
        originDate: _origin,
      )!;
      expect(iso.startAt, DateTime(2026, 3, 14, 18, 30));

      final epoch = XunjiApiDataSource.parseTrain(
        <String, Object?>{
          'localid': 'x16',
          'startTime': 1773500000,
        },
        originDate: _origin,
      )!;
      expect(epoch.startAt.millisecondsSinceEpoch, 1773500000);
    });

    test('endTime 别名与毫秒级时间戳', () {
      final sample = XunjiApiDataSource.parseTrain(
        <String, Object?>{
          'localid': 'x17',
          'start': 1773500000000,
          'endTime': 1773503600000,
        },
        originDate: _origin,
      )!;

      expect(sample.startAt.millisecondsSinceEpoch, 1773500000000);
      expect(sample.endAt!.millisecondsSinceEpoch, 1773503600000);
    });

    test('返回的是可直接还原为 WorkoutSession 的运动样本', () {
      final sample = XunjiApiDataSource.parseTrain(
        <String, Object?>{
          'localid': 'x18',
          'title': '腿日',
          'start': '2026-03-14T19:00:00.000',
          'end': '2026-03-14T20:30:00.000',
          'movements': <Object?>[
            <String, Object?>{
              'sets': <Object?>[
                <String, Object?>{'weight': 100, 'reps': 5},
              ],
            },
          ],
        },
        originDate: _origin,
      )!;

      expect(sample.source, HealthSourceId.xunji);
      expect(sample.kind, HealthSampleKind.workout);
      expect(sample.title, '腿日');
      expect(sample.externalId, 'xunji:x18');

      final session = WorkoutSession.tryFromSample(sample)!;
      expect(session.name, '腿日');
      expect(session.category, WorkoutCategory.strength);
      expect(session.durationMinutes, 90.0);
      expect(session.totalVolumeKg, 500.0);
      expect(session.totalSets, 1);
      expect(session.totalReps, 5);
    });

    test('原始 train 对象完整保留在 payload.raw 中', () {
      final train = <String, Object?>{
        'localid': 'x19',
        'title': '背日',
        '未知字段': <String, Object?>{'a': 1},
      };

      final sample =
          XunjiApiDataSource.parseTrain(train, originDate: _origin)!;

      expect(sample.payload['raw'], same(train));
    });

    test('缺少标题时用「训记训练」兜底', () {
      expect(
        XunjiApiDataSource.parseTrain(
          <String, Object?>{'localid': 'x20'},
          originDate: _origin,
        )!.title,
        '训记训练',
      );
    });
  });

  group('parseTrain 的幂等键', () {
    test('有 localid 时直接用 localid', () {
      final sample = XunjiApiDataSource.parseTrain(
        <String, Object?>{'localid': 'stable-id'},
        originDate: _origin,
      )!;

      expect(sample.externalId, 'xunji:stable-id');
    });

    test('localId/id 是 localid 的别名', () {
      expect(
        XunjiApiDataSource.parseTrain(
          <String, Object?>{'localId': 'camel'},
          originDate: _origin,
        )!.externalId,
        'xunji:camel',
      );
      expect(
        XunjiApiDataSource.parseTrain(
          <String, Object?>{'id': 12345},
          originDate: _origin,
        )!.externalId,
        'xunji:12345',
      );
    });

    test('缺 localid 时同一输入两次得到相同幂等键', () {
      final train = <String, Object?>{
        'title': '腿日',
        'start': '2026-03-14T19:00:00.000',
      };

      final first = XunjiApiDataSource.parseTrain(train, originDate: _origin)!;
      final second = XunjiApiDataSource.parseTrain(train, originDate: _origin)!;

      expect(first.externalId, second.externalId);
      expect(first.externalId, startsWith('xunji:2026-03-14:'));
    });

    test('缺 localid 时标题或开始时间不同会得到不同的幂等键', () {
      final base = XunjiApiDataSource.parseTrain(
        <String, Object?>{'title': '腿日', 'start': '2026-03-14T19:00:00.000'},
        originDate: _origin,
      )!;
      final otherTitle = XunjiApiDataSource.parseTrain(
        <String, Object?>{'title': '推日', 'start': '2026-03-14T19:00:00.000'},
        originDate: _origin,
      )!;
      final otherTime = XunjiApiDataSource.parseTrain(
        <String, Object?>{'title': '腿日', 'start': '2026-03-14T20:00:00.000'},
        originDate: _origin,
      )!;

      expect(base.externalId, isNot(otherTitle.externalId));
      expect(base.externalId, isNot(otherTime.externalId));
    });

    test('localid 为空串时退回指纹', () {
      final sample = XunjiApiDataSource.parseTrain(
        <String, Object?>{'localid': '', 'title': '腿日'},
        originDate: _origin,
      )!;

      expect(sample.externalId, startsWith('xunji:2026-03-14:'));
    });
  });

  group('checkAvailability', () {
    test('缺少 API Key 时要求先配置', () async {
      final source = XunjiApiDataSource(
        config: const HealthSourceConfig(),
        interRequestDelay: Duration.zero,
      );

      final availability = (await source.checkAvailability()).requireValue();

      expect(availability.canFetch, isFalse);
      expect(availability.hint, contains('API Key'));
    });

    test('API Key 只有空白时等同于未配置', () async {
      final source = XunjiApiDataSource(
        config: const HealthSourceConfig(apiKey: '   '),
        interRequestDelay: Duration.zero,
      );

      expect((await source.checkAvailability()).requireValue().canFetch, isFalse);
    });

    test('填入 API Key 即视为已授权', () async {
      final source = XunjiApiDataSource(
        config: const HealthSourceConfig(apiKey: 'k'),
        interRequestDelay: Duration.zero,
      );

      expect((await source.authorize()).requireValue().isAuthorized, isTrue);
      expect(source.id, HealthSourceId.xunji);
      expect(source.supportsAutomaticSync, isTrue);
    });

    test('协议常量与默认基址稳定', () {
      expect(XunjiApiDataSource.defaultBaseUrl, 'https://trains.xunjiapp.cn');
      expect(XunjiApiDataSource.schemaVersion, 'train_open_api_v2');
    });
  });

  group('fetch 的请求与错误处理', () {
    final window = HealthFetchWindow(
      start: DateTime(2026, 3, 14),
      end: DateTime(2026, 3, 14, 23, 59),
    );

    (XunjiApiDataSource, _FakeAdapter) build({
      String? apiKey = 'key-1',
      String? baseUrl,
      required ResponseBody Function(RequestOptions options) respond,
    }) {
      final adapter = _FakeAdapter(respond);
      final dio = Dio(BaseOptions(validateStatus: (_) => true))
        ..httpClientAdapter = adapter;
      return (
        XunjiApiDataSource(
          config: HealthSourceConfig(apiKey: apiKey, baseUrl: baseUrl),
          dio: dio,
          interRequestDelay: Duration.zero,
        ),
        adapter,
      );
    }

    test('未配置 API Key 时直接失败，不发请求', () async {
      final (source, adapter) = build(
        apiKey: null,
        respond: (options) => _jsonResponse(<String, Object?>{}, 200),
      );

      final result = await source.fetch(window);

      expect(result.isOk, isFalse);
      expect(result.failureOrNull!.kind, FailureKind.authentication);
      expect(result.failureOrNull!.code, 'xunji.missing_key');
      expect(adapter.requests, isEmpty);
    });

    test('请求地址、鉴权头与请求体符合协议', () async {
      final (source, adapter) = build(
        respond: (options) => _jsonResponse(<String, Object?>{
          'res': <String, Object?>{'trains': <Object?>[]},
        }, 200),
      );

      await source.fetch(window);

      final request = adapter.requests.single;
      expect(request.path, 'https://trains.xunjiapp.cn/api_trains_for_llm_v2');
      expect(request.headers['Authorization'], 'Bearer key-1');
      expect(request.headers['x-api-key'], 'key-1');
      expect(request.data, <String, Object?>{
        'schema_version': 'train_open_api_v2',
        'datestr': '2026-03-14',
      });
    });

    test('自定义基址去掉尾部斜杠', () async {
      final (source, adapter) = build(
        baseUrl: 'https://proxy.example.com/',
        respond: (options) => _jsonResponse(<String, Object?>{
          'res': <String, Object?>{'trains': <Object?>[]},
        }, 200),
      );

      await source.fetch(window);

      expect(adapter.requests.single.path,
          'https://proxy.example.com/api_trains_for_llm_v2');
    });

    test('成功路径把 trains 归一化为样本', () async {
      final (source, _) = build(
        respond: (options) => _jsonResponse(<String, Object?>{
          'res': <String, Object?>{
            'trains': <Object?>[
              <String, Object?>{
                'localid': 't1',
                'title': '推日',
                'movements': <Object?>[
                  <String, Object?>{
                    'sets': <Object?>[
                      <String, Object?>{'weight': 60, 'reps': 10},
                    ],
                  },
                ],
              },
            ],
          },
        }, 200),
      );

      final fetched = (await source.fetch(window)).requireValue();

      expect(fetched.samples.length, 1);
      expect(fetched.samples.single.externalId, 'xunji:t1');
      expect(fetched.samples.single.doubleField('totalVolumeKg'), 600.0);
      expect(fetched.warnings, isEmpty);
    });

    test('窗口跨两天时逐日请求', () async {
      final (source, adapter) = build(
        respond: (options) => _jsonResponse(<String, Object?>{
          'res': <String, Object?>{'trains': <Object?>[]},
        }, 200),
      );

      await source.fetch(HealthFetchWindow(
        start: DateTime(2026, 3, 13, 10),
        end: DateTime(2026, 3, 14, 10),
      ));

      expect(
        adapter.requests
            .map((request) => (request.data! as Map)['datestr'])
            .toList(),
        <String>['2026-03-13', '2026-03-14'],
      );
    });

    test('限流的日子被跳过并记入告警，其余日子继续', () async {
      final (source, adapter) = build(
        respond: (options) {
          final datestr = (options.data! as Map)['datestr'];
          if (datestr == '2026-03-13') {
            return _jsonResponse(<String, Object?>{
              'error': 'too frequent, retry after 90s',
            }, 429);
          }
          return _jsonResponse(<String, Object?>{
            'res': <String, Object?>{
              'trains': <Object?>[
                <String, Object?>{'localid': 'ok'},
              ],
            },
          }, 200);
        },
      );

      final fetched = (await source.fetch(HealthFetchWindow(
        start: DateTime(2026, 3, 13, 10),
        end: DateTime(2026, 3, 14, 10),
      )))
          .requireValue();

      expect(adapter.requests.length, 2);
      expect(fetched.warnings.single, contains('2026-03-13'));
      expect(fetched.warnings.single, contains('限流'));
      expect(fetched.samples.single.externalId, 'xunji:ok');
    });

    test('鉴权失败让整次取数失败', () async {
      final (source, _) = build(
        respond: (options) => _jsonResponse(<String, Object?>{
          'error': 'apikey invalid',
        }, 401),
      );

      final result = await source.fetch(window);

      expect(result.isOk, isFalse);
      expect(result.failureOrNull!.kind, FailureKind.authentication);
      expect(result.failureOrNull!.code, 'xunji.bad_key');
    });

    test('VIP 提示被识别为鉴权类失败', () async {
      final (source, _) = build(
        respond: (options) => _jsonResponse(<String, Object?>{'msg': '仅VIP可用'}, 200),
      );

      final result = await source.fetch(window);

      expect(result.failureOrNull!.code, 'xunji.vip_required');
      expect(result.failureOrNull!.message, contains('VIP'));
    });

    test('5xx 映射为可重试的网络失败', () async {
      final (source, _) = build(
        respond: (options) => _jsonResponse('server error', 502),
      );

      final result = await source.fetch(window);

      expect(result.failureOrNull!.kind, FailureKind.network);
      expect(result.failureOrNull!.code, 'xunji.server_error');
    });

    test('网络异常映射为 network 失败并保留 cause', () async {
      final (source, _) = build(
        respond: (options) => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
          message: '超时',
        ),
      );

      final result = await source.fetch(window);

      expect(result.failureOrNull!.kind, FailureKind.network);
      expect(result.failureOrNull!.code, 'xunji.network');
      expect(result.failureOrNull!.cause, isA<DioException>());
    });

    test('响应结构无法识别时返回空样本而不是失败', () async {
      final (source, _) = build(
        respond: (options) => _jsonResponse(<String, Object?>{'unexpected': true}, 200),
      );

      final fetched = (await source.fetch(window)).requireValue();

      expect(fetched.samples, isEmpty);
      expect(fetched.warnings, isEmpty);
    });
  });
}
