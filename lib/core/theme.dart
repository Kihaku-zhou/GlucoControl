import 'package:flutter/material.dart';

class AppTheme {
  // 血糖安全范围 (mg/dL)
  static const double safeRangeMin = 70.0;
  static const double safeRangeMax = 140.0;
  
  // 血糖范围颜色
  static const Color lowBloodSugarColor = Color(0xFF2196F3);    // 低血糖 - 蓝色
  static const Color normalBloodSugarColor = Color(0xFF4CAF50); // 正常 - 绿色
  static const Color preDiabetesColor = Color(0xFFFFC107);      // 糖尿病前期 - 黄色
  static const Color highBloodSugarColor = Color(0xFFF44336);   // 高血糖 - 红色
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2196F3),
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF2196F3),
      ),
    );
  }
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2196F3),
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
  
  /// 获取血糖值对应的颜色
  static Color getBloodSugarColor(double value) {
    if (value < 70) return lowBloodSugarColor;
    if (value < 100) return normalBloodSugarColor;
    if (value < 126) return preDiabetesColor;
    return highBloodSugarColor;
  }
  
  /// 获取血糖状态文本
  static String getBloodSugarStatus(double value) {
    if (value < 70) return '低血糖';
    if (value < 100) return '正常';
    if (value < 126) return '糖尿病前期';
    return '高血糖';
  }
}
