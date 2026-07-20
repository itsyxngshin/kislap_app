import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import 'sign_up_screen.dart';
import '../dashboard/dashboard_shell.dart';
import 'sign_in_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = textColor.withValues(alpha: 0.6);

    return Container(
      // Dynamic Theme Background applied here
      decoration: AppTheme.globalBackground(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Branding Header
                Row(
                  children: [
                    const Icon(Icons.bolt, color: AppColors.appYellow, size: 32),
                    const SizedBox(width: 8),
                    Text(
                      'Kislap',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                
                const Spacer(),

                // Hero Graphic / Icon
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: AppColors.appYellow.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.electric_meter_outlined, 
                      size: 100, 
                      color: AppColors.appYellow,
                    ),
                  ),
                ),
                
                const Spacer(),

                // Value Proposition Text
                Text(
                  'Take control of\nyour electricity bill.',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  'Track your appliances, set a monthly target budget, and let automated reduction optimization balance your schedules.',
                  style: TextStyle(
                    color: hintColor,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignUpScreen()),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.appYellow,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Get Started', 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignInScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: hintColor.withValues(alpha: 0.3), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'I already have an account', 
                      style: TextStyle(fontSize: 16, color: textColor),
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const DashboardShell()),
                      );
                    },
                    child: Text(
                      'Continue as Guest',
                      style: TextStyle(color: hintColor, fontSize: 14),
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