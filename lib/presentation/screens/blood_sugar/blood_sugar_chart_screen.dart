import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../data/database/database.dart';
import '../../../data/database/database_providers.dart';

/// 血糖图表页面
class BloodSugarChartScreen extends ConsumerStatefulWidget {
  const BloodSugarChartScreen({super.key});

  @override
  ConsumerState<BloodSugarChartScreen> createState() => _BloodSugarChartScreenState();
}

class _BloodSugarChartScreenState extends ConsumerState<BloodSugarChartScreen> {
  DateRange _selectedRange = DateRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(
      bloodSugarRecordsByDateRangeProvider(_selectedRange),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('血糖趋势'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                switch (value) {
                  case '7d':
                    _selectedRange = DateRange(
                      start: DateTime.now().subtract(const Duration(days: 7)),
                      end: DateTime.now(),
                    );
                    break;
                  case '30d':
                    _selectedRange = DateRange(
                      start: DateTime.now().subtract(const Duration(days: 30)),
                      end: DateTime.now(),
                    );
                    break;
                  case '90d':
                    _selectedRange = DateRange(
                      start: DateTime.now().subtract(const Duration(days: 90)),
                      end: DateTime.now(),
                    );
                    break;
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: '7d', child: Text('最近 7 天')),
              const PopupMenuItem(value: '30d', child: Text('最近 30 天')),
              const PopupMenuItem(value: '90d', child: Text('最近 90 天')),
            ],
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const Text('筛选'),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: recordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('错误: $error')),
        data: (records) {
          if (records.isEmpty) {
            return const Center(
              child: Text('暂无数据', style: TextStyle(color: Colors.grey)),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 统计卡片
                _buildStatisticsCard(records),
                const SizedBox(height: 24),

                // 血糖范围图例
                _buildLegend(),
                const SizedBox(height: 16),

                // 图表
                SizedBox(
                  height: 300,
                  child: _buildChart(records),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatisticsCard(List<BloodSugarRecord> records) {
    // 获取当前单位
    final currentUnit = ref.watch(bloodSugarUnitProvider);
    
    // 先把所有血糖值统一转换为 mg/dL 再计算统计
    double totalMgDl = 0;
    double maxMgDl = double.negativeInfinity;
    double minMgDl = double.infinity;
    for (final r in records) {
      if (r.unit == 'mmol/L') {
        totalMgDl += AppConstants.mmolLToMgDl(r.value);
        final mgDlValue = AppConstants.mmolLToMgDl(r.value);
        if (mgDlValue > maxMgDl) maxMgDl = mgDlValue;
        if (mgDlValue < minMgDl) minMgDl = mgDlValue;
      } else {
        totalMgDl += r.value;
        if (r.value > maxMgDl) maxMgDl = r.value;
        if (r.value < minMgDl) minMgDl = r.value;
      }
    }
    final avgMgDl = totalMgDl / records.length;
    
    // 获取安全范围（存储的是 mg/dL）
    final safeMinStored = ref.read(safeRangeMinProvider);
    final safeMaxStored = ref.read(safeRangeMaxProvider);
    
    // 转换为当前显示单位
    final safeMin = currentUnit == 'mmol/L' ? AppTheme.mgdlToMmoll(safeMinStored) : safeMinStored;
    final safeMax = currentUnit == 'mmol/L' ? AppTheme.mgdlToMmoll(safeMaxStored) : safeMaxStored;
    
    // 将统计值转换为显示单位
    final displayAvg = currentUnit == 'mmol/L' ? AppTheme.mgdlToMmoll(avgMgDl) : avgMgDl;
    final displayMax = currentUnit == 'mmol/L' ? AppTheme.mgdlToMmoll(maxMgDl) : maxMgDl;
    final displayMin = currentUnit == 'mmol/L' ? AppTheme.mgdlToMmoll(minMgDl) : minMgDl;
    
    // 计算达标率 TIR (Time In Range)
    final inRange = records.where((r) {
      final mgDlValue = r.unit == 'mmol/L' ? AppConstants.mmolLToMgDl(r.value) : r.value;
      return mgDlValue >= safeMinStored && mgDlValue <= safeMaxStored;
    }).length;
    final inRangePercent = (inRange / records.length * 100).toStringAsFixed(1);
    
    // 计算低血糖和高血糖占比
    final lowCount = records.where((r) {
      final mgDlValue = r.unit == 'mmol/L' ? AppConstants.mmolLToMgDl(r.value) : r.value;
      return mgDlValue < safeMinStored;
    }).length;
    final highCount = records.where((r) {
      final mgDlValue = r.unit == 'mmol/L' ? AppConstants.mmolLToMgDl(r.value) : r.value;
      return mgDlValue > safeMaxStored;
    }).length;
    final lowPercent = (lowCount / records.length * 100).toStringAsFixed(1);
    final highPercent = (highCount / records.length * 100).toStringAsFixed(1);
    
    final displayValues = records.map((r) {
      final mgDlValue = r.unit == 'mmol/L' ? AppConstants.mmolLToMgDl(r.value) : r.value;
      return currentUnit == 'mmol/L' ? AppTheme.mgdlToMmoll(mgDlValue) : mgDlValue;
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '统计摘要',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('平均值', displayAvg.toStringAsFixed(1), currentUnit),
                _buildStatItem('最高', displayMax.toStringAsFixed(1), currentUnit),
                _buildStatItem('最低', displayMin.toStringAsFixed(1), currentUnit),
                _buildStatItem('TIR', '$inRangePercent', '%', color: Colors.green),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // TIR 明细
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('达标', '$inRangePercent', '%', color: Colors.green),
                _buildStatItem('偏低', '$lowPercent', '%', color: Colors.orange),
                _buildStatItem('偏高', '$highPercent', '%', color: Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit, {Color? color}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black,
          ),
        ),
        Text(unit, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildLegendItem('低血糖', AppTheme.lowBloodSugarColor),
        _buildLegendItem('正常', AppTheme.normalBloodSugarColor),
        _buildLegendItem('糖尿病前期', AppTheme.preDiabetesColor),
        _buildLegendItem('高血糖', AppTheme.highBloodSugarColor),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildChart(List<BloodSugarRecord> records) {
    // 按时间排序
    final sortedRecords = List<BloodSugarRecord>.from(records)
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    // 获取当前单位
    final currentUnit = ref.watch(bloodSugarUnitProvider);
    
    // 获取安全范围（存储的是 mg/dL）
    final safeMinStored = ref.read(safeRangeMinProvider);
    final safeMaxStored = ref.read(safeRangeMaxProvider);
    
    // 转换为显示单位
    final safeMin = currentUnit == 'mmol/L' ? AppTheme.mgdlToMmoll(safeMinStored) : safeMinStored;
    final safeMax = currentUnit == 'mmol/L' ? AppTheme.mgdlToMmoll(safeMaxStored) : safeMaxStored;

    // 使用时间戳作为x轴，实现等比例显示
    final minTime = sortedRecords.first.recordedAt.millisecondsSinceEpoch.toDouble();
    final maxTime = sortedRecords.last.recordedAt.millisecondsSinceEpoch.toDouble();
    final timeRange = maxTime - minTime;
    
    // 如果只有一个点或时间范围为0，使用索引
    // 先统一转为 mg/dL，再根据当前显示单位转换
    final spots = sortedRecords.map((r) {
      // 先统一转换为 mg/dL
      final mgDlValue = r.unit == 'mmol/L' ? AppConstants.mmolLToMgDl(r.value) : r.value;
      // 再转换为显示单位
      final displayValue = currentUnit == 'mmol/L' ? AppTheme.mgdlToMmoll(mgDlValue) : mgDlValue;
      if (timeRange > 0 && sortedRecords.length > 1) {
        // 将时间戳映射到 0 到 (n-1) 的范围
        final x = (r.recordedAt.millisecondsSinceEpoch.toDouble() - minTime) / timeRange * (sortedRecords.length - 1);
        return FlSpot(x, displayValue);
      } else {
        // 只有一个点或时间相同，使用索引
        final index = sortedRecords.indexOf(r);
        return FlSpot(index.toDouble(), displayValue);
      }
    }).toList();
    
    // 计算Y轴范围
    final displayValues = spots.map((s) => s.y).toList();
    final minY = (displayValues.reduce((a, b) => a < b ? a : b) - 30).clamp(0.0, double.infinity).toDouble();
    final maxY = (displayValues.reduce((a, b) => a > b ? a : b) + 30).toDouble();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          horizontalInterval: currentUnit == 'mmol/L' ? 2 : 50,  // mmol/L 时间隔为2
          getDrawingHorizontalLine: (value) {
            if ((value - safeMin).abs() < 0.1 || (value - safeMax).abs() < 0.1) {
              return FlLine(
                color: Colors.orange.withValues(alpha: 0.5),
                strokeWidth: 2,
                dashArray: [5, 5],
              );
            }
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: sortedRecords.length > 1 ? 1 : 1,
              getTitlesWidget: (value, meta) {
                // 根据x值计算对应的记录索引
                final index = value.toInt();
                if (index >= 0 && index < sortedRecords.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('MM/dd').format(sortedRecords[index].recordedAt),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              interval: currentUnit == 'mmol/L' ? 2 : 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(currentUnit == 'mmol/L' ? 1 : 0),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        minX: 0,
        maxX: (sortedRecords.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final value = sortedRecords[index].value;
                final color = AppTheme.getBloodSugarColor(value, currentUnit);
                return FlDotCirclePainter(
                  radius: 5,
                  color: color,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withValues(alpha: 0.1),
            ),
          ),
        ],
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: safeMin,
              color: Colors.orange.withValues(alpha: 0.5),
              strokeWidth: 2,
              dashArray: [5, 5],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                style: const TextStyle(color: Colors.orange, fontSize: 10),
                labelResolver: (line) => '下限: ${safeMin.toStringAsFixed(currentUnit == 'mmol/L' ? 1 : 0)}',
              ),
            ),
            HorizontalLine(
              y: safeMax,
              color: Colors.orange.withValues(alpha: 0.5),
              strokeWidth: 2,
              dashArray: [5, 5],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.bottomRight,
                style: const TextStyle(color: Colors.orange, fontSize: 10),
                labelResolver: (line) => '上限: ${safeMax.toStringAsFixed(currentUnit == 'mmol/L' ? 1 : 0)}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
