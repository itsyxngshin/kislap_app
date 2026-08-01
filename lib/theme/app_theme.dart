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
                const Color(0xFF1E293B), // Soft slate glow
                const Color(0xFF0B0F19), // Deep background
                AppColors.appYellow.withValues(alpha: 0.05), // Subtle tricolor hints
                Colors.orange.withValues(alpha: 0.03),
                Colors.redAccent.withValues(alpha: 0.02),
              ]
            : [
                Colors.white, // Bright origin
                const Color(0xFFF1F5F9), // Soft transition
                AppColors.appYellow.withValues(alpha: 0.08), // Warm, vibrant ambient light
                Colors.greenAccent.withValues(alpha: 0.03),
                Colors.orange.withValues(alpha: 0.04),
              ],
        stops: const [0.0, 0.4, 0.7, 0.85, 1.0],
      ),
    );
  }
}
