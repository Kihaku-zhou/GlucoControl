import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../data/database/database_providers.dart';

/// HbA1c 计算器页面
class HbA1cCalculatorScreen extends ConsumerStatefulWidget {
  const HbA1cCalculatorScreen({super.key});

  @override
  ConsumerState<HbA1cCalculatorScreen> createState() => _HbA1cCalculatorScreenState();
}

class _HbA1cCalculatorScreenState extends ConsumerState<HbA1cCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _avgBloodSugarController = TextEditingController();
  final _hba1cController = TextEditingController();
  
  double? _calculatedHbA1c;
  double? _calculatedAvgBloodSugar;

  @override
  void dispose() {
    _avgBloodSugarController.dispose();
    _hba1cController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HbA1c 计算器'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 说明卡片
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          const Text(
                            '关于 HbA1c',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '糖化血红蛋白（HbA1c）反映过去 2-3 个月的平均血糖水平。'
                        '它是评估糖尿病控制效果的重要指标。',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '计算公式：HbA1c% = (平均血糖 + 46.7) / 28.7',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // HbA1c 参考表
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'HbA1c 参考范围',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildReferenceRow('正常', '< 5.7%', Colors.green),
                      _buildReferenceRow('糖尿病前期', '5.7% - 6.4%', Colors.orange),
                      _buildReferenceRow('糖尿病', '≥ 6.5%', Colors.red),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 计算方式选择
              const Text(
                '选择计算方式：',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),

              // 方式一：根据平均血糖计算 HbA1c
              Card(
                color: _calculatedHbA1c != null ? Colors.blue.shade50 : null,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '方式一：根据平均血糖计算 HbA1c',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      
                      // 使用全局血糖单位设置
                      Row(
                        children: [
                          const Text('血糖单位：'),
                          const SizedBox(width: 8),
                          Consumer(
                            builder: (context, ref, child) {
                              final unit = ref.watch(bloodSugarUnitProvider);
                              return Chip(label: Text(unit));
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _avgBloodSugarController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: '平均血糖值',
                          hintText: '输入平均血糖',
                          suffixText: ref.watch(bloodSugarUnitProvider),
                        ),
                        onChanged: (_) => _clearResults(),
                      ),
                      const SizedBox(height: 16),

                      ElevatedButton(
                        onPressed: _calculateHbA1c,
                        child: const Text('计算 HbA1c'),
                      ),

                      if (_calculatedHbA1c != null) ...[
                        const Divider(height: 32),
                        _buildResultCard(
                          '计算结果',
                          '${_calculatedHbA1c!.toStringAsFixed(1)}%',
                          _getHbA1cStatus(_calculatedHbA1c!),
                          _getHbA1cColor(_calculatedHbA1c!),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 方式二：根据 HbA1c 计算平均血糖
              Card(
                color: _calculatedAvgBloodSugar != null ? Colors.blue.shade50 : null,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '方式二：根据 HbA1c 计算平均血糖',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _hba1cController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'HbA1c 值',
                          hintText: '输入 HbA1c',
                          suffixText: '%',
                        ),
                        onChanged: (_) => _clearResults(),
                      ),
                      const SizedBox(height: 16),

                      ElevatedButton(
                        onPressed: _calculateAvgBloodSugar,
                        child: const Text('计算平均血糖'),
                      ),

                      if (_calculatedAvgBloodSugar != null) ...[
                        const Divider(height: 32),
                        Consumer(
                          builder: (context, ref, child) {
                            final unit = ref.watch(bloodSugarUnitProvider);
                            return _buildResultCard(
                              '计算结果',
                              '${_calculatedAvgBloodSugar!.toStringAsFixed(1)} $unit',
                              _getHbA1cStatus(double.parse(_hba1cController.text)),
                              _getHbA1cColor(double.parse(_hba1cController.text)),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReferenceRow(String label, String range, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(
            range,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(String title, String value, String status, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              status,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _calculateHbA1c() {
    if (_avgBloodSugarController.text.isEmpty) return;

    final value = double.tryParse(_avgBloodSugarController.text);
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的血糖值')),
      );
      return;
    }

    // 如果是 mmol/L，转换为 mg/dL
    double mgDlValue = value;
    if (ref.read(bloodSugarUnitProvider) == 'mmol/L') {
      mgDlValue = AppConstants.mmolLToMgDl(value);
    }

    setState(() {
      _calculatedHbA1c = AppConstants.calculateHbA1c(mgDlValue);
    });
  }

  void _calculateAvgBloodSugar() {
    if (_hba1cController.text.isEmpty) return;

    final hba1c = double.tryParse(_hba1cController.text);
    if (hba1c == null || hba1c <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的 HbA1c 值')),
      );
      return;
    }

    double avgBloodSugar = AppConstants.calculateAvgBloodSugar(hba1c);

    // 如果选择 mmol/L，转换结果
    if (ref.read(bloodSugarUnitProvider) == 'mmol/L') {
      avgBloodSugar = AppConstants.mgDlToMmolL(avgBloodSugar);
    }

    setState(() {
      _calculatedAvgBloodSugar = avgBloodSugar;
    });
  }

  void _clearResults() {
    setState(() {
      _calculatedHbA1c = null;
      _calculatedAvgBloodSugar = null;
    });
  }

  String _getHbA1cStatus(double hba1c) {
    if (hba1c < 5.7) return '正常';
    if (hba1c < 6.5) return '糖尿病前期';
    return '糖尿病';
  }

  Color _getHbA1cColor(double hba1c) {
    if (hba1c < 5.7) return Colors.green;
    if (hba1c < 6.5) return Colors.orange;
    return Colors.red;
  }
}
