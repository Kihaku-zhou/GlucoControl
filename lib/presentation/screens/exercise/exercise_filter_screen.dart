import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 运动筛选页面
class ExerciseFilterScreen extends ConsumerWidget {
  const ExerciseFilterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('筛选运动记录'),
      ),
      body: ListView(
        children: [
          // 运动类型筛选
          _buildSectionHeader(context, '运动类型'),
          _buildFilterTile(
            context: context,
            icon: Icons.directions_run,
            title: '有氧运动',
            provider: filterAerobicProvider,
          ),
          _buildFilterTile(
            context: context,
            icon: Icons.fitness_center,
            title: '力量训练',
            provider: filterAnaerobicProvider,
          ),
          _buildFilterTile(
            context: context,
            icon: Icons.timer,
            title: '耐力训练',
            provider: filterEnduranceProvider,
          ),
          
          const Divider(),
          
          // 时间范围筛选
          _buildSectionHeader(context, '时间范围'),
          _buildFilterTile(
            context: context,
            icon: Icons.today,
            title: '今天',
            provider: exerciseFilterTodayProvider,
          ),
          _buildFilterTile(
            context: context,
            icon: Icons.date_range,
            title: '本周',
            provider: exerciseFilterThisWeekProvider,
          ),
          _buildFilterTile(
            context: context,
            icon: Icons.calendar_month,
            title: '本月',
            provider: exerciseFilterThisMonthProvider,
          ),
          
          const Divider(),
          
          // 清除筛选按钮
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(filterAerobicProvider.notifier).state = true;
                ref.read(filterAnaerobicProvider.notifier).state = true;
                ref.read(filterEnduranceProvider.notifier).state = true;
                ref.read(exerciseFilterTodayProvider.notifier).state = false;
                ref.read(exerciseFilterThisWeekProvider.notifier).state = false;
                ref.read(exerciseFilterThisMonthProvider.notifier).state = false;
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

// 运动筛选 Providers
final filterAerobicProvider = StateProvider<bool>((ref) => true);
final filterAnaerobicProvider = StateProvider<bool>((ref) => true);
final filterEnduranceProvider = StateProvider<bool>((ref) => true);
final exerciseFilterTodayProvider = StateProvider<bool>((ref) => false);
final exerciseFilterThisWeekProvider = StateProvider<bool>((ref) => false);
final exerciseFilterThisMonthProvider = StateProvider<bool>((ref) => false);
