/// `health_assistant.dart` 的单元测试。
///
/// 用一个覆写 `complete` 的假 [AiChatClient] 驱动 [HealthAssistant.send] 的工具
/// 循环：验证工具确实被执行、回填消息的 role/tool_call_id 正确、toolTraces 记录
/// 完整、工具失败时不抛异常而是回填 error JSON，以及达到 maxToolRounds 能收敛。
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:glucocontrol/core/result.dart';
import 'package:glucocontrol/services/ai/ai_chat_client.dart';
import 'package:glucocontrol/services/ai/ai_tool.dart';
import 'package:glucocontrol/services/ai/health_assistant.dart';

/// 记录每次请求并把预设回复按顺序回放的假客户端。
class _ScriptedChatClient extends AiChatClient {
  _ScriptedChatClient({
    super.config = _defaultConfig,
    required this.replies,
  });

  final List<Result<AiChatReply>> replies;

  final List<List<Map<String, Object?>>> requests =
      <List<Map<String, Object?>>>[];
  final List<List<AiToolDefinition>> toolsPerRequest =
      <List<AiToolDefinition>>[];

  @override
  Future<Result<AiChatReply>> complete({
    required List<Map<String, Object?>> messages,
    List<AiToolDefinition> tools = const <AiToolDefinition>[],
    double temperature = 0.3,
    int maxTokens = 2000,
  }) async {
    requests.add(_snapshot(messages));
    toolsPerRequest.add(List<AiToolDefinition>.of(tools));
    final index = requests.length - 1;
    return replies[index < replies.length ? index : replies.length - 1];
  }

  /// 深拷贝消息，避免后续轮次的改动影响已记录的断言依据。
  static List<Map<String, Object?>> _snapshot(
          List<Map<String, Object?>> messages) =>
      (jsonDecode(jsonEncode(messages)) as List<dynamic>)
          .map((item) => (item as Map<String, dynamic>).cast<String, Object?>())
          .toList();
}

const AiEndpointConfig _defaultConfig = AiEndpointConfig(
  baseUrl: 'https://api.example.com/v1',
  apiKey: 'sk-test',
  model: 'test-model',
);

const AiEndpointConfig _visionConfig = AiEndpointConfig(
  baseUrl: 'https://api.example.com/v1',
  apiKey: 'sk-test',
  model: 'gpt-4o',
  supportsVision: true,
);

/// 记录入参并回放预设结果的假工具。
class _StubTool implements AiTool {
  _StubTool(this.definition, {this.result = const Ok<Object?>(null)});

  @override
  final AiToolDefinition definition;

  Result<Object?> result;
  final List<Map<String, Object?>> invocations = <Map<String, Object?>>[];

  @override
  Future<Result<Object?>> invoke(Map<String, Object?> arguments) async {
    invocations.add(arguments);
    return result;
  }
}

const AiToolDefinition _glucoseTool = AiToolDefinition(
  name: 'query_glucose',
  description: '查询指定时间段的血糖读数',
);

AiChatReply _toolCallReply({
  String id = 'call_1',
  String name = 'query_glucose',
  String arguments = '{"days":7}',
  String? content,
}) =>
    AiChatReply(
      content: content,
      toolCalls: <AiToolInvocation>[
        AiToolInvocation(id: id, name: name, argumentsJson: arguments),
      ],
    );

List<Map<String, Object?>> _history() => <Map<String, Object?>>[
      <String, Object?>{'role': 'system', 'content': '你是健康助手'},
      <String, Object?>{'role': 'user', 'content': '最近血糖怎么样'},
    ];

void main() {
  group('buildSystemPrompt', () {
    test('包含工具清单与请求时刻', () {
      final assistant = HealthAssistant(
        client: _ScriptedChatClient(
          replies: const <Result<AiChatReply>>[Ok<AiChatReply>(AiChatReply())],
        ),
        tools: AiToolRegistry()..register(_StubTool(_glucoseTool)),
      );

      final prompt =
          assistant.buildSystemPrompt(now: DateTime(2026, 3, 14, 9, 30));

      expect(prompt, contains('2026-03-14T09:30:00.000'));
      expect(prompt, contains('- `query_glucose`：查询指定时间段的血糖读数'));
      expect(prompt, contains('用中文回答'));
    });

    test('没有注册工具时工具清单为空', () {
      final assistant = HealthAssistant(
        client: _ScriptedChatClient(
          replies: const <Result<AiChatReply>>[Ok<AiChatReply>(AiChatReply())],
        ),
        tools: AiToolRegistry(),
      );

      final prompt = assistant.buildSystemPrompt(now: DateTime(2026, 3, 14));

      expect(prompt, isNot(contains('query_glucose')));
      expect(prompt, contains('你可以调用以下工具取数'));
    });

    test('toolDefinitions 暴露按名字排序的工具定义', () {
      final assistant = HealthAssistant(
        client: _ScriptedChatClient(
          replies: const <Result<AiChatReply>>[Ok<AiChatReply>(AiChatReply())],
        ),
        tools: AiToolRegistry()
          ..register(_StubTool(const AiToolDefinition(
              name: 'zeta', description: 'z')))
          ..register(_StubTool(_glucoseTool)),
      );

      expect(
        assistant.toolDefinitions.map((definition) => definition.name).toList(),
        <String>['query_glucose', 'zeta'],
      );
    });
  });

  group('send 的工具循环', () {
    test('执行工具并把 assistant/tool 消息回填给模型', () async {
      final tool = _StubTool(
        _glucoseTool,
        result: const Ok<Object?>(<String, Object?>{'count': 12, 'meanMmolPerL': 6.2}),
      );
      final client = _ScriptedChatClient(replies: <Result<AiChatReply>>[
        const Ok<AiChatReply>(AiChatReply(
          toolCalls: <AiToolInvocation>[
            AiToolInvocation(
                id: 'call_1', name: 'query_glucose', argumentsJson: '{"days":7}'),
          ],
        )),
        const Ok<AiChatReply>(AiChatReply(content: '最近 7 天平均 6.2 mmol/L')),
      ]);
      final history = _history();
      final assistant = HealthAssistant(
        client: client,
        tools: AiToolRegistry()..register(tool),
      );

      final turn = (await assistant.send(history: history)).requireValue();

      expect(turn.text, '最近 7 天平均 6.2 mmol/L');
      expect(turn.usedTools, isTrue);
      expect(tool.invocations.single, <String, Object?>{'days': 7});
      expect(client.requests.length, 2);

      final secondRequest = client.requests[1];
      expect(secondRequest.length, 4);
      expect(secondRequest[0]['role'], 'system');
      expect(secondRequest[1]['role'], 'user');

      final assistantMessage = secondRequest[2];
      expect(assistantMessage['role'], 'assistant');
      final toolCalls = assistantMessage['tool_calls']! as List<Object?>;
      final firstCall = toolCalls.single as Map<String, Object?>;
      expect(firstCall['id'], 'call_1');
      expect(firstCall['type'], 'function');
      final function = firstCall['function']! as Map<String, Object?>;
      expect(function['name'], 'query_glucose');
      expect(function['arguments'], '{"days":7}');

      final toolMessage = secondRequest[3];
      expect(toolMessage['role'], 'tool');
      expect(toolMessage['tool_call_id'], 'call_1');
      expect(toolMessage['content'],
          jsonEncode(<String, Object?>{'count': 12, 'meanMmolPerL': 6.2}));
    });

    test('toolTraces 记录调用参数、成功标记与结果摘要', () async {
      final tool = _StubTool(
        _glucoseTool,
        result: const Ok<Object?>(<String, Object?>{'count': 12}),
      );
      final client = _ScriptedChatClient(replies: <Result<AiChatReply>>[
        Ok<AiChatReply>(_toolCallReply(arguments: '{"days":30}')),
        const Ok<AiChatReply>(AiChatReply(content: '结论')),
      ]);
      final assistant = HealthAssistant(
        client: client,
        tools: AiToolRegistry()..register(tool),
      );

      final turn = (await assistant.send(history: _history())).requireValue();

      final trace = turn.toolTraces.single;
      expect(trace.name, 'query_glucose');
      expect(trace.arguments, <String, Object?>{'days': 30});
      expect(trace.succeeded, isTrue);
      expect(trace.error, isNull);
      expect(trace.resultPreview, jsonEncode(<String, Object?>{'count': 12}));
      expect(trace.toJson(), <String, Object?>{
        'tool': 'query_glucose',
        'arguments': <String, Object?>{'days': 30},
        'succeeded': true,
        'preview': '{"count":12}',
      });
      expect(trace.toString(), 'AiToolTrace(query_glucose, ok=true)');
    });

    test('未到上限的每一轮都带着工具定义请求模型', () async {
      final tool = _StubTool(_glucoseTool);
      final client = _ScriptedChatClient(replies: <Result<AiChatReply>>[
        Ok<AiChatReply>(_toolCallReply()),
        const Ok<AiChatReply>(AiChatReply(content: '结论')),
      ]);
      final assistant = HealthAssistant(
        client: client,
        tools: AiToolRegistry()..register(tool),
        maxToolRounds: 4,
      );

      await assistant.send(history: _history());

      expect(client.toolsPerRequest[0].single.name, 'query_glucose');
      expect(client.toolsPerRequest[1].single.name, 'query_glucose');
    });

    test('一次回复中的多个工具调用全部执行并按顺序回填', () async {
      final glucose = _StubTool(
        _glucoseTool,
        result: const Ok<Object?>('g'),
      );
      final meals = _StubTool(
        const AiToolDefinition(name: 'query_meals', description: '查询饮食'),
        result: const Ok<Object?>('m'),
      );
      final client = _ScriptedChatClient(replies: <Result<AiChatReply>>[
        const Ok<AiChatReply>(AiChatReply(
          toolCalls: <AiToolInvocation>[
            AiToolInvocation(
                id: 'c1', name: 'query_glucose', argumentsJson: '{"days":1}'),
            AiToolInvocation(
                id: 'c2', name: 'query_meals', argumentsJson: '{"days":1}'),
          ],
        )),
        const Ok<AiChatReply>(AiChatReply(content: '结论')),
      ]);
      final assistant = HealthAssistant(
        client: client,
        tools: AiToolRegistry()
          ..register(glucose)
          ..register(meals),
      );

      final turn = (await assistant.send(history: _history())).requireValue();

      expect(turn.toolTraces.length, 2);
      expect(
        turn.toolTraces.map((trace) => trace.name).toList(),
        <String>['query_glucose', 'query_meals'],
      );
      final secondRequest = client.requests[1];
      expect(secondRequest.length, 5);
      expect(secondRequest[3]['tool_call_id'], 'c1');
      expect(secondRequest[4]['tool_call_id'], 'c2');
      expect(secondRequest[3]['content'], jsonEncode('g'));
      expect(secondRequest[4]['content'], jsonEncode('m'));
    });
  });

  group('send 的失败处理', () {
    test('工具返回失败时回填带 error 的 JSON 而不抛异常', () async {
      final tool = _StubTool(
        _glucoseTool,
        result: const Err<Object?>(AppFailure(
          kind: FailureKind.parsing,
          message: 'days 必须是正整数',
          code: 'ai_tool.bad_arguments',
        )),
      );
      final client = _ScriptedChatClient(replies: <Result<AiChatReply>>[
        Ok<AiChatReply>(_toolCallReply(arguments: '{"days":"七"}')),
        const Ok<AiChatReply>(AiChatReply(content: '参数不对，我改用默认值')),
      ]);
      final assistant = HealthAssistant(
        client: client,
        tools: AiToolRegistry()..register(tool),
      );

      final turn = (await assistant.send(history: _history())).requireValue();

      expect(turn.text, '参数不对，我改用默认值');
      expect(turn.toolTraces.single.succeeded, isFalse);
      expect(turn.toolTraces.single.error, 'days 必须是正整数');
      expect(turn.toolTraces.single.resultPreview, isEmpty);

      final toolMessage = client.requests[1][3];
      expect(toolMessage['role'], 'tool');
      expect(toolMessage['tool_call_id'], 'call_1');
      expect(jsonDecode(toolMessage['content']! as String), <String, Object?>{
        'error': 'days 必须是正整数',
        'code': 'ai_tool.bad_arguments',
      });
    });

    test('结果摘要超过 400 字符时被截断并标注总长度', () async {
      final longValue = 'x' * 500;
      final tool = _StubTool(_glucoseTool, result: Ok<Object?>(longValue));
      final client = _ScriptedChatClient(replies: <Result<AiChatReply>>[
        Ok<AiChatReply>(_toolCallReply()),
        const Ok<AiChatReply>(AiChatReply(content: '结论')),
      ]);
      final assistant = HealthAssistant(
        client: client,
        tools: AiToolRegistry()..register(tool),
      );

      final turn = (await assistant.send(history: _history())).requireValue();

      final encoded = jsonEncode(longValue);
      final trace = turn.toolTraces.single;
      expect(trace.resultPreview,
          '${encoded.substring(0, 400)}…（共 ${encoded.length} 字符）');
      expect(trace.resultPreview.endsWith('…（共 502 字符）'), isTrue);
      // 回填给模型的仍是完整结果，只有界面摘要被截断。
      expect(client.requests[1][3]['content'], encoded);
      expect(trace.toJson()['preview'], trace.resultPreview);
    });

    test('调用未注册的工具时同样以 error JSON 回填', () async {
      final client = _ScriptedChatClient(replies: <Result<AiChatReply>>[
        Ok<AiChatReply>(_toolCallReply(name: 'ghost_tool', arguments: '{}')),
        const Ok<AiChatReply>(AiChatReply(content: '没有这个工具')),
      ]);
      final assistant = HealthAssistant(
        client: client,
        tools: AiToolRegistry()..register(_StubTool(_glucoseTool)),
      );

      final turn = (await assistant.send(history: _history())).requireValue();

      final trace = turn.toolTraces.single;
      expect(trace.succeeded, isFalse);
      expect(trace.error, contains('不存在名为 ghost_tool 的工具'));
      expect(trace.error, contains('query_glucose'));

      final payload =
          jsonDecode(client.requests[1][3]['content']! as String) as Map<String, Object?>;
      expect(payload['code'], 'ai_tool.unknown');
      expect(payload['error'], contains('ghost_tool'));
    });

    test('模型调用失败时把失败透传给调用方', () async {
      final client = _ScriptedChatClient(replies: const <Result<AiChatReply>>[
        Err<AiChatReply>(AppFailure(
          kind: FailureKind.network,
          message: 'AI 接口限流，请稍后重试',
          code: 'ai.rate_limited',
        )),
      ]);
      final assistant = HealthAssistant(
        client: client,
        tools: AiToolRegistry(),
      );

      final result = await assistant.send(history: _history());

      expect(result.isOk, isFalse);
      expect(result.failureOrNull!.kind, FailureKind.network);
      expect(result.failureOrNull!.code, 'ai.rate_limited');
      expect(client.requests.length, 1);
    });

    test('第二轮模型失败时把失败透传且保留已完成轨迹', () async {
      final client = _ScriptedChatClient(replies: <Result<AiChatReply>>[
        Ok<AiChatReply>(_toolCallReply()),
        const Err<AiChatReply>(AppFailure(
          kind: FailureKind.network,
          message: 'AI 接口限流，请稍后重试',
        )),
      ]);
      final assistant = HealthAssistant(
        client: client,
        tools: AiToolRegistry()..register(_StubTool(_glucoseTool)),
      );

      final result = await assistant.send(history: _history());

      expect(result.isOk, isFalse);
      expect(client.requests.length, 2);
    });

    test('模型既没有正文也没有工具调用时给出占位文本', () async {
      final client = _ScriptedChatClient(replies: const <Result<AiChatReply>>[
        Ok<AiChatReply>(AiChatReply()),
      ]);
      final assistant = HealthAssistant(
        client: client,
        tools: AiToolRegistry(),
      );

      final turn = (await assistant.send(history: _history())).requireValue();

      expect(turn.text, '（模型没有返回内容）');
      expect(turn.usedTools, isFalse);
      expect(turn.toolTraces, isEmpty);
    });

    test('工具返回不可 JSON 序列化的对象时回退为文本而不是中断', () async {
      final tool = _StubTool(_glucoseTool, result: Ok<Object?>(Object()));
      final client = _ScriptedChatClient(replies: <Result<AiChatReply>>[
        Ok<AiChatReply>(_toolCallReply()),
        const Ok<AiChatReply>(AiChatReply(content: '拿到数据了')),
      ]);
      final assistant = HealthAssistant(
        client: client,
        tools: AiToolRegistry()..register(tool),
      );

      final turn = (await assistant.send(history: _history())).requireValue();

      expect(turn.text, '拿到数据了');
      expect(turn.toolTraces.single.succeeded, isTrue);
      final payload = jsonDecode(client.requests[1][3]['content']! as String)
          as Map<String, Object?>;
      expect(payload['result'], startsWith('Instance of'));
    });
  });

  group('send 的轮数上限', () {
    test('达到 maxToolRounds 时停止并返回提示文本', () async {
      final tool = _StubTool(_glucoseTool, result: const Ok<Object?>('ok'));
      final client = _ScriptedChatClient(replies: <Result<AiChatReply>>[
        Ok<AiChatReply>(_toolCallReply(id: 'c0')),
        Ok<AiChatReply>(_toolCallReply(id: 'c1')),
        Ok<AiChatReply>(_toolCallReply(id: 'c2')),
        Ok<AiChatReply>(_toolCallReply(id: 'c3')),
      ]);
      final assistant = HealthAssistant(
        client: client,
        tools: AiToolRegistry()..register(tool),
        maxToolRounds: 3,
      );

      final turn = (await assistant.send(history: _history())).requireValue();

      // 0..maxToolRounds 共 4 次请求，最后一轮不再提供工具。
      expect(client.requests.length, 4);
      expect(client.toolsPerRequest[3], isEmpty);
      expect(client.toolsPerRequest[2], isNotEmpty);
      expect(turn.text, '数据查询步骤过多，已停止。请把问题拆得更具体一些再试。');
      // 最后一轮虽然不再提供工具，模型若仍返回 tool_calls 依旧会被执行。
      expect(turn.toolTraces.length, 4);
      expect(tool.invocations.length, 4);
    });

    test('maxToolRounds 为 0 时只请求一次且不提供工具', () async {
      final tool = _StubTool(_glucoseTool);
      final client = _ScriptedChatClient(replies: <Result<AiChatReply>>[
        Ok<AiChatReply>(_toolCallReply()),
      ]);
      final assistant = HealthAssistant(
        client: client,
        tools: AiToolRegistry()..register(tool),
        maxToolRounds: 0,
      );

      final turn = (await assistant.send(history: _history())).requireValue();

      expect(client.requests.length, 1);
      expect(client.toolsPerRequest.single, isEmpty);
      expect(turn.text, contains('数据查询步骤过多'));
      expect(tool.invocations.length, 1);
      expect(turn.toolTraces.length, 1);
    });
  });

  group('send 的图片附加', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('gluco_assistant_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('支持 vision 时把图片作为内容块附加到最后一条用户消息', () async {
      final file = File('${tempDir.path}${Platform.pathSeparator}meal.png')
        ..writeAsBytesSync(<int>[1, 2, 3]);
      final client = _ScriptedChatClient(
        config: _visionConfig,
        replies: const <Result<AiChatReply>>[
          Ok<AiChatReply>(AiChatReply(content: '这是一份高碳水餐')),
        ],
      );
      final assistant = HealthAssistant(
        client: client,
        tools: AiToolRegistry(),
      );
      final history = <Map<String, Object?>>[
        <String, Object?>{'role': 'system', 'content': '你是健康助手'},
        <String, Object?>{'role': 'user', 'content': '早饭吃了什么'},
        <String, Object?>{'role': 'assistant', 'content': '请提供照片'},
        <String, Object?>{'role': 'user', 'content': '这是照片'},
      ];

      await assistant.send(history: history, imagePaths: <String>[file.path]);

      final content = client.requests[0][3]['content']! as List<Object?>;
      expect(content.length, 2);
      expect(content.first, <String, Object?>{'type': 'text', 'text': '这是照片'});
      final imagePart = content.last as Map<String, Object?>;
      expect(imagePart['type'], 'image_url');
      expect(
        (imagePart['image_url']! as Map<String, Object?>)['url'],
        'data:image/png;base64,${base64Encode(<int>[1, 2, 3])}',
      );
      // 调用方传入的历史不被就地改写。
      expect(history[3]['content'], '这是照片');
    });

    test('模型不支持 vision 时忽略图片参数', () async {
      final file = File('${tempDir.path}${Platform.pathSeparator}meal.png')
        ..writeAsBytesSync(<int>[1]);
      final client = _ScriptedChatClient(replies: const <Result<AiChatReply>>[
        Ok<AiChatReply>(AiChatReply(content: '好的')),
      ]);
      final assistant = HealthAssistant(
        client: client,
        tools: AiToolRegistry(),
      );

      await assistant.send(
        history: _history(),
        imagePaths: <String>[file.path],
      );

      expect(client.requests[0][1]['content'], '最近血糖怎么样');
    });

    test('图片文件不存在时保持文本消息不变', () async {
      final client = _ScriptedChatClient(
        config: _visionConfig,
        replies: const <Result<AiChatReply>>[
          Ok<AiChatReply>(AiChatReply(content: '好的')),
        ],
      );
      final assistant = HealthAssistant(
        client: client,
        tools: AiToolRegistry(),
      );

      await assistant.send(
        history: _history(),
        imagePaths: <String>['${tempDir.path}${Platform.pathSeparator}missing.png'],
      );

      expect(client.requests[0][1]['content'], '最近血糖怎么样');
    });
  });

  group('HealthAssistantTurn 与 AiToolTrace', () {
    test('usedTools 由轨迹是否为空决定', () {
      expect(const HealthAssistantTurn(text: 'x').usedTools, isFalse);
      expect(
        const HealthAssistantTurn(
          text: 'x',
          toolTraces: <AiToolTrace>[
            AiToolTrace(
              name: 'query',
              arguments: <String, Object?>{},
              succeeded: true,
            ),
          ],
        ).usedTools,
        isTrue,
      );
    });

    test('失败的轨迹 JSON 带 error 且不带 preview', () {
      const trace = AiToolTrace(
        name: 'query',
        arguments: <String, Object?>{'days': 7},
        succeeded: false,
        error: '参数错误',
      );

      expect(trace.toJson(), <String, Object?>{
        'tool': 'query',
        'arguments': <String, Object?>{'days': 7},
        'succeeded': false,
        'error': '参数错误',
      });
      expect(trace.toString(), 'AiToolTrace(query, ok=false)');
    });
  });
}
