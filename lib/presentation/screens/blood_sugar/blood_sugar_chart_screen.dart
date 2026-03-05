import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
    final values = records.map((r) => r.value).toList();
    final avg = values.reduce((a, b) => a + b) / values.length;
    final max = values.reduce((a, b) => a > b ? a : b);
    final min = values.reduce((a, b) => a < b ? a : b);
    
    // 计算达标率
    final safeMin = ref.read(safeRangeMinProvider);
    final safeMax = ref.read(safeRangeMaxProvider);
    final inRange = values.where((v) => v >= safeMin && v <= safeMax).length;
    final inRangePercent = (inRange / values.length * 100).toStringAsFixed(1);

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
                _buildStatItem('平均值', '${avg.toStringAsFixed(1)}', 'mg/dL'),
                _buildStatItem('最高', '${max.toStringAsFixed(1)}', 'mg/dL'),
                _buildStatItem('最低', '${min.toStringAsFixed(1)}', 'mg/dL'),
                _buildStatItem('达标率', '$inRangePercent', '%', color: Colors.green),
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

    final safeMin = ref.read(safeRangeMinProvider);
    final safeMax = ref.read(safeRangeMaxProvider);

    final spots = sortedRecords.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value.value,
      );
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          horizontalInterval: 50,
          getDrawingHorizontalLine: (value) {
            if (value == safeMin || value == safeMax) {
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
              interval: (sortedRecords.length / 5).ceilToDouble(),
              getTitlesWidget: (value, meta) {
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
              interval: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        minY: (sortedRecords.map((r) => r.value).reduce((a, b) => a < b ? a : b) - 30).clamp(0, double.infinity),
        maxY: sortedRecords.map((r) => r.value).reduce((a, b) => a > b ? a : b) + 30,
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
                final color = AppTheme.getBloodSugarColor(value);
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
                labelResolver: (line) => '下限: ${safeMin.toInt()}',
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
                labelResolver: (line) => '上限: ${safeMax.toInt()}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
