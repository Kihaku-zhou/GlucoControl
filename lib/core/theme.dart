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
  
  // 主色调
  static const Color primaryColor = Color(0xFF1976D2);
  static const Color primaryColorDark = Color(0xFF64B5F6);
  
  /// mg/dL 转 mmol/L
  static double mgdlToMmoll(double mgdl) {
    return mgdl / 18.0182;
  }
  
  /// mmol/L 转 mg/dL
  static double mmollToMgdl(double mmol) {
    return mmol * 18.0182;
  }
  
  /// 根据当前单位获取血糖值对应的颜色
  static Color getBloodSugarColor(double value, [String unit = 'mg/dL']) {
    if (unit == 'mmol/L') {
      value = mmollToMgdl(value);
    }
    if (value < 70) return lowBloodSugarColor;
    if (value < 100) return normalBloodSugarColor;
    if (value < 126) return preDiabetesColor;
    return highBloodSugarColor;
  }
  
  /// 获取血糖状态文本
  static String getBloodSugarStatus(double value, [String unit = 'mg/dL']) {
    if (unit == 'mmol/L') {
      value = mmollToMgdl(value);
    }
    if (value < 70) return '低血糖';
    if (value < 100) return '正常';
    if (value < 126) return '糖尿病前期';
    return '高血糖';
  }
  
  static ThemeData get lightTheme {
    final brightness = Brightness.light;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: const Color(0xFF03A9F4),
        surface: Colors.white,
        error: const Color(0xFFB00020),
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: primaryColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
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
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      iconTheme: IconThemeData(
        color: brightness == Brightness.dark ? Colors.white : primaryColor,
      ),
      dividerColor: Colors.grey.shade300,
    );
  }
  
  static ThemeData get darkTheme {
    final brightness = Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColorDark,
        brightness: Brightness.dark,
        primary: primaryColorDark,
        secondary: const Color(0xFF4FC3F7),
        surface: const Color(0xFF1E1E1E),
        error: const Color(0xFFCF6679),
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardTheme(
        elevation: 4,
        color: brightness == Brightness.dark ? const Color(0xFF2D2D2D) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: brightness == Brightness.dark ? Colors.white : primaryColor,
        textColor: brightness == Brightness.dark ? Colors.white : null,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: brightness == Brightness.dark ? const Color(0xFF2D2D2D) : Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: brightness == Brightness.dark ? Colors.white : primaryColorDark,
          foregroundColor: brightness == Brightness.dark ? Colors.black : Colors.white,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: brightness == Brightness.dark ? Colors.white : primaryColorDark,
        unselectedItemColor: brightness == Brightness.dark ? Colors.grey : Colors.grey,
        backgroundColor: brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: brightness == Brightness.dark ? Colors.white : primaryColorDark,
        foregroundColor: brightness == Brightness.dark ? Colors.black : Colors.white,
      ),
      iconTheme: IconThemeData(
        color: brightness == Brightness.dark ? Colors.white : Colors.white,
      ),
      dividerTheme: DividerThemeData(
        color: brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade300,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
        bodySmall: TextStyle(color: Colors.white70),
        titleLarge: TextStyle(color: Colors.white),
        titleMedium: TextStyle(color: Colors.white),
        titleSmall: TextStyle(color: Colors.white),
        labelLarge: TextStyle(color: Colors.white),
      ),
    );
  }
}
