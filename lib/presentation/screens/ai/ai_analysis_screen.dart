import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/ai/health_assistant.dart';
import '../../providers/health_providers.dart';
import '../settings/settings_screen.dart';

/// AI 分析页。
///
/// 是「一键分析」的入口：不再自己拼装数据摘要，而是把一个固定问题交给
/// [HealthAssistant]，由它按需调用工具取数。因此这里的分析结论与聊天页共享
/// 同一套数据来源与同一套推算口径。
class AIAnalysisScreen extends ConsumerStatefulWidget {
  /// 构造页面。
  const AIAnalysisScreen({super.key});

  @override
  ConsumerState<AIAnalysisScreen> createState() => _AIAnalysisScreenState();
}

class _AIAnalysisScreenState extends ConsumerState<AIAnalysisScreen> {
  /// 可选的分析时间跨度。
  static const List<int> _rangeOptions = <int>[7, 14, 30, 90];

  int _days = 30;
  bool _loading = false;
  String? _error;
  HealthAssistantTurn? _result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runAnalysis());
  }

  /// 按当前跨度发起一次分析。
  Future<void> _runAnalysis() async {
    final assistant = ref.read(healthAssistantProvider);
    if (assistant == null) {
      setState(() {
        _error = '尚未配置 AI。请先在「设置 > AI API 配置」中填写接口地址、API Key 与模型。';
        _result = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final history = <Map<String, Object?>>[
      <String, Object?>{
        'role': 'system',
        'content': assistant.buildSystemPrompt(),
      },
      <String, Object?>{
        'role': 'user',
        'content': '请分析我最近 $_days 天的健康数据，按以下顺序作答：\n'
            '1. 血糖总体控制情况：平均血糖、目标范围内时间占比、偏高与偏低的时段分布；\n'
            '2. 血糖波动最明显的几个时段，分别指出当时有没有饮食或运动记录；\n'
            '3. 运动对血糖的影响（如果数据量足够做对比）；\n'
            '4. 基于以上数据，给出 2 到 3 条具体且可执行的建议。\n'
            '请先说明你实际取到了哪些数据、覆盖多长时间，并指出数据不足之处。',
      },
    ];

    final reply = await assistant.send(history: history);
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (reply.isOk) {
        _result = reply.requireValue();
      } else {
        _error = reply.failureOrNull!.message;
        _result = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 健康分析'),
        actions: <Widget>[
          IconButton(
            tooltip: '重新分析',
            onPressed: _loading ? null : _runAnalysis,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _buildRangeSelector(),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error != null) _buildError(),
          if (_result != null) ..._buildResult(_result!),
        ],
      ),
    );
  }

  /// 时间跨度选择。
  Widget _buildRangeSelector() {
    return SegmentedButton<int>(
      segments: _rangeOptions
          .map((days) => ButtonSegment<int>(
                value: days,
                label: Text('$days 天'),
              ))
          .toList(),
      selected: <int>{_days},
      onSelectionChanged: _loading
          ? null
          : (selection) {
              setState(() => _days = selection.first);
              _runAnalysis();
            },
    );
  }

  /// 错误提示，配置类问题直接给出跳转入口。
  Widget _buildError() {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(_error!, style: const TextStyle(height: 1.5)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AIApiSettingsScreen(),
                ),
              ),
              child: const Text('前往 AI 配置'),
            ),
          ],
        ),
      ),
    );
  }

  /// 分析结果与工具调用记录。
  List<Widget> _buildResult(HealthAssistantTurn turn) {
    return <Widget>[
      if (turn.toolTraces.isNotEmpty) ...<Widget>[
        Card(
          child: ExpansionTile(
            leading: const Icon(Icons.build_circle_outlined),
            title: Text('本次查询了 ${turn.toolTraces.length} 项数据'),
            children: turn.toolTraces
                .map((trace) => ListTile(
                      dense: true,
                      leading: Icon(
                        trace.succeeded
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        size: 18,
                        color: trace.succeeded ? Colors.green : Colors.red,
                      ),
                      title: Text(trace.name,
                          style: const TextStyle(fontSize: 13)),
                      subtitle: Text(
                        trace.succeeded
                            ? '参数：${trace.arguments}'
                            : '失败：${trace.error}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
      ],
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            turn.text,
            style: const TextStyle(fontSize: 14, height: 1.7),
          ),
        ),
      ),
      const SizedBox(height: 16),
      const Text(
        '以上结论基于应用内记录与你已接入的外部数据源。'
        '本应用只做数据记录与展示，不能作为诊断依据；'
        '涉及用药调整请咨询医生。',
        style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.5),
      ),
    ];
  }
}
