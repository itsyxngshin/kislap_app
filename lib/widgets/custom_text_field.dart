import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CustomTextField extends StatefulWidget {
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextEditingController? controller;
  final TextInputType? keyboardType;

  const CustomTextField({
    super.key,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.controller,
    this.keyboardType,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  // This state variable tracks if the text is hidden or visible
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    // Only obscure the text initially if the widget is flagged as a password field
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscureText, // Only ONE declaration here
      keyboardType: widget.keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: const TextStyle(color: AppColors.textHintColor, fontSize: 14),
        filled: true,
        fillColor: AppColors.inputBackground,
        prefixIcon: Icon(widget.icon, color: AppColors.textHintColor, size: 20),

        // Properly implements an IconButton to toggle the state
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textHintColor,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : null,

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
