import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../providers/settings_provider.dart';
import '../dashboard/dashboard_shell.dart';

class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({super.key});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  int _currentStep = 0;

  late final List<Map<String, dynamic>> _tutorialSteps;

  @override
  void initState() {
    super.initState();
    _tutorialSteps = [
      {
        'tab': 0,
        'title_en': 'The Dashboard',
        'title_ph': 'Ang Buod (Dashboard)',
        'desc_en': 'Here you can see a bird\'s-eye view of your budget. The system automatically compares your optimized bill with your target limit.',
        'desc_ph': 'Dito mo makikita ang kabuuan ng iyong budget. Awtomatikong kinukumpara ng sistema ang na-optimize na bill sa iyong limitasyon.',
      },
      {
        'tab': 1,
        'title_en': 'Locking Appliances',
        'title_ph': 'Pag-lock ng mga Gamit',
        'desc_en': 'In the Devices tab, you can Lock (🔒) appliances you MUST use. Unlocked items (🔓) will be reduced to protect your budget.',
        'desc_ph': 'Sa Devices tab, i-lock (🔒) ang mga gamit na kailangan mo. Ang mga naka-unlock (🔓) ay babawasan para hindi ka lumampas sa budget.',
      },
      {
        'tab': 2,
        'title_en': 'Analysis & Projections',
        'title_ph': 'Pagsusuri at Proyeksyon',
        'desc_en': 'The Analysis tab explains exactly how Kislap does the math, showing daily, weekly, and monthly projections based on your regional tariff.',
        'desc_ph': 'Ipinapakita ng Analysis tab kung paano kinakalkula ng Kislap ang gastos araw-araw, lingguhan, at buwanan base sa presyo ng kuryente sa inyong lugar.',
      },
      {
        'tab': 3,
        'title_en': 'Settings & Billing',
        'title_ph': 'Mga Setting at Bill',
        'desc_en': 'Update your budget, change your tariff rate, log your past billing history, or switch the app language anytime in the Settings tab.',
        'desc_ph': 'I-update ang budget, palitan ang halaga ng kuryente, itala ang nakaraang bill, o baguhin ang wika ng app anumang oras sa Settings tab.',
      },
    ];
  }

  void _nextStep() async {
    if (_currentStep < _tutorialSteps.length - 1) {
      setState(() => _currentStep++);
    } else {
      await ref.read(settingsProvider.notifier).completeTutorial();
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardShell()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPh = ref.watch(settingsProvider).language == 'ph';
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = textColor.withValues(alpha: 0.6);

    final currentTab = _tutorialSteps[_currentStep]['tab'] as int;

    return Scaffold(
      body: Stack(
        children: [
          // 1. THE DUMMY APP LAYER
          IgnorePointer(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Container(
                decoration: AppTheme.globalBackground(context),
                child: SafeArea(
                  child: IndexedStack(
                    index: currentTab,
                    children: [
                      _buildDummyHome(surfaceColor, textColor, hintColor, isPh),
                      _buildDummyDevices(surfaceColor, textColor, hintColor, isPh),
                      _buildDummyAnalysis(surfaceColor, textColor, hintColor, isPh),
                      _buildDummySettings(surfaceColor, textColor, hintColor, isPh),
                    ],
                  ),
                ),
              ),
              bottomNavigationBar: Container(
                decoration: BoxDecoration(border: Border(top: BorderSide(color: textColor.withValues(alpha: 0.05), width: 1))),
                child: NavigationBar(
                  selectedIndex: currentTab,
                  backgroundColor: surfaceColor,
                  indicatorColor: AppColors.appYellow.withValues(alpha: 0.2),
                  destinations: [
                    NavigationDestination(icon: Icon(Icons.home_outlined, color: hintColor), selectedIcon: const Icon(Icons.home, color: AppColors.appYellow), label: isPh ? 'Buod' : 'Home'),
                    NavigationDestination(icon: Icon(Icons.electrical_services_outlined, color: hintColor), selectedIcon: const Icon(Icons.electrical_services, color: AppColors.appYellow), label: isPh ? 'Mga Gamit' : 'Devices'),
                    NavigationDestination(icon: Icon(Icons.analytics_outlined, color: hintColor), selectedIcon: const Icon(Icons.analytics, color: AppColors.appYellow), label: isPh ? 'Pagsusuri' : 'Analysis'),
                    NavigationDestination(icon: Icon(Icons.settings_outlined, color: hintColor), selectedIcon: const Icon(Icons.settings, color: AppColors.appYellow), label: isPh ? 'Setting' : 'Settings'),
                  ],
                ),
              ),
            ),
          ),

          // 2. THE TRANSLUCENT OVERLAY LAYER
          Container(
            color: Colors.black.withValues(alpha: 0.4),
            width: double.infinity,
            height: double.infinity,
          ),

          // 3. THE REPOSITIONED TOOLTIP DIALOG
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 100.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  key: ValueKey<int>(_currentStep),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.appYellow.withValues(alpha: 0.5), width: 2),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 5)
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getIconForStep(_currentStep),
                            size: 32,
                            color: AppColors.appYellow,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isPh ? _tutorialSteps[_currentStep]['title_ph'] : _tutorialSteps[_currentStep]['title_en'],
                              style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isPh ? _tutorialSteps[_currentStep]['desc_ph'] : _tutorialSteps[_currentStep]['desc_en'],
                        style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 14, height: 1.5),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: List.generate(
                              _tutorialSteps.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.only(right: 6),
                                height: 6,
                                width: _currentStep == index ? 20 : 6,
                                decoration: BoxDecoration(
                                  color: _currentStep == index ? AppColors.appYellow : Colors.grey.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                          FilledButton(
                            onPressed: _nextStep,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.appYellow,
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              _currentStep == _tutorialSteps.length - 1
                                ? (isPh ? 'Pumasok' : 'Enter App')
                                : (isPh ? 'Susunod' : 'Next'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForStep(int step) {
    switch (step) {
      case 0: return Icons.dashboard_outlined;
      case 1: return Icons.lock_outline;
      case 2: return Icons.insights_outlined;
      case 3: return Icons.settings_outlined;
      default: return Icons.rocket_launch_outlined;
    }
  }

  // =========================================================================
  // DUMMY SCREEN BUILDERS (Visual Replicas of the App)
  // =========================================================================

  Widget _buildDummyHome(Color surfaceColor, Color textColor, Color hintColor, bool isPh) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isPh ? 'Buod' : 'Dashboard', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: surfaceColor.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isPh ? 'NA-OPTIMIZE NA BUWANANG BILL' : 'OPTIMIZED MONTHLY BILL', style: TextStyle(color: hintColor, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('₱', style: TextStyle(color: AppColors.appYellow, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    Text('1,250.00', style: TextStyle(color: textColor, fontSize: 36, fontWeight: FontWeight.bold, height: 1.0)),
                  ],
                ),
                const SizedBox(height: 10),
                const LinearProgressIndicator(value: 0.83, backgroundColor: Colors.black26, valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: surfaceColor.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(20), border: Border.all(color: textColor.withValues(alpha: 0.05))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.bolt, color: AppColors.appYellow, size: 20),
                      const SizedBox(height: 10),
                      Text('4.5 kWh', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(isPh ? 'Konsumo ngayon' : "Today's draw", style: TextStyle(color: hintColor, fontSize: 11)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: surfaceColor.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(20), border: Border.all(color: textColor.withValues(alpha: 0.05))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.access_time, color: Colors.greenAccent, size: 20),
                      const SizedBox(height: 10),
                      Text('₱56', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(isPh ? 'Est. gastos ngayon' : "Est. cost today", style: TextStyle(color: hintColor, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _dummyQuickAction(Icons.add, isPh ? 'Magdagdag' : 'Add item', true, surfaceColor, hintColor),
              _dummyQuickAction(Icons.show_chart, isPh ? 'Pagsusuri' : 'Analysis', false, surfaceColor, hintColor),
              _dummyQuickAction(Icons.settings, isPh ? 'Setting' : 'Config', false, surfaceColor, hintColor),
              _dummyQuickAction(Icons.ios_share, isPh ? 'I-export' : 'Export', false, surfaceColor, hintColor),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDummyDevices(Color surfaceColor, Color textColor, Color hintColor, bool isPh) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isPh ? 'Lugar ng Pagpaplano' : 'My Planning Space', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.appYellow.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.appYellow.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: AppColors.appYellow, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isPh
                      ? 'I-lock (🔒) ang mahahalagang gamit. Iwanang naka-unlock (🔓) ang iba para sa awtomatikong pag-optimize ng budget.'
                      : 'Lock (🔒) essential items. Leave flexible items unlocked (🔓) for automatic budget optimization.',
                    style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          _dummyDeviceCard('Refrigerator', '150W', '24.0h', true, surfaceColor, textColor, hintColor),
          _dummyDeviceCard('Air Conditioner', '1050W', '5.2h', false, surfaceColor, textColor, hintColor),
        ],
      ),
    );
  }

  Widget _buildDummyAnalysis(Color surfaceColor, Color textColor, Color hintColor, bool isPh) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isPh ? 'Pagsusuri' : 'Analysis', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.greenAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const Icon(Icons.trending_down, color: Colors.greenAccent, size: 28),
                const SizedBox(width: 12),
                Text(isPh ? 'Bumaba ang Konsumo' : 'Decreased Usage Trend', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: surfaceColor.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isPh ? 'PAANO KINAKALKULA NG KISLAP' : 'HOW KISLAP COMPUTES', style: const TextStyle(color: AppColors.appYellow, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: textColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                  child: const Text('(Wattage ÷ 1000) × Hours', style: TextStyle(color: Colors.greenAccent, fontFamily: 'monospace')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDummySettings(Color surfaceColor, Color textColor, Color hintColor, bool isPh) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isPh ? 'Mga Setting' : 'Settings', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: surfaceColor.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16), border: Border.all(color: textColor.withValues(alpha: 0.05))),
            child: Row(
              children: [
                Container(
                  height: 56, width: 56,
                  decoration: BoxDecoration(color: AppColors.appYellow.withValues(alpha: 0.2), shape: BoxShape.circle, border: Border.all(color: AppColors.appYellow.withValues(alpha: 0.5))),
                  child: const Center(child: Text('K', style: TextStyle(color: AppColors.appYellow, fontSize: 24, fontWeight: FontWeight.bold))),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kislap User', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('user@kislap.app', style: TextStyle(color: hintColor, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 35),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: surfaceColor.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isPh ? 'Limitasyon sa Budget' : 'Monthly Budget Limit', style: TextStyle(color: hintColor, fontSize: 12)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: textColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                  child: Text('₱ 1500.00', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                Text(isPh ? 'Halaga ng Kuryente' : 'Utility Rate', style: TextStyle(color: hintColor, fontSize: 12)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: textColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                  child: Text('₱ 12.35 / kWh', style: TextStyle(color: textColor, fontSize: 16)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dummyQuickAction(IconData icon, String label, bool isPrimary, Color surfaceColor, Color hintColor) {
    return Column(
      children: [
        Container(
          height: 60, width: 60,
          decoration: BoxDecoration(color: isPrimary ? Colors.orange.shade600 : surfaceColor.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16)),
          child: Icon(icon, color: isPrimary ? Colors.white : hintColor, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: hintColor, fontSize: 12)),
      ],
    );
  }

  Widget _dummyDeviceCard(String name, String watts, String hours, bool isLocked, Color surfaceColor, Color textColor, Color hintColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isLocked ? AppColors.appYellow.withValues(alpha: 0.4) : textColor.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: isLocked ? AppColors.appYellow.withValues(alpha: 0.1) : textColor.withValues(alpha: 0.05), shape: BoxShape.circle),
            child: Icon(isLocked ? Icons.ac_unit : Icons.electrical_services, color: isLocked ? AppColors.appYellow : hintColor, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                Text('$watts • Target: $hours/day', style: TextStyle(color: hintColor, fontSize: 12)),
              ],
            ),
          ),
          Icon(isLocked ? Icons.lock : Icons.lock_open, color: isLocked ? AppColors.appYellow : hintColor),
        ],
      ),
    );
  }
}
