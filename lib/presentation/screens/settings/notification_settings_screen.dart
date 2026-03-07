import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/database_providers.dart';
import '../../../services/notification_service.dart';

/// 通知设置页面
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    await _notificationService.initialize();
    final granted = await _notificationService.requestPermission();
    if (granted && mounted) {
      setState(() => _initialized = true);
    }
  }

  Future<void> _updateNotifications() async {
    final reminderEnabled = ref.read(reminderEnabledProvider);
    final morningEnabled = ref.read(morningReminderEnabledProvider);
    final eveningEnabled = ref.read(eveningReminderEnabledProvider);
    final morningTime = ref.read(morningReminderTimeProvider);
    final eveningTime = ref.read(eveningReminderTimeProvider);

    await _notificationService.cancelAllNotifications();

    if (!reminderEnabled) return;

    // 早上提醒
    if (morningEnabled) {
      await _notificationService.scheduleDailyNotification(
        id: 1,
        title: '血糖测量提醒',
        body: '该测量空腹血糖了，记得记录您的血糖值',
        hour: morningTime.hour,
        minute: morningTime.minute,
      );
    }

    // 晚上提醒
    if (eveningEnabled) {
      await _notificationService.scheduleDailyNotification(
        id: 2,
        title: '血糖测量提醒',
        body: '该测量睡前血糖了，记得记录您的血糖值',
        hour: eveningTime.hour,
        minute: eveningTime.minute,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reminderEnabled = ref.watch(reminderEnabledProvider);
    final morningEnabled = ref.watch(morningReminderEnabledProvider);
    final eveningEnabled = ref.watch(eveningReminderEnabledProvider);
    final morningTime = ref.watch(morningReminderTimeProvider);
    final eveningTime = ref.watch(eveningReminderTimeProvider);
    final afterMealEnabled = ref.watch(afterMealReminderEnabledProvider);
    final afterMealHours = ref.watch(afterMealReminderHoursProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('通知设置'),
      ),
      body: ListView(
        children: [
          // 开关
          SwitchListTile(
            title: const Text('启用测量提醒'),
            subtitle: const Text('定时提醒测量血糖'),
            value: reminderEnabled,
            onChanged: (value) {
              ref.read(reminderEnabledProvider.notifier).state = value;
              _updateNotifications();
            },
          ),
          
          if (reminderEnabled) ...[
            const Divider(),
            
            // 早上提醒
            SwitchListTile(
              title: const Text('空腹血糖提醒'),
              subtitle: Text('${morningTime.hour.toString().padLeft(2, '0')}:${morningTime.minute.toString().padLeft(2, '0')}'),
              value: morningEnabled,
              onChanged: (value) {
                ref.read(morningReminderEnabledProvider.notifier).state = value;
                _updateNotifications();
              },
            ),
            if (morningEnabled)
              ListTile(
                title: const Text('设置时间'),
                trailing: TextButton(
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: morningTime,
                    );
                    if (time != null) {
                      ref.read(morningReminderTimeProvider.notifier).state = time;
                      _updateNotifications();
                    }
                  },
                  child: Text('${morningTime.hour.toString().padLeft(2, '0')}:${morningTime.minute.toString().padLeft(2, '0')}'),
                ),
              ),
            
            // 晚上提醒
            SwitchListTile(
              title: const Text('睡前血糖提醒'),
              subtitle: Text('${eveningTime.hour.toString().padLeft(2, '0')}:${eveningTime.minute.toString().padLeft(2, '0')}'),
              value: eveningEnabled,
              onChanged: (value) {
                ref.read(eveningReminderEnabledProvider.notifier).state = value;
                _updateNotifications();
              },
            ),
            if (eveningEnabled)
              ListTile(
                title: const Text('设置时间'),
                trailing: TextButton(
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: eveningTime,
                    );
                    if (time != null) {
                      ref.read(eveningReminderTimeProvider.notifier).state = time;
                      _updateNotifications();
                    }
                  },
                  child: Text('${eveningTime.hour.toString().padLeft(2, '0')}:${eveningTime.minute.toString().padLeft(2, '0')}'),
                ),
              ),
            
            const Divider(),
            
            // 餐后提醒
            SwitchListTile(
              title: const Text('餐后血糖提醒'),
              subtitle: Text('餐后 $afterMealHours 小时提醒'),
              value: afterMealEnabled,
              onChanged: (value) {
                ref.read(afterMealReminderEnabledProvider.notifier).state = value;
              },
            ),
            if (afterMealEnabled)
              ListTile(
                title: const Text('餐后小时数'),
                trailing: DropdownButton<int>(
                  value: afterMealHours,
                  items: [1, 2, 3, 4].map((h) => 
                    DropdownMenuItem(value: h, child: Text('$h 小时'))
                  ).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(afterMealReminderHoursProvider.notifier).state = value;
                    }
                  },
                ),
              ),
          ],
          
          const Divider(),
          
          // 运动提醒
          _buildSectionHeader('运动提醒', context),
          SwitchListTile(
            title: const Text('运动提醒'),
            subtitle: const Text('定时提醒运动'),
            value: ref.watch(exerciseReminderEnabledProvider),
            onChanged: (value) {
              ref.read(exerciseReminderEnabledProvider.notifier).state = value;
              _updateNotifications();
            },
          ),
          
          if (ref.watch(exerciseReminderEnabledProvider)) ...[
            ListTile(
              title: const Text('提醒时间'),
              trailing: TextButton(
                onPressed: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: ref.read(exerciseReminderTimeProvider),
                  );
                  if (time != null) {
                    ref.read(exerciseReminderTimeProvider.notifier).state = time;
                    _updateNotifications();
                  }
                },
                child: Text(
                  '${ref.read(exerciseReminderTimeProvider).hour.toString().padLeft(2, '0')}:${ref.read(exerciseReminderTimeProvider).minute.toString().padLeft(2, '0')}',
                ),
              ),
            ),
            ListTile(
              title: const Text('提醒日期'),
              subtitle: Text(_getWeekDaysText(ref.read(exerciseReminderDaysProvider))),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showExerciseDaysDialog(context, ref),
            ),
          ],
          
          const Divider(),
          
          // 测试通知按钮
          ListTile(
            title: const Text('测试通知'),
            subtitle: const Text('发送一条测试通知'),
            trailing: const Icon(Icons.send),
            onTap: () async {
              if (!_initialized) {
                await _initNotifications();
              }
              await _notificationService.showNotification(
                id: 999,
                title: '测试通知',
                body: '这是 GlucoControl 的测试通知',
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('测试通知已发送')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

  Widget _buildSectionHeader(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getWeekDaysText(List<int> days) {
    if (days.isEmpty) return '未选择';
    const weekDays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return days.map((d) => weekDays[d - 1]).join('、');
  }

  void _showExerciseDaysDialog(BuildContext context, WidgetRef ref) {
    final selectedDays = List<int>.from(ref.read(exerciseReminderDaysProvider));
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('选择提醒日期'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  title: const Text('周一'),
                  value: selectedDays.contains(1),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        selectedDays.add(1);
                      } else {
                        selectedDays.remove(1);
                      }
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('周二'),
                  value: selectedDays.contains(2),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        selectedDays.add(2);
                      } else {
                        selectedDays.remove(2);
                      }
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('周三'),
                  value: selectedDays.contains(3),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        selectedDays.add(3);
                      } else {
                        selectedDays.remove(3);
                      }
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('周四'),
                  value: selectedDays.contains(4),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        selectedDays.add(4);
                      } else {
                        selectedDays.remove(4);
                      }
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('周五'),
                  value: selectedDays.contains(5),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        selectedDays.add(5);
                      } else {
                        selectedDays.remove(5);
                      }
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('周六'),
                  value: selectedDays.contains(6),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        selectedDays.add(6);
                      } else {
                        selectedDays.remove(6);
                      }
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('周日'),
                  value: selectedDays.contains(7),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        selectedDays.add(7);
                      } else {
                        selectedDays.remove(7);
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                ref.read(exerciseReminderDaysProvider.notifier).state = selectedDays;
                Navigator.pop(dialogContext);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
