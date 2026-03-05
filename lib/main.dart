import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/router.dart';
import 'core/theme.dart';
import 'data/database/database_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化日期格式化（解决中文 locale 问题）
  await initializeDateFormatting('zh_CN', null);
  
  // 初始化 SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const GlucoControlApp(),
    ),
  );
}

class GlucoControlApp extends ConsumerWidget {
  const GlucoControlApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'GlucoControl',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
