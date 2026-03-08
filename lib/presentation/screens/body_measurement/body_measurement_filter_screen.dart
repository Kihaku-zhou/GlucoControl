import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 体测筛选页面
class BodyMeasurementFilterScreen extends ConsumerWidget {
  const BodyMeasurementFilterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('筛选体测记录'),
      ),
      body: ListView(
        children: [
          // 时间范围筛选
          _buildSectionHeader(context, '时间范围'),
          _buildFilterTile(
            context: context,
            icon: Icons.today,
            title: '今天',
            provider: bodyFilterTodayProvider,
          ),
          _buildFilterTile(
            context: context,
            icon: Icons.date_range,
            title: '本周',
            provider: bodyFilterThisWeekProvider,
          ),
          _buildFilterTile(
            context: context,
            icon: Icons.calendar_month,
            title: '本月',
            provider: bodyFilterThisMonthProvider,
          ),
          
          const Divider(),
          
          // 清除筛选按钮
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(bodyFilterTodayProvider.notifier).state = false;
                ref.read(bodyFilterThisWeekProvider.notifier).state = false;
                ref.read(bodyFilterThisMonthProvider.notifier).state = false;
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('清除所有筛选'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
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

  Widget _buildFilterTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required StateProvider<bool> provider,
  }) {
    return Consumer(
      builder: (context, ref, child) {
        final isEnabled = ref.watch(provider);
        
        return SwitchListTile(
          secondary: Icon(icon),
          title: Text(title),
          value: isEnabled,
          onChanged: (value) {
            ref.read(provider.notifier).state = value;
          },
        );
      },
    );
  }
}

// 体测筛选 Providers
final bodyFilterTodayProvider = StateProvider<bool>((ref) => false);
final bodyFilterThisWeekProvider = StateProvider<bool>((ref) => false);
final bodyFilterThisMonthProvider = StateProvider<bool>((ref) => false);
