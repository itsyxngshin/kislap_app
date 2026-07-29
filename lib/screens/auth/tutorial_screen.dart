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
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _slides = [
    {
      'title': 'Set Your Budget',
      'title_ph': 'Itakda ang Budget',
      'desc': 'Input your monthly electricity budget and let Kislap do the math based on regional tariffs.',
      'desc_ph': 'Ipasok ang iyong buwanang limitasyon at hayaang kalkulahin ito ng Kislap.',
      'icon': 'account_balance_wallet',
    },
    {
      'title': 'Lock Essentials',
      'title_ph': 'I-lock ang Mahahalaga',
      'desc': 'Lock (🔒) appliances you must use. We will reduce the unlocked ones to protect your budget.',
      'desc_ph': 'I-lock ang mahahalagang gamit. Babawasan namin ang oras ng iba para makatipid.',
      'icon': 'lock',
    },
    {
      'title': 'Track Consumption',
      'title_ph': 'Bantayan ang Konsumo',
      'desc': 'View daily estimates and monthly projections to avoid bill shocks.',
      'desc_ph': 'Tingnan ang iyong pang-araw-araw na gastos para iwas-gulat sa bill.',
      'icon': 'bar_chart',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = textColor.withValues(alpha: 0.7);
    final lang = ref.watch(settingsProvider).language; // Dynamic Language

    return Scaffold(
      body: Container(
        decoration: AppTheme.globalBackground(context),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (int page) => setState(() => _currentPage = page),
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getIcon(slide['icon']!),
                            size: 100,
                            color: AppColors.appYellow,
                          ),
                          const SizedBox(height: 50),
                          Text(
                            lang == 'ph' ? slide['title_ph']! : slide['title']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.bold, height: 1.2),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            lang == 'ph' ? slide['desc_ph']! : slide['desc']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: hintColor, fontSize: 16, height: 1.5),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Dot Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _currentPage == index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? AppColors.appYellow : Colors.grey.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Next / Get Started Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: () async {
                      if (_currentPage < _slides.length - 1) {
                        _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
                      } else {
                        // Mark tutorial as complete in SQLite and proceed to Dashboard
                        await ref.read(settingsProvider.notifier).completeTutorial();
                        if (context.mounted) {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardShell()));
                        }
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.appYellow,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      _currentPage == _slides.length - 1
                          ? (lang == 'ph' ? 'Magsimula' : 'Get Started')
                          : (lang == 'ph' ? 'Susunod' : 'Next'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'account_balance_wallet': return Icons.account_balance_wallet_outlined;
      case 'lock': return Icons.lock_outline;
      case 'bar_chart': return Icons.bar_chart_rounded;
      default: return Icons.bolt;
    }
  }
}
