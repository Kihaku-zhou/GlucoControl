import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 饮食筛选页面
class MealFilterScreen extends ConsumerWidget {
  const MealFilterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('筛选饮食记录'),
      ),
      body: ListView(
        children: [
          // 餐饮类型筛选
          _buildSectionHeader(context, '餐饮类型'),
          _buildFilterTile(
            context: context,
            icon: Icons.free_breakfast,
            title: '早餐',
            provider: mealFilterBreakfastProvider,
          ),
          _buildFilterTile(
            context: context,
            icon: Icons.lunch_dining,
            title: '午餐',
            provider: mealFilterLunchProvider,
          ),
          _buildFilterTile(
            context: context,
            icon: Icons.dinner_dining,
            title: '晚餐',
            provider: mealFilterDinnerProvider,
          ),
          _buildFilterTile(
            context: context,
            icon: Icons.cookie,
            title: '零食',
            provider: mealFilterSnackProvider,
          ),
          
          const Divider(),
          
          // 时间范围筛选
          _buildSectionHeader(context, '时间范围'),
          _buildFilterTile(
            context: context,
            icon: Icons.today,
            title: '今天',
            provider: mealFilterTodayProvider,
          ),
          _buildFilterTile(
            context: context,
            icon: Icons.date_range,
            title: '本周',
            provider: mealFilterThisWeekProvider,
          ),
          _buildFilterTile(
            context: context,
            icon: Icons.calendar_month,
            title: '本月',
            provider: mealFilterThisMonthProvider,
          ),
          
          const Divider(),
          
          // 清除筛选按钮
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(mealFilterBreakfastProvider.notifier).state = true;
                ref.read(mealFilterLunchProvider.notifier).state = true;
                ref.read(mealFilterDinnerProvider.notifier).state = true;
                ref.read(mealFilterSnackProvider.notifier).state = true;
                ref.read(mealFilterTodayProvider.notifier).state = false;
                ref.read(mealFilterThisWeekProvider.notifier).state = false;
                ref.read(mealFilterThisMonthProvider.notifier).state = false;
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

// 饮食筛选 Providers
final mealFilterBreakfastProvider = StateProvider<bool>((ref) => true);
final mealFilterLunchProvider = StateProvider<bool>((ref) => true);
final mealFilterDinnerProvider = StateProvider<bool>((ref) => true);
final mealFilterSnackProvider = StateProvider<bool>((ref) => true);
final mealFilterTodayProvider = StateProvider<bool>((ref) => false);
final mealFilterThisWeekProvider = StateProvider<bool>((ref) => false);
final mealFilterThisMonthProvider = StateProvider<bool>((ref) => false);
