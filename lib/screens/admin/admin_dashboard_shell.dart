import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../auth/sign_in_screen.dart';
import '../dashboard/dashboard_shell.dart';
import 'admin_analytics_screen.dart';
import 'admin_lockdown_screen.dart';

class AdminDashboardShell extends StatefulWidget {
  const AdminDashboardShell({super.key});

  @override
  State<AdminDashboardShell> createState() => _AdminDashboardShellState();
}

class _AdminDashboardShellState extends State<AdminDashboardShell> {
  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SignInScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return DefaultTabController(
      length: 2, // Condensed from 3 to 2 tabs
      child: Container(
        decoration: AppTheme.globalBackground(context),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: surfaceColor.withOpacity(0.95),
            elevation: 0,
            title: Row(
              children: [
                const Icon(Icons.admin_panel_settings, color: AppColors.adminRed),
                const SizedBox(width: 10),
                Text('Admin Control', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.exit_to_app),
                color: textColor.withOpacity(0.7),
                tooltip: 'Switch to User App',
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const DashboardShell()),
                    (route) => false,
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                color: textColor.withOpacity(0.7),
                onPressed: _signOut,
              ),
            ],
            bottom: TabBar(
              indicatorColor: AppColors.adminRed,
              labelColor: AppColors.adminRed,
              unselectedLabelColor: textColor.withOpacity(0.5),
              tabs: const [
                Tab(
                  icon: Icon(Icons.analytics_outlined),
                  text: 'Analytics',
                ),
                Tab(
                  icon: Icon(Icons.lock_person_outlined),
                  text: 'Lockdown',
                ),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              AdminAnalyticsScreen(),
              AdminLockdownScreen(),
            ],
          ),
        ),
      ),
    );
  }
}