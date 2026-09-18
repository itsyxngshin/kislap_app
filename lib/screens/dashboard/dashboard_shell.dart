import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../../providers/settings_provider.dart';
import '../../providers/navigation_provider.dart';
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
    // Run all startup modal checks in sequence
    _runStartupSequence();
  }

  Future<void> _runStartupSequence() async {
    await _checkSystemStatus();
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      // 1. Show Tutorial first if needed
      bool tutorialShown = await _showTutorialPrompt();

      // 2. If tutorial wasn't needed, check if we need to prompt for the missing rate
      if (!tutorialShown && mounted) {
        await _checkMissingBillingRate();
      }
    }
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

  Future<bool> _showTutorialPrompt() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final settings = await db.query('user_settings', limit: 1);
      if (settings.isNotEmpty) {
        final isFirstTime = (settings.first['is_first_time'] as int?) ?? 1;
        if (isFirstTime != 1) return false;
      } else {
        return false;
      }
    } catch (_) {
      return false;
    }

    if (!mounted) return false;

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
    return true; // Indicates the tutorial dialog was triggered
  }

  // --- NEW: MISSING BILLING RATE PROMPT LOGIC ---
  Future<void> _checkMissingBillingRate() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final settings = await db.query('user_settings', limit: 1);
      if (settings.isEmpty) return;

      // Determine the exact previous month relative to today
      final now = DateTime.now();
      int prevMonth = now.month == 1 ? 12 : now.month - 1;
      int prevYear = now.month == 1 ? now.year - 1 : now.year;
      String paddedMonth = prevMonth.toString().padLeft(2, '0');
      String targetPeriod = '$prevYear-$paddedMonth-01';

      // Check if this specific period exists in the history table
      final pastBills = await db.query(
        'recording_periods',
        where: 'period_month = ?',
        whereArgs: [targetPeriod],
        limit: 1,
      );

      // If it doesn't exist, show the missing rate prompt
      if (pastBills.isEmpty && mounted) {
        _showRatePrompt(prevMonth, prevYear, paddedMonth, targetPeriod);
      }
    } catch (e) {
      debugPrint('Rate check error: $e');
    }
  }

  void _showRatePrompt(int prevMonth, int prevYear, String paddedMonth, String targetPeriod) {
    final isPh = ref.read(settingsProvider).language == 'ph';
    final textColor = Theme.of(context).colorScheme.onSurface;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final hintColor = textColor.withOpacity(0.6);

    final List<String> monthsEn = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final List<String> monthsPh = ['Enero', 'Pebrero', 'Marso', 'Abril', 'Mayo', 'Hunyo', 'Hulyo', 'Agosto', 'Setyembre', 'Oktubre', 'Nobyembre', 'Disyembre'];

    final String monthName = isPh ? monthsPh[prevMonth - 1] : monthsEn[prevMonth - 1];
    final TextEditingController rateController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.bolt, color: AppColors.appYellow),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isPh ? 'Nawawalang Rate' : 'Missing Rate',
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPh
                  ? 'Wala pa tayong naitalang halaga ng kuryente (₱/kWh) para noong $monthName $prevYear. Ilagay ito upang maging mas tumpak ang iyong budget.'
                  : 'We haven\'t recorded your electricity rate (₱/kWh) for $monthName $prevYear yet. Please enter it to keep your estimates accurate.',
                style: TextStyle(color: textColor.withOpacity(0.8), height: 1.4, fontSize: 14),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: rateController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixText: '₱ ',
                  prefixStyle: TextStyle(color: textColor, fontSize: 18),
                  suffixText: '/ kWh',
                  suffixStyle: TextStyle(color: hintColor, fontSize: 14),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Let them skip it if they want
              child: Text(isPh ? 'Mamaya' : 'Later', style: const TextStyle(color: AppColors.textHintColor)),
            ),
            FilledButton(
              onPressed: () async {
                final rate = double.tryParse(rateController.text);
                if (rate != null && rate > 0) {
                  final db = await DatabaseHelper.instance.database;

                  int lastDay = DateTime(prevYear, prevMonth + 1, 0).day;

                  // 1. Insert into history
                  await db.insert('recording_periods', {
                    'period_month': targetPeriod,
                    'period_name': '$monthName $prevYear',
                    'start_date': targetPeriod,
                    'end_date': '$prevYear-$paddedMonth-$lastDay',
                    'billing_rate': rate,
                  });

                  // 2. Update current active tariff rate
                  await db.update('user_settings', {'tariff_rate': rate}, where: 'id = 1');

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isPh ? 'Na-save na ang rate!' : 'Rate saved successfully!'), backgroundColor: Colors.green)
                    );

                    // 3. Hard reload the shell to instantly update the rate across all tabs
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardShell()));
                  }
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.appYellow,
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isPh ? 'I-save' : 'Save Rate', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the global tab index state
    final currentIndex = ref.watch(dashboardTabProvider);

    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = textColor.withOpacity(0.6);
    final isPh = ref.watch(settingsProvider).language == 'ph';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      body: IndexedStack(
        index: currentIndex, // Controlled by Riverpod
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
                  _buildNavItem(Icons.home_outlined, Icons.home, isPh ? 'Buod' : 'Home', 0, currentIndex, textColor, hintColor),
                  _buildNavItem(Icons.electrical_services_outlined, Icons.electrical_services, isPh ? 'Mga Gamit' : 'Devices', 1, currentIndex, textColor, hintColor),
                  _buildNavItem(Icons.show_chart, Icons.show_chart_rounded, isPh ? 'Pagsusuri' : 'Analysis', 2, currentIndex, textColor, hintColor),
                  _buildNavItem(Icons.receipt_long_outlined, Icons.receipt_long, isPh ? 'Mga Ulat' : 'Reports', 3, currentIndex, textColor, hintColor),
                  _buildNavItem(Icons.settings_outlined, Icons.settings, isPh ? 'Setting' : 'Settings', 4, currentIndex, textColor, hintColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, IconData activeIcon, String label, int index, int currentIndex, Color textColor, Color hintColor) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () {
        ref.read(dashboardTabProvider.notifier).state = index;
      },
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
