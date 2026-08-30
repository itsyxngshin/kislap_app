import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      colorScheme: const ColorScheme.light(
        surface: Colors.white,
        onSurface: Color(0xFF0F172A), // High contrast slate for readability
        primary: AppColors.appYellow,
        secondary: Color(0xFFD32F2F),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF0F172A)), // Standardized back buttons
      ),
      fontFamily: 'Inter',
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0B0F19),
      colorScheme: const ColorScheme.dark(
        surface: Color(0xFF1E293B),
        onSurface: Colors.white,
        primary: AppColors.appYellow,
        secondary: Color(0xFFD32F2F),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      fontFamily: 'Inter',
    );
  }

  // FIX: This missing method is restored so Auth/Onboarding screens don't crash
  // It now returns your clean, standardized solid background color.
  static BoxDecoration globalBackground(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).scaffoldBackgroundColor,
    );
  }
}
