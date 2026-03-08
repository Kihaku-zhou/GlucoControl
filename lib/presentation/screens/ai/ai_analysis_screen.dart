import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/database.dart';
import '../../../data/database/database_providers.dart';
import '../../../services/ai/ai_analysis_service.dart';
import '../settings/settings_screen.dart';

/// AI 分析页面
class AIAnalysisScreen extends ConsumerStatefulWidget {
  const AIAnalysisScreen({super.key});

  @override
  ConsumerState<AIAnalysisScreen> createState() => _AIAnalysisScreenState();
}

class _AIAnalysisScreenState extends ConsumerState<AIAnalysisScreen> {
  bool _isLoading = false;
  String? _error;
  AIAnalysisResult? _result;
  DateTime? _lastAnalysisTime;

  @override
  void initState() {
    super.initState();
    // 自动开始分析
    _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    setState(() {
      _isLoading = true;
      _error = null;
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
        setState(() {
          _error = '请先在设置中配置 AI API';
          _isLoading = false;
        });
        return;
      }

      // 初始化 AI 服务
      final aiService = AIAnalysisService();
      aiService.init(AIConfig(
        apiUrl: apiUrl,
        apiKey: apiKey,
        model: model,
        enabled: true,
      ));

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

      // 转换为 Map 格式
      final bloodSugarData = bloodSugarRecords.map((r) => {
        'recordedAt': r.recordedAt.toString().substring(0, 16),
        'value': r.value,
        'unit': r.unit,
        'type': r.type,
      }).toList();

      debugPrint('AI Analysis - Blood sugar records: ${bloodSugarData.length}');
      debugPrint('AI Analysis - Exercise records: ${exerciseRecords.length}');
      debugPrint('AI Analysis - Meal records: ${mealRecords.length}');

      final exerciseData = exerciseRecords.map((r) => {
        'startedAt': r.startedAt.toString().substring(0, 16),
        'type': r.type,
        'name': r.name,
        'duration': r.duration,
        'calories': r.calories,
      }).toList();

      final mealData = mealRecords.map((r) => {
        'recordedAt': r.recordedAt.toString().substring(0, 16),
        'type': r.type,
      }).toList();

      // 调用 AI 分析
      final result = await aiService.analyzeBloodSugarTrend(
        bloodSugarRecords: bloodSugarData,
        exerciseRecords: exerciseData,
        mealRecords: mealData,
      );

      debugPrint('AI Analysis result: $result');

      setState(() {
        _result = result;
        _lastAnalysisTime = DateTime.now();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 健康分析'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _runAnalysis,
            tooltip: '重新分析',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('AI 正在分析你的健康数据...'),
            SizedBox(height: 8),
            Text('这可能需要几秒钟', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('分析失败', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _runAnalysis,
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AIApiSettingsScreen(),
                    ),
                  );
                },
                child: const Text('检查 AI API 配置'),
              ),
            ],
          ),
        ),
      );
    }

    if (_result == null) {
      return const Center(child: Text('暂无数据'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 分析时间
          if (_lastAnalysisTime != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                '分析时间: ${_lastAnalysisTime!.toString().substring(0, 16)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),

          // 概览
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.analytics, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text(
                        '健康概览',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _result!.summary,
                    style: const TextStyle(height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 建议
          if (_result!.suggestions.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text(
                          '健康建议',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._result!.suggestions.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${entry.key + 1}. ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            Expanded(child: Text(entry.value)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 详细分析
          if (_result!.analysis.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.insights, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          '数据分析',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._result!.analysis.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              entry.value.toString(),
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// AI API 设置页面（复用 settings 中的）
class AIApiSettingsScreen extends ConsumerStatefulWidget {
  const AIApiSettingsScreen({super.key});

  @override
  ConsumerState<AIApiSettingsScreen> createState() => _AIApiSettingsScreenState();
}

class _AIApiSettingsScreenState extends ConsumerState<AIApiSettingsScreen> {
  final _apiUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _modelController = TextEditingController();
  bool _enabled = false;
  bool _isTesting = false;
  bool? _testResult;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final prefs = ref.read(sharedPreferencesProvider);
    setState(() {
      _apiUrlController.text = prefs.getString('ai_api_url') ?? '';
      _apiKeyController.text = prefs.getString('ai_api_key') ?? '';
      _modelController.text = prefs.getString('ai_model') ?? 'gpt-3.5-turbo';
      _enabled = prefs.getBool('ai_enabled') ?? false;
    });
  }

  Future<void> _saveConfig() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('ai_api_url', _apiUrlController.text);
    await prefs.setString('ai_api_key', _apiKeyController.text);
    await prefs.setString('ai_model', _modelController.text);
    await prefs.setBool('ai_enabled', _enabled);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI API 设置已保存')),
      );
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    // 保存配置
    await _saveConfig();

    // 测试连接
    final aiService = AIAnalysisService();
    aiService.init(AIConfig(
      apiUrl: _apiUrlController.text,
      apiKey: _apiKeyController.text,
      model: _modelController.text,
      enabled: true,
    ));

    final result = await aiService.testConnection();

    setState(() {
      _isTesting = false;
      _testResult = result;
    });
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI API 配置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('启用 AI 分析'),
            subtitle: const Text('基于血糖、饮食、运动数据进行分析'),
            value: _enabled,
            onChanged: (value) {
              setState(() {
                _enabled = value;
              });
            },
          ),
          const Divider(),
          TextField(
            controller: _apiUrlController,
            decoration: const InputDecoration(
              labelText: 'API 地址',
              hintText: 'https://api.openai.com/v1',
              helperText: '支持 OpenAI 兼容的 API',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _apiKeyController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'API Key',
              hintText: '你的 API Key',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _modelController,
            decoration: const InputDecoration(
              labelText: '模型',
              hintText: 'gpt-3.5-turbo',
            ),
          ),
          const SizedBox(height: 24),
          if (_testResult != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: _testResult! ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _testResult! ? Icons.check_circle : Icons.error,
                    color: _testResult! ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _testResult! ? '连接成功！' : '连接失败，请检查配置',
                    style: TextStyle(
                      color: _testResult! ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isTesting ? null : _testConnection,
                  icon: _isTesting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_tethering),
                  label: const Text('测试连接'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveConfig,
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('支持的 API', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('• OpenAI (api.openai.com)'),
                  Text('• SiliconFlow (api.siliconflow.cn)'),
                  Text('• DeepSeek (api.deepseek.com)'),
                  Text('• 其他 OpenAI 兼容 API'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
