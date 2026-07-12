import 'package:flutter/material.dart';

class AppColors {
  static const Color appYellow = Color(0xFFFFB703);
  static const Color inputBackground = Color(0xFF23395B);
  static const Color textHintColor = Color(0xFF8D99AE);
  static const Color navBackground = Color(0xFF0B132B);
  static const Color adminRed = Color(0xFFE63946);

  static const BoxDecoration globalGradient = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF1B2A47), 
        Color(0xFF0B132B),
      ],
    ),
  );
}