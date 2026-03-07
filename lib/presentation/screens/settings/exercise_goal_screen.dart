import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/database_providers.dart';

/// 运动目标设置页面
class ExerciseGoalScreen extends ConsumerWidget {
  const ExerciseGoalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyGoal = ref.watch(weeklyExerciseGoalProvider);
    final weeklyDaysGoal = ref.watch(weeklyExerciseDaysGoalProvider);
    final dailyCalorieGoal = ref.watch(dailyCalorieGoalProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('运动目标'),
      ),
      body: ListView(
        children: [
          // 每周运动时长目标
          _buildGoalCard(
            context: context,
            icon: Icons.timer,
            title: '每周运动时长目标',
            currentValue: '$weeklyGoal 分钟',
            subtitle: '建议: 150-300 分钟/周',
            onTap: () => _showWeeklyGoalDialog(context, ref, weeklyGoal),
          ),
          
          // 每周运动天数目标
          _buildGoalCard(
            context: context,
            icon: Icons.calendar_today,
            title: '每周运动天数目标',
            currentValue: '$weeklyDaysGoal 天',
            subtitle: '建议: 3-5 天/周',
            onTap: () => _showWeeklyDaysGoalDialog(context, ref, weeklyDaysGoal),
          ),
          
          // 每日卡路里消耗目标
          _buildGoalCard(
            context: context,
            icon: Icons.local_fire_department,
            title: '每日卡路里消耗目标',
            currentValue: '$dailyCalorieGoal 千卡',
            subtitle: '建议: 200-500 千卡/天',
            onTap: () => _showDailyCalorieGoalDialog(context, ref, dailyCalorieGoal),
          ),
          
          const Divider(),
          
          // 运动建议
          const ListTile(
            leading: Icon(Icons.lightbulb, color: Colors.amber),
            title: Text('运动建议'),
            subtitle: Text(
              '• 每周至少 150 分钟中等强度有氧运动\n'
              '• 每周 2 天以上力量训练\n'
              '• 每次运动后做好热身和拉伸\n'
              '• 循序渐进，避免运动过量',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String currentValue,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(
          currentValue,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  void _showWeeklyGoalDialog(BuildContext context, WidgetRef ref, int currentValue) {
    int newValue = currentValue;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('每周运动时长目标'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$newValue 分钟', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Slider(
              value: newValue.toDouble(),
              min: 30,
              max: 600,
              divisions: 57,
              label: '$newValue 分钟',
              onChanged: (value) {
                newValue = value.toInt();
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
              ref.read(weeklyExerciseGoalProvider.notifier).state = newValue;
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showWeeklyDaysGoalDialog(BuildContext context, WidgetRef ref, int currentValue) {
    int newValue = currentValue;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('每周运动天数目标'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$newValue 天', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Slider(
              value: newValue.toDouble(),
              min: 1,
              max: 7,
              divisions: 6,
              label: '$newValue 天',
              onChanged: (value) {
                newValue = value.toInt();
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
              ref.read(weeklyExerciseDaysGoalProvider.notifier).state = newValue;
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showDailyCalorieGoalDialog(BuildContext context, WidgetRef ref, int currentValue) {
    int newValue = currentValue;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('每日卡路里消耗目标'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$newValue 千卡', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Slider(
              value: newValue.toDouble(),
              min: 100,
              max: 1000,
              divisions: 18,
              label: '$newValue 千卡',
              onChanged: (value) {
                newValue = value.toInt();
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
              ref.read(dailyCalorieGoalProvider.notifier).state = newValue;
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
