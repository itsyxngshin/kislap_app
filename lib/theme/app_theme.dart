import 'package:flutter/material.dart';
import 'app_colors.dart';  

class AppTheme {
  // Adaptive Light Mode
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Cool off-white
      colorScheme: const ColorScheme.light(
        surface: Colors.white,
        onSurface: Color(0xFF0F172A), // Deep slate for highly readable text
        primary: AppColors.appYellow,
      ),
      fontFamily: 'Inter',
    );
  }

  // Adaptive Dark Mode
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0B0F19), // Deepest space black
      colorScheme: const ColorScheme.dark(
        surface: Color(0xFF1E293B),
        onSurface: Colors.white,
        primary: AppColors.appYellow,
      ),
      fontFamily: 'Inter',
    );
  }

  // Solid Unified Background (Gradient Removed)
  static BoxDecoration globalBackground(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).scaffoldBackgroundColor, // Reverts to a pure, solid color
    );
  }
}
