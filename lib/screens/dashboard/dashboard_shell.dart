import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
import '../../theme/app_colors.dart';
import '../../providers/settings_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/inventory_provider.dart';
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

  bool _isOffline = false;
  Timer? _networkTimer;

  @override
  void initState() {
    super.initState();
    _runStartupSequence();
    _startNetworkPolling();
  }

  @override
  void dispose() {
    _networkTimer?.cancel();
    super.dispose();
  }

  void _startNetworkPolling() {
    _checkNetwork();
    _networkTimer = Timer.periodic(const Duration(seconds: 15), (_) => _checkNetwork());
  }

  Future<void> _checkNetwork() async {
    try {
      await Supabase.instance.client.from('app_settings').select('id').limit(1);
      if (_isOffline && mounted) setState(() => _isOffline = false);
    } catch (_) {
      if (!_isOffline && mounted) setState(() => _isOffline = true);
    }
  }

  Future<void> _runStartupSequence() async {
    await _checkSystemStatus();
    await _ensureCloudProfile();
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      bool tutorialShown = await _showTutorialPrompt();
      if (!tutorialShown && mounted) {
        await _checkMissingBillingRate();
      }
    }
  }

  Future<void> _ensureCloudProfile() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) return;

      final profile = await supabase.from('profiles').select('id').eq('id', user.id).maybeSingle();

      if (profile == null) {
        final db = await DatabaseHelper.instance.database;
        final settings = await db.query('user_settings', limit: 1);

        double budget = 0.0;
        double tariff = 12.35;
        String size = 'Small';

        if (settings.isNotEmpty) {
          budget = (settings.first['monthly_budget'] as num).toDouble();
          tariff = (settings.first['tariff_rate'] as num).toDouble();
          size = settings.first['household_size'] as String? ?? 'Small';
        }

        await supabase.from('profiles').insert({
          'id': user.id,
          'full_name': user.userMetadata?['full_name'] ?? 'User',
          'monthly_budget': budget,
          'tariff_rate': tariff,
          'household_size': size,
          'role': 'user',
          'is_active': true,
        });
      }
    } catch (e) {
      if (!_isOffline && mounted) setState(() => _isOffline = true);
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
    return true;
  }

  Future<void> _checkMissingBillingRate() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final settings = await db.query('user_settings', limit: 1);
      if (settings.isEmpty) return;

      final now = DateTime.now();
      int prevMonth = now.month == 1 ? 12 : now.month - 1;
      int prevYear = now.month == 1 ? now.year - 1 : now.year;
      String paddedMonth = prevMonth.toString().padLeft(2, '0');
      String targetPeriod = '$prevYear-$paddedMonth-01';

      final pastBills = await db.query(
        'recording_periods',
        where: 'period_month = ?',
        whereArgs: [targetPeriod],
        limit: 1,
      );

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
              onPressed: () => Navigator.pop(context),
              child: Text(isPh ? 'Mamaya' : 'Later', style: const TextStyle(color: AppColors.textHintColor)),
            ),
            FilledButton(
              onPressed: () async {
                final rate = double.tryParse(rateController.text);
                if (rate != null && rate > 0) {
                  try {
                    final db = await DatabaseHelper.instance.database;
                    int lastDay = DateTime(prevYear, prevMonth + 1, 0).day;
                    final String endDate = '$prevYear-$paddedMonth-$lastDay';
                    final String periodName = '$monthName $prevYear';

                    await db.insert('recording_periods', {
                      'period_month': targetPeriod,
                      'period_name': periodName,
                      'start_date': targetPeriod,
                      'end_date': endDate,
                      'billing_rate': rate,
                    }, conflictAlgorithm: ConflictAlgorithm.replace);

                    await db.update('user_settings', {'tariff_rate': rate}, where: 'id = 1');

                    final user = Supabase.instance.client.auth.currentUser;
                    if (user != null) {
                      await Supabase.instance.client.from('profiles').update({
                        'tariff_rate': rate,
                      }).eq('id', user.id);

                      await Supabase.instance.client.from('recording_periods').upsert({
                        'user_id': user.id,
                        'period_month': targetPeriod,
                        'period_name': periodName,
                        'start_date': targetPeriod,
                        'end_date': endDate,
                        'billing_rate': rate,
                      }, onConflict: 'user_id, period_month');
                    }

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isPh ? 'Na-save na ang rate!' : 'Rate saved successfully!'), backgroundColor: Colors.green)
                      );
                      ref.invalidate(inventoryProvider);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Supabase Sync Error: $e\nEnsure RLS policies are enabled.'), backgroundColor: Colors.red, duration: const Duration(seconds: 4))
                      );
                    }
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
    final currentIndex = ref.watch(dashboardTabProvider);

    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = textColor.withOpacity(0.6);
    final isPh = ref.watch(settingsProvider).language == 'ph';

    // MATHEMATICAL TOP PADDING CALCULATION (Replaces SafeArea for the overlay)
    final safeTop = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      body: Stack(
        children: [
          // 1. The Main Application Views
          IndexedStack(
            index: currentIndex,
            children: _screens,
          ),

          // 2. FIXED: Floating Offline Banner explicitly inside the Stack
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            top: _isOffline ? safeTop + 10 : -80, // Safely drops below device notch
            left: 20,
            right: 20,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(20),
              color: AppColors.adminRed,
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.white, size: 16),
                    const SizedBox(width: 10),
                    Text(
                      isPh ? 'Offline Mode - Walang Internet' : 'Offline Mode - No Internet',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
