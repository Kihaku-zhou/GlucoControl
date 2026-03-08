import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/database/database.dart';
import '../../../data/database/database_providers.dart';
import '../../../services/ai/ai_analysis_service.dart';

/// AI 聊天页面
class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({super.key});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;
  int? _currentConversationId;
  String _currentTitle = '新对话';

  @override
  void initState() {
    super.initState();
    _createNewConversation();
  }

  Future<void> _createNewConversation() async {
    final db = ref.read(databaseProvider);
    final now = DateTime.now();
    final title = '对话 ${DateFormat('MM/dd HH:mm').format(now)}';
    
    final id = await db.insertAIConversation(
      AIConversationsCompanion.insert(
        title: title,
        createdAt: now,
        updatedAt: now,
      ),
    );
    
    setState(() {
      _currentConversationId = id;
      _currentTitle = title;
    });
    
    // 刷新对话列表
    ref.invalidate(aiConversationsProvider);
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    _messageController.clear();
    
    // 添加用户消息到UI（临时）
    setState(() {
      _isLoading = true;
    });

    try {
      final db = ref.read(databaseProvider);
      final prefs = ref.read(sharedPreferencesProvider);
      
      // 获取 AI 配置
      final apiUrl = prefs.getString('ai_api_url') ?? '';
      final apiKey = prefs.getString('ai_api_key') ?? '';
      final model = prefs.getString('ai_model') ?? 'gpt-3.5-turbo';
      final enabled = prefs.getBool('ai_enabled') ?? false;
      
      if (!enabled || apiKey.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('请先在设置中配置 AI API')),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 保存用户消息
      await db.insertAIMessage(
        AIMessagesCompanion.insert(
          conversationId: _currentConversationId!,
          role: 'user',
          content: message,
          createdAt: DateTime.now(),
        ),
      );

      // 刷新消息列表
      ref.invalidate(aiMessagesProvider(_currentConversationId!));

      // 调用 AI
      final aiService = AIAnalysisService();
      aiService.init(AIConfig(
        apiUrl: apiUrl,
        apiKey: apiKey,
        model: model,
        enabled: true,
      ));

      // 获取历史消息
      final history = await db.getAIMessages(_currentConversationId!);
      final List<Map<String, String>> messages = history.map((m) => {
        'role': m.role,
        'content': m.content,
      }).toList();

      // 添加当前用户消息
      messages.add({'role': 'user', 'content': message});

      // 调用 AI
      final response = await aiService.chat(messages);

      // 保存 AI 回复
      await db.insertAIMessage(
        AIMessagesCompanion.insert(
          conversationId: _currentConversationId!,
          role: 'assistant',
          content: response,
          createdAt: DateTime.now(),
        ),
      );

      // 更新对话时间
      final conversation = await db.getAIConversation(_currentConversationId!);
      if (conversation != null) {
        await db.updateAIConversation(
          conversation.copyWith(updatedAt: DateTime.now()),
        );
      }

      // 刷新消息列表
      ref.invalidate(aiMessagesProvider(_currentConversationId!));
      ref.invalidate(aiConversationsProvider);

      // 滚动到底部
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('错误: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// 获取并分析健康数据
  Future<void> _fetchAndAnalyzeHealthData() async {
    final db = ref.read(databaseProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    
    final apiUrl = prefs.getString('ai_api_url') ?? '';
    final apiKey = prefs.getString('ai_api_key') ?? '';
    final model = prefs.getString('ai_model') ?? 'gpt-3.5-turbo';
    
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先在设置中配置 AI API')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在获取健康数据...')),
    );

    try {
      // 获取最近30天的数据
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      // 获取血糖记录
      final bloodSugarRecords = await db.getBloodSugarRecordsByDateRange(
        thirtyDaysAgo,
        DateTime.now(),
      );
      
      // 获取运动记录
      final exerciseRecords = await db.getExerciseRecordsByDateRange(
        thirtyDaysAgo,
        DateTime.now(),
      );
      
      // 获取饮食记录
      final mealRecords = await db.getMealRecordsByDateRange(
        thirtyDaysAgo,
        DateTime.now(),
      );
      
      // 获取体测记录
      final bodyRecords = await db.getBodyMeasurementRecordsByDateRange(
        thirtyDaysAgo,
        DateTime.now(),
      );

      // 构建数据摘要
      final summary = StringBuffer();
      summary.writeln('【血糖记录】共${bloodSugarRecords.length}条:');
      if (bloodSugarRecords.isNotEmpty) {
        final avg = bloodSugarRecords.map((r) => r.value).reduce((a, b) => a + b) / bloodSugarRecords.length;
        summary.writeln('- 平均血糖: ${avg.toStringAsFixed(1)} ${bloodSugarRecords.first.unit}');
        summary.writeln('- 最高: ${bloodSugarRecords.map((r) => r.value).reduce((a, b) => a > b ? a : b)}');
        summary.writeln('- 最低: ${bloodSugarRecords.map((r) => r.value).reduce((a, b) => a < b ? a : b)}');
      }
      
      summary.writeln('\n【运动记录】共${exerciseRecords.length}条:');
      if (exerciseRecords.isNotEmpty) {
        final totalDuration = exerciseRecords.map((r) => r.duration).reduce((a, b) => a + b);
        final totalCalories = exerciseRecords.where((r) => r.calories != null).map((r) => r.calories!).fold(0, (a, b) => a + b);
        summary.writeln('- 总时长: $totalDuration 分钟');
        summary.writeln('- 总消耗: $totalCalories kcal');
      }
      
      summary.writeln('\n【饮食记录】共${mealRecords.length}条');
      summary.writeln('\n【体测记录】共${bodyRecords.length}条');
      if (bodyRecords.isNotEmpty) {
        final latest = bodyRecords.first;
        summary.writeln('- 最新体重: ${latest.weight} kg');
        if (latest.bodyFat != null) {
          summary.writeln('- 体脂率: ${latest.bodyFat}%');
        }
      }

      // 保存为用户消息
      final dataMessage = '请分析以下我的健康数据，并给出建议：\n\n${summary.toString()}';
      
      if (_currentConversationId != null) {
        await db.insertAIMessage(
          AIMessagesCompanion.insert(
            conversationId: _currentConversationId!,
            role: 'user',
            content: dataMessage,
            createdAt: DateTime.now(),
          ),
        );
        
        // 调用 AI 分析
        final aiService = AIAnalysisService();
        aiService.init(AIConfig(
          apiUrl: apiUrl,
          apiKey: apiKey,
          model: model,
          enabled: true,
        ));
        
        final result = await aiService.analyzeBloodSugarTrend(
          bloodSugarRecords: bloodSugarRecords.map((r) => {
            'recordedAt': r.recordedAt.toString(),
            'value': r.value,
            'unit': r.unit,
            'type': r.type,
          }).toList(),
          exerciseRecords: exerciseRecords.map((r) => {
            'startedAt': r.startedAt.toString(),
            'type': r.type,
            'name': r.name,
            'duration': r.duration,
            'calories': r.calories,
          }).toList(),
          mealRecords: mealRecords.map((r) => {
            'recordedAt': r.recordedAt.toString(),
            'type': r.type,
          }).toList(),
        );
        
        String aiResponse;
        if (result != null) {
          aiResponse = result.summary;
          if (result.suggestions.isNotEmpty) {
            aiResponse += '\n\n建议:\n${result.suggestions.map((s) => '- $s').join('\n')}';
          }
        } else {
          aiResponse = '数据已加载，但 AI 分析失败。请手动查看以上数据后问我问题。';
        }
        
        // 保存 AI 回复
        await db.insertAIMessage(
          AIMessagesCompanion.insert(
            conversationId: _currentConversationId!,
            role: 'assistant',
            content: aiResponse,
            createdAt: DateTime.now(),
          ),
        );
        
        // 刷新消息列表
        ref.invalidate(aiMessagesProvider(_currentConversationId!));
        _scrollToBottom();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已加载 ${bloodSugarRecords.length} 条血糖、${exerciseRecords.length} 条运动、${mealRecords.length} 条饮食记录')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('获取数据失败: $e')),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = _currentConversationId != null
        ? ref.watch(aiMessagesProvider(_currentConversationId!))
        : const AsyncValue<List<AIMessage>>.data([]);

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _fetchAndAnalyzeHealthData(),
            tooltip: '分析健康数据',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewConversation,
            tooltip: '新对话',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showConversationHistory(context),
            tooltip: '历史对话',
          ),
        ],
      ),
      body: Column(
        children: [
          // 消息列表
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('错误: $e')),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.psychology, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          '开始和 AI 助手聊天',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '询问关于血糖、运动、饮食等问题',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isUser = message.role == 'user';
                    
                    return Align(
                      alignment: isUser 
                          ? Alignment.centerRight 
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isUser 
                              ? Theme.of(context).primaryColor 
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          message.content,
                          style: TextStyle(
                            color: isUser ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // 输入框
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: '输入消息...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isLoading 
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  onPressed: _isLoading ? null : _sendMessage,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showConversationHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Consumer(
            builder: (context, ref, child) {
              final conversationsAsync = ref.watch(aiConversationsProvider);
              
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Text(
                          '历史对话',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            Navigator.pop(context);
                            _createNewConversation();
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: conversationsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, s) => Center(child: Text('错误: $e')),
                      data: (conversations) {
                        if (conversations.isEmpty) {
                          return const Center(
                            child: Text('暂无对话记录'),
                          );
                        }

                        return ListView.builder(
                          controller: scrollController,
                          itemCount: conversations.length,
                          itemBuilder: (context, index) {
                            final conversation = conversations[index];
                            return ListTile(
                              leading: const Icon(Icons.chat),
                              title: Text(conversation.title),
                              subtitle: Text(
                                DateFormat('yyyy/MM/dd HH:mm').format(conversation.updatedAt),
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  final db = ref.read(databaseProvider);
                                  await db.deleteAIConversation(conversation.id);
                                  ref.invalidate(aiConversationsProvider);
                                },
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                setState(() {
                                  _currentConversationId = conversation.id;
                                  _currentTitle = conversation.title;
                                });
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
