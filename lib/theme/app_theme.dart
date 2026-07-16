import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  // A dynamic method to get the correct gradient based on the current theme
  static BoxDecoration globalBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [const Color(0xFF0F172A), const Color(0xFF1E293B)] // Deep slate dark mode
            : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)], // Soft airy light mode
      ),
    );
  }

  // --- DARK THEME (Your existing Kislap aesthetic) ---
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.appYellow,
      scaffoldBackgroundColor: Colors.transparent, // Transparent to show the gradient
      colorScheme: const ColorScheme.dark(
        primary: AppColors.appYellow,
        surface: Color(0xFF1E293B), // Card background
        onSurface: Colors.white, // Standard text
        outline: Colors.white24, // Borders
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.appYellow,
          foregroundColor: Colors.black87,
        ),
      ),
    );
  }

  // --- LIGHT THEME ---
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.appYellow,
      scaffoldBackgroundColor: Colors.transparent, // Transparent to show the gradient
      colorScheme: const ColorScheme.light(
        primary: AppColors.appYellow,
        surface: Colors.white, // Card background
        onSurface: Color(0xFF0F172A), // Standard text (dark blue/black)
        outline: Colors.black12, // Borders
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.appYellow,
          foregroundColor: Colors.black87,
        ),
      ),
    );
  }
}