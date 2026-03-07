import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../data/database/database.dart';
import '../../../data/database/database_providers.dart';
import 'blood_sugar_chart_screen.dart';
import 'weekly_report_screen.dart';
import 'blood_sugar_stats_screen.dart';
import 'blood_sugar_filter_screen.dart';
import 'blood_sugar_achievement_screen.dart';
import 'blood_sugar_trend_screen.dart';
import '../ai/ai_analysis_screen.dart';

/// 血糖记录列表页面
class BloodSugarListScreen extends ConsumerWidget {
  const BloodSugarListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(bloodSugarRecordsProvider);
    final currentUnit = ref.watch(bloodSugarUnitProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('血糖记录'),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WeeklyReportScreen(),
                ),
              );
            },
            tooltip: '每周报告',
          ),
          IconButton(
            icon: const Icon(Icons.psychology),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AIAnalysisScreen(),
                ),
              );
            },
            tooltip: 'AI 分析',
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BloodSugarChartScreen(),
                ),
              );
            },
            tooltip: '血糖图表',
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BloodSugarStatsScreen(),
                ),
              );
            },
            tooltip: '血糖统计',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BloodSugarFilterScreen(),
                ),
              );
            },
            tooltip: '筛选',
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BloodSugarAchievementScreen(),
                ),
              );
            },
            tooltip: '血糖成就',
          ),
          IconButton(
            icon: const Icon(Icons.trending_up),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BloodSugarTrendScreen(),
                ),
              );
            },
            tooltip: '血糖趋势',
          ),
        ],
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
                  Icon(Icons.monitor_heart_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('暂无血糖记录', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('点击右下角按钮添加记录', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // 计算 HbA1c（基于最近 30 天的平均血糖）
          final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
          final recentRecords = records.where((r) => r.recordedAt.isAfter(thirtyDaysAgo)).toList();
          double? estimatedHbA1c;
          if (recentRecords.isNotEmpty) {
            // 先把所有血糖值转换为 mg/dL 再求平均
            double totalMgDl = 0;
            for (final r in recentRecords) {
              if (r.unit == 'mmol/L') {
                totalMgDl += AppConstants.mmolLToMgDl(r.value);
              } else {
                totalMgDl += r.value;
              }
            }
            final avgBloodSugar = totalMgDl / recentRecords.length;
            estimatedHbA1c = (avgBloodSugar + 46.7) / 28.7;
          }

          // 按日期分组
          final groupedRecords = _groupRecordsByDate(records);

          return Column(
            children: [
              // HbA1c 估算卡片
              if (estimatedHbA1c != null)
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.analytics, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('预估 HbA1c', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Text(
                          '${estimatedHbA1c.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: estimatedHbA1c < 5.7 ? Colors.green : (estimatedHbA1c < 6.5 ? Colors.orange : Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // 记录列表
              Expanded(
                child: ListView.builder(
                  itemCount: groupedRecords.length,
                  itemBuilder: (context, index) {
                    final date = groupedRecords.keys.elementAt(index);
                    final dayRecords = groupedRecords[date]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            date,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        ...dayRecords.map((record) => _BloodSugarRecordTile(record: record)),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickAddMenu(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showQuickAddMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _QuickAddMenu(
        onAdd: (value, type) => _quickAddBloodSugar(context, ref, value, type),
        onAddCustom: () {
          Navigator.pop(context);
          _showAddBloodSugarDialog(context, ref);
        },
      ),
    );
  }

  Future<void> _quickAddBloodSugar(BuildContext context, WidgetRef ref, double value, String type) async {
    Navigator.pop(context);
    try {
      final db = ref.read(databaseProvider);
      final currentUnit = ref.read(bloodSugarUnitProvider);
      
      // 转换为 mg/dL 存储
      var mgDlValue = value;
      if (currentUnit == 'mmol/L') {
        mgDlValue = AppConstants.mmolLToMgDl(value);
      }
      
      await db.insertBloodSugarRecord(
        BloodSugarRecordsCompanion.insert(
          value: mgDlValue,
          unit: drift.Value(AppConstants.unitMgDl),
          type: type,
          recordedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      
      ref.invalidate(bloodSugarRecordsProvider);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已快速记录 $value $currentUnit')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('记录失败: $e')),
        );
      }
    }
  }

  Map<String, List<BloodSugarRecord>> _groupRecordsByDate(List<BloodSugarRecord> records) {
    final Map<String, List<BloodSugarRecord>> grouped = {};
    final dateFormat = DateFormat('yyyy年M月d日 E', 'zh_CN');

    for (final record in records) {
      final dateKey = dateFormat.format(record.recordedAt);
      grouped.putIfAbsent(dateKey, () => []).add(record);
    }

    return grouped;
  }

  void _showAddBloodSugarDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddBloodSugarSheet(),
    );
  }
}

/// 血糖记录列表项
class _BloodSugarRecordTile extends ConsumerWidget {
  final BloodSugarRecord record;

  const _BloodSugarRecordTile({required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsUnit = ref.watch(bloodSugarUnitProvider);
    
    // 根据设置单位转换显示值
    double displayValue = record.value;
    String displayUnit = record.unit;
    
    // 如果设置是 mmol/L，但记录是 mg/dL
    if (settingsUnit == 'mmol/L' && record.unit == 'mg/dL') {
      displayValue = record.value / 18.0182;
      displayUnit = 'mmol/L';
    }
    // 如果设置是 mg/dL，但记录是 mmol/L
    else if (settingsUnit == 'mg/dL' && record.unit == 'mmol/L') {
      displayValue = record.value * 18.0182;
      displayUnit = 'mg/dL';
    }
    
    final color = AppTheme.getBloodSugarColor(displayValue);
    final status = AppTheme.getBloodSugarStatus(displayValue);
    final timeFormat = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              displayValue.toStringAsFixed(0),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: Text(
          '${displayValue.toStringAsFixed(1)} $displayUnit',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getTypeText(record.type)),
            if (record.hoursAfterMeal != null)
              Text('餐后 ${record.hoursAfterMeal} 小时'),
            Text(timeFormat.format(record.recordedAt)),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ),
        onTap: () => _showRecordDetail(context, ref, record),
      ),
    );
  }

  void _showRecordDetail(BuildContext context, WidgetRef ref, BloodSugarRecord record) {
    final timeFormat = DateFormat('yyyy年M月d日 HH:mm');
    final currentUnit = ref.watch(bloodSugarUnitProvider);
    
    // 单位转换
    double displayValue = record.value;
    String displayUnit = record.unit;
    if (currentUnit == 'mmol/L' && record.unit == 'mg/dL') {
      displayValue = record.value / 18.0182;
      displayUnit = 'mmol/L';
    } else if (currentUnit == 'mg/dL' && record.unit == 'mmol/L') {
      displayValue = record.value * 18.0182;
      displayUnit = 'mg/dL';
    }
    
    final color = AppTheme.getBloodSugarColor(displayValue);

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.monitor_heart, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  '血糖记录详情',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow('血糖值', '${displayValue.toStringAsFixed(1)} $displayUnit', color: color),
            _buildDetailRow('状态', AppTheme.getBloodSugarStatus(displayValue), color: color),
            _buildDetailRow('测量时间', _getTypeText(record.type)),
            if (record.hoursAfterMeal != null)
              _buildDetailRow('餐后时间', '${record.hoursAfterMeal} 小时'),
            _buildDetailRow('记录时间', timeFormat.format(record.recordedAt)),
            if (record.note != null && record.note!.isNotEmpty)
              _buildDetailRow('备注', record.note!),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      final db = ref.read(databaseProvider);
                      await db.deleteBloodSugarRecord(record.id);
                      ref.invalidate(bloodSugarRecordsProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('记录已删除')),
                        );
                      }
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('删除', style: TextStyle(color: Colors.red)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('关闭'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeText(String type) {
    switch (type) {
      case 'fasting':
        return '空腹';
      case 'post_meal':
        return '餐后';
      case 'custom':
        return '自定义';
      default:
        return type;
    }
  }
}

/// 添加血糖记录表单
class AddBloodSugarSheet extends ConsumerStatefulWidget {
  const AddBloodSugarSheet({super.key});

  @override
  ConsumerState<AddBloodSugarSheet> createState() => _AddBloodSugarSheetState();
}

class _AddBloodSugarSheetState extends ConsumerState<AddBloodSugarSheet> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  String _selectedType = 'fasting';
  late String _selectedUnit; // 默认单位从设置中读取
  double? _hoursAfterMeal;
  TimeOfDay _selectedTime = TimeOfDay.now();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // 从设置中读取默认单位
    _selectedUnit = ref.read(bloodSugarUnitProvider);
  }

  // 根据单位获取血糖范围验证
  String? _validateBloodSugar(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入血糖值';
    }
    final num = double.tryParse(value);
    if (num == null || num <= 0) {
      return '请输入有效的血糖值';
    }
    // 根据单位验证合理范围
    if (_selectedUnit == AppConstants.unitMgDl) {
      // mg/dL 合理范围: 20 - 600
      if (num < 20 || num > 600) {
        return '血糖值应在 20-600 mg/dL 之间';
      }
    } else {
      // mmol/L 合理范围: 1.1 - 33.3
      if (num < 1.1 || num > 33.3) {
        return '血糖值应在 1.1-33.3 mmol/L 之间';
      }
    }
    return null;
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '添加血糖记录',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // 血糖值输入
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _valueController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: '血糖值',
                        hintText: '请输入血糖值',
                      ),
                      validator: _validateBloodSugar,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      decoration: const InputDecoration(
                        labelText: '单位',
                      ),
                      items: const [
                        DropdownMenuItem(value: AppConstants.unitMgDl, child: Text('mg/dL')),
                        DropdownMenuItem(value: AppConstants.unitMmolL, child: Text('mmol/L')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedUnit = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 血糖类型选择
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: '测量时间'),
                items: const [
                  DropdownMenuItem(value: 'fasting', child: Text('空腹')),
                  DropdownMenuItem(value: 'post_meal', child: Text('餐后')),
                  DropdownMenuItem(value: 'custom', child: Text('自定义')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // 餐后小时数（仅餐后显示）
              if (_selectedType == 'post_meal')
                DropdownButtonFormField<double>(
                  value: _hoursAfterMeal,
                  decoration: const InputDecoration(labelText: '餐后时间'),
                  items: AppConstants.postMealHours
                      .map((h) => DropdownMenuItem(
                            value: h,
                            child: Text('$h 小时'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _hoursAfterMeal = value;
                    });
                  },
                ),
              const SizedBox(height: 16),

              // 日期时间选择
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            _selectedDate = date;
                          });
                        }
                      },
                      child: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime,
                        );
                        if (time != null) {
                          setState(() {
                            _selectedTime = time;
                          });
                        }
                      },
                      child: Text(_selectedTime.format(context)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 提交按钮
              ElevatedButton(
                onPressed: _saveRecord,
                child: const Text('保存'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    debugPrint('=== Saving blood sugar record ===');
    debugPrint('Value: ${_valueController.text}');
    debugPrint('Unit: $_selectedUnit');
    debugPrint('Type: $_selectedType');
    debugPrint('Hours after meal: $_hoursAfterMeal');
    debugPrint('Date: $_selectedDate $_selectedTime');

    try {
      final db = ref.read(databaseProvider);
      debugPrint('Database provider obtained');
      
      var value = double.parse(_valueController.text);
      debugPrint('Parsed value: $value');
      
      // 统一转换为 mg/dL 存储
      if (_selectedUnit == AppConstants.unitMmolL) {
        value = AppConstants.mmolLToMgDl(value);
        debugPrint('Converted to mg/dL: $value');
      }
      
      final recordedAt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      debugPrint('Recorded at: $recordedAt');

      await db.insertBloodSugarRecord(
        BloodSugarRecordsCompanion.insert(
          value: value,
          unit: drift.Value(AppConstants.unitMgDl),
          type: _selectedType,
          recordedAt: recordedAt,
          hoursAfterMeal: drift.Value(_hoursAfterMeal),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      debugPrint('Insert completed');

      // 刷新列表
      ref.invalidate(bloodSugarRecordsProvider);
      debugPrint('Invalidated provider');

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('血糖记录已保存')),
        );
      }
      debugPrint('=== Save successful ===');
    } catch (e, stack) {
      debugPrint('=== Save FAILED ===');
      debugPrint('Error: $e');
      debugPrint('Stack: $stack');
      // 显示错误信息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }
}

/// 快速添加菜单
class _QuickAddMenu extends StatelessWidget {
  final Function(double value, String type) onAdd;
  final VoidCallback onAddCustom;

  const _QuickAddMenu({
    required this.onAdd,
    required this.onAddCustom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '快速记录',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // 空腹血糖快速选项
          const Text('空腹血糖', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _QuickAddChip(label: '4.0', unit: 'mmol/L', type: 'fasting', onTap: () => onAdd(4.0, 'fasting')),
              _QuickAddChip(label: '4.5', unit: 'mmol/L', type: 'fasting', onTap: () => onAdd(4.5, 'fasting')),
              _QuickAddChip(label: '5.0', unit: 'mmol/L', type: 'fasting', onTap: () => onAdd(5.0, 'fasting')),
              _QuickAddChip(label: '5.5', unit: 'mmol/L', type: 'fasting', onTap: () => onAdd(5.5, 'fasting')),
              _QuickAddChip(label: '6.0', unit: 'mmol/L', type: 'fasting', onTap: () => onAdd(6.0, 'fasting')),
              _QuickAddChip(label: '6.5', unit: 'mmol/L', type: 'fasting', onTap: () => onAdd(6.5, 'fasting')),
              _QuickAddChip(label: '7.0', unit: 'mmol/L', type: 'fasting', onTap: () => onAdd(7.0, 'fasting')),
              _QuickAddChip(label: '7.8', unit: 'mmol/L', type: 'fasting', onTap: () => onAdd(7.8, 'fasting')),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 餐后血糖快速选项
          const Text('餐后血糖', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _QuickAddChip(label: '6.0', unit: 'mmol/L', type: 'post_meal', onTap: () => onAdd(6.0, 'post_meal')),
              _QuickAddChip(label: '7.0', unit: 'mmol/L', type: 'post_meal', onTap: () => onAdd(7.0, 'post_meal')),
              _QuickAddChip(label: '8.0', unit: 'mmol/L', type: 'post_meal', onTap: () => onAdd(8.0, 'post_meal')),
              _QuickAddChip(label: '9.0', unit: 'mmol/L', type: 'post_meal', onTap: () => onAdd(9.0, 'post_meal')),
              _QuickAddChip(label: '10.0', unit: 'mmol/L', type: 'post_meal', onTap: () => onAdd(10.0, 'post_meal')),
              _QuickAddChip(label: '11.0', unit: 'mmol/L', type: 'post_meal', onTap: () => onAdd(11.0, 'post_meal')),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 自定义添加按钮
          OutlinedButton.icon(
            onPressed: onAddCustom,
            icon: const Icon(Icons.edit),
            label: const Text('自定义添加'),
          ),
          
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _QuickAddChip extends StatelessWidget {
  final String label;
  final String unit;
  final String type;
  final VoidCallback onTap;

  const _QuickAddChip({
    required this.label,
    required this.unit,
    required this.type,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text('$label $unit'),
      onPressed: onTap,
    );
  }
}
