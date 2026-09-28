import 'dart:convert';

import '../../core/result.dart';
import 'ai_chat_client.dart';
import 'ai_tool.dart';

/// 一次工具调用的可追溯记录。
///
/// 界面用它展示「AI 这次查了什么」，让结论可以被复核——这是把「模型凭摘要
/// 猜测」换成「模型按需取数」之后必须补上的透明度。
class AiToolTrace {
  /// 构造调用记录。
  const AiToolTrace({
    required this.name,
    required this.arguments,
    required this.succeeded,
    this.error,
    this.resultPreview = '',
  });

  /// 被调用的工具名。
  final String name;

  /// 模型给出的参数。
  final Map<String, Object?> arguments;

  /// 是否执行成功。
  final bool succeeded;

  /// 失败原因。
  final String? error;

  /// 结果摘要，用于界面展示。
  final String resultPreview;

  /// 转为便于写入会话记录或日志的 JSON。
  Map<String, Object?> toJson() => <String, Object?>{
        'tool': name,
        'arguments': arguments,
        'succeeded': succeeded,
        if (error != null) 'error': error,
        if (resultPreview.isNotEmpty) 'preview': resultPreview,
      };

  @override
  String toString() => 'AiToolTrace($name, ok=$succeeded)';
}

/// 助手一次回复的完整结果。
class HealthAssistantTurn {
  /// 构造回复。
  const HealthAssistantTurn({required this.text, this.toolTraces = const []});

  /// 面向用户的正文。
  final String text;

  /// 本轮发生的工具调用，按发生顺序。
  final List<AiToolTrace> toolTraces;

  /// 本轮是否调用过工具。
  bool get usedTools => toolTraces.isNotEmpty;
}

/// 带工具调用的健康助手。
///
/// 与旧实现的关键区别：不再把全部健康数据拼成一大段文本塞进系统提示，而是
/// 把可用的查询能力注册成工具，让模型按问题自己决定查什么。这样做的收益是
/// 上下文占用与数据量解耦、结论可追溯到具体查询，并且新增数据源时只要注册
/// 新工具，提示词不必修改。
class HealthAssistant {
  /// 构造助手。
  HealthAssistant({
    required AiChatClient client,
    required AiToolRegistry tools,
    this.maxToolRounds = 6,
  })  : _client = client,
        _tools = tools;

  /// 单轮对话中允许的最大工具调用轮数。
  ///
  /// 取值偏小而明确：模型陷入反复查询时应当在有限步内停下来给出部分结论，
  /// 而不是无限消耗额度。
  final int maxToolRounds;

  final AiChatClient _client;
  final AiToolRegistry _tools;

  /// 当前注册的工具定义。
  List<AiToolDefinition> get toolDefinitions => _tools.definitions;

  /// 生成系统提示。
  ///
  /// 每次调用都重新生成，因为提示里包含当前时间——模型需要「今天是几号」
  /// 才能把「最近一周」换算成具体区间。
  String buildSystemPrompt({DateTime? now}) {
    final timestamp = now ?? DateTime.now();
    final toolList = _tools.definitions
        .map((tool) => '- `${tool.name}`：${tool.description}')
        .join('\n');

    return '''
你是 GlucoControl 的健康数据助手，帮助用户理解自己的血糖、饮食、运动、体测与睡眠数据。

## 当前时间
${timestamp.toIso8601String()}（用户本地时间）。把「最近一周」「上个月」这类说法换算成具体日期时以此为准。

## 数据来源
用户的数据来自本应用录入，以及他授权接入的外部应用：华为运动健康、Android Health Connect、硅基轻享（经 Nightscout）、iGPSPORT、Keep、训记。每条记录都带 `source` 字段标明来源。
**不要假设数据是完整的**：某个来源可能未接入、未授权或同步失败。当用户的结论依赖某个来源时，先用 `list_data_sources` 确认它的状态，并在回答中说明数据覆盖情况。

## 工具使用
你可以调用以下工具取数，而不是凭空推测：
$toolList

工作方式：
1. 先判断问题需要哪些数据、覆盖多长时间，再选择工具。
2. 需要多个角度时（例如「血糖为什么波动」）组合调用：先看时间线，再对可疑时刻用 `glucose_context` 找前后事件。
3. 数据不足时如实说明缺少什么，并告诉用户怎样补齐（例如导入导出文件、完成授权）。
4. 得到数据后给出结论，并指出结论依赖的样本量与时间范围。

## 回答要求
- 用中文回答，结构清晰，先给结论再给依据。
- 引用具体数字时带上单位和时间；不要虚构任何未从工具得到的数值。
- 区分「数据支持的观察」与「一般性健康建议」，不要把相关性说成因果。
- 涉及用药、胰岛素剂量调整、低血糖处置等问题时，说明这属于医疗决策，需要咨询医生；不要给出具体剂量。
- 本应用只做数据记录与展示，不能作为诊断依据。
''';
  }

  /// 发起一轮对话。
  ///
  /// [history] 是完整的消息数组（含 system），格式与接口一致。返回的
  /// [HealthAssistantTurn.text] 是最终正文；中间的工具调用记录在
  /// [HealthAssistantTurn.toolTraces] 中。
  Future<Result<HealthAssistantTurn>> send({
    required List<Map<String, Object?>> history,
    List<String> imagePaths = const <String>[],
  }) async {
    final messages = <Map<String, Object?>>[...history];
    final traces = <AiToolTrace>[];

    if (imagePaths.isNotEmpty && _client.config.supportsVision) {
      await _attachImages(messages, imagePaths);
    }

    for (var round = 0; round <= maxToolRounds; round++) {
      final isLastRound = round == maxToolRounds;
      final reply = await _client.complete(
        messages: messages,
        // 最后一轮不再提供工具，促使模型基于已有数据给出结论。
        tools: isLastRound
            ? const <AiToolDefinition>[]
            : _tools.definitions,
      );
      if (!reply.isOk) return Err(reply.failureOrNull!);

      final parsed = reply.requireValue();
      if (!parsed.wantsTools) {
        return Ok(HealthAssistantTurn(
          text: parsed.content ?? '（模型没有返回内容）',
          toolTraces: traces,
        ));
      }

      messages.add(<String, Object?>{
        'role': 'assistant',
        'content': parsed.content,
        'tool_calls': parsed.toolCalls
            .map((call) => <String, Object?>{
                  'id': call.id,
                  'type': 'function',
                  'function': <String, Object?>{
                    'name': call.name,
                    'arguments': call.argumentsJson,
                  },
                })
            .toList(),
      });

      for (final call in parsed.toolCalls) {
        final outcome = await _execute(call);
        traces.add(outcome.trace);
        messages.add(<String, Object?>{
          'role': 'tool',
          'tool_call_id': call.id,
          'content': outcome.payload,
        });
      }
    }

    // 只有在模型持续请求工具时才会走到这里。
    return Ok(HealthAssistantTurn(
      text: '数据查询步骤过多，已停止。请把问题拆得更具体一些再试。',
      toolTraces: traces,
    ));
  }

  /// 执行一次工具调用并生成回填给模型的内容。
  Future<({AiToolTrace trace, String payload})> _execute(
      AiToolInvocation call) async {
    final arguments = parseToolArguments(call.argumentsJson);
    final result = await _tools.invoke(call.name, arguments);

    if (!result.isOk) {
      final failure = result.failureOrNull!;
      return (
        trace: AiToolTrace(
          name: call.name,
          arguments: arguments,
          succeeded: false,
          error: failure.message,
        ),
        payload: jsonEncode(<String, Object?>{
          'error': failure.message,
          'code': failure.code,
        }),
      );
    }

    final encoded = _encode(result.requireValue());
    return (
      trace: AiToolTrace(
        name: call.name,
        arguments: arguments,
        succeeded: true,
        resultPreview: _preview(encoded),
      ),
      payload: encoded,
    );
  }

  /// 把工具结果编码为 JSON 字符串。
  static String _encode(Object? value) {
    try {
      return jsonEncode(value);
    } on JsonUnsupportedObjectError {
      // 工具返回了不可序列化的对象，属于实现缺陷；回退为文本以免中断对话。
      return jsonEncode(<String, Object?>{'result': value.toString()});
    }
  }

  /// 截取结果摘要供界面展示。
  static String _preview(String encoded) => encoded.length <= 400
      ? encoded
      : '${encoded.substring(0, 400)}…（共 ${encoded.length} 字符）';

  /// 把图片附加到最后一条用户消息上。
  static Future<void> _attachImages(
    List<Map<String, Object?>> messages,
    List<String> imagePaths,
  ) async {
    final index = messages.lastIndexWhere((m) => m['role'] == 'user');
    if (index < 0) return;

    final parts = await AiChatClient.imageContentParts(imagePaths);
    if (parts.isEmpty) return;

    final original = messages[index]['content'];
    final text = original is String ? original : '';
    messages[index] = <String, Object?>{
      'role': 'user',
      'content': <Map<String, Object?>>[
        if (text.isNotEmpty) <String, Object?>{'type': 'text', 'text': text},
        ...parts,
      ],
    };
  }
}
