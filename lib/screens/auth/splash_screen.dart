import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../services/database_helper.dart';
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
    // Show branding splash animation
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    // 1. Check if user is logged in via Supabase Cloud
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardShell()),
      );
      return;
    }

    // 2. THE FIX: Check if Guest Setup has already been completed in SQLite
    try {
      final db = await DatabaseHelper.instance.database;
      final settings = await db.query('user_settings', limit: 1);

      if (settings.isNotEmpty) {
        final budget = (settings.first['monthly_budget'] as num?)?.toDouble() ?? 0.0;

        // If a budget has already been set, auto-login into Guest Dashboard!
        if (budget > 0) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DashboardShell()),
            );
            return;
          }
        }
      }
    } catch (_) {}

    // 3. If no account AND no guest settings exist, show Onboarding
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
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
                width: 200,
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
