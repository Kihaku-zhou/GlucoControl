import 'package:flutter/material.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/ai/ai_chat_screen.dart';

/// 创建主应用抽屉
Drawer buildMainDrawer(BuildContext context) {
  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.favorite, color: Colors.white, size: 48),
              SizedBox(height: 8),
              Text(
                'GlucoControl',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '血糖控制应用',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.psychology),
          title: const Text('AI 健康助手'),
          subtitle: const Text('智能分析健康数据与问答'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AIChatScreen(),
              ),
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text('设置'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsMainScreen(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('关于'),
          onTap: () {
            Navigator.pop(context);
            showAboutDialog(
              context: context,
              applicationName: 'GlucoControl',
              applicationVersion: '1.0.0',
              applicationLegalese: '© 2024 GlucoControl',
            );
          },
        ),
      ],
    ),
  );
}
