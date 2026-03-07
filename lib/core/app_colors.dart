import 'package:flutter/material.dart';

/// 主题感知的颜色辅助类
class AppColors {
  // 主色调
  static Color primary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF64B5F6) 
        : const Color(0xFF1976D2);
  }
  
  // 背景色
  static Color background(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF121212) 
        : const Color(0xFFF5F5F5);
  }
  
  // 卡片背景色
  static Color cardBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF2D2D2D) 
        : Colors.white;
  }
  
  // 文字主色
  static Color textPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? Colors.white 
        : Colors.black87;
  }
  
  // 文字次色
  static Color textSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? Colors.white70 
        : Colors.grey;
  }
  
  // 图标颜色
  static Color icon(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF64B5F6) 
        : const Color(0xFF1976D2);
  }
  
  // 分隔线颜色
  static Color divider(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? Colors.grey.shade700 
        : Colors.grey.shade300;
  }
  
  // 成功颜色
  static Color success(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF81C784) 
        : Colors.green;
  }
  
  // 警告颜色
  static Color warning(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFFFFB74D) 
        : Colors.orange;
  }
  
  // 错误颜色
  static Color error(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFFE57373) 
        : Colors.red;
  }
  
  // 蓝色
  static Color blue(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF64B5F6) 
        : Colors.blue;
  }
  
  // 绿色
  static Color green(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF81C784) 
        : Colors.green;
  }
  
  // 橙色
  static Color orange(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFFFFB74D) 
        : Colors.orange;
  }
  
  // 红色
  static Color red(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFFE57373) 
        : Colors.red;
  }
  
  // 紫色
  static Color purple(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFFBA68C8) 
        : Colors.purple;
  }
  
  // 进度条背景色
  static Color progressBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? Colors.grey.shade700 
        : Colors.grey.shade200;
  }
}
