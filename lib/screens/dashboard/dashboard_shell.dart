import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../auth/lockdown_screen.dart';

// This is the main shell of the dashboard, containing the navigation bar and the body that switches between different screens.
import 'home_screen.dart'; // We will create this next
import 'devices_screen.dart';
import 'analysis_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _currentIndex = 0;

  // The screens driven by the navigation bar
  final List<Widget> _screens = [
    const HomeScreen(),
    const DevicesScreen(),
    const AnalysisScreen(),
    const ReportsScreen(),
    const SettingsScreen(),
  ];

  // 1. ADDED THIS: The check must run as soon as the shell is initialized
  @override
  void initState() {
    super.initState();
    _checkSystemStatus();
  }

  Future<void> _checkSystemStatus() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) return;

      // 1. Safely Check Global Maintenance Mode
      final settings = await supabase.from('app_settings').select().eq('id', 1).maybeSingle();

      if (settings != null && settings['is_maintenance_mode'] == true) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => LockdownScreen(
              message: settings['lock_message']?.toString() ?? 'System maintenance in progress.'
            )),
            (route) => false
          );
        }
        return; // Stop here if under maintenance
      }

      // 2. Safely Check Individual Client Account Status
      final profile = await supabase.from('profiles').select('is_active').eq('id', user.id).maybeSingle();

      if (profile != null && profile['is_active'] == false) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LockdownScreen(
              message: 'Your account has been suspended. Please contact administration to settle your account.',
              isMaintenance: false,
            )),
            (route) => false
          );
        }
      }
    } catch (e) {
      // If the query fails (e.g., poor internet), we silently catch it
      // so the app doesn't crash, allowing the user to continue normally.
      debugPrint('Error checking system status: $e');
    }
  }

  @override
    Widget build(BuildContext context) {
      final textColor = Theme.of(context).colorScheme.onSurface;
      final hintColor = textColor.withOpacity(0.6);

      return Container(
        // Dynamic Theme Background applied here!
        decoration: AppTheme.globalBackground(context),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          body: _screens[_currentIndex],

          bottomNavigationBar: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 30),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: textColor.withOpacity(0.1), width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(Icons.home_outlined, Icons.home, 'Home', 0, textColor, hintColor),
                      _buildNavItem(Icons.electrical_services_outlined, Icons.electrical_services, 'Devices', 1, textColor, hintColor),
                      _buildNavItem(Icons.show_chart, Icons.show_chart_rounded, 'Analysis', 2, textColor, hintColor),
                      _buildNavItem(Icons.receipt_long_outlined, Icons.receipt_long, 'Reports', 3, textColor, hintColor),
                      _buildNavItem(Icons.settings_outlined, Icons.settings, 'Settings', 4, textColor, hintColor),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Updated to accept dynamic theme colors
    Widget _buildNavItem(IconData icon, IconData activeIcon, String label, int index, Color textColor, Color hintColor) {
      final isSelected = _currentIndex == index;
      return GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.appYellow : hintColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.appYellow : hintColor,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      );
    }
}