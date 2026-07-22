import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';
import 'guest_setup_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = textColor.withValues(alpha: 0.6);

    return Scaffold(
      body: Container(
        decoration: AppTheme.globalBackground(context),
        child: SafeArea(
          // LayoutBuilder + SingleChildScrollView + IntrinsicHeight is the ultimate fix for bottom overflow
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(flex: 2),

                          // Tech-Inspired Hero Graphic
                          _buildHeroGraphic(context),
                          const SizedBox(height: 40),

                          // Typography / Branding
                          Text(
                            'Kislap',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Optimize your power.\nMaximize your budget.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: hintColor,
                              fontSize: 16,
                              height: 1.5,
                              letterSpacing: 0.5,
                            ),
                          ),

                          const Spacer(flex: 3),

                          // Primary Action: Sign Up
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpScreen()));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.appYellow,
                                foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 8,
                                shadowColor: AppColors.appYellow.withValues(alpha: 0.4),
                              ),
                              child: const Text('Create an Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Secondary Action: Log In
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const SignInScreen()));
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: hintColor.withValues(alpha: 0.3), width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                foregroundColor: textColor,
                              ),
                              child: const Text('Log In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Tertiary Action: Guest Mode (Safely positioned at the bottom)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(height: 1, width: 40, color: hintColor.withValues(alpha: 0.2)),
                              const SizedBox(width: 15),
                              Text('OR', style: TextStyle(color: hintColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                              const SizedBox(width: 15),
                              Container(height: 1, width: 40, color: hintColor.withValues(alpha: 0.2)),
                            ],
                          ),
                          const SizedBox(height: 15),

                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const GuestSetupScreen()));
                            },
                            icon: Icon(Icons.rocket_launch_outlined, color: Colors.greenAccent.withValues(alpha: 0.8), size: 20),
                            label: Text(
                              'Continue as Guest',
                              style: TextStyle(color: Colors.greenAccent.withValues(alpha: 0.8), fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),

                          const Spacer(flex: 1),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // A sleek, tech-forward orb graphic to serve as the onboarding focal point
  Widget _buildHeroGraphic(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glowing orbital ring
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.appYellow.withValues(alpha: 0.1), width: 2),
          ),
        ),
        // Inner dashed tech ring
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.appYellow.withValues(alpha: 0.3), width: 1),
          ),
        ),
        // Solid vibrant core
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.appYellow,
            boxShadow: [
              BoxShadow(
                color: AppColors.appYellow.withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: 5,
              )
            ],
          ),
          child: const Icon(Icons.bolt, color: Colors.black87, size: 35),
        ),
      ],
    );
  }
}
