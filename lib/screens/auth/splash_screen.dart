import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import 'onboarding_screen.dart';
import '../dashboard/dashboard_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Smooth fade-in animation for the logo
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);

    _animationController.forward();
    _routeUser();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _routeUser() async {
    // Wait for at least 2.5 seconds to show off the branding, plus network check time
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardShell()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: AppTheme.globalBackground(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: Image.asset(
                'assets/images/logo_stacked.png',
                width: 200, // Adjust based on your visual preference
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                color: AppColors.appYellow,
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
