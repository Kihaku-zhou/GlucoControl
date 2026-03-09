import 'dart:io';

import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/database/database.dart';
import '../../../data/database/database_providers.dart';
import '../../../services/meal_image_service.dart';
import '../../../services/auto_sync_service.dart';
import 'meal_filter_screen.dart';

/// 饮食记录列表页面
class MealListScreen extends ConsumerWidget {
  const MealListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(mealRecordsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('饮食记录'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MealFilterScreen(),
                ),
              );
            },
            tooltip: '筛选',
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
                  Icon(Icons.restaurant_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('暂无饮食记录', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('点击右下角按钮添加饮食', style: TextStyle(color: Colors.grey)),
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
                  ...dayRecords.map((record) => _MealRecordTile(record: record)),
                ],
              );
            },
          );
        },
      ),
        onPressed: () => _showAddMealDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Map<String, List<MealRecord>> _groupRecordsByDate(List<MealRecord> records) {
    final Map<String, List<MealRecord>> grouped = {};
    final dateFormat = DateFormat('yyyy年M月d日 E', 'zh_CN');

    for (final record in records) {
      final dateKey = dateFormat.format(record.recordedAt);
      grouped.putIfAbsent(dateKey, () => []).add(record);
    }

    return grouped;
  }

  void _showAddMealDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddMealSheet(),
    );
  }
}

/// 饮食记录列表项
class _MealRecordTile extends StatelessWidget {
  final MealRecord record;

  const _MealRecordTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getMealTypeColor(record.type).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getMealTypeIcon(record.type),
            color: _getMealTypeColor(record.type),
          ),
        ),
        title: Text(
          _getMealTypeText(record.type),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(timeFormat.format(record.recordedAt)),
            if (record.note != null && record.note!.isNotEmpty)
              Text(record.note!, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: record.imagePath != null
            ? const Icon(Icons.photo, color: Colors.grey)
            : null,
        onTap: () => _showRecordDetail(context, record),
      ),
    );
  }

  void _showRecordDetail(BuildContext context, MealRecord record) {
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
                Icon(_getMealTypeIcon(record.type), color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  '饮食记录详情',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow('餐次', _getMealTypeText(record.type)),
            _buildDetailRow('记录时间', dateFormat.format(record.recordedAt)),
            if (record.imagePath != null && record.imagePath!.isNotEmpty) ...[
              const Text('图片', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(record.imagePath!),
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Text('图片加载失败'),
                ),
              ),
            ],
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

  IconData _getMealTypeIcon(String type) {
    switch (type) {
      case 'breakfast':
        return Icons.wb_sunny;
      case 'lunch':
        return Icons.wb_cloudy;
      case 'dinner':
        return Icons.nightlight_round;
      case 'snack':
        return Icons.cookie;
      default:
        return Icons.restaurant;
    }
  }

  Color _getMealTypeColor(String type) {
    switch (type) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.blue;
      case 'dinner':
        return Colors.purple;
      case 'snack':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  String _getMealTypeText(String type) {
    switch (type) {
      case 'breakfast':
        return '早餐';
      case 'lunch':
        return '午餐';
      case 'dinner':
        return '晚餐';
      case 'snack':
        return '加餐';
      default:
        return type;
    }
  }
}

/// 添加饮食记录表单
class AddMealSheet extends ConsumerStatefulWidget {
  const AddMealSheet({super.key});

  @override
  ConsumerState<AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends ConsumerState<AddMealSheet> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  
  String _selectedType = 'breakfast';
  TimeOfDay _selectedTime = TimeOfDay.now();
  DateTime _selectedDate = DateTime.now();
  final List<FoodItemInput> _foodItems = [];
  
  // 图片相关
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();
  final MealImageService _imageService = MealImageService();

  @override
  void initState() {
    super.initState();
    // 初始化时清理旧图片
    _imageService.cleanupOldImages();
  }

  @override
  void dispose() {
    _noteController.dispose();
    for (var item in _foodItems) {
      item.nameController.dispose();
      item.amountController.dispose();
      item.carbsController.dispose();
    }
    super.dispose();
  }

  /// 选择图片来源
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );
      
      if (pickedFile != null) {
        // 保存并压缩图片
        final savedPath = await _imageService.saveCompressedImage(pickedFile);
        if (savedPath != null && mounted) {
          setState(() {
            _imagePath = savedPath;
          });
        }
      }
    } catch (e) {
      debugPrint('选择图片失败: $e');
    }
  }

  /// 显示图片选择对话框
  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('拍照'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('从相册选择'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_imagePath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('删除图片', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _imagePath = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  /// 构建图片选择器
  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _showImagePicker,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: _imagePath != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_imagePath!),
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      radius: 16,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 16, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _imagePath = null;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text('点击添加图片', style: TextStyle(color: Colors.grey[600])),
                  Text('(图片将自动压缩)', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                ],
              ),
      ),
    );
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
                  '添加饮食记录',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // 餐次选择
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'breakfast', label: Text('早餐')),
                    ButtonSegment(value: 'lunch', label: Text('午餐')),
                    ButtonSegment(value: 'dinner', label: Text('晚餐')),
                    ButtonSegment(value: 'snack', label: Text('加餐')),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (value) {
                    setState(() {
                      _selectedType = value.first;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // 图片上传
                _buildImagePicker(),
                const SizedBox(height: 16),

                // 食物列表
                const Text('食物', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                
                ..._foodItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: item.nameController,
                                  decoration: const InputDecoration(
                                    labelText: '食物名称',
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: item.amountController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: '份量',
                                    isDense: true,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _foodItems.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: item.carbsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: '碳水化合物（可选）',
                              suffixText: 'g',
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _foodItems.add(FoodItemInput());
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('添加食物'),
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

  Future<void> _saveRecord() async {
    final db = ref.read(databaseProvider);
    final recordedAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // 插入饮食记录
    final mealId = await db.insertMealRecord(
      MealRecordsCompanion.insert(
        type: _selectedType,
        recordedAt: recordedAt,
        imagePath: drift.Value(_imagePath),
        note: drift.Value(_noteController.text.isNotEmpty ? _noteController.text : null),
        createdAt: DateTime.now(),
      ),
    );

    // 插入食物项
    for (final item in _foodItems) {
      if (item.nameController.text.isNotEmpty) {
        double? carbs;
        if (item.carbsController.text.isNotEmpty) {
          carbs = double.tryParse(item.carbsController.text);
        }
        
        await db.insertFoodItem(
          FoodItemsCompanion.insert(
            mealId: mealId,
            name: item.nameController.text,
            amount: double.tryParse(item.amountController.text) ?? 100,
            carbs: drift.Value(carbs),
          ),
        );
      }
    }

    // 刷新列表
    ref.invalidate(mealRecordsProvider);
    triggerAutoSync(ref);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('饮食记录已保存')),
      );
    }
  }
}

/// 临时食物输入类
class FoodItemInput {
  final nameController = TextEditingController();
  final amountController = TextEditingController(text: '100');
  final carbsController = TextEditingController();
}
