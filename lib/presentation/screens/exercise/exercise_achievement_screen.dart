import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/database_providers.dart';

/// 运动成就页面
class ExerciseAchievementScreen extends ConsumerWidget {
  const ExerciseAchievementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(exerciseRecordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('运动成就'),
      ),
      body: recordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('错误: $error')),
        data: (records) => _buildAchievements(context, records),
      ),
    );
  }

  Widget _buildAchievements(BuildContext context, List records) {
    final achievements = _calculateAchievements(records);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 成就标题
        Card(
          color: Colors.amber.shade50,
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber, size: 32),
                SizedBox(width: 12),
                Text(
                  '运动成就',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 成就列表
        ...achievements.map((a) => _buildAchievementCard(a)),
      ],
    );
  }

  List<Map<String, dynamic>> _calculateAchievements(List records) {
    final achievements = <Map<String, dynamic>>[];
    
    if (records.isEmpty) {
      return [
        {
          'icon': Icons.directions_run,
          'title': '开始运动',
          'description': '记录你的第一次运动',
          'color': Colors.blue,
          'unlocked': false,
        },
      ];
    }

    // 计算总时长
    int totalMinutes = 0;
    int totalCalories = 0;
    int totalCount = records.length;
    for (final r in records) {
      totalMinutes += r.duration;
      totalCalories += r.calories ?? 0;
    }

    // 成就1: 第一次运动
    achievements.add({
      'icon': Icons.directions_run,
      'title': '开始运动',
      'description': '记录你的第一次运动',
      'color': Colors.blue,
      'unlocked': true,
    });

    // 成就2: 运动10次
    if (totalCount >= 10) {
      achievements.add({
        'icon': Icons.fitness_center,
        'title': '运动达人',
        'description': '累计运动 10 次',
        'color': Colors.green,
        'unlocked': true,
      });
    } else {
      achievements.add({
        'icon': Icons.fitness_center,
        'title': '运动达人',
        'description': '累计运动 10 次 (${totalCount}/10)',
        'color': Colors.grey,
        'unlocked': false,
      });
    }

    // 成就3: 运动60分钟
    if (totalMinutes >= 60) {
      achievements.add({
        'icon': Icons.timer,
        'title': '运动一小时',
        'description': '累计运动 60 分钟',
        'color': Colors.orange,
        'unlocked': true,
      });
    } else {
      achievements.add({
        'icon': Icons.timer,
        'title': '运动一小时',
        'description': '累计运动 60 分钟 ($totalMinutes/60)',
        'color': Colors.grey,
        'unlocked': false,
      });
    }

    // 成就4: 消耗500卡路里
    if (totalCalories >= 500) {
      achievements.add({
        'icon': Icons.local_fire_department,
        'title': '燃脂达人',
        'description': '累计消耗 500 千卡',
        'color': Colors.red,
        'unlocked': true,
      });
    } else {
      achievements.add({
        'icon': Icons.local_fire_department,
        'title': '燃脂达人',
        'description': '累计消耗 500 千卡 ($totalCalories/500)',
        'color': Colors.grey,
        'unlocked': false,
      });
    }

    // 成就5: 运动30次
    if (totalCount >= 30) {
      achievements.add({
        'icon': Icons.star,
        'title': '运动狂人',
        'description': '累计运动 30 次',
        'color': Colors.purple,
        'unlocked': true,
      });
    } else {
      achievements.add({
        'icon': Icons.star,
        'title': '运动狂人',
        'description': '累计运动 30 次 ($totalCount/30)',
        'color': Colors.grey,
        'unlocked': false,
      });
    }

    // 成就6: 运动10小时
    if (totalMinutes >= 600) {
      achievements.add({
        'icon': Icons.military_tech,
        'title': '运动冠军',
        'description': '累计运动 10 小时',
        'color': Colors.amber,
        'unlocked': true,
      });
    } else {
      achievements.add({
        'icon': Icons.military_tech,
        'title': '运动冠军',
        'description': '累计运动 10 小时 (${totalMinutes ~/ 60}/10)',
        'color': Colors.grey,
        'unlocked': false,
      });
    }

    return achievements;
  }

  Widget _buildAchievementCard(Map<String, dynamic> achievement) {
    final unlocked = achievement['unlocked'] as bool;
    final color = achievement['color'] as Color;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: unlocked ? color.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            achievement['icon'] as IconData,
            color: unlocked ? color : Colors.grey,
          ),
        ),
        title: Text(
          achievement['title'] as String,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: unlocked ? Colors.black : Colors.grey,
          ),
        ),
        subtitle: Text(achievement['description'] as String),
        trailing: unlocked 
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.lock_outline, color: Colors.grey),
      ),
    );
  }
}
