import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../data/database/database.dart';
import '../../../data/database/database_providers.dart';

/// 血糖趋势图表页面
class BloodSugarTrendScreen extends ConsumerWidget {
  const BloodSugarTrendScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(bloodSugarRecordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('血糖趋势'),
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
                  Text('暂无血糖数据', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('开始记录血糖来查看趋势', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return _buildTrendChart(context, records);
        },
      ),
    );
  }

  Widget _buildTrendChart(BuildContext context, List<BloodSugarRecord> records) {
    // 获取最近8周的数据
    final now = DateTime.now();
    final weeklyData = <String, Map<String, double>>{};
    
    for (int i = 7; i >= 0; i--) {
      final weekStart = now.subtract(Duration(days: now.weekday - 1 + i * 7));
      final weekEnd = weekStart.add(const Duration(days: 6));
      final weekKey = '${weekStart.month}/${weekStart.day}';
      
      double total = 0;
      int count = 0;
      double max = double.negativeInfinity;
      double min = double.infinity;
      
      for (final r in records) {
        if ((r.recordedAt.isAfter(weekStart) || r.recordedAt.isAtSameMomentAs(weekStart)) &&
            r.recordedAt.isBefore(weekEnd.add(const Duration(days: 1)))) {
          final value = r.unit == 'mmol/L' ? AppConstants.mmolLToMgDl(r.value) : r.value;
          total += value;
          count++;
          if (value > max) max = value;
          if (value < min) min = value;
        }
      }
      
      if (count > 0) {
        weeklyData[weekKey] = {
          'avg': total / count,
          'max': max,
          'min': min,
        };
      }
    }

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
                    '每周血糖趋势',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 趋势图表
          _buildLineChart(weeklyData),
          
          const SizedBox(height: 16),
          
          // 统计摘要
          _buildStatsSummary(records),
          
          const SizedBox(height: 16),
          
          // 达标率趋势
          _buildTirTrend(records),
        ],
      ),
    );
  }

  Widget _buildLineChart(Map<String, Map<String, double>> weeklyData) {
    if (weeklyData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('暂无数据')),
        ),
      );
    }

    final spots = <FlSpot>[];
    final maxSpots = <FlSpot>[];
    final minSpots = <FlSpot>[];
    
    int index = 0;
    weeklyData.forEach((key, data) {
      spots.add(FlSpot(index.toDouble(), data['avg']!));
      maxSpots.add(FlSpot(index.toDouble(), data['max']!));
      minSpots.add(FlSpot(index.toDouble(), data['min']!));
      index++;
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('每周平均血糖趋势', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 50,
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
                    // 平均值线
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                  minY: 50,
                  maxY: 250,
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      // 安全范围线
                      HorizontalLine(
                        y: 70,
                        color: Colors.green.withValues(alpha: 0.5),
                        strokeWidth: 2,
                        dashArray: [5, 5],
                      ),
                      HorizontalLine(
                        y: 140,
                        color: Colors.green.withValues(alpha: 0.5),
                        strokeWidth: 2,
                        dashArray: [5, 5],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('—', style: TextStyle(color: Colors.green)),
                SizedBox(width: 4),
                Text('安全范围 70-140 mg/dL', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSummary(List<BloodSugarRecord> records) {
    double total = 0;
    int count = 0;
    for (final r in records) {
      final value = r.unit == 'mmol/L' ? AppConstants.mmolLToMgDl(r.value) : r.value;
      total += value;
      count++;
    }
    final avg = count > 0 ? total / count : 0.0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('统计摘要', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('总记录', '$count', '次'),
                _buildStatItem('平均血糖', avg.toStringAsFixed(0), 'mg/dL'),
                _buildStatItem('记录天数', '${_getUniqueDays(records)}', '天'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(unit, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  int _getUniqueDays(List<BloodSugarRecord> records) {
    final days = <String>{};
    for (final r in records) {
      days.add('${r.recordedAt.year}-${r.recordedAt.month}-${r.recordedAt.day}');
    }
    return days.length;
  }

  Widget _buildTirTrend(List<BloodSugarRecord> records) {
    const safeMin = 70.0;
    const safeMax = 140.0;
    
    // 计算最近4周的数据
    final now = DateTime.now();
    final tirData = <String, double>{};
    
    for (int i = 3; i >= 0; i--) {
      final weekStart = now.subtract(Duration(days: now.weekday - 1 + i * 7));
      final weekEnd = weekStart.add(const Duration(days: 6));
      final weekKey = '${weekStart.month}/${weekStart.day}';
      
      int inRange = 0;
      int total = 0;
      
      for (final r in records) {
        if ((r.recordedAt.isAfter(weekStart) || r.recordedAt.isAtSameMomentAs(weekStart)) &&
            r.recordedAt.isBefore(weekEnd.add(const Duration(days: 1)))) {
          final value = r.unit == 'mmol/L' ? AppConstants.mmolLToMgDl(r.value) : r.value;
          if (value >= safeMin && value <= safeMax) {
            inRange++;
          }
          total++;
        }
      }
      
      if (total > 0) {
        tirData[weekKey] = inRange / total * 100;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('TIR (达标率) 趋势', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...tirData.entries.map((e) => _buildTirRow(e.key, e.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildTirRow(String week, double tir) {
    Color color;
    if (tir >= 70) {
      color = Colors.green;
    } else if (tir >= 50) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(week),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: tir / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Text(
              '${tir.toStringAsFixed(0)}%',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
