import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/constants.dart';
import '../../../core/app_colors.dart';
import '../../../core/theme.dart';
import '../../../data/database/database.dart';
import '../../../data/database/database_providers.dart';

/// 血糖统计详情页面
class BloodSugarStatsScreen extends ConsumerWidget {
  const BloodSugarStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(bloodSugarRecordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('血糖统计'),
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
                  Text('暂无血糖数据', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          return _buildStats(context, records);
        },
      ),
    );
  }

  Widget _buildStats(BuildContext context, List<BloodSugarRecord> records) {
    final currentUnit = ref.watch(bloodSugarUnitProvider);
    final safeMin = ref.watch(safeRangeMinProvider);
    final safeMax = ref.watch(safeRangeMaxProvider);

    // 统一转换为 mg/dL 计算
    double totalMgDl = 0;
    double maxMgDl = double.negativeInfinity;
    double minMgDl = double.infinity;
    int fastingCount = 0;
    int postMealCount = 0;
    int inRangeCount = 0;
    int lowCount = 0;
    int highCount = 0;

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

      if (mgDlValue >= safeMin && mgDlValue <= safeMax) {
        inRangeCount++;
      } else if (mgDlValue < safeMin) {
        lowCount++;
      } else {
        highCount++;
      }
    }

    final avgMgDl = totalMgDl / records.length;
    final tir = records.isNotEmpty ? (inRangeCount / records.length * 100) : 0.0;

    // 转换为显示单位
    String formatValue(double value) {
      if (currentUnit == 'mmol/L') {
        return AppTheme.mgdlToMmoll(value).toStringAsFixed(1);
      }
      return value.toStringAsFixed(0);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // TIR 达标率卡片
        _buildTirCard(tir, inRangeCount, records.length),
        
        const SizedBox(height: 16),
        
        // 统计摘要
        _buildSummaryCard(
          formatValue(avgMgDl),
          formatValue(maxMgDl),
          formatValue(minMgDl),
          currentUnit,
        ),
        
        const SizedBox(height: 16),
        
        // 血糖类型分布
        _buildTypeDistributionCard(fastingCount, postMealCount, records.length),
        
        const SizedBox(height: 16),
        
        // 血糖范围分布
        _buildRangeDistributionCard(inRangeCount, lowCount, highCount, records.length),
        
        const SizedBox(height: 16),
        
        // 总记录数
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('总记录', '${records.length}', '次', Colors.blue),
                _buildStatItem('偏低', '$lowCount', '次', Colors.orange),
                _buildStatItem('达标', '$inRangeCount', '次', Colors.green),
                _buildStatItem('偏高', '$highCount', '次', Colors.red),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTirCard(double tir, int inRange, int total) {
    Color tirColor;
    String tirStatus;
    if (tir >= 70) {
      tirColor = Colors.green;
      tirStatus = '优秀';
    } else if (tir >= 50) {
      tirColor = Colors.orange;
      tirStatus = '一般';
    } else {
      tirColor = Colors.red;
      tirStatus = '需改进';
    }

    return Card(
      color: tirColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'TIR (Time In Range)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${tir.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: tirColor,
              ),
            ),
            Text(
              tirStatus,
              style: TextStyle(color: tirColor, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '$inRange / $total 次达标',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: tir / 100,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation(tirColor),
                minHeight: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String avg, String max, String min, String unit) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '统计摘要',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('平均值', avg, unit, Colors.blue),
                _buildStatItem('最高', max, unit, Colors.red),
                _buildStatItem('最低', min, unit, Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeDistributionCard(int fasting, int postMeal, int total) {
    if (total == 0) return const SizedBox.shrink();
    
    final fastingPercent = fasting / total * 100;
    final postMealPercent = postMeal / total * 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '血糖类型分布',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('空腹血糖'),
                          Text('$fasting 次 (${fastingPercent.toStringAsFixed(0)}%)'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: fastingPercent / 100,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation(Colors.blue),
                          minHeight: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('餐后血糖'),
                          Text('$postMeal 次 (${postMealPercent.toStringAsFixed(0)}%)'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: postMealPercent / 100,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation(Colors.green),
                          minHeight: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeDistributionCard(int inRange, int low, int high, int total) {
    if (total == 0) return const SizedBox.shrink();
    
    final inRangePercent = inRange / total * 100;
    final lowPercent = low / total * 100;
    final highPercent = high / total * 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '血糖范围分布',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text('达标'),
                            ],
                          ),
                          Text('$inRangePercent.toStringAsFixed(0)}%'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text('偏低'),
                            ],
                          ),
                          Text('${lowPercent.toStringAsFixed(0)}%'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text('偏高'),
                            ],
                          ),
                          Text('${highPercent.toStringAsFixed(0)}%'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
        Text(unit, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
