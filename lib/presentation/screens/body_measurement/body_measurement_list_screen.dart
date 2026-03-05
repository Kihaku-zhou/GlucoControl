import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/database/database.dart';
import '../../../data/database/database_providers.dart';

/// 体测记录列表页面
class BodyMeasurementListScreen extends ConsumerWidget {
  const BodyMeasurementListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(bodyMeasurementsProvider);
    final latestAsync = ref.watch(latestBodyMeasurementProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('体测记录'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BodyMeasurementChartScreen(),
                ),
              );
            },
            tooltip: '体测趋势',
          ),
        ],
      ),
      body: Column(
        children: [
          // 最新体测卡片
          latestAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (latest) {
              if (latest == null) return const SizedBox.shrink();
              return _LatestMeasurementCard(measurement: latest);
            },
          ),
          
          // 体测记录列表
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
                        Icon(Icons.straighten, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('暂无体测记录', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        SizedBox(height: 8),
                        Text('点击右下角按钮添加体测', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];
                    return _BodyMeasurementTile(record: record);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMeasurementDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddMeasurementDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddBodyMeasurementSheet(),
    );
  }
}

/// 最新体测卡片
class _LatestMeasurementCard extends StatelessWidget {
  final BodyMeasurement measurement;

  const _LatestMeasurementCard({required this.measurement});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment_turned_in, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  '最新体测',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('yyyy-MM-dd').format(measurement.measuredAt),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 主要指标
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (measurement.weight != null)
                  _MetricItem(
                    label: '体重',
                    value: '${measurement.weight!.toStringAsFixed(1)}',
                    unit: 'kg',
                  ),
                if (measurement.bmi != null)
                  _MetricItem(
                    label: 'BMI',
                    value: measurement.bmi!.toStringAsFixed(1),
                    unit: '',
                    color: _getBmiColor(measurement.bmi!),
                  ),
                if (measurement.bodyFat != null)
                  _MetricItem(
                    label: '体脂',
                    value: '${measurement.bodyFat!.toStringAsFixed(1)}',
                    unit: '%',
                  ),
                if (measurement.waistHipRatio != null)
                  _MetricItem(
                    label: '腰臀比',
                    value: measurement.waistHipRatio!.toStringAsFixed(2),
                    unit: '',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getBmiColor(double bmi) {
    if (bmi < 18.5) return Colors.orange;
    if (bmi < 24) return Colors.green;
    if (bmi < 28) return Colors.orange;
    return Colors.red;
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color? color;

  const _MetricItem({
    required this.label,
    required this.value,
    required this.unit,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (unit.isNotEmpty)
              Text(
                unit,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
      ],
    );
  }
}

/// 体测记录列表项
class _BodyMeasurementTile extends StatelessWidget {
  final BodyMeasurement record;

  const _BodyMeasurementTile({required this.record});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.straighten,
            color: Colors.purple,
          ),
        ),
        title: Text(
          DateFormat('yyyy年M月d日').format(record.measuredAt),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            if (record.weight != null) Text('体重: ${record.weight}kg'),
            if (record.bmi != null) Text('BMI: ${record.bmi!.toStringAsFixed(1)}'),
            if (record.bodyFat != null) Text('体脂: ${record.bodyFat}%'),
            if (record.waist != null && record.hip != null) 
              Text('腰臀比: ${record.waistHipRatio?.toStringAsFixed(2) ?? "-"}'),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('编辑'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('删除', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) async {
            if (value == 'delete') {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('确认删除'),
                  content: const Text('确定要删除这条体测记录吗？'),
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
                // 获取 ref 的方式
                final container = ProviderScope.containerOf(context);
                final db = container.read(databaseProvider);
                await db.deleteBodyMeasurement(record.id);
                container.invalidate(bodyMeasurementsProvider);
                container.invalidate(latestBodyMeasurementProvider);
              }
            } else if (value == 'edit') {
              if (context.mounted) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => AddBodyMeasurementSheet(measurement: record),
                );
              }
            }
          },
        ),
      ),
    );
  }
}

/// 添加体测记录表单
class AddBodyMeasurementSheet extends ConsumerStatefulWidget {
  final BodyMeasurement? measurement;
  
  const AddBodyMeasurementSheet({super.key, this.measurement});

  @override
  ConsumerState<AddBodyMeasurementSheet> createState() => _AddBodyMeasurementSheetState();
}

class _AddBodyMeasurementSheetState extends ConsumerState<AddBodyMeasurementSheet> {
  final _formKey = GlobalKey<FormState>();
  
  // 基本信息
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _muscleMassController = TextEditingController();
  
  // 围度测量
  final _chestController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipController = TextEditingController();
  final _thighLeftController = TextEditingController();
  final _thighRightController = TextEditingController();
  final _armLeftController = TextEditingController();
  final _armRightController = TextEditingController();
  final _neckController = TextEditingController();
  
  // 其他
  final _noteController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  // 计算出的指标
  double? _calculatedBmi;
  double? _calculatedWaistHipRatio;

  @override
  void initState() {
    super.initState();
    if (widget.measurement != null) {
      _loadMeasurement(widget.measurement!);
    } else {
      _loadLatestMeasurement();
    }
  }

  void _loadMeasurement(BodyMeasurement m) {
    if (m.weight != null) _weightController.text = m.weight.toString();
    if (m.height != null) _heightController.text = m.height.toString();
    if (m.bodyFat != null) _bodyFatController.text = m.bodyFat.toString();
    if (m.muscleMass != null) _muscleMassController.text = m.muscleMass.toString();
    if (m.chest != null) _chestController.text = m.chest.toString();
    if (m.waist != null) _waistController.text = m.waist.toString();
    if (m.hip != null) _hipController.text = m.hip.toString();
    if (m.thighLeft != null) _thighLeftController.text = m.thighLeft.toString();
    if (m.thighRight != null) _thighRightController.text = m.thighRight.toString();
    if (m.armLeft != null) _armLeftController.text = m.armLeft.toString();
    if (m.armRight != null) _armRightController.text = m.armRight.toString();
    if (m.neck != null) _neckController.text = m.neck.toString();
    if (m.note != null) _noteController.text = m.note!;
    _selectedDate = m.measuredAt;
    _selectedTime = TimeOfDay.fromDateTime(m.measuredAt);
    _calculateMetrics();
  }

  Future<void> _loadLatestMeasurement() async {
    try {
      final db = ref.read(databaseProvider);
      final latest = await db.getLatestBodyMeasurement();
      if (latest != null && mounted) {
        // 预填身高（如果有记录的话）
        if (latest.height != null) {
          _heightController.text = latest.height.toString();
        }
      }
    } catch (e) {
      debugPrint('Failed to load latest measurement: $e');
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _bodyFatController.dispose();
    _muscleMassController.dispose();
    _chestController.dispose();
    _waistController.dispose();
    _hipController.dispose();
    _thighLeftController.dispose();
    _thighRightController.dispose();
    _armLeftController.dispose();
    _armRightController.dispose();
    _neckController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _calculateMetrics() {
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);
    final waist = double.tryParse(_waistController.text);
    final hip = double.tryParse(_hipController.text);

    // 计算 BMI = 体重(kg) / 身高(m)^2
    if (weight != null && height != null && height > 0) {
      _calculatedBmi = weight / ((height / 100) * (height / 100));
    }

    // 计算腰臀比 = 腰围 / 臀围
    if (waist != null && hip != null && hip > 0) {
      _calculatedWaistHipRatio = waist / hip;
    }

    setState(() {});
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
                Text(
                  widget.measurement == null ? '添加体测记录' : '编辑体测记录',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // 计算的指标展示
                if (_calculatedBmi != null || _calculatedWaistHipRatio != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        if (_calculatedBmi != null)
                          Column(
                            children: [
                              const Text('BMI', style: TextStyle(color: Colors.grey)),
                              Text(
                                _calculatedBmi!.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              Text(
                                _getBmiStatus(_calculatedBmi!),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getBmiColor(_calculatedBmi!),
                                ),
                              ),
                            ],
                          ),
                        if (_calculatedWaistHipRatio != null)
                          Column(
                            children: [
                              const Text('腰臀比', style: TextStyle(color: Colors.grey)),
                              Text(
                                _calculatedWaistHipRatio!.toStringAsFixed(2),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              Text(
                                _getWaistHipStatus(_calculatedWaistHipRatio!),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                // 基本信息
                const Text('基本信息', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: '体重',
                          suffixText: 'kg',
                        ),
                        onChanged: (_) => _calculateMetrics(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _heightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: '身高',
                          suffixText: 'cm',
                        ),
                        onChanged: (_) => _calculateMetrics(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _bodyFatController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: '体脂率',
                          suffixText: '%',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _muscleMassController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: '肌肉量',
                          suffixText: 'kg',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 围度测量
                const Text('围度测量', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _chestController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: '胸围',
                          suffixText: 'cm',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _waistController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: '腰围',
                          suffixText: 'cm',
                        ),
                        onChanged: (_) => _calculateMetrics(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _hipController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: '臀围',
                          suffixText: 'cm',
                        ),
                        onChanged: (_) => _calculateMetrics(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _thighLeftController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: '左大腿',
                          suffixText: 'cm',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _thighRightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: '右大腿',
                          suffixText: 'cm',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _armLeftController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: '左臂',
                          suffixText: 'cm',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _armRightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: '右臂',
                          suffixText: 'cm',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _neckController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: '颈围',
                          suffixText: 'cm',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 备注
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: '备注（可选）',
                    hintText: '添加一些备注...',
                  ),
                  maxLines: 2,
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

  String _getBmiStatus(double bmi) {
    if (bmi < 18.5) return '偏瘦';
    if (bmi < 24) return '正常';
    if (bmi < 28) return '偏胖';
    return '肥胖';
  }

  Color _getBmiColor(double bmi) {
    if (bmi < 18.5) return Colors.orange;
    if (bmi < 24) return Colors.green;
    if (bmi < 28) return Colors.orange;
    return Colors.red;
  }

  String _getWaistHipStatus(double ratio) {
    if (ratio < 0.8) return '偏低';
    if (ratio <= 0.9) return '正常';
    return '偏高';
  }

  Future<void> _saveRecord() async {
    // 解析输入值
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);
    final bodyFat = double.tryParse(_bodyFatController.text);
    final muscleMass = double.tryParse(_muscleMassController.text);
    final chest = double.tryParse(_chestController.text);
    final waist = double.tryParse(_waistController.text);
    final hip = double.tryParse(_hipController.text);
    final thighLeft = double.tryParse(_thighLeftController.text);
    final thighRight = double.tryParse(_thighRightController.text);
    final armLeft = double.tryParse(_armLeftController.text);
    final armRight = double.tryParse(_armRightController.text);
    final neck = double.tryParse(_neckController.text);

    final measuredAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // 计算 BMI 和腰臀比
    double? bmi;
    double? waistHipRatio;
    
    if (weight != null && height != null && height > 0) {
      bmi = weight / ((height / 100) * (height / 100));
    }
    if (waist != null && hip != null && hip > 0) {
      waistHipRatio = waist / hip;
    }

    final db = ref.read(databaseProvider);

    if (widget.measurement == null) {
      // 新增记录
      await db.insertBodyMeasurement(
        BodyMeasurementsCompanion.insert(
          weight: drift.Value(weight),
          height: drift.Value(height),
          bodyFat: drift.Value(bodyFat),
          muscleMass: drift.Value(muscleMass),
          chest: drift.Value(chest),
          waist: drift.Value(waist),
          hip: drift.Value(hip),
          thighLeft: drift.Value(thighLeft),
          thighRight: drift.Value(thighRight),
          armLeft: drift.Value(armLeft),
          armRight: drift.Value(armRight),
          neck: drift.Value(neck),
          bmi: drift.Value(bmi),
          waistHipRatio: drift.Value(waistHipRatio),
          note: drift.Value(_noteController.text.isNotEmpty ? _noteController.text : null),
          measuredAt: measuredAt,
          createdAt: DateTime.now(),
        ),
      );
    } else {
      // 更新记录 - 先删除再重新插入
      await db.deleteBodyMeasurement(widget.measurement!.id);
      
      await db.insertBodyMeasurement(
        BodyMeasurementsCompanion.insert(
          weight: drift.Value(weight),
          height: drift.Value(height),
          bodyFat: drift.Value(bodyFat),
          muscleMass: drift.Value(muscleMass),
          chest: drift.Value(chest),
          waist: drift.Value(waist),
          hip: drift.Value(hip),
          thighLeft: drift.Value(thighLeft),
          thighRight: drift.Value(thighRight),
          armLeft: drift.Value(armLeft),
          armRight: drift.Value(armRight),
          neck: drift.Value(neck),
          bmi: drift.Value(bmi),
          waistHipRatio: drift.Value(waistHipRatio),
          note: drift.Value(_noteController.text.isNotEmpty ? _noteController.text : null),
          measuredAt: measuredAt,
          createdAt: DateTime.now(),
        ),
      );
    }

    ref.invalidate(bodyMeasurementsProvider);
    ref.invalidate(latestBodyMeasurementProvider);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('体测记录已保存')),
      );
    }
  }
}

/// 体测趋势图表页面
class BodyMeasurementChartScreen extends ConsumerWidget {
  const BodyMeasurementChartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(bodyMeasurementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('体测趋势'),
      ),
      body: recordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('错误: $error')),
        data: (records) {
          if (records.length < 2) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.show_chart, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('数据不足', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('至少需要2条记录才能显示趋势', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // TODO: 实现图表功能
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.show_chart, size: 64, color: Colors.blue),
                const SizedBox(height: 16),
                Text('共 ${records.length} 条记录', style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                const Text('图表功能开发中...', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        },
      ),
    );
  }
}
