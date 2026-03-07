import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/database_providers.dart';

/// 血糖筛选页面
class BloodSugarFilterScreen extends ConsumerWidget {
  const BloodSugarFilterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('筛选血糖记录'),
      ),
      body: ListView(
        children: [
          // 血糖类型筛选
          _buildSectionHeader(context, '血糖类型'),
          _buildFilterTile(
            context: context,
            icon: Icons.restaurant,
            title: '空腹血糖',
            provider: filterFastingProvider,
          ),
          _buildFilterTile(
            context: context,
            icon: Icons.free_breakfast,
            title: '餐后血糖',
            provider: filterPostMealProvider,
          ),
          _buildFilterTile(
            context: context,
            icon: Icons.edit,
            title: '自定义',
            provider: filterCustomProvider,
          ),
          
          const Divider(),
          
          // 血糖范围筛选
          _buildSectionHeader(context, '血糖范围'),
          _buildFilterTile(
            context: context,
            icon: Icons.check_circle,
            title: '达标',
            provider: filterInRangeProvider,
          ),
          _buildFilterTile(
            context: context,
            icon: Icons.arrow_downward,
            title: '偏低',
            provider: filterLowProvider,
          ),
          _buildFilterTile(
            context: context,
            icon: Icons.arrow_upward,
            title: '偏高',
            provider: filterHighProvider,
          ),
          
          const Divider(),
          
          // 时间范围筛选
          _buildSectionHeader(context, '时间范围'),
          _buildFilterTile(
            context: context,
            icon: Icons.today,
            title: '今天',
            provider: filterTodayProvider,
          ),
          _buildFilterTile(
            context: context,
            icon: Icons.date_range,
            title: '本周',
            provider: filterThisWeekProvider,
          ),
          _buildFilterTile(
            context: context,
            icon: Icons.calendar_month,
            title: '本月',
            provider: filterThisMonthProvider,
          ),
          
          const Divider(),
          
          // 清除筛选按钮
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(filterFastingProvider.notifier).state = true;
                ref.read(filterPostMealProvider.notifier).state = true;
                ref.read(filterCustomProvider.notifier).state = true;
                ref.read(filterInRangeProvider.notifier).state = true;
                ref.read(filterLowProvider.notifier).state = true;
                ref.read(filterHighProvider.notifier).state = true;
                ref.read(filterTodayProvider.notifier).state = false;
                ref.read(filterThisWeekProvider.notifier).state = false;
                ref.read(filterThisMonthProvider.notifier).state = false;
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

// 血糖筛选 Providers
final filterFastingProvider = StateProvider<bool>((ref) => true);
final filterPostMealProvider = StateProvider<bool>((ref) => true);
final filterCustomProvider = StateProvider<bool>((ref) => true);
final filterInRangeProvider = StateProvider<bool>((ref) => true);
final filterLowProvider = StateProvider<bool>((ref) => true);
final filterHighProvider = StateProvider<bool>((ref) => true);
final filterTodayProvider = StateProvider<bool>((ref) => false);
final filterThisWeekProvider = StateProvider<bool>((ref) => false);
final filterThisMonthProvider = StateProvider<bool>((ref) => false);
