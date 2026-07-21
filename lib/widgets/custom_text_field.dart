import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextEditingController? controller; // <-- Added this
  final TextInputType? keyboardType;

  const CustomTextField({
    super.key,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.controller, // <-- Added this
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller, // <-- Added this
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textHintColor, fontSize: 14),
        filled: true,
        fillColor: AppColors.inputBackground,
        prefixIcon: Icon(icon, color: AppColors.textHintColor, size: 20),
        suffixIcon: isPassword ? const Icon(Icons.visibility_off, color: AppColors.textHintColor, size: 20) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.appYellow, width: 1.5),
        ),
      ),
    );
  }
}
