import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  // Adaptive Light Mode
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      colorScheme: const ColorScheme.light(
        surface: Colors.white,
        onSurface: Color(0xFF0F172A),
        primary: AppColors.appYellow,
      ),
      fontFamily: 'Inter',
    );
  }

  // Adaptive Dark Mode
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0B0F19),
      colorScheme: const ColorScheme.dark(
        surface: Color(0xFF1E293B),
        onSurface: Colors.white,
        primary: AppColors.appYellow,
      ),
      fontFamily: 'Inter',
    );
  }

  // Vibrant Ambient Background Graphic
  static BoxDecoration globalBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BoxDecoration(
      color: Theme.of(context).scaffoldBackgroundColor,
      gradient: RadialGradient(
        center: const Alignment(-0.8, -0.6),
        radius: 2.0,
        colors: isDark
            ? [
                const Color(0xFF1E293B),
                const Color(0xFF0B0F19),
                AppColors.appYellow.withOpacity(0.05),
                Colors.orange.withOpacity(0.03),
                Colors.redAccent.withOpacity(0.02),
              ]
            : [
                Colors.white,
                const Color(0xFFF1F5F9),
                AppColors.appYellow.withOpacity(0.08),
                Colors.greenAccent.withOpacity(0.03),
                Colors.orange.withOpacity(0.04),
              ],
        stops: const [0.0, 0.4, 0.7, 0.85, 1.0],
      ),
    );
  }
}
