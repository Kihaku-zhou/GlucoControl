import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/database/database.dart';
import '../../../data/database/database_providers.dart';

/// 运动报告页面
class ExerciseReportScreen extends ConsumerWidget {
  const ExerciseReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(exerciseRecordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('运动报告'),
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
                  Icon(Icons.assessment_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('暂无运动数据', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('开始记录运动来查看报告', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // 计算本月统计
          final now = DateTime.now();
          final monthStart = DateTime(now.year, now.month, 1);
          final monthRecords = records.where((r) => 
            r.startedAt.isAfter(monthStart) || r.startedAt.isAtSameMomentAs(monthStart)
          ).toList();

          return _buildReport(context, monthRecords, records, now);
        },
      ),
    );
  }

  Widget _buildReport(BuildContext context, List<ExerciseRecord> monthRecords, 
      List<ExerciseRecord> allRecords, DateTime now) {
    // 本月统计
    final monthStats = _calculateStats(monthRecords);
    final allStats = _calculateStats(allRecords);

    // 运动类型分布
    final typeDistribution = _getTypeDistribution(monthRecords);
    
    // 本月目标进度
    final weeklyGoal = 150; // 默认目标
    final weeksInMonth = (now.day / 7).ceil();
    final monthlyGoal = weeklyGoal * weeksInMonth;
    final goalProgress = (monthStats['totalMinutes']! / monthlyGoal * 100).clamp(0, 100);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 月报告标题
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.assessment, size: 48, color: Colors.green),
                  const SizedBox(height: 8),
                  Text(
                    '${now.year}年${now.month}月运动报告',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text('共 ${monthRecords.length} 次运动', style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 目标进度
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('月度目标进度', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${monthStats['totalMinutes']} / $monthGoal 分钟'),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: goalProgress / 100,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation(
                                  goalProgress >= 100 ? Colors.green : Colors.blue,
                                ),
                                minHeight: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${goalProgress.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: goalProgress >= 100 ? Colors.green : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 统计摘要
          Row(
            children: [
              Expanded(child: _buildStatCard(
                '本月运动', 
                '${monthStats['totalMinutes']}', 
                '分钟', 
                Colors.blue,
              )),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard(
                '消耗热量', 
                '${monthStats['totalCalories']}', 
                '千卡', 
                Colors.orange,
              )),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard(
                '运动次数', 
                '${monthStats['totalCount']}', 
                '次', 
                Colors.green,
              )),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 运动类型分布
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('运动类型分布', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildTypeDistribution(typeDistribution),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 历史累计统计
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('历史累计', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildHistoryRow('总运动时长', '${allStats['totalMinutes']} 分钟', Icons.timer),
                  _buildHistoryRow('总运动次数', '${allStats['totalCount']} 次', Icons.fitness_center),
                  _buildHistoryRow('总消耗热量', '${allStats['totalCalories']} 千卡', Icons.local_fire_department),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, int> _calculateStats(List<ExerciseRecord> records) {
    int totalMinutes = 0;
    int totalCalories = 0;
    
    for (final r in records) {
      totalMinutes += r.duration;
      totalCalories += r.calories ?? 0;
    }
    
    return {
      'totalMinutes': totalMinutes,
      'totalCalories': totalCalories,
      'totalCount': records.length,
    };
  }

  Map<String, int> _getTypeDistribution(List<ExerciseRecord> records) {
    int aerobic = 0;
    int anaerobic = 0;
    
    for (final r in records) {
      if (r.type == 'aerobic') {
        aerobic++;
      } else {
        anaerobic++;
      }
    }
    
    return {
      'aerobic': aerobic,
      'anaerobic': anaerobic,
    };
  }

  Widget _buildStatCard(String label, String value, String unit, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(unit, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeDistribution(Map<String, int> distribution) {
    final total = distribution['aerobic']! + distribution['anaerobic']!;
    if (total == 0) {
      return const Text('暂无数据', style: TextStyle(color: Colors.grey));
    }
    
    final aerobicPercent = distribution['aerobic']! / total * 100;
    final anaerobicPercent = distribution['anaerobic']! / total * 100;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTypeBar('有氧运动', aerobicPercent, Colors.blue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTypeBar('力量训练', anaerobicPercent, Colors.purple),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text('${distribution['aerobic']} 次', style: const TextStyle(color: Colors.blue)),
            Text('${distribution['anaerobic']} 次', style: const TextStyle(color: Colors.purple)),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeBar(String label, double percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('${percent.toStringAsFixed(0)}%'),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
