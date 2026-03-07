import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../data/database/database_providers.dart';
import '../../../services/data_export_service.dart';
import 'notification_settings_screen.dart';
import 'exercise_goal_screen.dart';
import 'blood_sugar_goal_screen.dart';

/// 设置主页面
class SettingsMainScreen extends ConsumerWidget {
  const SettingsMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          // 单位设置
          _buildSectionHeader('单位设置'),
          const BloodSugarUnitTile(),
          const Divider(),

          // 主题设置
          _buildSectionHeader('外观'),
          const ThemeModeTile(),
          const Divider(),

          // 血糖范围
          _buildSectionHeader('血糖范围'),
          const SafeRangeTile(),
          const Divider(),

          // WebDAV 同步
          _buildSectionHeader('数据同步'),
          ListTile(
            leading: const Icon(Icons.cloud_sync),
            title: const Text('WebDAV 同步'),
            subtitle: const Text('坚果云'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WebDAVSettingsScreen(),
                ),
              );
            },
          ),
          const Divider(),

          // 通知设置
          _buildSectionHeader('提醒'),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('测量提醒'),
            subtitle: const Text('定时提醒测量血糖'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsScreen(),
                ),
              );
            },
          ),
          const Divider(),

          // 运动目标
          _buildSectionHeader('运动目标'),
          ListTile(
            leading: const Icon(Icons.fitness_center),
            title: const Text('运动目标设置'),
            subtitle: const Text('设置每周运动时长和天数目标'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ExerciseGoalScreen(),
                ),
              );
            },
          ),
          
          // 血糖目标
          _buildSectionHeader('血糖目标'),
          ListTile(
            leading: const Icon(Icons.monitor_heart),
            title: const Text('血糖目标设置'),
            subtitle: const Text('设置安全血糖范围和TIR目标'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BloodSugarGoalScreen(),
                ),
              );
            },
          ),
          const Divider(),

          // AI API
          _buildSectionHeader('AI 分析'),
          ListTile(
            leading: const Icon(Icons.psychology),
            title: const Text('AI API 配置'),
            subtitle: const Text('自定义 AI 分析'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AIApiSettingsScreen(),
                ),
              );
            },
          ),
          const Divider(),

          // 数据管理
          _buildSectionHeader('数据管理'),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('导出数据 (JSON)'),
            subtitle: const Text('导出为 JSON 文件'),
            onTap: () async {
              try {
                final db = ref.read(databaseProvider);
                final exportService = DataExportService(db);
                final filePath = await exportService.saveExportToFile();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('数据已导出到: $filePath')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('导出失败: $e')),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.table_chart),
            title: const Text('导出血糖 (CSV)'),
            subtitle: const Text('导出为 Excel 可用格式'),
            onTap: () async {
              try {
                final db = ref.read(databaseProvider);
                final exportService = DataExportService(db);
                final csv = await exportService.exportBloodSugarToCsv();
                
                final directory = await getApplicationDocumentsDirectory();
                final file = File('${directory.path}/glucocontrol_bloodsugar_${DateTime.now().millisecondsSinceEpoch}.csv');
                await file.writeAsString(csv);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('血糖数据已导出到: ${file.path}')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('导出失败: $e')),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_upload),
            title: const Text('导入数据'),
            subtitle: const Text('从 JSON 文件导入'),
            onTap: () async {
              try {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['json'],
                );
                
                if (result != null && result.files.single.path != null) {
                  final file = File(result.files.single.path!);
                  final jsonString = await file.readAsString();
                  
                  final db = ref.read(databaseProvider);
                  final exportService = DataExportService(db);
                  final count = await exportService.importFromJson(jsonString);
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('成功导入 $count 条记录')),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('导入失败: $e')),
                  );
                }
              }
            },
          ),
          const Divider(),

          // 数据管理
          _buildSectionHeader('数据管理'),
          ListTile(
            leading: const Icon(Icons.delete_sweep, color: Colors.red),
            title: const Text('清理旧数据'),
            subtitle: const Text('删除指定日期之前的数据'),
            onTap: () => _showClearDataDialog(context, ref),
          ),
          const Divider(),

          // 关于
          _buildSectionHeader('关于'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('GlucoControl'),
            subtitle: Text('版本 0.1.0'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// 血糖单位设置
class BloodSugarUnitTile extends ConsumerWidget {
  const BloodSugarUnitTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUnit = ref.watch(bloodSugarUnitProvider);

    return ListTile(
      leading: const Icon(Icons.speed),
      title: const Text('血糖单位'),
      subtitle: Text(currentUnit),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('选择血糖单位'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text('mg/dL'),
                  value: 'mg/dL',
                  groupValue: currentUnit,
                  onChanged: (value) async {
                    if (value != currentUnit) {
                      final db = ref.read(databaseProvider);
                      final prefs = ref.read(sharedPreferencesProvider);
                      // 转换已有记录
                      await db.convertBloodSugarUnit(currentUnit, value!);
                      await prefs.setString('blood_sugar_unit', value);
                      ref.read(bloodSugarUnitProvider.notifier).state = value;
                      // 刷新血糖记录
                      ref.invalidate(bloodSugarRecordsProvider);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('血糖单位已切换')),
                        );
                      }
                    } else {
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                ),
                RadioListTile<String>(
                  title: const Text('mmol/L'),
                  value: 'mmol/L',
                  groupValue: currentUnit,
                  onChanged: (value) async {
                    if (value != currentUnit) {
                      final db = ref.read(databaseProvider);
                      final prefs = ref.read(sharedPreferencesProvider);
                      // 转换已有记录
                      await db.convertBloodSugarUnit(currentUnit, value!);
                      await prefs.setString('blood_sugar_unit', value);
                      ref.read(bloodSugarUnitProvider.notifier).state = value;
                      // 刷新血糖记录
                      ref.invalidate(bloodSugarRecordsProvider);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('血糖单位已切换')),
                        );
                      }
                    } else {
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 安全范围设置
class SafeRangeTile extends ConsumerWidget {
  const SafeRangeTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final min = ref.watch(safeRangeMinProvider);
    final max = ref.watch(safeRangeMaxProvider);

    return ListTile(
      leading: const Icon(Icons.security),
      title: const Text('安全血糖范围'),
      subtitle: Text('${min.toInt()} - ${max.toInt()} mg/dL'),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SafeRangeEditScreen(),
          ),
        );
      },
    );
  }
}

/// 安全范围编辑页面
class SafeRangeEditScreen extends ConsumerStatefulWidget {
  const SafeRangeEditScreen({super.key});

  @override
  ConsumerState<SafeRangeEditScreen> createState() => _SafeRangeEditScreenState();
}

class _SafeRangeEditScreenState extends ConsumerState<SafeRangeEditScreen> {
  late double _min;
  late double _max;

  @override
  void initState() {
    super.initState();
    _min = ref.read(safeRangeMinProvider);
    _max = ref.read(safeRangeMaxProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('安全血糖范围'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '设置血糖安全范围，图表将显示达标区间',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            
            // 范围预设
            const Text('预设范围', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('标准 (70-140)'),
                  onPressed: () {
                    setState(() {
                      _min = 70;
                      _max = 140;
                    });
                  },
                ),
                ActionChip(
                  label: const Text('严格 (80-120)'),
                  onPressed: () {
                    setState(() {
                      _min = 80;
                      _max = 120;
                    });
                  },
                ),
                ActionChip(
                  label: const Text('宽松 (70-180)'),
                  onPressed: () {
                    setState(() {
                      _min = 70;
                      _max = 180;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // 下限
            Text('下限: ${_min.toInt()} mg/dL'),
            Slider(
              value: _min,
              min: 40,
              max: 100,
              divisions: 60,
              label: '${_min.toInt()}',
              onChanged: (value) {
                setState(() {
                  _min = value;
                  if (_min >= _max) _max = _min + 10;
                });
              },
            ),
            
            // 上限
            Text('上限: ${_max.toInt()} mg/dL'),
            Slider(
              value: _max,
              min: 100,
              max: 250,
              divisions: 150,
              label: '${_max.toInt()}',
              onChanged: (value) {
                setState(() {
                  _max = value;
                  if (_max <= _min) _min = _max - 10;
                });
              },
            ),
            
            const Spacer(),
            
            // 保存按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final prefs = ref.read(sharedPreferencesProvider);
                  await prefs.setDouble('safe_range_min', _min);
                  await prefs.setDouble('safe_range_max', _max);
                  ref.read(safeRangeMinProvider.notifier).state = _min;
                  ref.read(safeRangeMaxProvider.notifier).state = _max;
                  
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('安全范围已保存')),
                    );
                  }
                },
                child: const Text('保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// WebDAV 设置页面
class WebDAVSettingsScreen extends ConsumerStatefulWidget {
  const WebDAVSettingsScreen({super.key});

  @override
  ConsumerState<WebDAVSettingsScreen> createState() => _WebDAVSettingsScreenState();
}

class _WebDAVSettingsScreenState extends ConsumerState<WebDAVSettingsScreen> {
  final _serverController = TextEditingController(text: 'https://dav.jianguoyun.com/dav/');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = ref.read(sharedPreferencesProvider);
    setState(() {
      _serverController.text = prefs.getString('webdav_server') ?? 'https://dav.jianguoyun.com/dav/';
      _usernameController.text = prefs.getString('webdav_username') ?? '';
      _passwordController.text = prefs.getString('webdav_password') ?? '';
      _isEnabled = prefs.getBool('webdav_enabled') ?? false;
    });
  }

  @override
  void dispose() {
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebDAV 同步'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 启用开关
          SwitchListTile(
            title: const Text('启用 WebDAV 同步'),
            subtitle: const Text('同步数据到坚果云'),
            value: _isEnabled,
            onChanged: (value) {
              setState(() {
                _isEnabled = value;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // 服务器地址
          TextField(
            controller: _serverController,
            decoration: const InputDecoration(
              labelText: '服务器地址',
              hintText: 'https://dav.jianguoyun.com/dav/',
              prefixIcon: Icon(Icons.cloud),
            ),
          ),
          const SizedBox(height: 16),
          
          // 用户名
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: '用户名',
              hintText: '坚果云账号',
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 16),
          
          // 密码
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: '密码',
              hintText: '应用密码',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          const Text(
            '提示：坚果云需要使用应用密码，不是登录密码。\n在坚果云网页版 → 设置 → 安全 → 添加应用',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 24),
          
          // 测试连接按钮
          OutlinedButton.icon(
            onPressed: _testConnection,
            icon: const Icon(Icons.wifi_tethering),
            label: const Text('测试连接'),
          ),
          const SizedBox(height: 16),
          
          // 保存按钮
          ElevatedButton(
            onPressed: _saveSettings,
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _testConnection() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('测试连接功能开发中...')),
    );
  }

  Future<void> _saveSettings() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('webdav_server', _serverController.text);
    await prefs.setString('webdav_username', _usernameController.text);
    await prefs.setString('webdav_password', _passwordController.text);
    await prefs.setBool('webdav_enabled', _isEnabled);
    
    ref.read(webdavEnabledProvider.notifier).state = _isEnabled;
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WebDAV 设置已保存')),
      );
    }
  }
}

/// AI API 设置页面
class AIApiSettingsScreen extends ConsumerStatefulWidget {
  const AIApiSettingsScreen({super.key});

  @override
  ConsumerState<AIApiSettingsScreen> createState() => _AIApiSettingsScreenState();
}

class _AIApiSettingsScreenState extends ConsumerState<AIApiSettingsScreen> {
  final _apiUrlController = TextEditingController(text: 'https://api.openai.com/v1/chat/completions');
  final _apiKeyController = TextEditingController();
  final _modelController = TextEditingController(text: 'gpt-3.5-turbo');
  bool _obscureKey = true;
  bool _isEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = ref.read(sharedPreferencesProvider);
    setState(() {
      _apiUrlController.text = prefs.getString('ai_api_url') ?? 'https://api.openai.com/v1/chat/completions';
      _apiKeyController.text = prefs.getString('ai_api_key') ?? '';
      _modelController.text = prefs.getString('ai_model') ?? 'gpt-3.5-turbo';
      _isEnabled = prefs.getBool('ai_enabled') ?? false;
    });
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI API 配置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 启用开关
          SwitchListTile(
            title: const Text('启用 AI 分析'),
            subtitle: const Text('基于血糖、饮食、运动数据进行分析'),
            value: _isEnabled,
            onChanged: (value) {
              setState(() {
                _isEnabled = value;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // API 地址
          TextField(
            controller: _apiUrlController,
            decoration: const InputDecoration(
              labelText: 'API 地址',
              hintText: 'https://api.openai.com/v1/chat/completions',
              prefixIcon: Icon(Icons.link),
            ),
          ),
          const SizedBox(height: 16),
          
          // API Key
          TextField(
            controller: _apiKeyController,
            obscureText: _obscureKey,
            decoration: InputDecoration(
              labelText: 'API Key',
              hintText: 'your-api-key',
              prefixIcon: const Icon(Icons.key),
              suffixIcon: IconButton(
                icon: Icon(_obscureKey ? Icons.visibility : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    _obscureKey = !_obscureKey;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // 模型选择
          TextField(
            controller: _modelController,
            decoration: const InputDecoration(
              labelText: '模型',
              hintText: 'gpt-3.5-turbo',
              prefixIcon: Icon(Icons.psychology),
            ),
          ),
          const SizedBox(height: 8),
          
          const Text(
            '支持 OpenAI 兼容的 API（如 OpenAI、SiliconFlow、DeepSeek 等）',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 24),
          
          // 保存按钮
          ElevatedButton(
            onPressed: _saveSettings,
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('ai_api_url', _apiUrlController.text);
    await prefs.setString('ai_api_key', _apiKeyController.text);
    await prefs.setString('ai_model', _modelController.text);
    await prefs.setBool('ai_enabled', _isEnabled);
    
    ref.read(aiApiEnabledProvider.notifier).state = _isEnabled;
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI API 设置已保存')),
      );
    }
  }
}

/// 主题模式设置
class ThemeModeTile extends ConsumerWidget {
  const ThemeModeTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return ListTile(
      leading: Icon(
        themeMode == ThemeMode.dark
            ? Icons.dark_mode
            : themeMode == ThemeMode.light
                ? Icons.light_mode
                : Icons.brightness_auto,
      ),
      title: const Text('主题模式'),
      subtitle: Text(_getThemeModeText(themeMode)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showThemeModeDialog(context, ref),
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return '跟随系统';
      case ThemeMode.light:
        return '浅色模式';
      case ThemeMode.dark:
        return '深色模式';
    }
  }

  void _showThemeModeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('跟随系统'),
              value: ThemeMode.system,
              groupValue: ref.read(themeModeProvider),
              onChanged: (value) {
                ref.read(themeModeProvider.notifier).state = value!;
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('浅色模式'),
              value: ThemeMode.light,
              groupValue: ref.read(themeModeProvider),
              onChanged: (value) {
                ref.read(themeModeProvider.notifier).state = value!;
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('深色模式'),
              value: ThemeMode.dark,
              groupValue: ref.read(themeModeProvider),
              onChanged: (value) {
                ref.read(themeModeProvider.notifier).state = value!;
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

  /// 显示清理数据对话框
  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    DateTime selectedDate = DateTime.now().subtract(const Duration(days: 90));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清理旧数据'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('删除指定日期之前的数据，此操作不可恢复，请谨慎操作！'),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  selectedDate = date;
                  (context as Element).markNeedsBuild();
                }
              },
              child: Text('选择日期: ${selectedDate.year}-${selectedDate.month}-${selectedDate.day}'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('仅显示'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final db = ref.read(databaseProvider);
                final count = await db.clearRecordsBeforeDate(selectedDate);
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('已删除 $count 条记录')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('删除失败: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
  }
