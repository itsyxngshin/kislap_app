import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/social_button.dart';
import 'sign_up_screen.dart';
import '../dashboard/dashboard_shell.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppColors.globalGradient,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.show_chart_rounded, size: 50, color: AppColors.appYellow),
                const SizedBox(height: 20),
                
                const Text('Welcome back', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                const Text('Sign in to keep tracking your usage.', style: TextStyle(color: AppColors.textHintColor, fontSize: 14)),
                const SizedBox(height: 40),

                const Text('Email', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                const CustomTextField(hint: 'name@email.com', icon: Icons.email_outlined),
                const SizedBox(height: 20),

                const Text('Password', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                const CustomTextField(hint: '••••••••', icon: Icons.lock_outline, isPassword: true),
                
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text('Forgot Password?', style: TextStyle(color: AppColors.appYellow, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardShell()));
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.appYellow,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Sign in', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 30),
                
                const Center(child: Text('or continue with', style: TextStyle(color: AppColors.textHintColor, fontSize: 12))),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(child: SocialButton(icon: Icons.g_mobiledata, label: 'Google', onPressed: () {})),
                    const SizedBox(width: 15),
                    Expanded(child: SocialButton(icon: Icons.apple, label: 'Apple', onPressed: () {})),
                  ],
                ),
                const SizedBox(height: 30),

                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpScreen())),
                    child: const Text.rich(
                      TextSpan(
                        text: 'New here? ',
                        style: TextStyle(color: AppColors.textHintColor, fontSize: 13),
                        children: [
                          TextSpan(text: 'Create an Account', style: TextStyle(color: AppColors.appYellow, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}