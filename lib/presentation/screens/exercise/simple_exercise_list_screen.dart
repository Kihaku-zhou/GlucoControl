import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
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
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () => _showTemplateMenu(context, ref),
            tooltip: '运动模板',
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

  void _showTemplateMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _ExerciseTemplateSheet(
        onSelectTemplate: (type, name, template) {
          Navigator.pop(context);
          _showAddExerciseDialogWithTemplate(context, ref, type, name, template);
        },
      ),
    );
  }

  void _showAddExerciseDialogWithTemplate(BuildContext context, WidgetRef ref, String type, String name, Map<String, dynamic> template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ExerciseAddSheet(
        initialType: type,
        initialName: name,
        template: template,
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
    final typeIcon = _getTypeIcon(record.type);
    final typeText = _getTypeText(record.type);
    final timeFormat = DateFormat('HH:mm');
    final details = _getRecordDetails(record);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(record.type),
          child: Icon(typeIcon, color: Colors.white, size: 20),
        ),
        title: Text(record.name),
        subtitle: Text(
          '$typeText · ${record.duration}分钟 · ${timeFormat.format(record.startedAt)}${details.isNotEmpty ? ' · $details' : ''}',
        ),
        trailing: record.calories != null
            ? Text('${record.calories} kcal')
            : null,
        onTap: () => _showRecordDetail(context, ref, record),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'aerobic':
        return Icons.directions_run;
      case 'anaerobic':
        return Icons.fitness_center;
      case 'endurance':
        return Icons.timer;
      default:
        return Icons.sports;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'aerobic':
        return Colors.blue;
      case 'anaerobic':
        return Colors.purple;
      case 'endurance':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getTypeText(String type) {
    switch (type) {
      case 'aerobic':
        return '有氧';
      case 'anaerobic':
        return '力量';
      case 'endurance':
        return '耐力';
      default:
        return type;
    }
  }

  String _getRecordDetails(ExerciseRecord record) {
    final details = <String>[];
    if (record.distance != null && record.distance! > 0) {
      details.add('${record.distance}km');
    }
    if (record.elevation != null && record.elevation! > 0) {
      details.add('${record.elevation}m');
    }
    if (record.power != null && record.power! > 0) {
      details.add('${record.power}W');
    }
    if (record.sets != null && record.sets! > 0) {
      details.add('${record.sets}组');
    }
    if (record.weight != null && record.weight! > 0) {
      details.add('${record.weight}kg');
    }
    if (record.seconds != null && record.seconds! > 0) {
      details.add('${record.seconds}秒');
    }
    return details.join(' ');
  }

  void _showRecordDetail(BuildContext context, WidgetRef ref, ExerciseRecord record) {
    final dateFormat = DateFormat('yyyy年M月d日 HH:mm');

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
                Icon(_getTypeIcon(record.type), color: _getTypeColor(record.type)),
                const SizedBox(width: 8),
                const Text('运动详情', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('运动名称', record.name),
            _buildDetailRow('运动类型', _getTypeText(record.type)),
            _buildDetailRow('时长', '${record.duration} 分钟'),
            if (record.distance != null && record.distance! > 0)
              _buildDetailRow('距离', '${record.distance} 公里'),
            if (record.elevation != null && record.elevation! > 0)
              _buildDetailRow('爬升', '${record.elevation} 米'),
            if (record.power != null && record.power! > 0)
              _buildDetailRow('平均功率', '${record.power} 瓦'),
            if (record.sets != null && record.sets! > 0)
              _buildDetailRow('组数', '${record.sets} 组'),
            if (record.weight != null && record.weight! > 0)
              _buildDetailRow('重量', '${record.weight} kg'),
            if (record.seconds != null && record.seconds! > 0)
              _buildDetailRow('时长', '${record.seconds} 秒'),
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
      builder: (context) => const ExerciseAddSheet(),
    );
  }
}

/// 运动模板选择
class _ExerciseTemplateSheet extends StatelessWidget {
  final Function(String type, String name, Map<String, dynamic> template) onSelectTemplate;

  const _ExerciseTemplateSheet({required this.onSelectTemplate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '选择运动模板',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // 有氧运动模板
          const Text('🏃 有氧运动', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTemplateChip('跑步', 'aerobic', {'distance': 5.0, 'duration': 30}),
              _buildTemplateChip('步行', 'aerobic', {'distance': 3.0, 'duration': 30}),
              _buildTemplateChip('骑行', 'aerobic', {'distance': 10.0, 'duration': 60}),
              _buildTemplateChip('登山', 'aerobic', {'distance': 5.0, 'elevation': 300, 'duration': 120}),
              _buildTemplateChip('椭圆机', 'aerobic', {'power': 100, 'duration': 30}),
              _buildTemplateChip('室内单车', 'aerobic', {'power': 120, 'duration': 45}),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 力量训练模板
          const Text('💪 力量训练', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTemplateChip('哑铃训练', 'anaerobic', {'sets': 4, 'weight': 20}),
              _buildTemplateChip('杠铃训练', 'anaerobic', {'sets': 4, 'weight': 40}),
              _buildTemplateChip('自重训练', 'anaerobic', {'sets': 3, 'weight': 0}),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 耐力训练模板
          const Text('⏱️ 耐力训练', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTemplateChip('波比跳', 'endurance', {'sets': 3, 'seconds': 60}),
              _buildTemplateChip('平板支撑', 'endurance', {'sets': 3, 'seconds': 60}),
              _buildTemplateChip('登山跑', 'endurance', {'sets': 4, 'seconds': 30}),
            ],
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTemplateChip(String name, String type, Map<String, dynamic> template) {
    return ActionChip(
      label: Text(name),
      onPressed: () => onSelectTemplate(type, name, template),
    );
  }
}

/// 运动记录表单
class ExerciseAddSheet extends ConsumerStatefulWidget {
  final String? initialType;
  final String? initialName;
  final Map<String, dynamic>? template;

  const ExerciseAddSheet({
    super.key,
    this.initialType,
    this.initialName,
    this.template,
  });

  @override
  ConsumerState<ExerciseAddSheet> createState() => _ExerciseAddSheetState();
}

class _ExerciseAddSheetState extends ConsumerState<ExerciseAddSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _durationController = TextEditingController();
  final _distanceController = TextEditingController();
  final _elevationController = TextEditingController();
  final _powerController = TextEditingController();
  final _setsController = TextEditingController();
  final _weightController = TextEditingController();
  final _secondsController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedType = 'aerobic';
  String? _selectedExercise;
  TimeOfDay _selectedTime = TimeOfDay.now();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) {
      _selectedType = widget.initialType!;
      _selectedExercise = widget.initialName;
      _nameController.text = widget.initialName ?? '';
    }
    if (widget.template != null) {
      final t = widget.template!;
      if (t['duration'] != null) _durationController.text = t['duration'].toString();
      if (t['distance'] != null) _distanceController.text = t['distance'].toString();
      if (t['elevation'] != null) _elevationController.text = t['elevation'].toString();
      if (t['power'] != null) _powerController.text = t['power'].toString();
      if (t['sets'] != null) _setsController.text = t['sets'].toString();
      if (t['weight'] != null) _weightController.text = t['weight'].toString();
      if (t['seconds'] != null) _secondsController.text = t['seconds'].toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _distanceController.dispose();
    _elevationController.dispose();
    _powerController.dispose();
    _setsController.dispose();
    _weightController.dispose();
    _secondsController.dispose();
    _caloriesController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<String> get _currentExerciseList {
    switch (_selectedType) {
      case 'aerobic':
        return AppConstants.aerobicExercises;
      case 'anaerobic':
        return AppConstants.strengthDevices;
      case 'endurance':
        return AppConstants.enduranceTypes;
      default:
        return AppConstants.aerobicExercises;
    }
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '添加运动',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 运动类型选择
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'aerobic', label: Text('有氧'), icon: Icon(Icons.directions_run)),
                    ButtonSegment(value: 'anaerobic', label: Text('力量'), icon: Icon(Icons.fitness_center)),
                    ButtonSegment(value: 'endurance', label: Text('耐力'), icon: Icon(Icons.timer)),
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
                  decoration: InputDecoration(
                    labelText: _selectedType == 'aerobic' ? '有氧运动' : 
                              _selectedType == 'anaerobic' ? '力量训练' : '耐力训练',
                    suffixIcon: _selectedExercise != null && _currentExerciseList.contains(_selectedExercise)
                        ? null
                        : const Icon(Icons.edit),
                  ),
                  items: _currentExerciseList
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedExercise = value;
                      if (value != null) _nameController.text = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请选择运动项目';
                    }
                    return null;
                  },
                ),
                
                // 自定义名称输入（如果选择了"其他"）
                if (_selectedExercise == '其他')
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: '自定义运动名称'),
                    validator: (value) {
                      if (_selectedExercise == '其他' && (value == null || value.isEmpty)) {
                        return '请输入运动名称';
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

                // 有氧运动额外字段
                if (_selectedType == 'aerobic') ...[
                  // 距离（跑步、骑行、登山）
                  if (AppConstants.distanceExercises.contains(_selectedExercise))
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
                        TextFormField(
                          controller: _elevationController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '爬升高度（可选）',
                            suffixText: '米',
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  // 功率（椭圆机、室内单车）
                  if (AppConstants.powerExercises.contains(_selectedExercise))
                    TextFormField(
                      controller: _powerController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '平均功率（可选）',
                        suffixText: '瓦',
                      ),
                    ),
                  const SizedBox(height: 16),
                ],

                // 力量训练额外字段
                if (_selectedType == 'anaerobic') ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _setsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '组数（可选）',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: '重量（可选）',
                            suffixText: 'kg',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // 耐力训练额外字段
                if (_selectedType == 'endurance') ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _setsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '组数（可选）',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _secondsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '每组时长',
                            suffixText: '秒',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // 卡路里
                TextFormField(
                  controller: _caloriesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '消耗卡路里（可选）',
                    suffixText: 'kcal',
                  ),
                ),
                const SizedBox(height: 16),

                // 备注
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: '备注（可选）',
                  ),
                  maxLines: 2,
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
      
      double? distance;
      double? elevation;
      double? power;
      int? sets;
      double? weight;
      int? seconds;
      int? calories;

      if (_distanceController.text.isNotEmpty) {
        distance = double.tryParse(_distanceController.text);
      }
      if (_elevationController.text.isNotEmpty) {
        elevation = double.tryParse(_elevationController.text);
      }
      if (_powerController.text.isNotEmpty) {
        power = double.tryParse(_powerController.text);
      }
      if (_setsController.text.isNotEmpty) {
        sets = int.tryParse(_setsController.text);
      }
      if (_weightController.text.isNotEmpty) {
        weight = double.tryParse(_weightController.text);
      }
      if (_secondsController.text.isNotEmpty) {
        seconds = int.tryParse(_secondsController.text);
      }
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

      final name = _selectedExercise ?? _nameController.text;

      await db.insertExerciseRecord(
        ExerciseRecordsCompanion.insert(
          type: _selectedType,
          name: name,
          duration: duration,
          distance: drift.Value(distance),
          elevation: drift.Value(elevation),
          power: drift.Value(power),
          sets: drift.Value(sets),
          weight: drift.Value(weight),
          seconds: drift.Value(seconds),
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
