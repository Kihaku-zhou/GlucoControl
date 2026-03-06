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
