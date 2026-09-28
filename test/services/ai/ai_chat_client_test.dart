/// `ai_chat_client.dart` 的单元测试。
///
/// 覆盖 [AiEndpointConfig.fromUserInput] 对三种地址写法的拆分与 vision 判定、
/// [AiChatClient.parseCompletion] 的报文容错（含文本块数组与 tool_calls）、
/// `complete()` 的请求构造与错误码分类，以及 [AiChatClient.imageContentParts]
/// 的图片编码。
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucocontrol/core/result.dart';
import 'package:glucocontrol/services/ai/ai_chat_client.dart';
import 'package:glucocontrol/services/ai/ai_tool.dart';

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

const AiEndpointConfig _defaultConfig = AiEndpointConfig(
  baseUrl: 'https://api.example.com/v1',
  apiKey: 'sk-test',
  model: 'test-model',
);

void main() {
  group('AiEndpointConfig.fromUserInput', () {
    test('纯基址沿用默认对话路径', () {
      final config = AiEndpointConfig.fromUserInput(
        apiUrl: 'https://api.deepseek.com/v1',
        apiKey: 'k',
        model: 'deepseek-chat',
      );

      expect(config.baseUrl, 'https://api.deepseek.com/v1');
      expect(config.chatPath, '/chat/completions');
      expect(config.chatPath, AiEndpointConfig.defaultChatPath);
    });

    test('基址尾部斜杠被去掉', () {
      final config = AiEndpointConfig.fromUserInput(
        apiUrl: 'https://api.deepseek.com/v1/',
        apiKey: 'k',
        model: 'deepseek-chat',
      );

      expect(config.baseUrl, 'https://api.deepseek.com/v1');
      expect(config.chatPath, '/chat/completions');
    });

    test('完整对话地址被拆成基址与路径，且保留 /v1 段', () {
      final withVersion = AiEndpointConfig.fromUserInput(
        apiUrl: 'https://api.deepseek.com/v1/chat/completions',
        apiKey: 'k',
        model: 'deepseek-chat',
      );
      expect(withVersion.baseUrl, 'https://api.deepseek.com/v1');
      expect(withVersion.chatPath, '/chat/completions');
      // 拼回的地址必须与用户填写的完全一致：少一段 /v1 就会打到错误端点。
      expect('${withVersion.baseUrl}${withVersion.chatPath}',
          'https://api.deepseek.com/v1/chat/completions');

      final withoutVersion = AiEndpointConfig.fromUserInput(
        apiUrl: 'https://api.deepseek.com/chat/completions',
        apiKey: 'k',
        model: 'deepseek-chat',
      );
      expect(withoutVersion.baseUrl, 'https://api.deepseek.com');
      expect(withoutVersion.chatPath, '/chat/completions');
    });

    test('MiniMax 的私有路径同样被拆出且保留 /v1', () {
      final config = AiEndpointConfig.fromUserInput(
        apiUrl: 'https://api.minimax.chat/v1/text/chatcompletion_v2',
        apiKey: 'k',
        model: 'abab6.5s-chat',
      );

      expect(config.baseUrl, 'https://api.minimax.chat/v1');
      expect(config.chatPath, '/text/chatcompletion_v2');
      expect('${config.baseUrl}${config.chatPath}',
          'https://api.minimax.chat/v1/text/chatcompletion_v2');
    });

    test('不带 /v1 的 MiniMax 路径也被识别', () {
      final config = AiEndpointConfig.fromUserInput(
        apiUrl: 'https://api.minimax.chat/text/chatcompletion_v2',
        apiKey: 'k',
        model: 'abab6.5s-chat',
      );

      expect(config.baseUrl, 'https://api.minimax.chat');
      expect(config.chatPath, '/text/chatcompletion_v2');
    });

    test('地址两侧空白被去掉', () {
      final config = AiEndpointConfig.fromUserInput(
        apiUrl: '  https://api.deepseek.com/v1  ',
        apiKey: 'k',
        model: 'deepseek-chat',
      );

      expect(config.baseUrl, 'https://api.deepseek.com/v1');
    });

    test('密钥与模型名原样保留，工具调用默认开启', () {
      final config = AiEndpointConfig.fromUserInput(
        apiUrl: 'https://x/v1',
        apiKey: 'sk-123',
        model: 'glm-4',
      );

      expect(config.apiKey, 'sk-123');
      expect(config.model, 'glm-4');
      expect(config.supportsToolCalling, isTrue);
      expect(config.isUsable, isTrue);
    });

    test('vision 模型名被识别', () {
      bool vision(String model) => AiEndpointConfig.fromUserInput(
            apiUrl: 'https://x/v1',
            apiKey: 'k',
            model: model,
          ).supportsVision;

      expect(vision('gpt-4o'), isTrue);
      expect(vision('qwen-vl-max'), isTrue);
      expect(vision('k2.5'), isTrue);
      expect(vision('abab6.5-vl'), isTrue);
      expect(vision('deepseek-chat'), isFalse);
      expect(vision('glm-4'), isFalse);
      expect(vision('abab6.5s-chat'), isFalse);
    });

    test('isUsable 要求三个字段都非空', () {
      expect(
        AiEndpointConfig.fromUserInput(apiUrl: '', apiKey: 'k', model: 'm')
            .isUsable,
        isFalse,
      );
      expect(
        AiEndpointConfig.fromUserInput(apiUrl: 'https://x', apiKey: '', model: 'm')
            .isUsable,
        isFalse,
      );
      expect(
        AiEndpointConfig.fromUserInput(
                apiUrl: 'https://x', apiKey: 'k', model: '')
            .isUsable,
        isFalse,
      );
    });
  });

  group('parseCompletion 的正常路径', () {
    test('解析正文与空工具调用', () {
      final result = AiChatClient.parseCompletion(<String, Object?>{
        'choices': <Object?>[
          <String, Object?>{
            'message': <String, Object?>{'role': 'assistant', 'content': '你的血糖很平稳'},
          },
        ],
      });

      final reply = result.requireValue();
      expect(reply.content, '你的血糖很平稳');
      expect(reply.toolCalls, isEmpty);
      expect(reply.wantsTools, isFalse);
    });

    test('content 为文本块数组时按顺序拼接', () {
      final reply = AiChatClient.parseCompletion(<String, Object?>{
        'choices': <Object?>[
          <String, Object?>{
            'message': <String, Object?>{
              'content': <Object?>[
                <String, Object?>{'type': 'text', 'text': '早餐后'},
                <String, Object?>{'type': 'text', 'text': '血糖偏高'},
              ],
            },
          },
        ],
      }).requireValue();

      expect(reply.content, '早餐后血糖偏高');
    });

    test('文本块数组里没有可用文本时 content 为 null', () {
      expect(
        AiChatClient.parseCompletion(<String, Object?>{
          'choices': <Object?>[
            <String, Object?>{
              'message': <String, Object?>{
                'content': <Object?>[
                  <String, Object?>{'type': 'image_url'},
                  'text',
                ],
              },
            },
          ],
        }).requireValue().content,
        isNull,
      );
    });

    test('content 为 null 或非字符串/数组时返回 null', () {
      expect(
        AiChatClient.parseCompletion(<String, Object?>{
          'choices': <Object?>[
            <String, Object?>{
              'message': <String, Object?>{'content': null},
            },
          ],
        }).requireValue().content,
        isNull,
      );
      expect(
        AiChatClient.parseCompletion(<String, Object?>{
          'choices': <Object?>[
            <String, Object?>{
              'message': <String, Object?>{'content': 42},
            },
          ],
        }).requireValue().content,
        isNull,
      );
    });

    test('只返回第一个 choice', () {
      final reply = AiChatClient.parseCompletion(<String, Object?>{
        'choices': <Object?>[
          <String, Object?>{
            'message': <String, Object?>{'content': '第一个'},
          },
          <String, Object?>{
            'message': <String, Object?>{'content': '第二个'},
          },
        ],
      }).requireValue();

      expect(reply.content, '第一个');
    });
  });

  group('parseCompletion 的 tool_calls', () {
    test('arguments 为字符串时原样保留', () {
      final reply = AiChatClient.parseCompletion(<String, Object?>{
        'choices': <Object?>[
          <String, Object?>{
            'message': <String, Object?>{
              'content': null,
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'call_1',
                  'type': 'function',
                  'function': <String, Object?>{
                    'name': 'query_glucose',
                    'arguments': '{"days":7}',
                  },
                },
              ],
            },
          },
        ],
      }).requireValue();

      expect(reply.wantsTools, isTrue);
      expect(reply.content, isNull);
      expect(reply.toolCalls.single.id, 'call_1');
      expect(reply.toolCalls.single.name, 'query_glucose');
      expect(reply.toolCalls.single.argumentsJson, '{"days":7}');
    });

    test('arguments 为对象时被编码为 JSON 字符串', () {
      final reply = AiChatClient.parseCompletion(<String, Object?>{
        'choices': <Object?>[
          <String, Object?>{
            'message': <String, Object?>{
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'call_2',
                  'function': <String, Object?>{
                    'name': 'query_workouts',
                    'arguments': <String, Object?>{'days': 30},
                  },
                },
              ],
            },
          },
        ],
      }).requireValue();

      expect(reply.toolCalls.single.argumentsJson, '{"days":30}');
    });

    test('缺少 id 时用下标兜底', () {
      final reply = AiChatClient.parseCompletion(<String, Object?>{
        'choices': <Object?>[
          <String, Object?>{
            'message': <String, Object?>{
              'tool_calls': <Object?>[
                <String, Object?>{
                  'function': <String, Object?>{'name': 'a', 'arguments': '{}'},
                },
                <String, Object?>{
                  'function': <String, Object?>{'name': 'b', 'arguments': '{}'},
                },
              ],
            },
          },
        ],
      }).requireValue();

      expect(
        reply.toolCalls.map((call) => call.id).toList(),
        <String>['call_0', 'call_1'],
      );
    });

    test('结构不完整的工具调用被跳过', () {
      final reply = AiChatClient.parseCompletion(<String, Object?>{
        'choices': <Object?>[
          <String, Object?>{
            'message': <String, Object?>{
              'tool_calls': <Object?>[
                'not a map',
                <String, Object?>{'id': 'no-function'},
                <String, Object?>{
                  'id': 'no-name',
                  'function': <String, Object?>{'arguments': '{}'},
                },
                <String, Object?>{
                  'id': 'empty-name',
                  'function': <String, Object?>{'name': '', 'arguments': '{}'},
                },
                <String, Object?>{
                  'id': 'ok',
                  'function': <String, Object?>{'name': 'good', 'arguments': '{}'},
                },
              ],
            },
          },
        ],
      }).requireValue();

      expect(reply.toolCalls.length, 1);
      expect(reply.toolCalls.single.name, 'good');
    });

    test('tool_calls 非数组时视为没有工具调用', () {
      final reply = AiChatClient.parseCompletion(<String, Object?>{
        'choices': <Object?>[
          <String, Object?>{
            'message': <String, Object?>{
              'content': '纯文本',
              'tool_calls': <String, Object?>{},
            },
          },
        ],
      }).requireValue();

      expect(reply.toolCalls, isEmpty);
      expect(reply.wantsTools, isFalse);
    });
  });

  group('parseCompletion 的报文容错', () {
    test('响应不是对象时报 malformed_response', () {
      for (final data in <Object?>[null, 'text', 42, <Object?>[]]) {
        final result = AiChatClient.parseCompletion(data);

        expect(result.isOk, isFalse, reason: '$data 应当失败');
        expect(result.failureOrNull!.kind, FailureKind.parsing);
        expect(result.failureOrNull!.code, 'ai.malformed_response');
      }
    });

    test('缺少 choices 或 choices 为空时报 no_choices', () {
      final missing =
          AiChatClient.parseCompletion(<String, Object?>{'id': 'x'});
      final empty =
          AiChatClient.parseCompletion(<String, Object?>{'choices': <Object?>[]});

      expect(missing.failureOrNull!.code, 'ai.no_choices');
      expect(empty.failureOrNull!.code, 'ai.no_choices');
    });

    test('choices 不是数组时报 no_choices', () {
      final result = AiChatClient.parseCompletion(
          <String, Object?>{'choices': <String, Object?>{}});

      expect(result.failureOrNull!.code, 'ai.no_choices');
    });

    test('choice 不是对象时报 bad_choice', () {
      final result =
          AiChatClient.parseCompletion(<String, Object?>{'choices': <Object?>['x']});

      expect(result.failureOrNull!.code, 'ai.bad_choice');
    });

    test('缺少 message 时报 bad_message', () {
      final result = AiChatClient.parseCompletion(<String, Object?>{
        'choices': <Object?>[
          <String, Object?>{'finish_reason': 'stop'},
        ],
      });

      expect(result.failureOrNull!.code, 'ai.bad_message');
    });

    test('message 不是对象时报 bad_message', () {
      final result = AiChatClient.parseCompletion(<String, Object?>{
        'choices': <Object?>[
          <String, Object?>{'message': 'nope'},
        ],
      });

      expect(result.failureOrNull!.code, 'ai.bad_message');
    });
  });

  group('complete 的请求与错误处理', () {
    (AiChatClient, _FakeAdapter) build({
      AiEndpointConfig? config,
      required ResponseBody Function(RequestOptions options) respond,
    }) {
      final effective = config ?? _defaultConfig;
      final adapter = _FakeAdapter(respond);
      final dio = Dio(BaseOptions(
        baseUrl: effective.baseUrl,
        // 与 AiChatClient 的真实 Dio 一致：非 2xx 也交给 _classifyError 判定。
        validateStatus: (_) => true,
      ))
        ..httpClientAdapter = adapter;
      return (AiChatClient(config: effective, dio: dio), adapter);
    }

    test('配置不完整时不发请求', () async {
      final (client, adapter) = build(
        config: const AiEndpointConfig(baseUrl: '', apiKey: '', model: ''),
        respond: (options) => _jsonResponse(<String, Object?>{}, 200),
      );

      final result = await client.complete(messages: const <Map<String, Object?>>[]);

      expect(result.isOk, isFalse);
      expect(result.failureOrNull!.kind, FailureKind.configuration);
      expect(result.failureOrNull!.code, 'ai.not_configured');
      expect(adapter.callCount, 0);
    });

    test('请求体包含模型、消息、温度与令牌上限', () async {
      final (client, adapter) = build(
        respond: (options) => _jsonResponse(<String, Object?>{
          'choices': <Object?>[
            <String, Object?>{
              'message': <String, Object?>{'content': 'ok'},
            },
          ],
        }, 200),
      );

      final result = await client.complete(
        messages: const <Map<String, Object?>>[
          <String, Object?>{'role': 'user', 'content': '你好'},
        ],
        temperature: 0.7,
        maxTokens: 512,
      );

      final request = adapter.lastOptions!;
      expect(request.baseUrl, 'https://api.example.com/v1');
      expect(request.path, '/chat/completions');
      expect(request.headers['Authorization'], 'Bearer sk-test');
      expect(request.data, <String, Object?>{
        'model': 'test-model',
        'messages': <Map<String, Object?>>[
          <String, Object?>{'role': 'user', 'content': '你好'},
        ],
        'temperature': 0.7,
        'max_tokens': 512,
      });
      expect(result.requireValue().content, 'ok');
    });

    test('默认温度与令牌上限', () async {
      final (client, adapter) = build(
        respond: (options) =>
            _jsonResponse(<String, Object?>{'choices': <Object?>[]}, 200),
      );

      await client.complete(messages: const <Map<String, Object?>>[]);

      final body = adapter.lastOptions!.data! as Map<String, Object?>;
      expect(body['temperature'], 0.3);
      expect(body['max_tokens'], 2000);
    });

    test('有工具且支持工具调用时发送 tools 字段', () async {
      final (client, adapter) = build(
        respond: (options) =>
            _jsonResponse(<String, Object?>{'choices': <Object?>[]}, 200),
      );
      const tool = AiToolDefinition(name: 'query', description: '查询');

      await client.complete(
        messages: const <Map<String, Object?>>[],
        tools: const <AiToolDefinition>[tool],
      );

      final body = adapter.lastOptions!.data! as Map<String, Object?>;
      expect(body['tools'], <Object?>[tool.toOpenAiJson()]);
    });

    test('工具列表为空时不发送 tools 字段', () async {
      final (client, adapter) = build(
        respond: (options) =>
            _jsonResponse(<String, Object?>{'choices': <Object?>[]}, 200),
      );

      await client.complete(messages: const <Map<String, Object?>>[]);

      final body = adapter.lastOptions!.data! as Map<String, Object?>;
      expect(body.containsKey('tools'), isFalse);
    });

    test('模型不支持工具调用时不发送 tools 字段', () async {
      final (client, adapter) = build(
        config: const AiEndpointConfig(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'sk-test',
          model: 'no-tools',
          supportsToolCalling: false,
        ),
        respond: (options) =>
            _jsonResponse(<String, Object?>{'choices': <Object?>[]}, 200),
      );

      await client.complete(
        messages: const <Map<String, Object?>>[],
        tools: const <AiToolDefinition>[
          AiToolDefinition(name: 'query', description: '查询'),
        ],
      );

      final body = adapter.lastOptions!.data! as Map<String, Object?>;
      expect(body.containsKey('tools'), isFalse);
    });

    test('config 暴露当前配置', () {
      final (client, _) = build(
        config: _defaultConfig,
        respond: (options) => _jsonResponse(<String, Object?>{}, 200),
      );

      expect(client.config.model, 'test-model');
      expect(client.config.baseUrl, 'https://api.example.com/v1');
      expect(client.config.apiKey, 'sk-test');
    });

    test('401 与 403 映射为鉴权失败', () async {
      for (final status in <int>[401, 403]) {
        final (client, _) = build(
          respond: (options) => _jsonResponse(<String, Object?>{}, status),
        );

        final result = await client.complete(messages: const <Map<String, Object?>>[]);

        expect(result.failureOrNull!.kind, FailureKind.authentication);
        expect(result.failureOrNull!.code, 'ai.unauthorized');
        expect(result.failureOrNull!.isRetryable, isFalse);
      }
    });

    test('429 映射为可重试的限流失败', () async {
      final (client, _) = build(
        respond: (options) => _jsonResponse(<String, Object?>{}, 429),
      );

      final result = await client.complete(messages: const <Map<String, Object?>>[]);

      expect(result.failureOrNull!.kind, FailureKind.network);
      expect(result.failureOrNull!.code, 'ai.rate_limited');
      expect(result.failureOrNull!.isRetryable, isTrue);
    });

    test('5xx 带上 error.message 细节', () async {
      final (client, _) = build(
        respond: (options) => _jsonResponse(<String, Object?>{
          'error': <String, Object?>{'message': 'model overloaded'},
        }, 503),
      );

      final result = await client.complete(messages: const <Map<String, Object?>>[]);

      expect(result.failureOrNull!.kind, FailureKind.network);
      expect(result.failureOrNull!.code, 'ai.http_error');
      expect(result.failureOrNull!.message, contains('HTTP 503'));
      expect(result.failureOrNull!.message, contains('model overloaded'));
    });

    test('4xx 识别 MiniMax 的 base_resp.status_msg', () async {
      final (client, _) = build(
        respond: (options) => _jsonResponse(<String, Object?>{
          'base_resp': <String, Object?>{'status_msg': 'invalid params'},
        }, 400),
      );

      final result = await client.complete(messages: const <Map<String, Object?>>[]);

      expect(result.failureOrNull!.kind, FailureKind.unknown);
      expect(result.failureOrNull!.message, contains('invalid params'));
    });

    test('无法提取细节时只报告状态码', () async {
      final (client, _) = build(
        respond: (options) => _jsonResponse('plain text', 400),
      );

      final result = await client.complete(messages: const <Map<String, Object?>>[]);

      expect(result.failureOrNull!.message, 'AI 接口返回 HTTP 400');
    });

    test('网络异常映射为 network 失败并保留 cause', () async {
      final (client, _) = build(
        respond: (options) => throw DioException(
          requestOptions: options,
          type: DioExceptionType.receiveTimeout,
          message: '响应超时',
        ),
      );

      final result = await client.complete(messages: const <Map<String, Object?>>[]);

      expect(result.failureOrNull!.kind, FailureKind.network);
      expect(result.failureOrNull!.code, 'ai.network');
      expect(result.failureOrNull!.message, contains('响应超时'));
      expect(result.failureOrNull!.cause, isA<DioException>());
    });

    test('2xx 但报文缺 choices 时返回解析失败', () async {
      final (client, _) = build(
        respond: (options) => _jsonResponse(<String, Object?>{'id': 'x'}, 200),
      );

      final result = await client.complete(messages: const <Map<String, Object?>>[]);

      expect(result.failureOrNull!.kind, FailureKind.parsing);
      expect(result.failureOrNull!.code, 'ai.no_choices');
    });

    test('extraHeaders 会合并进请求头', () async {
      final (client, adapter) = build(
        config: const AiEndpointConfig(
          baseUrl: 'https://api.example.com/v1',
          apiKey: 'sk-test',
          model: 'm',
          extraHeaders: <String, String>{'X-Tenant': 't1'},
        ),
        respond: (options) =>
            _jsonResponse(<String, Object?>{'choices': <Object?>[]}, 200),
      );

      await client.complete(messages: const <Map<String, Object?>>[]);

      expect(adapter.lastOptions!.headers['X-Tenant'], 't1');
    });
  });

  group('imageContentParts', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('gluco_ai_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    File writeFile(String name, List<int> bytes) {
      final file = File('${tempDir.path}${Platform.pathSeparator}$name');
      file.writeAsBytesSync(bytes);
      return file;
    }

    test('把本地图片编码为 data URI 内容块', () async {
      final file = writeFile('meal.png', <int>[1, 2, 3]);

      final parts = await AiChatClient.imageContentParts(<String>[file.path]);

      expect(parts.length, 1);
      expect(parts.single['type'], 'image_url');
      final url = (parts.single['image_url']! as Map<String, Object?>)['url'];
      expect(url, 'data:image/png;base64,${base64Encode(<int>[1, 2, 3])}');
    });

    test('按扩展名推断 MIME 类型，未知扩展名按 jpeg', () async {
      final jpg = writeFile('a.jpg', <int>[1]);
      final gif = writeFile('b.gif', <int>[1]);
      final webp = writeFile('c.webp', <int>[1]);
      final heic = writeFile('d.heic', <int>[1]);
      final unknown = writeFile('e.bin', <int>[1]);

      final parts = await AiChatClient.imageContentParts(
        <String>[jpg.path, gif.path, webp.path, heic.path, unknown.path],
        limit: 5,
      );

      String urlOf(int index) =>
          (parts[index]['image_url']! as Map<String, Object?>)['url']! as String;

      expect(urlOf(0), startsWith('data:image/jpeg;base64,'));
      expect(urlOf(1), startsWith('data:image/gif;base64,'));
      expect(urlOf(2), startsWith('data:image/webp;base64,'));
      expect(urlOf(3), startsWith('data:image/heic;base64,'));
      expect(urlOf(4), startsWith('data:image/jpeg;base64,'));
    });

    test('不存在的文件被跳过而不是让整条消息失败', () async {
      final existing = writeFile('ok.png', <int>[9]);

      final parts = await AiChatClient.imageContentParts(<String>[
        '${tempDir.path}${Platform.pathSeparator}missing.png',
        existing.path,
      ]);

      expect(parts.length, 1);
      expect(
        (parts.single['image_url']! as Map<String, Object?>)['url'],
        startsWith('data:image/png;base64,'),
      );
    });

    test('超出 limit 的图片被丢弃', () async {
      final paths = <String>[
        for (var index = 0; index < 6; index++)
          writeFile('img$index.png', <int>[index]).path,
      ];

      final parts = await AiChatClient.imageContentParts(paths, limit: 2);

      expect(parts.length, 2);
      expect(
        (parts.last['image_url']! as Map<String, Object?>)['url'],
        'data:image/png;base64,${base64Encode(<int>[1])}',
      );
    });

    test('默认上限为 4 张', () async {
      final paths = <String>[
        for (var index = 0; index < 6; index++)
          writeFile('img$index.png', <int>[index]).path,
      ];

      expect(await AiChatClient.imageContentParts(paths), hasLength(4));
      expect(AiChatClient.maxImages, 4);
    });

    test('空输入返回空列表', () async {
      expect(await AiChatClient.imageContentParts(<String>[]), isEmpty);
    });
  });
}
