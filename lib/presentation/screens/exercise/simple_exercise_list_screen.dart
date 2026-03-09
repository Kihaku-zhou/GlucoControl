import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants.dart';
import '../../../widgets/main_drawer.dart';
import '../../../data/database/database.dart';
import '../../../data/database/database_providers.dart';
import '../../../services/auto_sync_service.dart';
import 'exercise_filter_screen.dart';

/// 简化版运动记录列表页面
class SimpleExerciseListScreen extends ConsumerWidget {
  const SimpleExerciseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(exerciseRecordsProvider);

    return Scaffold(
      drawer: buildMainDrawer(context),
    
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('运动记录'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ExerciseFilterScreen(),
                ),
              );
            },
            tooltip: '筛选',
          ),
          IconButton(
            icon: const Icon(Icons.fitness_center),
            onPressed: () => _showTemplateManager(context, ref),
            tooltip: '训练计划',
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  ...dayRecords.map((record) => _buildRecordTile(context, ref, record)),
                ],
              );
            },
          );
        },
      ),
        onPressed: () => _showAddExerciseDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showTemplateManager(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => _TrainingPlanListSheet(
          scrollController: scrollController,
          onSelectPlan: (plan, exercises) {
            Navigator.pop(context);
            _showPlanExerciseList(context, ref, plan, exercises);
          },
        ),
      ),
    );
  }

  void _showPlanExerciseList(BuildContext context, WidgetRef ref, TrainingPlan plan, List<TrainingPlanExercise> exercises) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _PlanExerciseListSheet(plan: plan, exercises: exercises),
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
    
    // 力量训练不显示时长
    final durationText = record.type == 'anaerobic' ? '' : ' · ${record.duration}分钟';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(record.type),
          child: Icon(typeIcon, color: Colors.white, size: 20),
        ),
        title: Text(record.name),
        subtitle: Text('$typeText$durationText · ${timeFormat.format(record.startedAt)}${details.isNotEmpty ? ' · $details' : ''}'),
        trailing: record.calories != null ? Text('${record.calories} kcal') : null,
        onTap: () => _showRecordDetail(context, ref, record),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'aerobic': return Icons.directions_run;
      case 'anaerobic': return Icons.fitness_center;
      case 'endurance': return Icons.timer;
      default: return Icons.sports;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'aerobic': return Colors.blue;
      case 'anaerobic': return Colors.purple;
      case 'endurance': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _getTypeText(String type) {
    switch (type) {
      case 'aerobic': return '有氧';
      case 'anaerobic': return '力量';
      case 'endurance': return '耐力';
      default: return type;
    }
  }

  String _getRecordDetails(ExerciseRecord record) {
    final details = <String>[];
    if (record.distance != null && record.distance! > 0) details.add('${record.distance}km');
    if (record.elevation != null && record.elevation! > 0) details.add('${record.elevation}m');
    if (record.power != null && record.power! > 0) details.add('${record.power}W');
    if (record.sets != null && record.sets! > 0) details.add('${record.sets}组');
    if (record.weight != null && record.weight! > 0) details.add('${record.weight}kg');
    if (record.seconds != null && record.seconds! > 0) details.add('${record.seconds}秒');
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
            if (record.type != 'anaerobic') _buildDetailRow('时长', '${record.duration} 分钟'),
            if (record.distance != null && record.distance! > 0) _buildDetailRow('距离', '${record.distance} 公里'),
            if (record.elevation != null && record.elevation! > 0) _buildDetailRow('爬升', '${record.elevation} 米'),
            if (record.power != null && record.power! > 0) _buildDetailRow('平均功率', '${record.power} 瓦'),
            if (record.sets != null && record.sets! > 0) _buildDetailRow('组数', '${record.sets} 组'),
            if (record.weight != null && record.weight! > 0) _buildDetailRow('重量', '${record.weight} kg'),
            if (record.seconds != null && record.seconds! > 0) _buildDetailRow('时长', '${record.seconds} 秒'),
            if (record.calories != null) _buildDetailRow('消耗热量', '${record.calories} kcal'),
            _buildDetailRow('开始时间', dateFormat.format(record.startedAt)),
            if (record.note != null && record.note!.isNotEmpty) _buildDetailRow('备注', record.note!),
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
                Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('关闭'))),
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
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  void _showAddExerciseDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (context) => const ExerciseAddSheet());
  }
}

/// 训练计划列表
class _TrainingPlanListSheet extends ConsumerWidget {
  final ScrollController scrollController;
  final Function(TrainingPlan plan, List<TrainingPlanExercise> exercises) onSelectPlan;

  const _TrainingPlanListSheet({required this.scrollController, required this.onSelectPlan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(trainingPlansProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('训练计划', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.add), onPressed: () => _showPlanEdit(context, ref, null)),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: plansAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('错误: $e')),
              data: (plans) {
                if (plans.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fitness_center_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('暂无训练计划', style: TextStyle(color: Colors.grey)),
                        Text('点击 + 创建', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: scrollController,
                  itemCount: plans.length,
                  itemBuilder: (context, index) {
                    final plan = plans[index];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.fitness_center)),
                        title: Text(plan.name),
                        subtitle: plan.description != null ? Text(plan.description!) : null,
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'edit', child: Text('编辑')),
                            const PopupMenuItem(value: 'delete', child: Text('删除')),
                          ],
                          onSelected: (value) async {
                            if (value == 'edit') {
                              _showPlanEdit(context, ref, plan);
                            } else if (value == 'delete') {
                              final db = ref.read(databaseProvider);
                              await db.deleteTrainingPlan(plan.id);
                              ref.invalidate(trainingPlansProvider);
                            }
                          },
                        ),
                        onTap: () async {
                          final db = ref.read(databaseProvider);
                          final exercises = await db.getExercisesByPlanId(plan.id);
                          onSelectPlan(plan, exercises);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showPlanEdit(BuildContext context, WidgetRef ref, TrainingPlan? plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _TrainingPlanEditSheet(plan: plan),
      ),
    );
  }
}

/// 训练计划编辑
class _TrainingPlanEditSheet extends ConsumerStatefulWidget {
  final TrainingPlan? plan;
  const _TrainingPlanEditSheet({this.plan});

  @override
  ConsumerState<_TrainingPlanEditSheet> createState() => _TrainingPlanEditSheetState();
}

class _TrainingPlanEditSheetState extends ConsumerState<_TrainingPlanEditSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  List<_PlanExerciseItem> _exercises = [];

  /// 格式化动作显示
  String _formatExerciseItem(_PlanExerciseItem e) {
    switch (e.type) {
      case 'aerobic':
        final parts = <String>['有氧', '${e.duration}分钟'];
        if (e.distance != null && e.distance! > 0) parts.add('${e.distance}km');
        if (e.elevation != null && e.elevation! > 0) parts.add('${e.elevation}m');
        return parts.join(' · ');
      case 'endurance':
        final repsStr = e.repsList.length <= 3 ? e.repsList.join('/') : '${e.repsList.take(3).join('/')}...';
        return '耐力 · ${e.sets}组 x $repsStr次';
      case 'strength':
      default:
        final repsStr = e.repsList.length <= 3 ? e.repsList.join('/') : '${e.repsList.take(3).join('/')}...';
        return '器械: ${e.device} · ${e.sets}组 x $repsStr次 · ${e.weight}kg · 休息${e.restSeconds}秒';
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.plan != null) {
      _nameController.text = widget.plan!.name;
      _descController.text = widget.plan!.description ?? '';
      _loadExercises();
    }
  }

  Future<void> _loadExercises() async {
    if (widget.plan == null) return;
    final db = ref.read(databaseProvider);
    final exercises = await db.getExercisesByPlanId(widget.plan!.id);
    setState(() {
      _exercises = exercises.map((e) {
        // 解析每组次数列表
        List<int> repsList = [];
        if (e.targetRepsList != null && e.targetRepsList!.isNotEmpty) {
          try {
            final str = e.targetRepsList!.replaceAll('[', '').replaceAll(']', '');
            repsList = str.split(',').map((s) => int.tryParse(s.trim()) ?? 0).where((r) => r > 0).toList();
          } catch (_) {
            repsList = [];
          }
        }
        if (repsList.isEmpty) {
          repsList = List.generate(e.targetSets, (_) => e.targetReps);
        }

        return _PlanExerciseItem(
          type: e.trainingType,
          device: e.device,
          movement: e.movement,
          sets: e.targetSets,
          reps: e.targetReps,
          repsList: repsList,
          weight: e.targetWeight ?? 0,
          restSeconds: e.restSeconds ?? 60,
        );
      }).toList();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.plan == null ? '创建训练计划' : '编辑训练计划', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: '计划名称'), validator: (v) => v == null || v.isEmpty ? '请输入名称' : null),
              const SizedBox(height: 8),
              TextFormField(controller: _descController, decoration: const InputDecoration(labelText: '描述（可选）'), maxLines: 2),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('动作列表', style: TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.add), onPressed: _addExercise),
                ],
              ),
              const SizedBox(height: 8),
              ..._exercises.asMap().entries.map((entry) {
                final i = entry.key;
                final e = entry.value;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text('${i + 1}. ${e.movement}', style: const TextStyle(fontWeight: FontWeight.bold))),
                            IconButton(icon: const Icon(Icons.delete, size: 20), onPressed: () => setState(() => _exercises.removeAt(i))),
                          ],
                        ),
                        Text(_formatExerciseItem(e)),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _save, child: const Text('保存')),
            ],
          ),
        ),
      ),
    );
  }

  void _addExercise() {
    showDialog(
      context: context,
      builder: (context) => _AddExerciseDialog(onAdd: (item) => setState(() => _exercises.add(item))),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请添加至少一个动作')));
      return;
    }

    final db = ref.read(databaseProvider);
    final now = DateTime.now();

    int planId;
    if (widget.plan == null) {
      planId = await db.insertTrainingPlan(TrainingPlansCompanion.insert(
        name: _nameController.text,
        description: drift.Value(_descController.text.isEmpty ? null : _descController.text),
        createdAt: now,
        updatedAt: now,
      ));
    } else {
      planId = widget.plan!.id;
      await (db.update(db.trainingPlans)..where((t) => t.id.equals(planId))).write(TrainingPlansCompanion(
        name: drift.Value(_nameController.text),
        description: drift.Value(_descController.text.isEmpty ? null : _descController.text),
        updatedAt: drift.Value(now),
      ));
      await (db.delete(db.trainingPlanExercises)..where((t) => t.planId.equals(planId))).go();
    }

    for (var i = 0; i < _exercises.length; i++) {
      final e = _exercises[i];
      // 将每组次数列表转换为 JSON 字符串存储
      final repsListJson = e.repsList.isNotEmpty ? '[${e.repsList.join(",")}]' : null;
      await db.insertTrainingPlanExercise(TrainingPlanExercisesCompanion.insert(
        planId: planId,
        device: e.device,
        movement: e.movement,
        targetSets: e.sets,
        targetReps: e.reps,
        targetRepsList: drift.Value(repsListJson),
        targetWeight: drift.Value(e.weight > 0 ? e.weight : null),
        restSeconds: drift.Value(e.restSeconds),
        trainingType: drift.Value(e.type),
        orderIndex: drift.Value(i),
      ));
    }

    ref.invalidate(trainingPlansProvider);
    if (mounted) Navigator.pop(context);
  }
}

class _PlanExerciseItem {
  String type; // strength, aerobic, endurance
  String device;
  String movement;
  int sets;
  int reps;
  List<int> repsList;
  double weight;
  int restSeconds;
  int duration; // 有氧时长（分钟）
  double? distance; // 有氧距离
  double? elevation; // 有氧爬升
  int? seconds; // 耐力每组时长

  _PlanExerciseItem({
    required this.type,
    required this.device,
    required this.movement,
    required this.sets,
    required this.reps,
    required this.repsList,
    required this.weight,
    required this.restSeconds,
    this.duration = 30,
    this.distance,
    this.elevation,
    this.seconds,
  });
}

class _AddExerciseDialog extends StatefulWidget {
  final Function(_PlanExerciseItem) onAdd;
  const _AddExerciseDialog({required this.onAdd});

  @override
  State<_AddExerciseDialog> createState() => _AddExerciseDialogState();
}

/// 力量训练器械列表
const _strengthDeviceList = [
  '高位下拉机',
  '划船机',
  '外展机',
  '内收机',
  '俯卧腿弯举',
  '倒蹬',
  '推胸',
  '其他',
];

/// 有氧训练列表
const _aerobicExerciseList = [
  '跑步',
  '步行',
  '骑行',
  '登山',
  '椭圆机',
  '室内单车',
  '游泳',
  '跳绳',
  '划船机',
  '其他',
];

/// 耐力训练列表
const _enduranceExerciseList = [
  '波比跳',
  '平板支撑',
  '登山跑',
  '深蹲跳',
  '开合跳',
  '高抬腿',
  '高位下拉悬垂',
  '其他',
];

class _AddExerciseDialogState extends State<_AddExerciseDialog> {
  String _selectedType = 'strength';
  String? _selectedExercise;
  final _movementController = TextEditingController();
  final _durationController = TextEditingController(text: '30');
  final _distanceController = TextEditingController();
  final _elevationController = TextEditingController();
  final _setsController = TextEditingController(text: '4');
  final _repsController = TextEditingController(text: '12');
  final _weightController = TextEditingController(text: '0');
  final _restController = TextEditingController(text: '60');
  final _secondsController = TextEditingController(text: '60');

  @override
  void dispose() {
    _movementController.dispose();
    _durationController.dispose();
    _distanceController.dispose();
    _elevationController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _restController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  List<String> get _currentExerciseList {
    switch (_selectedType) {
      case 'strength': return _strengthDeviceList;
      case 'aerobic': return _aerobicExerciseList;
      case 'endurance': return _enduranceExerciseList;
      default: return _strengthDeviceList;
    }
  }

  String get _exerciseLabel {
    switch (_selectedType) {
      case 'strength': return '器械';
      case 'aerobic': return '有氧项目';
      case 'endurance': return '耐力项目';
      default: return '项目';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加动作'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'strength', label: Text('力量'), icon: Icon(Icons.fitness_center)),
                ButtonSegment(value: 'aerobic', label: Text('有氧'), icon: Icon(Icons.directions_run)),
                ButtonSegment(value: 'endurance', label: Text('耐力'), icon: Icon(Icons.timer)),
              ],
              selected: {_selectedType},
              onSelectionChanged: (value) => setState(() {
                _selectedType = value.first;
                _selectedExercise = null;
                _movementController.clear();
              }),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedExercise,
              decoration: InputDecoration(labelText: _exerciseLabel),
              items: _currentExerciseList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() {
                _selectedExercise = v;
                if (v == '其他') _movementController.clear();
              }),
            ),
            const SizedBox(height: 8),
            if (_selectedExercise == '其他')
              TextField(
                controller: _movementController,
                decoration: InputDecoration(labelText: _selectedType == 'strength' ? '自定义器械名称' : '自定义动作名称'),
              ),
            const SizedBox(height: 8),
            ..._buildTypeSpecificFields(),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        ElevatedButton(onPressed: _onAdd, child: const Text('添加')),
      ],
    );
  }

  List<Widget> _buildTypeSpecificFields() {
    switch (_selectedType) {
      case 'strength': return _buildStrengthFields();
      case 'aerobic': return _buildAerobicFields();
      case 'endurance': return _buildEnduranceFields();
      default: return [];
    }
  }

  List<Widget> _buildStrengthFields() {
    return [
      TextField(controller: _setsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '组数'), onChanged: (_) => setState(() {})),
      const SizedBox(height: 8),
      _buildRepsPerSetInput(),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(child: TextField(controller: _weightController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '重量(kg)'))),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: _restController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '休息(秒)'))),
        ],
      ),
    ];
  }

  List<Widget> _buildAerobicFields() {
    final isOutdoor = _selectedExercise == '跑步' || _selectedExercise == '骑行' || _selectedExercise == '登山';
    return [
      TextField(controller: _durationController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '时长', suffixText: '分钟')),
      if (isOutdoor) ...[
        const SizedBox(height: 8),
        TextField(controller: _distanceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '距离（可选）', suffixText: '公里')),
        const SizedBox(height: 8),
        TextField(controller: _elevationController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '爬升（可选）', suffixText: '米')),
      ],
    ];
  }

  List<Widget> _buildEnduranceFields() {
    return [
      TextField(controller: _setsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '组数'), onChanged: (_) => setState(() {})),
      const SizedBox(height: 8),
      _buildRepsPerSetInput(label: '每组时长（如: 30,25,20,15）', hint: '秒'),
    ];
  }

  Widget _buildRepsPerSetInput({String label = '每组次数（如: 12,10,8,6）', String hint = '次'}) {
    final sets = int.tryParse(_setsController.text) ?? 0;
    if (sets <= 0) {
      return TextField(controller: _repsController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: label, hintText: hint));
    }
    final currentReps = _repsController.text.split(RegExp(r'[,\s]+')).map((s) => int.tryParse(s.trim()) ?? 0).toList();
    while (currentReps.length < sets) {
      currentReps.add(currentReps.isNotEmpty ? currentReps.last : 12);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        TextField(
          controller: _repsController,
          decoration: InputDecoration(labelText: label.split('（').first, hintText: currentReps.join(', ')),
        ),
      ],
    );
  }

  void _onAdd() {
    if (_selectedExercise == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择项目')));
      return;
    }
    final name = _selectedExercise == '其他' ? _movementController.text.trim() : _selectedExercise!;
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入动作名称')));
      return;
    }
    final sets = int.tryParse(_setsController.text) ?? 1;
    final repsList = _repsController.text.split(',').map((s) => int.tryParse(s.trim()) ?? 0).where((r) => r > 0).toList();
    final defaultReps = int.tryParse(_repsController.text) ?? 12;
    final finalRepsList = repsList.isEmpty ? List.generate(sets, (_) => defaultReps) : repsList;

    widget.onAdd(_PlanExerciseItem(
      type: _selectedType,
      device: name,
      movement: name,
      sets: sets,
      reps: finalRepsList.isNotEmpty ? finalRepsList.first : defaultReps,
      repsList: finalRepsList,
      weight: double.tryParse(_weightController.text) ?? 0,
      restSeconds: int.tryParse(_restController.text) ?? 60,
      duration: int.tryParse(_durationController.text) ?? 30,
      distance: double.tryParse(_distanceController.text),
      elevation: double.tryParse(_elevationController.text),
      seconds: int.tryParse(_secondsController.text),
    ));
    Navigator.pop(context);
  }
}

/// 计划动作列表 - 快速记录
class _PlanExerciseListSheet extends ConsumerStatefulWidget {
  final TrainingPlan plan;
  final List<TrainingPlanExercise> exercises;
  const _PlanExerciseListSheet({required this.plan, required this.exercises});

  @override
  ConsumerState<_PlanExerciseListSheet> createState() => _PlanExerciseListSheetState();
}

class _PlanExerciseListSheetState extends ConsumerState<_PlanExerciseListSheet> {
  final Map<int, bool> _completed = {};

  /// 格式化动作显示（快速记录页面）
  String _formatExerciseDisplay(TrainingPlanExercise e, String repsDisplay) {
    final type = e.trainingType;
    switch (type) {
      case 'aerobic':
        return '有氧 · ${e.targetSets}分钟';
      case 'endurance':
        return '耐力 · ${e.targetSets}组 x $repsDisplay次';
      case 'strength':
      default:
        return '${e.device} · 目标: ${e.targetSets}组 · $repsDisplay次 · ${e.targetWeight ?? 0}kg';
    }
  }

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.exercises.length; i++) {
      _completed[i] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.plan.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          if (widget.plan.description != null) Text(widget.plan.description!, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.exercises.length,
              itemBuilder: (context, index) {
                final e = widget.exercises[index];
                // 解析每组次数列表
                List<int> repsList = [];
                if (e.targetRepsList != null && e.targetRepsList!.isNotEmpty) {
                  try {
                    final str = e.targetRepsList!.replaceAll('[', '').replaceAll(']', '');
                    repsList = str.split(',').map((s) => int.tryParse(s.trim()) ?? 0).where((r) => r > 0).toList();
                  } catch (_) {
                    repsList = [];
                  }
                }
                if (repsList.isEmpty) {
                  repsList = List.generate(e.targetSets, (_) => e.targetReps);
                }
                final repsDisplay = repsList.length <= 3 
                    ? repsList.join('/') 
                    : '${repsList.take(3).join('/')}...';

                return Card(
                  child: CheckboxListTile(
                    value: _completed[index] ?? false,
                    onChanged: (v) => setState(() => _completed[index] = v ?? false),
                    title: Text(e.movement),
                    subtitle: Text(_formatExerciseDisplay(e, repsDisplay)),
                    secondary: _completed[index] == true ? const Icon(Icons.check_circle, color: Colors.green) : const Icon(Icons.circle_outlined),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(onPressed: _saveAll, icon: const Icon(Icons.save), label: const Text('保存所有到记录')),
        ],
      ),
    );
  }

  Future<void> _saveAll() async {
    final db = ref.read(databaseProvider);
    final now = DateTime.now();

    for (var i = 0; i < widget.exercises.length; i++) {
      final e = widget.exercises[i];
      if (_completed[i] != true) continue;

      // 根据训练类型保存运动记录
      final exerciseType = e.trainingType == 'aerobic' ? 'aerobic' 
          : e.trainingType == 'endurance' ? 'endurance' 
          : 'anaerobic';
      
      // 默认时长
      int duration = 30;

      await db.insertExerciseRecord(ExerciseRecordsCompanion.insert(
        type: exerciseType,
        name: e.movement,
        duration: duration,
        sets: drift.Value(e.targetSets),
        weight: drift.Value(e.targetWeight),
        calories: drift.Value(null),
        startedAt: now,
        endedAt: now.add(Duration(minutes: duration)),
        createdAt: now,
      ));
    }

    ref.invalidate(exerciseRecordsProvider);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已保存 ${_completed.values.where((v) => v).length} 个动作')));
    }
  }
}

/// 运动记录表单
class ExerciseAddSheet extends ConsumerStatefulWidget {
  final String? initialType;
  final String? initialName;
  final Map<String, dynamic>? template;
  const ExerciseAddSheet({super.key, this.initialType, this.initialName, this.template});

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
  final _repsController = TextEditingController(); // 每组次数/时长
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
      if (t['reps'] != null) _repsController.text = t['reps'].toString();
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
    _repsController.dispose();
    _caloriesController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<String> get _currentExerciseList {
    switch (_selectedType) {
      case 'aerobic': return _aerobicExerciseList;
      case 'anaerobic': return _strengthDeviceList;
      case 'endurance': return _enduranceExerciseList;
      default: return _aerobicExerciseList;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                    const Text('添加运动', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'aerobic', label: Text('有氧'), icon: Icon(Icons.directions_run)),
                    ButtonSegment(value: 'anaerobic', label: Text('力量'), icon: Icon(Icons.fitness_center)),
                    ButtonSegment(value: 'endurance', label: Text('耐力'), icon: Icon(Icons.timer)),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (value) => setState(() { _selectedType = value.first; _selectedExercise = null; _nameController.clear(); }),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedExercise,
                  decoration: InputDecoration(labelText: _selectedType == 'aerobic' ? '有氧运动' : _selectedType == 'anaerobic' ? '力量训练' : '耐力训练'),
                  items: _currentExerciseList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (value) => setState(() { _selectedExercise = value; if (value != null) _nameController.text = value; }),
                  validator: (value) => value == null || value.isEmpty ? '请选择运动项目' : null,
                ),
                if (_selectedExercise == '其他')
                  TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: '自定义运动名称'), validator: (value) => _selectedExercise == '其他' && (value == null || value.isEmpty) ? '请输入运动名称' : null),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '时长', suffixText: '分钟'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return '请输入运动时长';
                    final num = int.tryParse(value);
                    if (num == null || num <= 0) return '请输入有效的时长';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (_selectedType == 'aerobic') ...[
                  if (AppConstants.distanceExercises.contains(_selectedExercise)) ...[
                    TextFormField(controller: _distanceController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: '距离（可选）', suffixText: '公里')),
                    const SizedBox(height: 16),
                    TextFormField(controller: _elevationController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '爬升高度（可选）', suffixText: '米')),
                    const SizedBox(height: 16),
                  ],
                  if (AppConstants.powerExercises.contains(_selectedExercise)) TextFormField(controller: _powerController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '平均功率（可选）', suffixText: '瓦')),
                  const SizedBox(height: 16),
                ],
                if (_selectedType == 'anaerobic') ...[
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: _setsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '组数'))),
                      const SizedBox(width: 16),
                      Expanded(child: TextFormField(controller: _weightController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: '重量', suffixText: 'kg'))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildRepsInput('每组次数（如: 12,10,8,6）'),
                  const SizedBox(height: 16),
                ],
                if (_selectedType == 'endurance') ...[
                  Row(
                    children: [
                      Expanded(child: TextFormField(controller: _setsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '组数'))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildRepsInput('每组时长（如: 30,25,20,15）', isSeconds: true),
                  const SizedBox(height: 16),
                ],
                TextFormField(controller: _caloriesController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '消耗卡路里（可选）', suffixText: 'kcal')),
                const SizedBox(height: 16),
                TextFormField(controller: _noteController, decoration: const InputDecoration(labelText: '备注（可选）'), maxLines: 2),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time),
                  title: const Text('运动时间'),
                  subtitle: Text('${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day} ${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}'),
                  onTap: () async {
                    final date = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime.now());
                    if (date != null) {
                      final time = await showTimePicker(context: context, initialTime: _selectedTime);
                      if (time != null) setState(() { _selectedDate = date; _selectedTime = time; });
                    }
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _saveRecord, child: const Text('保存')),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建每组次数/时长输入框
  Widget _buildRepsInput(String hint, {bool isSeconds = false}) {
    final sets = int.tryParse(_setsController.text) ?? 0;
    if (sets <= 0) {
      return TextFormField(
        controller: _repsController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: isSeconds ? '每组时长' : '每组次数',
          hintText: isSeconds ? '如: 30,25,20,15' : '如: 12,10,8,6',
          suffixText: isSeconds ? '秒' : '次',
        ),
      );
    }

    // 解析现有的每组值
    final currentValues = _parseRepsList(_repsController.text);
    while (currentValues.length < sets) {
      currentValues.add(currentValues.isNotEmpty ? currentValues.last : (isSeconds ? 30 : 12));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isSeconds ? '每组时长（用逗号或空格分隔，如: 30,25,20,15）' : '每组次数（用逗号或空格分隔，如: 12,10,8,6）',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _repsController,
          decoration: InputDecoration(
            labelText: isSeconds ? '每组时长' : '每组次数',
            hintText: currentValues.join(', '),
            suffixText: isSeconds ? '秒' : '次',
          ),
        ),
      ],
    );
  }

  /// 解析逗号或空格分隔的列表
  List<int> _parseRepsList(String text) {
    if (text.isEmpty) return [];
    return text.split(RegExp(r'[,\s]+')).map((s) => int.tryParse(s.trim()) ?? 0).where((r) => r > 0).toList();
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final db = ref.read(databaseProvider);
      var duration = int.tryParse(_durationController.text) ?? 30;
      
      double? distance, elevation, power, weight;
      int? sets, seconds, calories;
      String? repsListJson;

      if (_distanceController.text.isNotEmpty) distance = double.tryParse(_distanceController.text);
      if (_elevationController.text.isNotEmpty) elevation = double.tryParse(_elevationController.text);
      if (_powerController.text.isNotEmpty) power = double.tryParse(_powerController.text);
      if (_setsController.text.isNotEmpty) sets = int.tryParse(_setsController.text);
      if (_weightController.text.isNotEmpty) weight = double.tryParse(_weightController.text);
      if (_caloriesController.text.isNotEmpty) calories = int.tryParse(_caloriesController.text);

      // 解析每组次数/时长列表
      final repsList = _parseRepsList(_repsController.text);
      if (repsList.isNotEmpty) {
        repsListJson = '[${repsList.join(",")}]';
        // 使用第一组作为默认秒数
        seconds = repsList.first;
      }
      
      // 计算总时长（耐力训练）
      if (_selectedType == 'endurance' && sets != null && seconds != null) {
        duration = (sets * seconds) ~/ 60;
        if (duration < 1) duration = 1;
      }
      
      final startedAt = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime.hour, _selectedTime.minute);
      final endedAt = startedAt.add(Duration(minutes: duration));
      final name = _selectedExercise ?? _nameController.text;

      await db.insertExerciseRecord(ExerciseRecordsCompanion.insert(
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
      ));

      ref.invalidate(exerciseRecordsProvider);
      
      // 触发自动同步
      _triggerAutoSync();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('运动记录已保存')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    }
  }
  
  /// 触发自动同步
  Future<void> _triggerAutoSync() async {
    await triggerAutoSync(ref);
  }
}