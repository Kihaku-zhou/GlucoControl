/// `ai_tool.dart` 的单元测试。
///
/// 覆盖 [parseToolArguments] 与 [decodeJsonObject] 的容错解析、工具定义的
/// OpenAI 兼容结构，以及 [AiToolRegistry] 的注册/覆盖/排序/未知工具行为。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:glucocontrol/core/result.dart';
import 'package:glucocontrol/services/ai/ai_tool.dart';

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

void main() {
  group('parseToolArguments', () {
    test('空串与纯空白串解析为空映射', () {
      expect(parseToolArguments(''), isEmpty);
      expect(parseToolArguments('   '), isEmpty);
      expect(parseToolArguments('\n\t'), isEmpty);
    });

    test('字面量 null 解析为空映射', () {
      expect(parseToolArguments('null'), isEmpty);
      expect(parseToolArguments('  null  '), isEmpty);
    });

    test('非法 JSON 解析为空映射而不是抛异常', () {
      expect(parseToolArguments('{'), isEmpty);
      expect(parseToolArguments('{"a": 1,}'), isEmpty);
      expect(parseToolArguments("{'a': 1}"), isEmpty);
      expect(parseToolArguments('undefined'), isEmpty);
    });

    test('数组或标量 JSON 解析为空映射', () {
      expect(parseToolArguments('[1,2,3]'), isEmpty);
      expect(parseToolArguments('[]'), isEmpty);
      expect(parseToolArguments('"text"'), isEmpty);
      expect(parseToolArguments('42'), isEmpty);
      expect(parseToolArguments('true'), isEmpty);
    });

    test('合法对象被解析为字符串键映射', () {
      expect(parseToolArguments('{"days": 7, "kind": "glucose"}'),
          <String, Object?>{'days': 7, 'kind': 'glucose'});
      expect(parseToolArguments('  {"a": {"b": 1}}  '),
          <String, Object?>{
            'a': <String, Object?>{'b': 1},
          });
    });

    test('值为 null 的键被保留', () {
      final parsed = parseToolArguments('{"from": null}');

      expect(parsed.containsKey('from'), isTrue);
      expect(parsed['from'], isNull);
    });
  });

  group('decodeJsonObject', () {
    test('对象返回字符串键映射', () {
      expect(decodeJsonObject('{"a": 1}'), <String, Object?>{'a': 1});
      expect(decodeJsonObject('{}'), isEmpty);
    });

    test('非对象返回 null', () {
      expect(decodeJsonObject('[]'), isNull);
      expect(decodeJsonObject('"x"'), isNull);
      expect(decodeJsonObject('5'), isNull);
      expect(decodeJsonObject('null'), isNull);
    });

    test('非法 JSON 抛出 FormatException 由调用方兜底', () {
      expect(() => decodeJsonObject('{'), throwsFormatException);
    });
  });

  group('AiToolDefinition', () {
    test('转成 OpenAI 兼容的工具描述', () {
      const definition = AiToolDefinition(
        name: 'query_glucose',
        description: '查询指定时间段的血糖读数',
        parameters: <String, Object?>{
          'type': 'object',
          'properties': <String, Object?>{
            'days': <String, Object?>{'type': 'integer'},
          },
          'required': <String>['days'],
        },
      );

      expect(definition.toOpenAiJson(), <String, Object?>{
        'type': 'function',
        'function': <String, Object?>{
          'name': 'query_glucose',
          'description': '查询指定时间段的血糖读数',
          'parameters': <String, Object?>{
            'type': 'object',
            'properties': <String, Object?>{
              'days': <String, Object?>{'type': 'integer'},
            },
            'required': <String>['days'],
          },
        },
      });
      expect(definition.toString(), 'AiToolDefinition(query_glucose)');
    });

    test('未指定参数时给出空对象 schema', () {
      const definition = AiToolDefinition(name: 'ping', description: '连通性检查');

      expect(definition.parameters, <String, Object?>{
        'type': 'object',
        'properties': <String, Object?>{},
      });
    });
  });

  group('AiToolRegistry', () {
    AiToolDefinition definitionOf(String name) =>
        AiToolDefinition(name: name, description: '$name 的说明');

    test('注册后可按名字查到', () {
      final registry = AiToolRegistry();
      final tool = _StubTool(definitionOf('list_records'));

      registry.register(tool);

      expect(registry.contains('list_records'), isTrue);
      expect(registry.contains('missing'), isFalse);
      expect(registry.names, <String>['list_records']);
    });

    test('重复注册同名工具会覆盖旧实现', () async {
      final registry = AiToolRegistry();
      final first = _StubTool(
        definitionOf('query'),
        result: const Ok<Object?>('first'),
      );
      final second = _StubTool(
        definitionOf('query'),
        result: const Ok<Object?>('second'),
      );

      registry.register(first);
      registry.register(second);
      final result = await registry.invoke('query', const <String, Object?>{});

      expect(registry.definitions.length, 1);
      expect(result.requireValue(), 'second');
      expect(first.invocations, isEmpty);
      expect(second.invocations, hasLength(1));
    });

    test('definitions 按工具名升序排列', () {
      final registry = AiToolRegistry()
        ..registerAll(<AiTool>[
          _StubTool(definitionOf('zeta')),
          _StubTool(definitionOf('alpha')),
          _StubTool(definitionOf('mid')),
        ]);

      expect(
        registry.definitions.map((definition) => definition.name).toList(),
        <String>['alpha', 'mid', 'zeta'],
      );
    });

    test('definitions 返回的是快照，外部改动不影响注册表', () {
      final registry = AiToolRegistry()
        ..register(_StubTool(definitionOf('a')));

      final snapshot = registry.definitions;
      expect(() => snapshot.add(definitionOf('b')), throwsUnsupportedError);
      expect(registry.definitions, hasLength(1));
    });

    test('调用未注册的工具返回 unknown 失败并列出可用工具', () async {
      final registry = AiToolRegistry()
        ..register(_StubTool(definitionOf('a')))
        ..register(_StubTool(definitionOf('b')));

      final result = await registry.invoke('c', const <String, Object?>{});

      expect(result.isOk, isFalse);
      final failure = result.failureOrNull!;
      expect(failure.kind, FailureKind.unknown);
      expect(failure.code, 'ai_tool.unknown');
      expect(failure.message, contains('c'));
      expect(failure.message, contains('a'));
      expect(failure.message, contains('b'));
    });

    test('调用已注册工具时把参数原样转交', () async {
      final registry = AiToolRegistry();
      final tool = _StubTool(
        definitionOf('query'),
        result: const Ok<Object?>(<String, Object?>{'count': 3}),
      );
      registry.register(tool);

      final result = await registry.invoke(
        'query',
        const <String, Object?>{'days': 7},
      );

      expect(result.requireValue(), <String, Object?>{'count': 3});
      expect(tool.invocations.single, <String, Object?>{'days': 7});
    });

    test('工具的失败结果原样冒泡', () async {
      final registry = AiToolRegistry();
      registry.register(_StubTool(
        definitionOf('query'),
        result: const Err<Object?>(AppFailure(
          kind: FailureKind.parsing,
          message: 'days 必须是正整数',
          code: 'ai_tool.bad_arguments',
        )),
      ));

      final result = await registry.invoke('query', const <String, Object?>{});

      expect(result.failureOrNull!.kind, FailureKind.parsing);
      expect(result.failureOrNull!.code, 'ai_tool.bad_arguments');
    });

    test('空注册表的 definitions 与 names 均为空', () {
      final registry = AiToolRegistry();

      expect(registry.definitions, isEmpty);
      expect(registry.names, isEmpty);
    });
  });

  group('AiToolInvocation', () {
    test('原样保存服务端分配的调用信息', () {
      const invocation = AiToolInvocation(
        id: 'call_abc',
        name: 'query_glucose',
        argumentsJson: '{"days":7}',
      );

      expect(invocation.id, 'call_abc');
      expect(invocation.name, 'query_glucose');
      expect(invocation.argumentsJson, '{"days":7}');
      expect(invocation.toString(), 'AiToolInvocation(query_glucose#call_abc)');
    });
  });
}
