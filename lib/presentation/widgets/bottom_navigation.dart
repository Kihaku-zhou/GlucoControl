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
    // 调整索引：点击0,1对应原0,1；点击2(添加)单独处理；点击3,4对应原2,3
    int adjustedIndex = currentIndex >= 2 ? currentIndex + 1 : currentIndex;
    
    return BottomNavigationBar(
      currentIndex: adjustedIndex,
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
          icon: Icon(Icons.add_circle, size: 32),
          label: '添加',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.straighten),
          label: '体测',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.restaurant),
          label: '饮食',
        ),
      ],
    );
  }
}