import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/result.dart';
import 'ai_tool.dart';

/// OpenAI 兼容接口的连接配置。
///
/// 用户填入的地址可能是 `https://host/v1`、`https://host/v1/chat/completions`
/// 或厂商特有路径，[AiEndpointConfig.fromUserInput] 会把它归一化为
/// 「基址 + 对话路径」两部分，避免在每次请求时做字符串判断。
class AiEndpointConfig {
  /// 构造配置。
  const AiEndpointConfig({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    this.chatPath = defaultChatPath,
    this.supportsToolCalling = true,
    this.supportsVision = false,
    this.extraHeaders = const <String, String>{},
  });

  /// 默认的对话补全路径。
  static const String defaultChatPath = '/chat/completions';

  /// 从用户在设置页填写的原始地址构造配置。
  ///
  /// 用户可能填完整对话地址，也可能只填基址。这里把结尾的对话路径剪掉，
  /// **保留基址中的版本段**（如 `/v1`），因为后续请求是 `baseUrl + chatPath`：
  /// `https://host/v1/chat/completions` → 基址 `https://host/v1` + 路径
  /// `/chat/completions`。
  factory AiEndpointConfig.fromUserInput({
    required String apiUrl,
    required String apiKey,
    required String model,
  }) {
    var url = apiUrl.trim();
    if (url.endsWith('/')) url = url.substring(0, url.length - 1);

    var path = defaultChatPath;
    for (final suffix in const <String>[
      '/chat/completions',
      '/text/chatcompletion_v2',
    ]) {
      if (url.endsWith(suffix)) {
        url = url.substring(0, url.length - suffix.length);
        path = suffix;
        break;
      }
    }

    final lowerModel = model.toLowerCase();
    final vision = lowerModel.contains('vision') ||
        lowerModel.contains('vl') ||
        lowerModel.contains('4o') ||
        lowerModel.contains('k2.5');

    return AiEndpointConfig(
      baseUrl: url,
      apiKey: apiKey,
      model: model,
      chatPath: path,
      supportsVision: vision,
    );
  }

  /// 服务基址，不含对话路径。
  final String baseUrl;

  /// 访问密钥。
  final String apiKey;

  /// 模型名。
  final String model;

  /// 对话补全路径，以 `/` 开头。
  final String chatPath;

  /// 该模型是否支持 function calling。
  ///
  /// 不支持时助手仍可工作，只是退化为「一次性把数据摘要放进提示词」。
  final bool supportsToolCalling;

  /// 该模型是否接受图片输入。
  final bool supportsVision;

  /// 附加请求头，用于个别厂商要求的额外字段。
  final Map<String, String> extraHeaders;

  /// 配置是否完整到可以发起请求。
  bool get isUsable => baseUrl.isNotEmpty && apiKey.isNotEmpty && model.isNotEmpty;
}

/// 一次模型回复。
class AiChatReply {
  /// 构造回复。
  const AiChatReply({this.content, this.toolCalls = const <AiToolInvocation>[]});

  /// 文本内容；模型只发起工具调用时为 null。
  final String? content;

  /// 模型请求调用的工具。
  final List<AiToolInvocation> toolCalls;

  /// 模型是否希望先执行工具。
  bool get wantsTools => toolCalls.isNotEmpty;
}

/// OpenAI 兼容的对话补全客户端。
///
/// 只做一件事：发一次请求、解析一次回复。工具的执行与多轮循环在
/// `HealthAssistant` 中，这样网络层可以独立测试。
class AiChatClient {
  /// 构造客户端。
  AiChatClient({required AiEndpointConfig config, Dio? dio})
      : _config = config,
        _dio = dio ??
            Dio(BaseOptions(
              baseUrl: config.baseUrl,
              connectTimeout: const Duration(seconds: 60),
              receiveTimeout: const Duration(seconds: 180),
              validateStatus: (_) => true,
            ));

  /// 单轮最多注入的图片数量，避免请求体过大。
  static const int maxImages = 4;

  final AiEndpointConfig _config;
  final Dio _dio;

  /// 当前生效的配置。
  AiEndpointConfig get config => _config;

  /// 发起一次对话补全。
  ///
  /// [messages] 已是接口要求的消息数组；[tools] 为空时不发送 `tools` 字段，
  /// 因为部分服务端在 `tools: []` 时会报参数错误。
  Future<Result<AiChatReply>> complete({
    required List<Map<String, Object?>> messages,
    List<AiToolDefinition> tools = const <AiToolDefinition>[],
    double temperature = 0.3,
    int maxTokens = 2000,
  }) async {
    if (!_config.isUsable) {
      return const Err(AppFailure(
        kind: FailureKind.configuration,
        message: 'AI 未配置：需要填写接口地址、API Key 与模型名',
        code: 'ai.not_configured',
      ));
    }

    try {
      final response = await _dio.post<Object?>(
        _config.chatPath,
        data: <String, Object?>{
          'model': _config.model,
          'messages': messages,
          'temperature': temperature,
          'max_tokens': maxTokens,
          if (tools.isNotEmpty && _config.supportsToolCalling)
            'tools': tools.map((tool) => tool.toOpenAiJson()).toList(),
        },
        options: Options(
          headers: <String, String>{
            'Authorization': 'Bearer ${_config.apiKey}',
            'Content-Type': 'application/json',
            ..._config.extraHeaders,
          },
          responseType: ResponseType.json,
        ),
      );

      final failure = _classifyError(response);
      if (failure != null) return Err(failure);
      return parseCompletion(response.data);
    } on DioException catch (error) {
      return Err(AppFailure(
        kind: FailureKind.network,
        message: '调用 AI 接口失败：${error.message ?? error.type.name}',
        code: 'ai.network',
        cause: error,
      ));
    }
  }

  /// 识别接口返回的错误；无错误时返回 null。
  AppFailure? _classifyError(Response<Object?> response) {
    final status = response.statusCode ?? 0;
    if (status == 401 || status == 403) {
      return const AppFailure(
        kind: FailureKind.authentication,
        message: 'AI 接口拒绝鉴权，请检查 API Key',
        code: 'ai.unauthorized',
      );
    }
    if (status == 429) {
      return const AppFailure(
        kind: FailureKind.network,
        message: 'AI 接口限流，请稍后重试',
        code: 'ai.rate_limited',
      );
    }
    if (status < 200 || status >= 300) {
      final detail = _errorDetail(response.data);
      return AppFailure(
        kind: status >= 500 ? FailureKind.network : FailureKind.unknown,
        message: 'AI 接口返回 HTTP $status${detail.isEmpty ? '' : '：$detail'}',
        code: 'ai.http_error',
      );
    }
    return null;
  }

  /// 从错误响应里提取可读原因，便于用户在设置页自查。
  static String _errorDetail(Object? data) {
    if (data is Map) {
      final error = data['error'];
      if (error is Map && error['message'] is String) {
        return error['message'] as String;
      }
      if (data['base_resp'] is Map) {
        final base = data['base_resp'] as Map;
        final message = base['status_msg'];
        if (message is String) return message;
      }
    }
    return '';
  }

  /// 解析对话补全响应。
  ///
  /// 纯函数，便于用固定报文做单元测试。兼容 `content` 为字符串或
  /// 「文本块数组」两种形态（部分厂商用后者表达富文本）。
  static Result<AiChatReply> parseCompletion(Object? data) {
    if (data is! Map) {
      return const Err(AppFailure(
        kind: FailureKind.parsing,
        message: 'AI 接口返回的不是 JSON 对象',
        code: 'ai.malformed_response',
      ));
    }
    final choices = data['choices'];
    if (choices is! List || choices.isEmpty) {
      return const Err(AppFailure(
        kind: FailureKind.parsing,
        message: 'AI 接口返回中没有 choices',
        code: 'ai.no_choices',
      ));
    }
    final first = choices.first;
    if (first is! Map) {
      return const Err(AppFailure(
        kind: FailureKind.parsing,
        message: 'AI 接口返回的 choices 结构无法识别',
        code: 'ai.bad_choice',
      ));
    }
    final message = first['message'];
    if (message is! Map) {
      return const Err(AppFailure(
        kind: FailureKind.parsing,
        message: 'AI 接口返回的 message 结构无法识别',
        code: 'ai.bad_message',
      ));
    }

    return Ok(AiChatReply(
      content: _contentOf(message['content']),
      toolCalls: _toolCallsOf(message['tool_calls']),
    ));
  }

  /// 归一化消息内容。
  static String? _contentOf(Object? raw) {
    if (raw is String) return raw;
    if (raw is List) {
      final buffer = StringBuffer();
      for (final part in raw) {
        if (part is Map && part['text'] is String) {
          buffer.write(part['text'] as String);
        }
      }
      return buffer.isEmpty ? null : buffer.toString();
    }
    return null;
  }

  /// 解析工具调用列表。
  static List<AiToolInvocation> _toolCallsOf(Object? raw) {
    if (raw is! List) return const <AiToolInvocation>[];
    final calls = <AiToolInvocation>[];
    for (var index = 0; index < raw.length; index++) {
      final item = raw[index];
      if (item is! Map) continue;
      final function = item['function'];
      if (function is! Map) continue;
      final name = function['name'];
      if (name is! String || name.isEmpty) continue;
      final arguments = function['arguments'];
      final id = item['id'];
      calls.add(AiToolInvocation(
        id: id is String && id.isNotEmpty ? id : 'call_$index',
        name: name,
        argumentsJson: arguments is String ? arguments : jsonEncode(arguments),
      ));
    }
    return calls;
  }

  /// 把本地图片编码为 OpenAI 兼容的多模态内容块。
  ///
  /// 读取失败的图片会被跳过而不是让整条消息失败——用户可能已经删除了旧照片，
  /// 那不应该阻止他提出问题。
  static Future<List<Map<String, Object?>>> imageContentParts(
    List<String> imagePaths, {
    int limit = maxImages,
  }) async {
    final parts = <Map<String, Object?>>[];
    for (final path in imagePaths.take(limit)) {
      try {
        final file = File(path);
        if (!await file.exists()) continue;
        final bytes = await file.readAsBytes();
        parts.add(<String, Object?>{
          'type': 'image_url',
          'image_url': <String, Object?>{
            'url': 'data:${_mimeTypeOf(path)};base64,${base64Encode(bytes)}',
          },
        });
      } on FileSystemException {
        // 文件在读取过程中被删除或不可读，跳过该图片。
        continue;
      }
    }
    return parts;
  }

  /// 根据扩展名推断 MIME 类型。
  static String _mimeTypeOf(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }
}
