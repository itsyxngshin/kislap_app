import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_text_field.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppColors.globalGradient,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Create Your Account', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              const Text('Start tracking usage in under a minute.', style: TextStyle(color: AppColors.textHintColor, fontSize: 14)),
              const SizedBox(height: 30),

              const Text('Full Name', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              const CustomTextField(hint: 'Maria Francia', icon: Icons.person_outline),
              const SizedBox(height: 20),

              const Text('Email', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              const CustomTextField(hint: 'name@email.com', icon: Icons.email_outlined),
              const SizedBox(height: 20),

              const Text('Password', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              const CustomTextField(hint: 'create a password', icon: Icons.lock_outline, isPassword: true),
              const SizedBox(height: 10),

              // Password Strength Indicator
              Row(
                children: [
                  Expanded(child: Container(height: 4, decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(width: 5),
                  Expanded(child: Container(height: 4, decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(width: 5),
                  Expanded(child: Container(height: 4, decoration: BoxDecoration(color: AppColors.textHintColor.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Checkbox(
                    value: true,
                    onChanged: (val) {},
                    activeColor: AppColors.appYellow,
                    checkColor: Colors.black,
                  ),
                  const Expanded(
                    child: Text('I agree to the Terms of Service and Privacy Policy', style: TextStyle(color: AppColors.textHintColor, fontSize: 11)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.appYellow,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Create account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),

              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text.rich(
                    TextSpan(
                      text: 'Already Registered? ',
                      style: TextStyle(color: AppColors.textHintColor, fontSize: 13),
                      children: [
                        TextSpan(text: 'Sign In', style: TextStyle(color: AppColors.appYellow, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}