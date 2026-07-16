import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
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

  Future<void> _checkSystemStatus() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    
    if (user == null) return;

    // 1. Check Global Maintenance Mode
    final settings = await supabase.from('app_settings').select().eq('id', 1).single();
    if (settings['is_maintenance_mode'] == true) {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context, 
          MaterialPageRoute(builder: (_) => LockdownScreen(message: settings['lock_message'])), 
          (route) => false
        );
      }
      return;
    }

    // 2. Check Individual Client Account Status (Payment/Suspension)
    final profile = await supabase.from('profiles').select('is_active').eq('id', user.id).single();
    if (profile['is_active'] == false) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppColors.globalGradient,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // CRUCIAL: This allows the scrollable body to pass behind the floating nav bar
        extendBody: true, 
        body: _screens[_currentIndex],
        
        // The Custom Glassmorphic Navigation Bar
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 30),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // The frost effect
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: AppColors.navBackground.withValues(alpha: 0.6), // Semi-transparent
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(Icons.home_outlined, Icons.home, 'Home', 0),
                    _buildNavItem(Icons.electrical_services_outlined, Icons.electrical_services, 'Devices', 1),
                    _buildNavItem(Icons.show_chart, Icons.show_chart_rounded, 'Analysis', 2),
                    _buildNavItem(Icons.receipt_long_outlined, Icons.receipt_long, 'Reports', 3),
                    _buildNavItem(Icons.settings_outlined, Icons.settings, 'Settings', 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build each individual tap target
  Widget _buildNavItem(IconData icon, IconData activeIcon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? AppColors.appYellow : AppColors.textHintColor,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.appYellow : AppColors.textHintColor,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}