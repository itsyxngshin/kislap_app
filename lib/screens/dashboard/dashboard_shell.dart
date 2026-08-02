import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../../providers/settings_provider.dart';
import '../../services/database_helper.dart';
import '../auth/lockdown_screen.dart';
import '../auth/tutorial_screen.dart';

import 'home_screen.dart';
import 'devices_screen.dart';
import 'analysis_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class DashboardShell extends ConsumerStatefulWidget {
  const DashboardShell({super.key});

  @override
  ConsumerState<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends ConsumerState<DashboardShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const DevicesScreen(),
    const AnalysisScreen(),
    const ReportsScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkSystemStatus();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _showTutorialPrompt();
    });
  }

  Future<void> _checkSystemStatus() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) return;

      final settings = await supabase.from('app_settings').select().eq('id', 1).maybeSingle();

      if (settings != null && settings['is_maintenance_mode'] == true) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => LockdownScreen(
                message: settings['lock_message']?.toString() ?? 'System maintenance in progress.',
              ),
            ),
            (route) => false,
          );
        }
        return;
      }

      final profile = await supabase.from('profiles').select('is_active').eq('id', user.id).maybeSingle();

      if (profile != null && profile['is_active'] == false) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const LockdownScreen(
                message: 'Your account has been suspended. Please contact administration to settle your account.',
                isMaintenance: false,
              ),
            ),
            (route) => false,
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking system status: $e');
    }
  }

  Future<void> _showTutorialPrompt() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final settings = await db.query('user_settings', limit: 1);
      if (settings.isNotEmpty) {
        final isFirstTime = (settings.first['is_first_time'] as int?) ?? 1;
        if (isFirstTime != 1) return;
      }
    } catch (_) {
      return;
    }

    if (!mounted) return;

    final isPh = ref.read(settingsProvider).language == 'ph';
    final textColor = Theme.of(context).colorScheme.onSurface;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.rocket_launch, color: AppColors.appYellow),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isPh ? 'Maligayang Pagdating!' : 'Welcome to Kislap!',
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Text(
            isPh
                ? 'Gusto mo bang kumuha ng mabilisang tutorial upang malaman kung paano gamitin ang app at makatipid sa kuryente?'
                : 'Would you like to take a quick tutorial to learn how to use the app and save on your electricity bill?',
            style: TextStyle(color: textColor.withOpacity(0.8), height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                ref.read(settingsProvider.notifier).completeTutorial();
                Navigator.pop(context);
              },
              child: Text(
                isPh ? 'Laktawan' : 'Skip',
                style: const TextStyle(color: AppColors.textHintColor),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TutorialScreen()));
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.appYellow,
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                isPh ? 'Magsimula' : 'Start Tutorial',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = textColor.withOpacity(0.6);
    final isPh = ref.watch(settingsProvider).language == 'ph';

    // REMOVED AppTheme.globalBackground Container. Returning standard Scaffold.
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
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
                  _buildNavItem(Icons.home_outlined, Icons.home, isPh ? 'Buod' : 'Home', 0, textColor, hintColor),
                  _buildNavItem(Icons.electrical_services_outlined, Icons.electrical_services, isPh ? 'Mga Gamit' : 'Devices', 1, textColor, hintColor),
                  _buildNavItem(Icons.show_chart, Icons.show_chart_rounded, isPh ? 'Pagsusuri' : 'Analysis', 2, textColor, hintColor),
                  _buildNavItem(Icons.receipt_long_outlined, Icons.receipt_long, isPh ? 'Mga Ulat' : 'Reports', 3, textColor, hintColor),
                  _buildNavItem(Icons.settings_outlined, Icons.settings, isPh ? 'Setting' : 'Settings', 4, textColor, hintColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

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
