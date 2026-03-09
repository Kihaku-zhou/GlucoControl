import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants.dart';
import '../../../data/database/database.dart';
import '../../../data/database/database_providers.dart';
import 'workout_timer_screen.dart';

/// 运动记录列表页面
class ExerciseListScreen extends ConsumerWidget {
  const ExerciseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(exerciseRecordsProvider);
    final selectedPlan = ref.watch(selectedTrainingPlanProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('运动记录'),
        actions: [
          // 训练计划按钮
          IconButton(
            icon: const Icon(Icons.assignment),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TrainingPlanListScreen(),
                ),
              );
            },
            tooltip: '训练计划',
          ),
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
      body: Column(
        children: [
          // 训练计划提示条
          if (selectedPlan != null)
            Container(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.assignment_turned_in, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '当前计划: ${selectedPlan.name}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(selectedTrainingPlanProvider.notifier).state = null;
                    },
                    child: const Text('清除'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: recordsAsync.when(
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

                // 计算本周统计
                final weekStats = _calculateWeekStats(records);

                // 按日期分组
                final groupedRecords = _groupRecordsByDate(records);

                return ListView.builder(
                  itemCount: groupedRecords.length + 1,
                  itemBuilder: (context, index) {
                    // 第一个item是统计卡片
                    if (index == 0) {
                      return _buildWeekStatsCard(weekStats, records);
                    }
                    
                    final date = groupedRecords.keys.elementAt(index - 1);
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickAddMenu(context, ref),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showQuickAddMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _QuickAddExerciseMenu(
        onAdd: (type, name, duration) => _quickAddExercise(context, ref, type, name, duration),
        onAddCustom: () {
          Navigator.pop(context);
          _showAddExerciseDialog(context, ref);
        },
      ),
    );
  }

  Future<void> _quickAddExercise(BuildContext context, WidgetRef ref, String type, String name, int duration) async {
    Navigator.pop(context);
    try {
      final db = ref.read(databaseProvider);
      final now = DateTime.now();
      
      await db.insertExerciseRecord(
        ExerciseRecordsCompanion.insert(
          type: type,
          name: name,
          duration: duration,
          startedAt: now,
          endedAt: now.add(Duration(minutes: duration)),
          createdAt: DateTime.now(),
        ),
      );
      
      ref.invalidate(exerciseRecordsProvider);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已记录 $name $duration 分钟')),
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

  Map<String, List<ExerciseRecord>> _groupRecordsByDate(List<ExerciseRecord> records) {
    final Map<String, List<ExerciseRecord>> grouped = {};
    final dateFormat = DateFormat('yyyy年M月d日 E', 'zh_CN');

    for (final record in records) {
      final dateKey = dateFormat.format(record.startedAt);
      grouped.putIfAbsent(dateKey, () => []).add(record);
    }

    return grouped;
  }

  /// 计算本周运动统计
  Map<String, dynamic> _calculateWeekStats(List<ExerciseRecord> records) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(weekStart.year, weekStart.month, weekStart.day);
    
    // 筛选本周记录
    final weekRecords = records.where((r) => 
      r.startedAt.isAfter(startOfWeek) || r.startedAt.isAtSameMomentAs(startOfWeek)
    ).toList();
    
    // 计算统计数据
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
    
    return {
      'totalMinutes': totalMinutes,
      'totalCalories': totalCalories,
      'aerobicCount': aerobicCount,
      'anaerobicCount': anaerobicCount,
      'totalCount': weekRecords.length,
    };
  }

  /// 构建统计卡片
  Widget _buildWeekStatsCard(Map<String, dynamic> stats, List<ExerciseRecord> records) {
    if (stats['totalCount'] == 0) {
      return const SizedBox.shrink();
    }
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue),
                SizedBox(width: 8),
                Text('本周运动', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('${stats['totalMinutes']}', '分钟', Colors.blue),
                _buildStatItem('${stats['totalCalories']}', '千卡', Colors.orange),
                _buildStatItem('${stats['totalCount']}', '次', Colors.green),
              ],
            ),
            const SizedBox(height: 12),
            // 运动类型分布
            Row(
              children: [
                Expanded(
                  child: _buildDistributionBar(
                    '有氧',
                    stats['aerobicCount'],
                    stats['totalCount'],
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDistributionBar(
                    '力量',
                    stats['anaerobicCount'],
                    stats['totalCount'],
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String unit, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
        Text(unit, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildDistributionBar(String label, int count, int total, Color color) {
    final percent = total > 0 ? (count / total * 100) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text('$count次', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ],
    );
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
    final dateFormat = DateFormat('yyyy年M月d日 HH:mm');
    final isAerobic = record.type == 'aerobic';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isAerobic ? Colors.blue.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
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
        onTap: () => _showRecordDetail(context, record),
      ),
    );
  }

  void _showRecordDetail(BuildContext context, ExerciseRecord record) {
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
                  color: isAerobic ? Colors.blue : Colors.orange,
                ),
                const SizedBox(width: 8),
                const Text(
                  '运动记录详情',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow('运动名称', record.name),
            _buildDetailRow('运动类型', isAerobic ? '有氧运动' : '力量训练'),
            _buildDetailRow('时长', '${record.duration} 分钟'),
            if (record.distance != null && false)
              _buildDetailRow('距离', '${record.distance} 公里'),
            if (record.distance != null && record.duration > 0)
              _buildDetailRow('平均速度', '${(record.distance! / (record.duration / 60)).toStringAsFixed(2)} km/h'),
            if (record.calories != null)
              _buildDetailRow('消耗热量', '${record.calories} kcal'),
            if (record.heartRateAvg != null)
              _buildDetailRow('平均心率', '${record.heartRateAvg} bpm'),
            if (record.heartRateMax != null)
              _buildDetailRow('最大心率', '${record.heartRateMax} bpm'),
            _buildDetailRow('开始时间', dateFormat.format(record.startedAt)),
            if (record.note != null && record.note!.isNotEmpty)
              _buildDetailRow('备注', record.note!),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
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
  final _distanceController = TextEditingController(); // 距离(公里)
  
  // 力量训练专用字段
  String? _selectedDevice;
  String _movementController = '';
  final _setsController = TextEditingController();
  final _repsController = TextEditingController();
  final _weightController = TextEditingController();
  final _restController = TextEditingController();
  
  // 训练类型：strength(力量) / endurance(计时耐力)
  String _trainingType = 'strength';
  final _enduranceDurationController = TextEditingController(); // 计时耐力时长(秒)
  
  String _selectedType = 'aerobic';
  String? _selectedExercise;
  TimeOfDay _selectedTime = TimeOfDay.now();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _caloriesController.dispose();
    _distanceController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _restController.dispose();
    _enduranceDurationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedPlan = ref.watch(selectedTrainingPlanProvider);
    
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

                // 训练计划提示
                if (selectedPlan != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.assignment_turned_in, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '正在使用计划: ${selectedPlan.name}',
                            style: const TextStyle(color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ),

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
                  _buildStrengthForm(),
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

                // 距离（可选）- 仅对需要距离的运动类型显示
                if (_selectedExercise != null && AppConstants.distanceExercises.contains(_selectedExercise))
                  Column(
                    children: [
                      TextFormField(
                        controller: _distanceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: '距离（可选）',
                          suffixText: '公里',
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

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

  /// 构建力量训练表单
  Widget _buildStrengthForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 训练类型选择
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'strength', label: Text('力量训练')),
            ButtonSegment(value: 'endurance', label: Text('计时耐力')),
          ],
          selected: {_trainingType},
          onSelectionChanged: (value) {
            setState(() {
              _trainingType = value.first;
            });
          },
        ),
        const SizedBox(height: 16),
        
        // 器械类型
        DropdownButtonFormField<String>(
          value: _selectedDevice,
          decoration: const InputDecoration(labelText: '器械类型'),
          items: AppConstants.strengthDevices
              .map((d) => DropdownMenuItem(value: d, child: Text(d)))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedDevice = value;
            });
          },
        ),
        const SizedBox(height: 16),
        
        // 动作名称
        TextFormField(
          initialValue: _movementController,
          decoration: const InputDecoration(
            labelText: '动作名称',
            hintText: '例如：卧推、深蹲、硬拉',
          ),
          onChanged: (value) => _movementController = value,
        ),
        const SizedBox(height: 16),
        
        if (_trainingType == 'strength') ...[
          // 力量训练：组数、次数、重量
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _setsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '组数',
                    hintText: '3',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _repsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '次数',
                    hintText: '10',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: '重量(kg)',
                    hintText: '20',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 休息时间
          TextFormField(
            controller: _restController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '休息时间（秒，可选）',
              hintText: '60',
            ),
          ),
        ] else ...[
          // 计时耐力训练：时长 + 重量
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _enduranceDurationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '持续时间',
                    suffixText: '秒',
                    hintText: '30',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: '重量(kg)',
                    hintText: '20',
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
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

    // 运动名称
    String exerciseName;
    if (_selectedType == 'aerobic') {
      exerciseName = _selectedExercise ?? (_nameController.text.isNotEmpty ? _nameController.text : '有氧运动');
    } else {
      exerciseName = _movementController.isNotEmpty ? _movementController : (_nameController.text.isNotEmpty ? _nameController.text : '力量训练');
    }

    // 先插入运动记录
    // 获取距离
    double? distance;
    if (_distanceController.text.isNotEmpty) {
      distance = double.tryParse(_distanceController.text);
    }
    
    final exerciseId = await db.insertExerciseRecord(
      ExerciseRecordsCompanion.insert(
        type: _selectedType,
        name: exerciseName,
        duration: duration,
        distance: drift.Value(distance),
        calories: drift.Value(calories),
        startedAt: startedAt,
        endedAt: endedAt,
        createdAt: DateTime.now(),
      ),
    );

    // 如果是力量训练且选择了器械，保存详细记录
    if (_selectedType == 'anaerobic' && _selectedDevice != null) {
      int? restSeconds;
      if (_restController.text.isNotEmpty) {
        restSeconds = int.tryParse(_restController.text);
      }
      double? weight;
      if (_weightController.text.isNotEmpty) {
        weight = double.tryParse(_weightController.text);
      }
      
      int? durationSeconds;
      if (_enduranceDurationController.text.isNotEmpty) {
        durationSeconds = int.tryParse(_enduranceDurationController.text);
      }
      
      await db.insertStrengthTraining(
        StrengthTrainingsCompanion.insert(
          exerciseId: exerciseId,
          device: _selectedDevice!,
          movement: _movementController.isNotEmpty ? _movementController : _nameController.text,
          sets: int.tryParse(_setsController.text) ?? 0,
          reps: int.tryParse(_repsController.text) ?? 0,
          weight: drift.Value(weight),
          restSeconds: drift.Value(restSeconds),
          trainingType: drift.Value(_trainingType),
          durationSeconds: drift.Value(durationSeconds),
        ),
      );
    }

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
class HeartRateScreen extends ConsumerWidget {
  const HeartRateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Web 平台显示提示
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('心率监测'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bluetooth_disabled, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Web 平台不支持蓝牙功能', style: TextStyle(fontSize: 18)),
              SizedBox(height: 8),
              Text('请使用手机或桌面端应用', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }
    
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

/// 训练计划列表页面
class TrainingPlanListScreen extends ConsumerWidget {
  const TrainingPlanListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(trainingPlansProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('训练计划'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TrainingPlanEditScreen(),
                ),
              );
            },
            tooltip: '创建计划',
          ),
        ],
      ),
      body: plansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('错误: $error')),
        data: (plans) {
          if (plans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('暂无训练计划', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('点击右上角创建训练计划', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TrainingPlanEditScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('创建计划'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.assignment, color: Colors.green),
                  title: Text(plan.name),
                  subtitle: plan.description != null 
                      ? Text(plan.description!, maxLines: 1, overflow: TextOverflow.ellipsis)
                      : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('确认删除'),
                          content: Text('确定要删除计划 "${plan.name}" 吗？'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('取消'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('删除', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        final db = ref.read(databaseProvider);
                        await db.deleteTrainingPlan(plan.id);
                        ref.invalidate(trainingPlansProvider);
                      }
                    },
                  ),
                  onTap: () {
                    // 显示选项：选择计划或开始训练
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.check_circle),
                              title: const Text('设为当前计划'),
                              onTap: () {
                                ref.read(selectedTrainingPlanProvider.notifier).state = plan;
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('已选择计划: ${plan.name}')),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.play_arrow, color: Colors.green),
                              title: const Text('开始训练', style: TextStyle(color: Colors.green)),
                              onTap: () async {
                                Navigator.pop(context);
                                // 获取计划动作并开始训练
                                final db = ref.read(databaseProvider);
                                final exercises = await db.getExercisesByPlanId(plan.id);
                                if (context.mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => WorkoutTimerScreen(
                                        plan: plan,
                                        exercises: exercises,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.edit),
                              title: const Text('编辑计划'),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TrainingPlanEditScreen(plan: plan),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// 训练计划编辑页面
class TrainingPlanEditScreen extends ConsumerStatefulWidget {
  final TrainingPlan? plan;
  
  const TrainingPlanEditScreen({super.key, this.plan});

  @override
  ConsumerState<TrainingPlanEditScreen> createState() => _TrainingPlanEditScreenState();
}

class _TrainingPlanEditScreenState extends ConsumerState<TrainingPlanEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<PlanExerciseInput> _exercises = [];

  @override
  void initState() {
    super.initState();
    if (widget.plan != null) {
      _nameController.text = widget.plan!.name;
      _descriptionController.text = widget.plan!.description ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    for (var e in _exercises) {
      e.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plan == null ? '创建训练计划' : '编辑训练计划'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 计划名称
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '计划名称',
                hintText: '例如：胸肌训练、腿部训练',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入计划名称';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // 计划描述
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '计划描述（可选）',
                hintText: '添加一些描述...',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            
            // 动作列表
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('训练动作', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _exercises.add(PlanExerciseInput());
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('添加动作'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            if (_exercises.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    '点击"添加动作"添加训练动作',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ..._exercises.asMap().entries.map((entry) {
                final index = entry.key;
                final exercise = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        // 训练类型选择
                        Row(
                          children: [
                            const Text('类型: ', style: TextStyle(fontSize: 12)),
                            ChoiceChip(
                              label: const Text('力量'),
                              selected: exercise.trainingType == 'strength',
                              onSelected: (selected) {
                                setState(() {
                                  exercise.trainingType = 'strength';
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('有氧'),
                              selected: exercise.trainingType == 'aerobic',
                              onSelected: (selected) {
                                setState(() {
                                  exercise.trainingType = 'aerobic';
                                });
                              },
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _exercises[index].dispose();
                                  _exercises.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        if (exercise.trainingType == 'strength') ...[
                          // 力量训练输入
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: exercise.device,
                                  decoration: const InputDecoration(
                                    labelText: '器械',
                                    isDense: true,
                                  ),
                                  items: AppConstants.strengthDevices
                                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      exercise.device = value;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: exercise.movementController,
                            decoration: const InputDecoration(
                              labelText: '动作名称',
                              hintText: '例如：卧推、深蹲',
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: exercise.setsController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: '组数',
                                    isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: exercise.repsController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: '次数',
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: exercise.weightController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: '重量(kg)',
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // 休息时间输入
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: exercise.restController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: '休息时间(秒)',
                                  hintText: '60',
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                '组间休息时长',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                        ] else ...[
                          // 有氧训练输入
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: exercise.durationController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: '时长(秒)',
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: exercise.repsController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: '组数',
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            
            const SizedBox(height: 24),
            
            // 保存按钮
            ElevatedButton(
              onPressed: _savePlan,
              child: const Text('保存计划'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate()) return;

    final db = ref.read(databaseProvider);
    final now = DateTime.now();

    int planId;
    if (widget.plan == null) {
      // 创建新计划
      planId = await db.insertTrainingPlan(
        TrainingPlansCompanion.insert(
          name: _nameController.text,
          description: drift.Value(_descriptionController.text.isNotEmpty ? _descriptionController.text : null),
          createdAt: now,
          updatedAt: now,
        ),
      );
    } else {
      // 更新现有计划
      // 先删除旧动作
      await db.deleteExercisesByPlanId(widget.plan!.id);
      planId = widget.plan!.id;
    }

    // 保存动作
    for (int i = 0; i < _exercises.length; i++) {
      final e = _exercises[i];
      if (e.device != null && e.movementController.text.isNotEmpty) {
        // 处理有氧训练：如果选择的是有氧，使用 durationController
        String movement = e.movementController.text;
        int targetSets = int.tryParse(e.setsController.text) ?? 3;
        int targetReps = int.tryParse(e.repsController.text) ?? 10;
        
        // 有氧训练使用 durationController 作为时长
        if (e.trainingType == 'aerobic') {
          targetReps = int.tryParse(e.durationController.text) ?? 30;
        }
        
        // 解析休息时间（仅力量训练需要）
        int? restSeconds;
        if (e.trainingType == 'strength' && e.restController.text.isNotEmpty) {
          restSeconds = int.tryParse(e.restController.text);
        }
        
        await db.insertTrainingPlanExercise(
          TrainingPlanExercisesCompanion.insert(
            planId: planId,
            device: e.device!,
            movement: movement,
            targetSets: targetSets,
            targetReps: targetReps,
            targetWeight: drift.Value(e.trainingType == 'aerobic' ? null : double.tryParse(e.weightController.text)),
            restSeconds: drift.Value(restSeconds),
            trainingType: drift.Value(e.trainingType == 'aerobic' ? 'endurance' : 'strength'),
            orderIndex: drift.Value(i),
          ),
        );
      }
    }

    ref.invalidate(trainingPlansProvider);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('训练计划已保存')),
      );
    }
  }
}

/// 训练计划动作输入
class PlanExerciseInput {
  String? device;
  String trainingType = 'strength'; // strength 或 aerobic
  final movementController = TextEditingController();
  final setsController = TextEditingController(text: '3');
  final repsController = TextEditingController(text: '10');
  final weightController = TextEditingController();
  final durationController = TextEditingController(text: '30'); // 有氧训练时长(秒)
  final restController = TextEditingController(text: '60'); // 休息时间(秒)
  
  void dispose() {
    movementController.dispose();
    setsController.dispose();
    repsController.dispose();
    weightController.dispose();
    durationController.dispose();
    restController.dispose();
  }
}

/// 快速添加运动菜单
class _QuickAddExerciseMenu extends StatelessWidget {
  final Function(String type, String name, int duration) onAdd;
  final VoidCallback onAddCustom;

  const _QuickAddExerciseMenu({
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
            '快速记录运动',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // 有氧运动快速选项
          const Text('🏃 有氧运动', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuickExerciseChip(
                label: '跑步 30分钟',
                onTap: () => onAdd('aerobic', '跑步', 30),
              ),
              _QuickExerciseChip(
                label: '快走 30分钟',
                onTap: () => onAdd('aerobic', '快走', 30),
              ),
              _QuickExerciseChip(
                label: '骑行 30分钟',
                onTap: () => onAdd('aerobic', '骑行', 30),
              ),
              _QuickExerciseChip(
                label: '游泳 30分钟',
                onTap: () => onAdd('aerobic', '游泳', 30),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 力量训练快速选项
          const Text('💪 力量训练', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuickExerciseChip(
                label: '哑铃 30分钟',
                onTap: () => onAdd('anaerobic', '哑铃训练', 30),
              ),
              _QuickExerciseChip(
                label: '杠铃 30分钟',
                onTap: () => onAdd('anaerobic', '杠铃训练', 30),
              ),
              _QuickExerciseChip(
                label: '自重 30分钟',
                onTap: () => onAdd('anaerobic', '自重训练', 30),
              ),
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

class _QuickExerciseChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickExerciseChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
    );
  }
}
