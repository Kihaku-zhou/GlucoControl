import 'dart:convert';

import '../../core/result.dart';

/// 一个可供模型调用的工具的定义。
///
/// [parameters] 是 JSON Schema 的 `object` 片段，直接透传给 OpenAI 兼容接口的
/// `tools[].function.parameters`；因此字段名与取值都必须是模型能理解的自然语言
/// 描述，而不是内部编码。
class AiToolDefinition {
  /// 构造工具定义。
  const AiToolDefinition({
    required this.name,
    required this.description,
    this.parameters = const <String, Object?>{
      'type': 'object',
      'properties': <String, Object?>{},
    },
  });

  /// 工具名。必须匹配 `^[a-zA-Z0-9_-]{1,64}$`，否则部分服务端会拒绝整个请求。
  final String name;

  /// 告诉模型「什么时候该用它、它返回什么」的说明。
  final String description;

  /// 参数的 JSON Schema。
  final Map<String, Object?> parameters;

  /// 转成 OpenAI 兼容接口要求的工具描述。
  Map<String, Object?> toOpenAiJson() => <String, Object?>{
        'type': 'function',
        'function': <String, Object?>{
          'name': name,
          'description': description,
          'parameters': parameters,
        },
      };

  @override
  String toString() => 'AiToolDefinition($name)';
}

/// 一个可被模型调用的工具。
///
/// 实现方负责把模型给出的 JSON 参数解析为强类型输入，并把结果整理成
/// 紧凑的 JSON——模型上下文有限，返回值应当是「结论 + 关键明细」而不是全量转储。
abstract interface class AiTool {
  /// 该工具对外暴露的定义。
  AiToolDefinition get definition;

  /// 执行工具。
  ///
  /// 参数缺失或不合法时应返回 [FailureKind.parsing] 失败，让模型看到可读的
  /// 错误说明并自行修正，而不是抛出异常中断整轮对话。
  Future<Result<Object?>> invoke(Map<String, Object?> arguments);
}

/// 模型发起的一次工具调用。
class AiToolInvocation {
  /// 构造调用请求。
  const AiToolInvocation({
    required this.id,
    required this.name,
    required this.argumentsJson,
  });

  /// 服务端分配的调用 id，回填结果时必须原样带回。
  final String id;

  /// 被调用的工具名。
  final String name;

  /// 模型给出的参数字符串。部分模型会返回空串表示无参数。
  final String argumentsJson;

  @override
  String toString() => 'AiToolInvocation($name#$id)';
}

/// 工具注册表。
///
/// 注册即生效：重复注册同名工具会覆盖旧实现，便于测试替换。
class AiToolRegistry {
  final Map<String, AiTool> _tools = <String, AiTool>{};

  /// 注册（或替换）一个工具。
  void register(AiTool tool) {
    _tools[tool.definition.name] = tool;
  }

  /// 批量注册。
  void registerAll(Iterable<AiTool> tools) {
    for (final tool in tools) {
      register(tool);
    }
  }

  /// 已注册的工具定义，顺序稳定以便测试与提示词缓存。
  List<AiToolDefinition> get definitions => _tools.values
      .map((tool) => tool.definition)
      .toList(growable: false)
    ..sort((a, b) => a.name.compareTo(b.name));

  /// 是否注册了同名工具。
  bool contains(String name) => _tools.containsKey(name);

  /// 已注册的工具名。
  Iterable<String> get names => _tools.keys;

  /// 执行一次调用。
  ///
  /// 未注册的工具名返回 [FailureKind.unknown] 失败；模型有时会凭记忆调用不存在
  /// 的工具，把这件事作为可读结果返回比中断对话更有用。
  Future<Result<Object?>> invoke(String name, Map<String, Object?> arguments) {
    final tool = _tools[name];
    if (tool == null) {
      return Future.value(Err<Object?>(AppFailure(
        kind: FailureKind.unknown,
        message: '不存在名为 $name 的工具，可用工具：${_tools.keys.join('、')}',
        code: 'ai_tool.unknown',
      )));
    }
    return tool.invoke(arguments);
  }
}

/// 解析模型给出的参数 JSON。
///
/// 模型偶尔会返回空串、`null` 字面量或带尾随逗号的片段；这些都属于可恢复的
/// 输入问题，返回空映射让工具走「使用默认值」或「参数缺失」的分支。
Map<String, Object?> parseToolArguments(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty || trimmed == 'null') return const <String, Object?>{};
  try {
    final decoded = decodeJsonObject(trimmed);
    return decoded ?? const <String, Object?>{};
  } on FormatException {
    return const <String, Object?>{};
  }
}

/// 把 JSON 解析成字符串键的对象；不是对象时返回 null。
///
/// 单独抽出是为了让参数解析与结果解析共用同一套容错规则。
Map<String, Object?>? decodeJsonObject(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is Map) {
    return decoded.map((key, value) => MapEntry(key.toString(), value));
  }
  return null;
}
