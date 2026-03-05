import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants.dart';
import '../../../data/database/database.dart';
import '../../../data/database/database_providers.dart';

/// 运动记录列表页面
class ExerciseListScreen extends ConsumerWidget {
  const ExerciseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(exerciseRecordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('运动记录'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HeartRateScreen(),
                ),
              );
            },
            tooltip: '心率监测',
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
                  Icon(Icons.fitness_center_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('暂无运动记录', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('点击右下角按钮添加运动', style: TextStyle(color: Colors.grey)),
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
                  ...dayRecords.map((record) => _ExerciseRecordTile(record: record)),
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

  void _showAddExerciseDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddExerciseSheet(),
    );
  }
}

/// 运动记录列表项
class _ExerciseRecordTile extends StatelessWidget {
  final ExerciseRecord record;

  const _ExerciseRecordTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    final isAerobic = record.type == 'aerobic';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isAerobic ? Colors.blue.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isAerobic ? Icons.directions_run : Icons.fitness_center,
            color: isAerobic ? Colors.blue : Colors.orange,
          ),
        ),
        title: Text(
          record.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${record.type == 'aerobic' ? '有氧' : '力量'} • ${record.duration} 分钟'),
            Text(timeFormat.format(record.startedAt)),
            if (record.heartRateAvg != null)
              Row(
                children: [
                  const Icon(Icons.favorite, size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  Text('平均 ${record.heartRateAvg} bpm'),
                ],
              ),
          ],
        ),
        trailing: record.calories != null
            ? Text('${record.calories} kcal')
            : null,
        onTap: () {
          // TODO: 查看详情或编辑
        },
      ),
    );
  }
}

/// 添加运动表单
class AddExerciseSheet extends ConsumerStatefulWidget {
  const AddExerciseSheet({super.key});

  @override
  ConsumerState<AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends ConsumerState<AddExerciseSheet> {
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
                  '添加运动记录',
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
                    });
                  },
                ),
                const SizedBox(height: 16),

                // 运动项目选择
                if (_selectedType == 'aerobic')
                  DropdownButtonFormField<String>(
                    value: _selectedExercise,
                    decoration: const InputDecoration(labelText: '运动项目'),
                    items: AppConstants.aerobicExercises
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedExercise = value;
                        _nameController.text = value ?? '';
                      });
                    },
                  )
                else
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: '运动名称',
                      hintText: '例如：胸部训练、背部训练',
                    ),
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
      ),
    );
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    final db = ref.read(databaseProvider);
    final duration = int.parse(_durationController.text);
    final startedAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    final endedAt = startedAt.add(Duration(minutes: duration));
    
    int? calories;
    if (_caloriesController.text.isNotEmpty) {
      calories = int.tryParse(_caloriesController.text);
    }

    await db.insertExerciseRecord(
      ExerciseRecordsCompanion.insert(
        type: _selectedType,
        name: _nameController.text,
        duration: duration,
        calories: drift.Value(calories),
        startedAt: startedAt,
        endedAt: endedAt,
        createdAt: DateTime.now(),
      ),
    );

    // 刷新列表
    ref.invalidate(exerciseRecordsProvider);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('运动记录已保存')),
      );
    }
  }
}

/// 心率监测页面
class HeartRateScreen extends StatelessWidget {
  const HeartRateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('心率监测'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text('连接心率设备', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('正在扫描附近的蓝牙心率设备...', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
