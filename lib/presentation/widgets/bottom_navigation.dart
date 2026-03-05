import 'package:flutter/material.dart';

class BottomNavigationWidget extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavigationWidget({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.monitor_heart),
          label: '血糖',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.fitness_center),
          label: '运动',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.restaurant),
          label: '饮食',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: '设置',
        ),
      ],
    );
  }
}