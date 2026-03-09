import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  String? _lastUserMessage; // 上一次用户发送的消息，用于重新回答
  
  // 图片上传
  final ImagePicker _imagePicker = ImagePicker();
  List<XFile> _uploadedImages = []; // 上传的图片
  
  // 健康数据缓存（不显示在对话框中）
  Map<String, dynamic>? _healthDataCache;
  DateTime? _healthDataFetchTime;

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
      _lastUserMessage = null; // 新对话时清空
    });
    
    // 刷新对话列表
    ref.invalidate(aiConversationsProvider);
  }

  /// 重新回答上一个问题
  Future<void> _regenerateResponse() async {
    if (_lastUserMessage == null || _lastUserMessage!.isEmpty || _isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有可重新回答的消息')),
      );
      return;
    }
    
    // 重新发送上一次的消息
    _messageController.text = _lastUserMessage!;
    await _sendMessage();
  }

  /// 选择图片上传
  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('拍照'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _imagePicker.pickImage(source: ImageSource.camera);
                if (image != null) {
                  setState(() {
                    _uploadedImages.add(image);
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('从相册选择'),
              onTap: () async {
                Navigator.pop(context);
                final List<XFile> images = await _imagePicker.pickMultiImage();
                if (images.isNotEmpty) {
                  setState(() {
                    _uploadedImages.addAll(images);
                  });
                }
              },
            ),
            if (_uploadedImages.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('清除图片', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _uploadedImages.clear();
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    // 保存用户消息，用于重新回答
    _lastUserMessage = message;
    
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

      // 如果有缓存的健康数据，在系统提示中加入（不显示给用户）
      String systemPrompt = '''你是一位专业的糖尿病健康管理助手，擅长分析血糖数据、饮食和运动的关系，并给出科学的建议。

你可以分析用户提供的饮食照片和身体测量照片，给出营养建议和身体变化分析。
对于力量训练，重点关注训练容量（重量×组数×次数）；对于有氧运动，重点关注功率或运动强度。
请用中文回复。''';
      if (_healthDataCache != null && _healthDataCache!['summary'] != null) {
        systemPrompt += '\n\n用户最近的健康数据摘要：\n${_healthDataCache!['summary']}';
        // 特别提醒AI有关于图片的信息
        final mealWithImages = (_healthDataCache!['meal'] as List).where((m) => m['imagePaths'] != null && (m['imagePaths'] as String).isNotEmpty).toList();
        final bodyWithImages = (_healthDataCache!['bodyMeasurement'] as List).where((m) => m['imagePath'] != null && (m['imagePath'] as String).isNotEmpty).toList();
        if (mealWithImages.isNotEmpty || bodyWithImages.isNotEmpty) {
          systemPrompt += '\n\n注意：用户有以下带图片的记录，图片文件路径已提供，你可以分析这些图片：';
          for (final m in mealWithImages.take(3)) {
            systemPrompt += '\n- 饮食图片: ${m['imagePaths']}';
          }
          for (final m in bodyWithImages.take(3)) {
            systemPrompt += '\n- 体测图片: ${m['imagePath']}';
          }
        }
      }
      
      // 构建消息（将系统提示加入第一条）
      final List<Map<String, String>> allMessages = [
        {'role': 'system', 'content': systemPrompt},
        ...messages,
      ];

      // 构建用户消息，如果有图片则附加图片信息
      String userMessageContent = message;
      if (_uploadedImages.isNotEmpty) {
        userMessageContent += '\n\n【上传的图片】\n';
        for (int i = 0; i < _uploadedImages.length; i++) {
          userMessageContent += '图片 ${i + 1}: ${_uploadedImages[i].path}\n';
        }
        userMessageContent += '\n请分析这些图片中的内容（如饮食照片、身体照片等）。';
      }
      
      // 添加当前用户消息
      messages.add({'role': 'user', 'content': userMessageContent});

      // 获取图片路径列表（如果有）
      List<String>? imagePaths;
      if (_uploadedImages.isNotEmpty) {
        imagePaths = _uploadedImages.map((f) => f.path).toList();
      }

      // 调用 AI（传递图片）
      final response = await aiService.chat(allMessages, images: imagePaths);

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
        // 发送成功后清空图片
        if (_messageController.text.isEmpty) {
          _uploadedImages.clear();
        }
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

  /// 获取并缓存健康数据（不显示在对话框中）
  Future<void> _fetchAndAnalyzeHealthData() async {
    final db = ref.read(databaseProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    final apiKey = prefs.getString('ai_api_key') ?? '';
    
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先在设置中配置 AI API')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在加载健康数据...')),
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
      final bodyMeasurements = await db.getAllBodyMeasurements();
      final recentBodyMeasurements = bodyMeasurements.where((m) => m.measuredAt.isAfter(thirtyDaysAgo)).toList();

      // 构建数据摘要（用于 API 调用，不显示在界面）
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
        // 计算力量训练总容量和有氧总强度
        int totalStrengthVolume = 0;
        double totalAerobicIntensity = 0;
        for (final r in exerciseRecords) {
          if (r.type == 'anaerobic' && r.weight != null && r.sets != null) {
            // 力量训练容量 = 重量 × 组数 × 次数
            final reps = int.tryParse(r.repsList?.split(',').first ?? '0') ?? 0;
            totalStrengthVolume += (r.weight! * r.sets! * reps).round();
          }
          if (r.type == 'aerobic' && r.power != null) {
            // 有氧强度用功率衡量
            totalAerobicIntensity += r.power!;
          }
        }
        final totalDuration = exerciseRecords.map((r) => r.duration).reduce((a, b) => a + b);
        final totalCalories = exerciseRecords.where((r) => r.calories != null).map((r) => r.calories!).fold(0, (a, b) => a + b);
        summary.writeln('- 总时长: $totalDuration 分钟');
        summary.writeln('- 总消耗: $totalCalories kcal');
        if (totalStrengthVolume > 0) {
          summary.writeln('- 力量训练总容量: $totalStrengthVolume kg');
        }
        if (totalAerobicIntensity > 0) {
          summary.writeln('- 有氧训练总功率: ${totalAerobicIntensity.toStringAsFixed(0)} W');
        }
        
        // 列出每条运动记录详情
        summary.writeln('\n详细记录:');
        for (final r in exerciseRecords.take(20)) {
          final typeStr = r.type == 'aerobic' ? '有氧' : r.type == 'anaerobic' ? '力量' : '耐力';
          final timeStr = DateFormat('MM/dd HH:mm').format(r.startedAt);
          String detail = '$timeStr $typeStr ${r.name} ${r.duration}分钟';
          if (r.type == 'anaerobic') {
            // 力量训练详情
            final repsStr = r.repsList ?? '';
            final sets = r.sets ?? 0;
            detail += ' ${sets}组';
            if (repsStr.isNotEmpty) detail += ' x $repsStr次';
            if (r.weight != null && r.weight! > 0) detail += ' ${r.weight}kg';
          } else if (r.type == 'aerobic') {
            // 有氧训练详情
            if (r.power != null && r.power! > 0) detail += ' ${r.power}W';
            if (r.distance != null && r.distance! > 0) detail += ' ${r.distance}km';
            if (r.elevation != null && r.elevation! > 0) detail += ' 爬升${r.elevation}m';
          }
          if (r.calories != null && r.calories! > 0) detail += ' ${r.calories}kcal';
          summary.writeln('- $detail');
        }
        if (exerciseRecords.length > 20) {
          summary.writeln('... 还有 ${exerciseRecords.length - 20} 条记录');
        }
      }
      
      summary.writeln('\n【饮食记录】共${mealRecords.length}条');
      // 列出有图片的饮食记录
      final mealsWithImages = mealRecords.where((r) => r.imagePaths != null && r.imagePaths!.isNotEmpty).toList();
      if (mealsWithImages.isNotEmpty) {
        summary.writeln('有图片的饮食记录: ${mealsWithImages.length}条');
        for (final r in mealsWithImages.take(5)) {
          summary.writeln('- ${DateFormat('MM/dd').format(r.recordedAt)} ${r.type}: ${r.imagePaths}');
        }
      }
      
      summary.writeln('\n【体测记录】共${recentBodyMeasurements.length}条');
      if (recentBodyMeasurements.isNotEmpty) {
        // 列出每条体测记录详情
        for (final m in recentBodyMeasurements.reversed.take(20)) {
          final timeStr = DateFormat('yyyy/MM/dd').format(m.measuredAt);
          String detail = '$timeStr';
          if (m.weight != null) detail += ' 体重${m.weight}kg';
          if (m.bodyFat != null) detail += ' 体脂${m.bodyFat}%';
          if (m.bmi != null) detail += ' BMI${m.bmi!.toStringAsFixed(1)}';
          if (m.muscleMass != null) detail += ' 肌肉${m.muscleMass}kg';
          if (m.waist != null) detail += ' 腰围${m.waist}cm';
          if (m.hip != null) detail += ' 臀围${m.hip}cm';
          if (m.chest != null) detail += ' 胸围${m.chest}cm';
          if (m.armLeft != null || m.armRight != null) {
            detail += ' 臂围${m.armLeft ?? '-'}/${m.armRight ?? '-'}cm';
          }
          if (m.thighLeft != null || m.thighRight != null) {
            detail += ' 大腿${m.thighLeft ?? '-'}/${m.thighRight ?? '-'}cm';
          }
          if (m.imagePath != null && m.imagePath!.isNotEmpty) {
            detail += ' 📷有图片';
          }
          summary.writeln('- $detail');
        }
        if (recentBodyMeasurements.length > 20) {
          summary.writeln('... 还有 ${recentBodyMeasurements.length - 20} 条记录');
        }
      }
      
      summary.writeln('\n【饮食记录】共${mealRecords.length}条');

      // 缓存数据
      _healthDataCache = {
        'bloodSugar': bloodSugarRecords.map((r) => {
          'recordedAt': r.recordedAt.toString(),
          'value': r.value,
          'unit': r.unit,
          'type': r.type,
        }).toList(),
        'exercise': exerciseRecords.map((r) => {
          'startedAt': r.startedAt.toString(),
          'type': r.type,
          'name': r.name,
          'duration': r.duration,
          'calories': r.calories,
          'weight': r.weight,
          'sets': r.sets,
          'repsList': r.repsList,
          'power': r.power,
        }).toList(),
        'meal': mealRecords.map((r) => {
          'recordedAt': r.recordedAt.toString(),
          'type': r.type,
          'imagePaths': r.imagePaths,
        }).toList(),
        'bodyMeasurement': recentBodyMeasurements.map((m) => {
          'measuredAt': m.measuredAt.toString(),
          'weight': m.weight,
          'bodyFat': m.bodyFat,
          'bmi': m.bmi,
          'imagePath': m.imagePath,
        }).toList(),
        'summary': summary.toString(),
      };
      _healthDataFetchTime = DateTime.now();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已加载 ${bloodSugarRecords.length} 条血糖、${exerciseRecords.length} 条运动、${mealRecords.length} 条饮食、${recentBodyMeasurements.length} 条体测记录。现在可以问我健康相关问题！')),
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
                    
                    return GestureDetector(
                      onLongPress: () {
                        // 复制消息内容
                        Clipboard.setData(ClipboardData(text: message.content));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已复制到剪贴板'), duration: Duration(seconds: 1)),
                        );
                      },
                      child: Align(
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
                                ? Theme.of(context).colorScheme.primary 
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.content,
                                style: TextStyle(
                                  color: isUser ? Colors.white : Colors.black87,
                                ),
                              ),
                              if (!isUser)
                                const Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Text(
                                    '长按复制',
                                    style: TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                ),
                            ],
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
                // 图片上传按钮或已上传图片预览
                if (_uploadedImages.isNotEmpty)
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 60,
                      height: 60,
                      margin: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_uploadedImages.first.path),
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (_uploadedImages.length > 1)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '+${_uploadedImages.length}',
                                  style: const TextStyle(color: Colors.white, fontSize: 10),
                                ),
                              ),
                            ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => setState(() => _uploadedImages.clear()),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.add_photo_alternate),
                    onPressed: _pickImage,
                    tooltip: '添加图片',
                  ),
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
                // 重新回答按钮
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: _lastUserMessage != null && !_isLoading ? Colors.orange : Colors.grey,
                  ),
                  onPressed: _lastUserMessage != null && !_isLoading ? _regenerateResponse : null,
                  tooltip: '重新回答',
                ),
                // 发送按钮
                IconButton(
                  icon: _isLoading 
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                  onPressed: _isLoading ? null : _sendMessage,
                  color: Colors.white,
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
