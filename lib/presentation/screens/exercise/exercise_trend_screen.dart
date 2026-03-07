import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../data/database/database.dart';
import '../../../data/database/database_providers.dart';

/// 运动趋势图表页面
class ExerciseTrendScreen extends ConsumerWidget {
  const ExerciseTrendScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(exerciseRecordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('运动趋势'),
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
                  Icon(Icons.show_chart, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('暂无运动数据', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('开始记录运动来查看趋势', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return _buildTrendChart(context, records);
        },
      ),
    );
  }

  Widget _buildTrendChart(BuildContext context, List<ExerciseRecord> records) {
    // 计算最近8周的运动数据
    final now = DateTime.now();
    final weeklyData = <String, int>{};
    
    for (int i = 7; i >= 0; i--) {
      final weekStart = now.subtract(Duration(days: now.weekday - 1 + i * 7));
      final weekEnd = weekStart.add(const Duration(days: 6));
      final weekKey = '${weekStart.month}/${weekStart.day}';
      
      int totalMinutes = 0;
      for (final r in records) {
        if ((r.startedAt.isAfter(weekStart) || r.startedAt.isAtSameMomentAs(weekStart)) &&
            r.startedAt.isBefore(weekEnd.add(const Duration(days: 1)))) {
          totalMinutes += r.duration;
        }
      }
      weeklyData[weekKey] = totalMinutes;
    }

    final spots = <FlSpot>[];
    int index = 0;
    weeklyData.forEach((key, value) {
      spots.add(FlSpot(index.toDouble(), value.toDouble()));
      index++;
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 标题
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.show_chart, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    '每周运动时长趋势',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 图表
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 250,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 60,
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}',
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final keys = weeklyData.keys.toList();
                            if (value.toInt() >= 0 && value.toInt() < keys.length) {
                              return Text(
                                keys[value.toInt()],
                                style: const TextStyle(fontSize: 10),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.blue.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                    minY: 0,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 统计信息
          _buildStatsCards(records, weeklyData),
          
          const SizedBox(height: 16),
          
          // 目标对比
          _buildGoalComparison(weeklyData),
        ],
      ),
    );
  }

  Widget _buildStatsCards(List<ExerciseRecord> records, Map<String, int> weeklyData) {
    // 计算统计数据
    int totalMinutes = 0;
    int totalCalories = 0;
    for (final r in records) {
      totalMinutes += r.duration;
      totalCalories += r.calories ?? 0;
    }
    
    final avgWeekly = weeklyData.values.isEmpty ? 0 : weeklyData.values.reduce((a, b) => a + b) ~/ weeklyData.length;
    final maxWeekly = weeklyData.values.isEmpty ? 0 : weeklyData.values.reduce((a, b) => a > b ? a : b);

    return Row(
      children: [
        Expanded(child: _buildStatCard('总时长', '$totalMinutes 分钟', Colors.blue)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard('总热量', '$totalCalories kcal', Colors.orange)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard('周平均', '$avgWeekly 分钟', Colors.green)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalComparison(Map<String, int> weeklyData) {
    const weeklyGoal = 150; // 每周目标150分钟
    final lastWeek = weeklyData.values.isNotEmpty ? weeklyData.values.last : 0;
    final progress = (lastWeek / weeklyGoal * 100).clamp(0, 100);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '上周目标对比',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$lastWeek / $weeklyGoal 分钟'),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress / 100,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(
                            progress >= 100 ? Colors.green : Colors.blue,
                          ),
                          minHeight: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${progress.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: progress >= 100 ? Colors.green : Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
