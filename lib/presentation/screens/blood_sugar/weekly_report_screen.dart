import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../data/database/database.dart';
import '../../../data/database/database_providers.dart';

/// 每周血糖报告页面
class WeeklyReportScreen extends ConsumerWidget {
  const WeeklyReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(bloodSugarRecordsProvider);
    final currentUnit = ref.watch(bloodSugarUnitProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('每周报告'),
      ),
      body: recordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('错误: $error')),
        data: (records) {
          // 获取本周数据
          final now = DateTime.now();
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          final startOfWeek = DateTime(weekStart.year, weekStart.month, weekStart.day);
          
          final weekRecords = records.where((r) => 
            r.recordedAt.isAfter(startOfWeek) || 
            r.recordedAt.isAtSameMomentAs(startOfWeek)
          ).toList();

          if (weekRecords.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assessment_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('本周暂无数据', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('开始记录血糖来查看每周报告', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // 计算统计数据
          return _buildReport(context, weekRecords, currentUnit, startOfWeek, now);
        },
      ),
    );
  }

  Widget _buildReport(BuildContext context, List<BloodSugarRecord> records, 
      String currentUnit, DateTime weekStart, DateTime weekEnd) {
    // 统一转换为 mg/dL 计算
    double totalMgDl = 0;
    double maxMgDl = double.negativeInfinity;
    double minMgDl = double.infinity;
    int fastingCount = 0;
    int postMealCount = 0;
    
    for (final r in records) {
      final mgDlValue = r.unit == 'mmol/L' ? AppConstants.mmolLToMgDl(r.value) : r.value;
      totalMgDl += mgDlValue;
      if (mgDlValue > maxMgDl) maxMgDl = mgDlValue;
      if (mgDlValue < minMgDl) minMgDl = mgDlValue;
      
      if (r.type == 'fasting') {
        fastingCount++;
      } else if (r.type == 'post_meal') {
        postMealCount++;
      }
    }
    
    final avgMgDl = totalMgDl / records.length;
    final safeMinStored = 70.0;
    final safeMaxStored = 140.0;
    
    final inRange = records.where((r) {
      final mgDlValue = r.unit == 'mmol/L' ? AppConstants.mmolLToMgDl(r.value) : r.value;
      return mgDlValue >= safeMinStored && mgDlValue <= safeMaxStored;
    }).length;
    final tir = (inRange / records.length * 100);

    // 转换显示单位
    final displayAvg = currentUnit == 'mmol/L' ? AppTheme.mgdlToMmoll(avgMgDl) : avgMgDl;
    final displayMax = currentUnit == 'mmol/L' ? AppTheme.mgdlToMmoll(maxMgDl) : maxMgDl;
    final displayMin = currentUnit == 'mmol/L' ? AppTheme.mgdlToMmoll(minMgDl) : minMgDl;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 周报告标题
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.assessment, size: 48, color: Colors.blue),
                  const SizedBox(height: 8),
                  Text(
                    '${DateFormat('M月d日').format(weekStart)} - ${DateFormat('M月d日').format(weekEnd)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text('共 ${records.length} 条记录', style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // TIR 达标率
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('TIR (达标时间)', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    '${tir.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: tir >= 70 ? Colors.green : (tir >= 50 ? Colors.orange : Colors.red),
                    ),
                  ),
                  Text(
                    tir >= 70 ? '优秀' : (tir >= 50 ? '一般' : '需改进'),
                    style: TextStyle(
                      color: tir >= 70 ? Colors.green : (tir >= 50 ? Colors.orange : Colors.red),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('目标: ≥70%', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 统计摘要
          Row(
            children: [
              Expanded(child: _buildStatCard('平均值', '${displayAvg.toStringAsFixed(1)} $currentUnit', Colors.blue)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard('最高', '${displayMax.toStringAsFixed(1)} $currentUnit', Colors.red)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard('最低', '${displayMin.toStringAsFixed(1)} $currentUnit', Colors.orange)),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 记录类型分布
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('记录类型分布', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildDistributionRow('空腹血糖', fastingCount, records.length, Colors.blue),
                  const SizedBox(height: 8),
                  _buildDistributionRow('餐后血糖', postMealCount, records.length, Colors.green),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 建议
          Card(
            color: Colors.amber.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.amber),
                      SizedBox(width: 8),
                      Text('本周建议', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_generateSuggestion(tir, records.length, currentUnit)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
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
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionRow(String label, int count, int total, Color color) {
    final percent = total > 0 ? (count / total * 100) : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 16,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$count次', style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  String _generateSuggestion(double tir, int recordCount, String unit) {
    final suggestions = <String>[];
    
    if (recordCount < 7) {
      suggestions.add('建议每天至少测量 1 次血糖，以便更好地跟踪趋势');
    }
    
    if (tir < 50) {
      suggestions.add('达标率偏低，建议调整饮食结构，减少高糖食物摄入');
      suggestions.add('适当增加运动量，有助于提高胰岛素敏感性');
    } else if (tir < 70) {
      suggestions.add('达标率有提升空间，继续保持良好的生活习惯');
    } else {
      suggestions.add('本周血糖控制优秀！继续保持');
    }
    
    if (suggestions.isEmpty) {
      suggestions.add('坚持记录血糖，了解自己的血糖变化规律');
    }
    
    return suggestions.join('\n');
  }
}
