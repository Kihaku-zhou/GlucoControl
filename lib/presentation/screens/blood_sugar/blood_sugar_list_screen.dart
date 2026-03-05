import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../data/database/database.dart';
import '../../../data/database/database_providers.dart';
import 'blood_sugar_chart_screen.dart';
import 'hba1c_calculator_screen.dart';

/// 血糖记录列表页面
class BloodSugarListScreen extends ConsumerWidget {
  const BloodSugarListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(bloodSugarRecordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('血糖记录'),
        actions: [
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
            icon: const Icon(Icons.calculate),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HbA1cCalculatorScreen(),
                ),
              );
            },
            tooltip: 'HbA1c 计算器',
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

          // 按日期分组
          final groupedRecords = _groupRecordsByDate(records);

          return ListView.builder(
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBloodSugarDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
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
class _BloodSugarRecordTile extends StatelessWidget {
  final BloodSugarRecord record;

  const _BloodSugarRecordTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getBloodSugarColor(record.value);
    final status = AppTheme.getBloodSugarStatus(record.value);
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
              record.value.toStringAsFixed(0),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: Text(
          '${record.value.toStringAsFixed(1)} ${record.unit}',
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
        onTap: () {
          // TODO: 编辑记录
        },
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
  String _selectedUnit = AppConstants.unitMgDl; // 默认 mg/dL
  double? _hoursAfterMeal;
  TimeOfDay _selectedTime = TimeOfDay.now();
  DateTime _selectedDate = DateTime.now();

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
