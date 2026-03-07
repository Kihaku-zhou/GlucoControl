import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/database/database.dart';
import '../../../data/database/database_providers.dart';

/// 运动周报页面
class ExerciseWeeklyReportScreen extends ConsumerWidget {
  const ExerciseWeeklyReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(exerciseRecordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('运动周报'),
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
                  Icon(Icons.calendar_view_week, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('暂无运动数据', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('开始记录运动来查看周报', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return _buildWeeklyReport(context, records);
        },
      ),
    );
  }

  Widget _buildWeeklyReport(BuildContext context, List<ExerciseRecord> records) {
    final now = DateTime.now();
    final weekReports = <Map<String, dynamic>>[];

    // 获取最近4周的数据
    for (int i = 0; i < 4; i++) {
      final weekStart = now.subtract(Duration(days: now.weekday - 1 + i * 7));
      final weekEnd = weekStart.add(const Duration(days: 6));
      
      final weekRecords = records.where((r) =>
        (r.startedAt.isAfter(weekStart) || r.startedAt.isAtSameMomentAs(weekStart)) &&
        r.startedAt.isBefore(weekEnd.add(const Duration(days: 1)))
      ).toList();

      int totalMinutes = 0;
      int totalCalories = 0;
      int aerobicCount = 0;
      int anaerobicCount = 0;

      for (final r in weekRecords) {
        totalMinutes += r.duration;
        totalCalories += r.calories ?? 0;
        if (r.type == 'aerobic') {
          aerobicCount++;
        } else {
          anaerobicCount++;
        }
      }

      weekReports.add({
        'weekStart': weekStart,
        'weekEnd': weekEnd,
        'totalMinutes': totalMinutes,
        'totalCalories': totalCalories,
        'aerobicCount': aerobicCount,
        'anaerobicCount': anaerobicCount,
        'totalCount': weekRecords.length,
      });
    }

    // 反转顺序，最新的周报在前面
    weekReports.reversed.toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 本周数据
        _buildThisWeekCard(weekReports.isNotEmpty ? weekReports.last : null),
        
        const SizedBox(height: 16),
        
        // 历史周报
        const Text(
          '历史周报',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        
        ...weekReports.reversed.skip(1).map((report) => _buildWeekCard(report)),
      ],
    );
  }

  Widget _buildThisWeekCard(Map<String, dynamic>? report) {
    if (report == null || report['totalCount'] == 0) {
      return Card(
        color: Colors.blue.shade50,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.calendar_today, size: 48, color: Colors.blue),
              SizedBox(height: 8),
              Text(
                '本周运动',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('暂无记录，开始运动吧！', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    final weekStart = report['weekStart'] as DateTime;
    final weekEnd = report['weekEnd'] as DateTime;
    const weeklyGoal = 150; // 每周目标150分钟
    final progress = (report['totalMinutes'] as int / weeklyGoal * 100).clamp(0, 100);

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  '${DateFormat('M/d').format(weekStart)} - ${DateFormat('M/d').format(weekEnd)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 目标进度
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${report['totalMinutes']} / $weeklyGoal 分钟'),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress / 100,
                          backgroundColor: Colors.grey.shade300,
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
            
            const SizedBox(height: 16),
            
            // 统计
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('${report['totalMinutes']}', '分钟', Colors.blue),
                _buildStatColumn('${report['totalCalories']}', '千卡', Colors.orange),
                _buildStatColumn('${report['totalCount']}', '次', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekCard(Map<String, dynamic> report) {
    final weekStart = report['weekStart'] as DateTime;
    final weekEnd = report['weekEnd'] as DateTime;
    const weeklyGoal = 150;
    final progress = (report['totalMinutes'] as int / weeklyGoal * 100).clamp(0, 100);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: progress >= 100 ? Colors.green.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            progress >= 100 ? Icons.check_circle : Icons.calendar_view_week,
            color: progress >= 100 ? Colors.green : Colors.grey,
          ),
        ),
        title: Text(
          '${DateFormat('M/d').format(weekStart)} - ${DateFormat('M/d').format(weekEnd)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${report['totalMinutes']} 分钟 | ${report['totalCalories']} 千卡 | ${report['totalCount']} 次',
        ),
        trailing: Text(
          '${progress.toStringAsFixed(0)}%',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: progress >= 100 ? Colors.green : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String unit, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        Text(unit, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
