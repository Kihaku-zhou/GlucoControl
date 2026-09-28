import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../data/database/database.dart';
import '../../../data/database/database_providers.dart';
import '../../../services/ai/health_assistant.dart';
import '../../providers/health_providers.dart';

/// AI 健康助手对话页。
///
/// 与早期实现的关键区别：健康数据不再被预先拼成一段摘要塞进系统提示，而是由
/// 模型按问题调用工具取数。每次取数都会在气泡下方留下可展开的记录，
/// 让用户能核对「这个结论是基于哪些数据得出的」。
class AIChatScreen extends ConsumerStatefulWidget {
  /// 构造页面。
  const AIChatScreen({super.key});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final ImagePicker _picker = ImagePicker();

  int? _conversationId;
  bool _sending = false;
  List<XFile> _pendingImages = <XFile>[];

  @override
  void initState() {
    super.initState();
    _startConversation();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// 新建一个对话并切换过去。
  Future<void> _startConversation() async {
    final database = ref.read(databaseProvider);
    final now = DateTime.now();
    final id = await database.insertAIConversation(
      AIConversationsCompanion.insert(
        title: '对话 ${DateFormat('MM/dd HH:mm').format(now)}',
        createdAt: now,
        updatedAt: now,
      ),
    );
    if (!mounted) return;
    setState(() => _conversationId = id);
    ref.invalidate(aiConversationsProvider);
  }

  /// 切换到已有对话。
  void _openConversation(int id) {
    setState(() => _conversationId = id);
    Navigator.pop(context);
  }

  /// 删除一个对话。
  Future<void> _deleteConversation(int id) async {
    await ref.read(databaseProvider).deleteAIConversation(id);
    ref.invalidate(aiConversationsProvider);
    if (!mounted) return;
    if (_conversationId == id) await _startConversation();
  }

  /// 选择待发送的图片。
  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage();
    if (images.isEmpty || !mounted) return;
    setState(() => _pendingImages = <XFile>[..._pendingImages, ...images]);
  }

  /// 发送当前输入。
  Future<void> _send() async {
    final text = _input.text.trim();
    if ((text.isEmpty && _pendingImages.isEmpty) || _sending) return;

    final assistant = ref.read(healthAssistantProvider);
    if (assistant == null) {
      _showMessage('请先在「设置 > AI API 配置」中填写接口地址、API Key 与模型');
      return;
    }
    final conversationId = _conversationId;
    if (conversationId == null) return;

    final database = ref.read(databaseProvider);
    final imagePaths = _pendingImages.map((image) => image.path).toList();

    setState(() {
      _sending = true;
      _pendingImages = <XFile>[];
    });
    _input.clear();

    try {
      await database.insertAIMessage(
        AIMessagesCompanion.insert(
          conversationId: conversationId,
          role: 'user',
          content: text.isEmpty ? '（图片）' : text,
          createdAt: DateTime.now(),
        ),
      );
      ref.invalidate(aiMessagesProvider(conversationId));

      final history = await _buildHistory(database, conversationId, assistant);
      final result = await assistant.send(
        history: history,
        imagePaths: imagePaths,
      );

      final reply = result.isOk
          ? result.requireValue()
          : HealthAssistantTurn(text: '请求失败：${result.failureOrNull!.message}');

      await database.insertAIMessage(
        AIMessagesCompanion.insert(
          conversationId: conversationId,
          role: 'assistant',
          content: reply.text,
          toolTraceJson: Value(
            reply.toolTraces.isEmpty
                ? null
                : jsonEncode(
                    reply.toolTraces.map((trace) => trace.toJson()).toList(),
                  ),
          ),
          createdAt: DateTime.now(),
        ),
      );
      await database.updateAIConversation(
        (await database.getAIConversation(conversationId))!
            .copyWith(updatedAt: DateTime.now()),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        ref.invalidate(aiMessagesProvider(conversationId));
        ref.invalidate(aiConversationsProvider);
        _scrollToBottom();
      }
    }
  }

  /// 组装发送给模型的消息数组。
  ///
  /// 历史消息只带角色与文本：工具调用及其结果属于已完成的一轮，
  /// 保留它们会让上下文迅速膨胀，而模型随时可以重新查询。
  Future<List<Map<String, Object?>>> _buildHistory(
    AppDatabase database,
    int conversationId,
    HealthAssistant assistant,
  ) async {
    final messages = await database.getAIMessages(conversationId);
    return <Map<String, Object?>>[
      <String, Object?>{
        'role': 'system',
        'content': assistant.buildSystemPrompt(),
      },
      for (final message in messages)
        <String, Object?>{
          'role': message.role,
          'content': message.content,
        },
    ];
  }

  /// 滚动到底部。
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  /// 弹出一次提示。
  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final conversationId = _conversationId;
    final messagesAsync = conversationId == null
        ? const AsyncValue<List<AIMessage>>.loading()
        : ref.watch(aiMessagesProvider(conversationId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 健康助手'),
        actions: <Widget>[
          IconButton(
            tooltip: '新对话',
            onPressed: _startConversation,
            icon: const Icon(Icons.add_comment_outlined),
          ),
        ],
      ),
      drawer: _buildConversationDrawer(),
      body: Column(
        children: <Widget>[
          Expanded(
            child: messagesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('读取对话失败：$error')),
              data: (messages) => messages.isEmpty
                  ? const _EmptyState()
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) =>
                          _MessageBubble(message: messages[index]),
                    ),
            ),
          ),
          if (_sending) const LinearProgressIndicator(),
          _buildComposer(),
        ],
      ),
    );
  }

  /// 左侧会话列表。
  Widget _buildConversationDrawer() {
    final conversations = ref.watch(aiConversationsProvider);
    return Drawer(
      child: SafeArea(
        child: Column(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('新建对话'),
              onTap: () {
                Navigator.pop(context);
                _startConversation();
              },
            ),
            const Divider(height: 1),
            Expanded(
              child: conversations.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('读取失败：$error')),
                data: (items) => ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final conversation = items[index];
                    return ListTile(
                      selected: conversation.id == _conversationId,
                      title: Text(
                        conversation.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => _deleteConversation(conversation.id),
                      ),
                      onTap: () => _openConversation(conversation.id),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 底部输入区。
  Widget _buildComposer() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (_pendingImages.isNotEmpty)
              Wrap(
                spacing: 8,
                children: _pendingImages
                    .map((image) => Chip(
                          label: Text(
                            image.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onDeleted: () => setState(
                            () => _pendingImages =
                                _pendingImages.where((i) => i != image).toList(),
                          ),
                        ))
                    .toList(),
              ),
            Row(
              children: <Widget>[
                IconButton(
                  tooltip: '添加图片',
                  onPressed: _sending ? null : _pickImages,
                  icon: const Icon(Icons.image_outlined),
                ),
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 4,
                    enabled: !_sending,
                    decoration: const InputDecoration(
                      hintText: '问问你的血糖、饮食和运动…',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: '发送',
                  onPressed: _sending ? null : _send,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 空对话时的引导内容。
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    const examples = <String>[
      '最近两周我的血糖控制得怎么样？',
      '昨天晚饭后血糖偏高，可能是什么原因？',
      '把有运动的日子和没运动的日子对比一下',
      '我接入的数据源里，哪些现在能正常取数？',
    ];
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        const Icon(Icons.psychology, size: 56, color: Colors.grey),
        const SizedBox(height: 16),
        const Text(
          '我可以直接查询你的健康数据',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          '我会按你的问题去调用相应的数据源——本应用录入的记录、'
          '以及你已接入的华为运动健康、Health Connect、Nightscout、'
          'iGPSPORT、Keep、训记等数据。每次查询都会显示在回答下方。',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.6),
        ),
        const SizedBox(height: 24),
        for (final example in examples)
          Card(
            child: ListTile(
              dense: true,
              title: Text(example, style: const TextStyle(fontSize: 13)),
            ),
          ),
      ],
    );
  }
}

/// 单条消息气泡。
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final AIMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final traces = _tracesOf(message.toolTraceJson);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (traces.isNotEmpty) ...<Widget>[
              _ToolTracePanel(traces: traces),
              const SizedBox(height: 8),
            ],
            SelectableText(
              message.content,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Text(
                  DateFormat('HH:mm').format(message.createdAt),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                if (!isUser)
                  IconButton(
                    iconSize: 16,
                    visualDensity: VisualDensity.compact,
                    tooltip: '复制',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: message.content));
                    },
                    icon: const Icon(Icons.copy),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 解析持久化的工具调用记录；格式损坏时返回空列表。
  static List<Map<String, Object?>> _tracesOf(String? raw) {
    if (raw == null || raw.isEmpty) return const <Map<String, Object?>>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((item) => item.map((key, value) => MapEntry(key.toString(), value)))
            .toList();
      }
    } on FormatException {
      // 手工改库或旧版本写入的非法 JSON；按「没有记录」处理。
      return const <Map<String, Object?>>[];
    }
    return const <Map<String, Object?>>[];
  }
}

/// 可展开的工具调用记录。
class _ToolTracePanel extends StatelessWidget {
  const _ToolTracePanel({required this.traces});

  final List<Map<String, Object?>> traces;

  @override
  Widget build(BuildContext context) {
    final succeeded = traces.where((t) => t['succeeded'] == true).length;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        dense: true,
        leading: const Icon(Icons.build_circle_outlined, size: 18),
        title: Text(
          '查询了 $succeeded/${traces.length} 项数据',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        children: traces
            .map((trace) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${trace['tool']}'
                        '${trace['succeeded'] == true ? '' : '（失败：${trace['error'] ?? '未知原因'}）'}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '参数：${trace['arguments']}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}
