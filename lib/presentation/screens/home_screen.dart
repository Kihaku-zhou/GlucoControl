import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/bottom_navigation.dart';
import 'blood_sugar/blood_sugar_list_screen.dart';
import 'exercise/exercise_list_screen.dart';
import 'meal/meal_list_screen.dart';
import 'settings/settings_screen.dart';
import 'body_measurement/body_measurement_list_screen.dart';

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
      appBar: AppBar(
        title: const Text('GlucoControl'),
        centerTitle: true,
      ),
      body: _buildCurrentScreen(),
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

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return const BloodSugarListScreen();
      case 1:
        return const ExerciseListScreen();
      case 2:
        return const BodyMeasurementListScreen();
      case 3:
        return const MealListScreen();
      case 4:
        return const SettingsMainScreen();
      default:
        return const Center(child: Text('页面不存在'));
    }
  }
}
