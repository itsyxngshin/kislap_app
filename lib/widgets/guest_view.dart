import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/auth/sign_in_screen.dart';

class GuestView extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const GuestView({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.inputBackground, shape: BoxShape.circle),
              child: Icon(icon, size: 60, color: AppColors.appYellow),
            ),
            const SizedBox(height: 24),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(subtitle, style: const TextStyle(color: AppColors.textHintColor, fontSize: 14, height: 1.5), textAlign: TextAlign.center),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpScreen())),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.appYellow,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Create an Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignInScreen())),
              child: const Text('Already have one? Log in', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }
}