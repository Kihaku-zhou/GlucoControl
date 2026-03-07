import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/database/database.dart';
import '../../../data/database/database_providers.dart';

/// 运动统计详情页面
class ExerciseStatsDetailScreen extends ConsumerWidget {
  const ExerciseStatsDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(exerciseRecordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('运动统计'),
      ),
      body: recordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('错误: $error')),
        data: (records) {
          if (records.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('暂无运动数据', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          return _buildStats(context, records);
        },
      ),
    );
  }

  Widget _buildStats(BuildContext context, List<ExerciseRecord> records) {
    // 计算各种统计
    int totalMinutes = 0;
    int totalCalories = 0;
    int totalDistance = 0;
    Map<String, int> exerciseCount = {};
    Map<String, int> exerciseMinutes = {};

    for (final r in records) {
      totalMinutes += r.duration;
      totalCalories += r.calories ?? 0;
      if (r.distance != null) {
        totalDistance += (r.distance! * 1000).toInt();
      }
      
      exerciseCount[r.name] = (exerciseCount[r.name] ?? 0) + 1;
      exerciseMinutes[r.name] = (exerciseMinutes[r.name] ?? 0) + r.duration;
    }

    // 找出最常用的运动
    final sortedByCount = exerciseCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sortedByMinutes = exerciseMinutes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 总统计卡片
        _buildTotalStatsCard(totalMinutes, totalCalories, records.length),
        
        const SizedBox(height: 16),
        
        // 最常用运动
        if (sortedByCount.isNotEmpty) ...[
          const Text(
            '运动',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.favorite, color: Colors.red),
              title: Text(sortedByCount.first.key),
              subtitle: Text('${sortedByCount.first.value} 次'),
            ),
          ),
          const SizedBox(height: 8),
          ...sortedByCount.skip(1).take(4).map((e) => 
            Card(
              child: ListTile(
                title: Text(e.key),
                subtitle: Text('${e.value} 次'),
              ),
            )
          ),
          
          const SizedBox(height: 16),
        ],
        
        // 耗时最长的运动
        if (sortedByMinutes.isNotEmpty) ...[
          const Text(
            '耗时最长的运动',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.timer, color: Colors.blue),
              title: Text(sortedByMinutes.first.key),
              subtitle: Text('${sortedByMinutes.first.value} 分钟'),
            ),
          ),
          const SizedBox(height: 8),
          ...sortedByMinutes.skip(1).take(4).map((e) => 
            Card(
              child: ListTile(
                title: Text(e.key),
                subtitle: Text('${e.value} 分钟'),
              ),
            )
          ),
          
          const SizedBox(height: 16),
        ],
        
        // 运动类型统计
        _buildExerciseTypeStats(records),
      ],
    );
  }

  Widget _buildTotalStatsCard(int minutes, int calories, int count) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bar_chart, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  '累计统计',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('$hours 小时 $remainingMinutes 分钟', '总时长', Colors.blue),
                _buildStatItem('$calories 千卡', '总消耗', Colors.orange),
                _buildStatItem('$count 次', '总次数', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildExerciseTypeStats(List<ExerciseRecord> records) {
    int aerobicCount = 0;
    int anaerobicCount = 0;
    int aerobicMinutes = 0;
    int anaerobicMinutes = 0;

    for (final r in records) {
      if (r.type == 'aerobic') {
        aerobicCount++;
        aerobicMinutes += r.duration;
      } else {
        anaerobicCount++;
        anaerobicMinutes += r.duration;
      }
    }

    final total = aerobicCount + anaerobicCount;
    if (total == 0) return const SizedBox.shrink();

    final aerobicPercent = aerobicCount / total * 100;
    final anaerobicPercent = anaerobicCount / total * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '运动类型分布',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.directions_run, color: Colors.blue, size: 20),
                              SizedBox(width: 8),
                              Text('有氧运动'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: aerobicPercent / 100,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation(Colors.blue),
                              minHeight: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$aerobicCount 次 | $aerobicMinutes 分钟',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.fitness_center, color: Colors.purple, size: 20),
                              SizedBox(width: 8),
                              Text('力量训练'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: anaerobicPercent / 100,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation(Colors.purple),
                              minHeight: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$anaerobicCount 次 | $anaerobicMinutes 分钟',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
