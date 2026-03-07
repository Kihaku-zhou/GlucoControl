import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants.dart';
import '../../../data/database/database.dart';
import '../../../data/database/database_providers.dart';

/// 简化版运动记录列表页面
class SimpleExerciseListScreen extends ConsumerWidget {
  const SimpleExerciseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(exerciseRecordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('运动记录'),
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
                  Icon(Icons.fitness_center_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('暂无运动记录', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('点击 + 添加运动', style: TextStyle(color: Colors.grey)),
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
                  // 日期标题
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      date,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  // 运动记录列表
                  ...dayRecords.map((record) => _buildRecordTile(context, ref, record)),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExerciseDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Map<String, List<ExerciseRecord>> _groupRecordsByDate(List<ExerciseRecord> records) {
    final Map<String, List<ExerciseRecord>> grouped = {};
    final dateFormat = DateFormat('yyyy年M月d日 E', 'zh_CN');

    for (final record in records) {
      final dateKey = dateFormat.format(record.startedAt);
      grouped.putIfAbsent(dateKey, () => []).add(record);
    }

    return grouped;
  }

  Widget _buildRecordTile(BuildContext context, WidgetRef ref, ExerciseRecord record) {
    final isAerobic = record.type == 'aerobic';
    final icon = isAerobic ? Icons.directions_run : Icons.fitness_center;
    final typeText = isAerobic ? '有氧' : '力量';
    final timeFormat = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isAerobic ? Colors.blue : Colors.purple,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(record.name),
        subtitle: Text(
          '$typeText · ${record.duration}分钟 · ${timeFormat.format(record.startedAt)}',
        ),
        trailing: record.calories != null
            ? Text('${record.calories} kcal')
            : null,
        onTap: () => _showRecordDetail(context, ref, record),
      ),
    );
  }

  void _showRecordDetail(BuildContext context, WidgetRef ref, ExerciseRecord record) {
    final dateFormat = DateFormat('yyyy年M月d日 HH:mm');
    final isAerobic = record.type == 'aerobic';

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
                Icon(
                  isAerobic ? Icons.directions_run : Icons.fitness_center,
                  color: isAerobic ? Colors.blue : Colors.purple,
                ),
                const SizedBox(width: 8),
                const Text(
                  '运动详情',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('运动名称', record.name),
            _buildDetailRow('运动类型', isAerobic ? '有氧运动' : '力量训练'),
            _buildDetailRow('时长', '${record.duration} 分钟'),
            if (record.calories != null)
              _buildDetailRow('消耗热量', '${record.calories} kcal'),
            _buildDetailRow('开始时间', dateFormat.format(record.startedAt)),
            if (record.note != null && record.note!.isNotEmpty)
              _buildDetailRow('备注', record.note!),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      final db = ref.read(databaseProvider);
                      await db.deleteExerciseRecord(record.id);
                      ref.invalidate(exerciseRecordsProvider);
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('删除'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
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

  Widget _buildDetailRow(String label, String value) {
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
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  void _showAddExerciseDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const SimpleAddExerciseSheet(),
    );
  }
}

/// 简化版添加运动表单
class SimpleAddExerciseSheet extends ConsumerStatefulWidget {
  const SimpleAddExerciseSheet({super.key});

  @override
  ConsumerState<SimpleAddExerciseSheet> createState() => _SimpleAddExerciseSheetState();
}

class _SimpleAddExerciseSheetState extends ConsumerState<SimpleAddExerciseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _durationController = TextEditingController();
  final _caloriesController = TextEditingController();
  
  String _selectedType = 'aerobic';
  String? _selectedExercise;
  TimeOfDay _selectedTime = TimeOfDay.now();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _caloriesController.dispose();
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '添加运动',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // 运动类型选择
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'aerobic', label: Text('有氧'), icon: Icon(Icons.directions_run)),
                    ButtonSegment(value: 'anaerobic', label: Text('力量'), icon: Icon(Icons.fitness_center)),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (value) {
                    setState(() {
                      _selectedType = value.first;
                      _selectedExercise = null;
                      _nameController.clear();
                    });
                  },
                ),
                const SizedBox(height: 16),

                // 运动项目选择
                DropdownButtonFormField<String>(
                  value: _selectedExercise,
                  decoration: const InputDecoration(labelText: '运动项目'),
                  items: (_selectedType == 'aerobic' 
                      ? AppConstants.aerobicExercises 
                      : AppConstants.strengthDevices)
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedExercise = value;
                      _nameController.text = value ?? '';
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请选择运动项目';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 时长
                TextFormField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '时长',
                    suffixText: '分钟',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入运动时长';
                    }
                    final num = int.tryParse(value);
                    if (num == null || num <= 0) {
                      return '请输入有效的时长';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 消耗卡路里（可选）
                TextFormField(
                  controller: _caloriesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '消耗卡路里（可选）',
                    suffixText: 'kcal',
                  ),
                ),
                const SizedBox(height: 16),

                // 运动时间
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time),
                  title: const Text('运动时间'),
                  subtitle: Text(
                    '${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day} ${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                      );
                      if (time != null) {
                        setState(() {
                          _selectedDate = date;
                          _selectedTime = time;
                        });
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),

                // 提交按钮
                ElevatedButton(
                  onPressed: _saveRecord,
                  child: const Text('保存'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final db = ref.read(databaseProvider);
      final duration = int.parse(_durationController.text);
      
      int? calories;
      if (_caloriesController.text.isNotEmpty) {
        calories = int.tryParse(_caloriesController.text);
      }
      
      final startedAt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      final endedAt = startedAt.add(Duration(minutes: duration));

      await db.insertExerciseRecord(
        ExerciseRecordsCompanion.insert(
          type: _selectedType,
          name: _selectedExercise ?? _nameController.text,
          duration: duration,
          calories: drift.Value(calories),
          startedAt: startedAt,
          endedAt: endedAt,
          createdAt: DateTime.now(),
        ),
      );

      ref.invalidate(exerciseRecordsProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('运动记录已保存')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }
}
