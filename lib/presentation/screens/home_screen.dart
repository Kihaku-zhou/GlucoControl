import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/bottom_navigation.dart';
import 'blood_sugar/blood_sugar_list_screen.dart';
import 'exercise/exercise_list_screen.dart';
import 'exercise/simple_exercise_list_screen.dart';
import 'meal/meal_list_screen.dart';
import 'settings/settings_screen.dart';
import 'body_measurement/body_measurement_list_screen.dart';
import 'ai/ai_chat_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      body: _buildCurrentScreen(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Scaffold.of(context).openDrawer(),
        tooltip: '菜单',
        child: const Icon(Icons.menu),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      bottomNavigationBar: BottomNavigationWidget(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
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
                  '健康管理中心',
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
            subtitle: const Text('智能问答与健康分析'),
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
              setState(() {
                _currentIndex = 4;
              });
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

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return const BloodSugarListScreen();
      case 1:
        return const SimpleExerciseListScreen();
      case 2:
        return const BodyMeasurementListScreen();
      case 3:
        return const MealListScreen();
      default:
        return const Center(child: Text('页面不存在'));
    }
  }
}
