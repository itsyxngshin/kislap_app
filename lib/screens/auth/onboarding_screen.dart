import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../services/database_helper.dart';
import '../../providers/settings_provider.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';
import 'guest_setup_screen.dart';
import '../dashboard/dashboard_shell.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = textColor.withValues(alpha: 0.6);
    final settings = ref.watch(settingsProvider);
    final isPh = settings.language == 'ph';

    return Scaffold(
      body: Container(
        decoration: AppTheme.globalBackground(context),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Top Bar: Language Toggle
                          Align(
                            alignment: Alignment.topRight,
                            child: _buildLanguageToggle(context, ref, isPh),
                          ),

                          const Spacer(flex: 2),

                          // Standalone Brand Icon
                          Image.asset(
                            'assets/images/logo_icon.png',
                            height: 110,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 30),

                          // Typography / Branding
                          Text(
                            'Kislap',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isPh
                              ? 'I-optimize ang kuryente.\nPataasin ang iyong budget.'
                              : 'Optimize your power.\nMaximize your budget.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: hintColor,
                              fontSize: 16,
                              height: 1.5,
                              letterSpacing: 0.5,
                            ),
                          ),

                          const Spacer(flex: 3),

                          // Primary Action: Sign Up
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpScreen()));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.appYellow,
                                foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 8,
                                shadowColor: AppColors.appYellow.withValues(alpha: 0.4),
                              ),
                              child: Text(
                                isPh ? 'Gumawa ng Account' : 'Create an Account',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Secondary Action: Log In
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const SignInScreen()));
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: hintColor.withValues(alpha: 0.3), width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                foregroundColor: textColor,
                              ),
                              child: Text(
                                isPh ? 'Mag-log in' : 'Log In',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Tertiary Action: Guest Mode
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(height: 1, width: 40, color: hintColor.withValues(alpha: 0.2)),
                              const SizedBox(width: 15),
                              Text(
                                isPh ? 'O' : 'OR',
                                style: TextStyle(color: hintColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)
                              ),
                              const SizedBox(width: 15),
                              Container(height: 1, width: 40, color: hintColor.withValues(alpha: 0.2)),
                            ],
                          ),
                          const SizedBox(height: 15),

                          TextButton.icon(
                            onPressed: () async {
                              try {
                                final db = await DatabaseHelper.instance.database;
                                final settings = await db.query('user_settings', limit: 1);
                                if (settings.isNotEmpty) {
                                  final budget = (settings.first['monthly_budget'] as num?)?.toDouble() ?? 0.0;
                                  if (budget > 0 && context.mounted) {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(builder: (_) => const DashboardShell()),
                                      (route) => false,
                                    );
                                    return;
                                  }
                                }
                              } catch (_) {}

                              if (context.mounted) {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const GuestSetupScreen()));
                              }
                            },
                            icon: Icon(Icons.rocket_launch_outlined, color: Colors.greenAccent.withValues(alpha: 0.8), size: 20),
                            label: Text(
                              isPh ? 'Magpatuloy bilang Bisita' : 'Continue as Guest',
                              style: TextStyle(color: Colors.greenAccent.withValues(alpha: 0.8), fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),

                          const Spacer(flex: 1),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageToggle(BuildContext context, WidgetRef ref, bool isPh) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.appYellow.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLangOption(ref, 'EN', 'en', !isPh),
          _buildLangOption(ref, 'PH', 'ph', isPh),
        ],
      ),
    );
  }

  Widget _buildLangOption(WidgetRef ref, String label, String langCode, bool isSelected) {
    return GestureDetector(
      onTap: () => ref.read(settingsProvider.notifier).setLanguage(langCode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.appYellow : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black87 : Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
