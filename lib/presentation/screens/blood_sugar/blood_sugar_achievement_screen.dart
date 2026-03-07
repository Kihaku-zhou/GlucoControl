import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/database_providers.dart';

/// 血糖成就页面
class BloodSugarAchievementScreen extends ConsumerWidget {
  const BloodSugarAchievementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(bloodSugarRecordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('血糖成就'),
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
          color: Colors.blue.shade50,
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber, size: 32),
                SizedBox(width: 12),
                Text(
                  '血糖成就',
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
          'icon': Icons.monitor_heart,
          'title': '开始记录',
          'description': '记录你的第一条血糖',
          'color': Colors.blue,
          'unlocked': false,
        },
      ];
    }

    // 计算统计数据
    int totalRecords = records.length;
    int fastingCount = 0;
    int postMealCount = 0;
    int lowCount = 0;
    int highCount = 0;
    int inRangeCount = 0;
    
    const safeMin = 70.0;
    const safeMax = 140.0;
    
    for (final r in records) {
      final value = r.value;
      
      if (r.type == 'fasting') {
        fastingCount++;
      } else if (r.type == 'post_meal') {
        postMealCount++;
      }
      
      if (value >= safeMin && value <= safeMax) {
        inRangeCount++;
      } else if (value < safeMin) {
        lowCount++;
      } else {
        highCount++;
      }
    }

    // 成就1: 开始记录
    achievements.add({
      'icon': Icons.monitor_heart,
      'title': '开始记录',
      'description': '记录你的第一条血糖',
      'color': Colors.blue,
      'unlocked': true,
    });

    // 成就2: 记录10次
    if (totalRecords >= 10) {
      achievements.add({
        'icon': Icons.folder,
        'title': '数据积累',
        'description': '累计记录 10 次血糖',
        'color': Colors.green,
        'unlocked': true,
      });
    } else {
      achievements.add({
        'icon': Icons.folder,
        'title': '数据积累',
        'description': '累计记录 10 次血糖 ($totalRecords/10)',
        'color': Colors.grey,
        'unlocked': false,
      });
    }

    // 成就3: 连续记录7天
    if (totalRecords >= 7) {
      achievements.add({
        'icon': Icons.calendar_today,
        'title': '坚持不懈',
        'description': '连续记录 7 天血糖',
        'color': Colors.orange,
        'unlocked': true,
      });
    } else {
      achievements.add({
        'icon': Icons.calendar_today,
        'title': '坚持不懈',
        'description': '连续记录 7 天血糖',
        'color': Colors.grey,
        'unlocked': false,
      });
    }

    // 成就4: 达标率100%
    if (totalRecords >= 7 && inRangeCount == totalRecords) {
      achievements.add({
        'icon': Icons.star,
        'title': '完美控制',
        'description': '所有记录都在安全范围内',
        'color': Colors.amber,
        'unlocked': true,
      });
    } else if (totalRecords >= 7) {
      final rate = (inRangeCount / totalRecords * 100).toStringAsFixed(0);
      achievements.add({
        'icon': Icons.star,
        'title': '完美控制',
        'description': '所有记录都在安全范围内 ($rate%)',
        'color': Colors.grey,
        'unlocked': false,
      });
    }

    // 成就5: 记录30次
    if (totalRecords >= 30) {
      achievements.add({
        'icon': Icons.military_tech,
        'title': '数据达人',
        'description': '累计记录 30 次血糖',
        'color': Colors.purple,
        'unlocked': true,
      });
    } else {
      achievements.add({
        'icon': Icons.military_tech,
        'title': '数据达人',
        'description': '累计记录 30 次血糖 ($totalRecords/30)',
        'color': Colors.grey,
        'unlocked': false,
      });
    }

    // 成就6: 空腹和餐后都有记录
    if (fastingCount > 0 && postMealCount > 0) {
      achievements.add({
        'icon': Icons.all_inclusive,
        'title': '全面监测',
        'description': '同时记录空腹和餐后血糖',
        'color': Colors.teal,
        'unlocked': true,
      });
    } else {
      achievements.add({
        'icon': Icons.all_inclusive,
        'title': '全面监测',
        'description': '同时记录空腹和餐后血糖',
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
