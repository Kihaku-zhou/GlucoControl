import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/database_providers.dart';

/// 血糖目标设置页面
class BloodSugarGoalScreen extends ConsumerWidget {
  const BloodSugarGoalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final safeMin = ref.watch(safeRangeMinProvider);
    final safeMax = ref.watch(safeRangeMaxProvider);
    final currentUnit = ref.watch(bloodSugarUnitProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('血糖目标设置'),
      ),
      body: ListView(
        children: [
          // 目标说明
          Card(
            color: Colors.blue.shade50,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        '血糖目标说明',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• 空腹血糖目标: 4.4-7.0 mmol/L (80-126 mg/dL)\n'
                    '• 餐后血糖目标: <10.0 mmol/L (<180 mg/dL)\n'
                    '• TIR 目标: ≥70%',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          
          const Divider(),
          
          // 安全血糖范围
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '安全血糖范围',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          
          // 最低值
          ListTile(
            leading: const Icon(Icons.arrow_downward, color: Colors.orange),
            title: const Text('最低安全值'),
            subtitle: Text(
              currentUnit == 'mmol/L' 
                ? '${(safeMin / 18.0182).toStringAsFixed(1)} mmol/L'
                : '${safeMin.toInt()} mg/dL',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showGoalDialog(
              context: context,
              ref: ref,
              title: '设置最低安全值',
              currentValue: safeMin,
              min: currentUnit == 'mmol/L' ? 3.3 / 18.0182 * 18.0182 : 60,
              max: currentUnit == 'mmol/L' ? 6.1 / 18.0182 * 18.0182 : 110,
              unit: currentUnit,
              onSave: (value) {
                ref.read(safeRangeMinProvider.notifier).state = value;
              },
            ),
          ),
          
          // 最高值
          ListTile(
            leading: const Icon(Icons.arrow_upward, color: Colors.red),
            title: const Text('最高安全值'),
            subtitle: Text(
              currentUnit == 'mmol/L' 
                ? '${(safeMax / 18.0182).toStringAsFixed(1)} mmol/L'
                : '${safeMax.toInt()} mg/dL',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showGoalDialog(
              context: context,
              ref: ref,
              title: '设置最高安全值',
              currentValue: safeMax,
              min: currentUnit == 'mmol/L' ? 7.0 / 18.0182 * 18.0182 : 126,
              max: currentUnit == 'mmol/L' ? 15.0 / 18.0182 * 18.0182 : 270,
              unit: currentUnit,
              onSave: (value) {
                ref.read(safeRangeMaxProvider.notifier).state = value;
              },
            ),
          ),
          
          const Divider(),
          
          // TIR 目标
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'TIR 目标',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          
          ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: const Text('达标时间目标 (TIR)'),
            subtitle: const Text('建议: ≥70%'),
            trailing: const Text(
              '70%',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          
          const Divider(),
          
          // 重置为默认值
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () => _showResetDialog(context, ref, currentUnit),
              icon: const Icon(Icons.restore),
              label: const Text('重置为默认值'),
            ),
          ),
        ],
      ),
    );
  }

  void _showGoalDialog({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required double currentValue,
    required double min,
    required double max,
    required String unit,
    required Function(double) onSave,
  }) {
    double newValue = currentValue;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              unit == 'mmol/L' 
                ? '${(newValue / 18.0182).toStringAsFixed(1)} mmol/L'
                : '${newValue.toInt()} mg/dL',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Slider(
              value: newValue.clamp(min, max),
              min: min,
              max: max,
              divisions: ((max - min) / (unit == 'mmol/L' ? 0.1 : 2)).toInt(),
              onChanged: (value) {
                newValue = value;
                (context as Element).markNeedsBuild();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              onSave(newValue);
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref, String unit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置为默认值'),
        content: const Text('确定要将血糖目标重置为默认值吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              // 重置为默认值
              ref.read(safeRangeMinProvider.notifier).state = 70.0; // mg/dL
              ref.read(safeRangeMaxProvider.notifier).state = 140.0; // mg/dL
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已重置为默认值')),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
