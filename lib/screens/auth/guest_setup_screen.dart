import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_text_field.dart';
import '../../services/database_helper.dart';
import '../../providers/settings_provider.dart';
import '../dashboard/dashboard_shell.dart';
import '../dashboard/add_device_screen.dart';

class GuestSetupScreen extends ConsumerStatefulWidget {
  const GuestSetupScreen({super.key});

  @override
  ConsumerState<GuestSetupScreen> createState() => _GuestSetupScreenState();
}

class _GuestSetupScreenState extends ConsumerState<GuestSetupScreen> {
  int _currentStep = 0;
  bool _isLoading = false;

  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _tariffController = TextEditingController(text: '12.35');
  String _householdSize = 'Small';

  String _getTargetBillingMonth(bool isPh) {
    final now = DateTime.now();
    final monthsEn = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final monthsPh = ['Enero', 'Pebrero', 'Marso', 'Abril', 'Mayo', 'Hunyo', 'Hulyo', 'Agosto', 'Setyembre', 'Oktubre', 'Nobyembre', 'Disyembre'];
    return isPh ? '${monthsPh[now.month - 1]} ${now.year}' : '${monthsEn[now.month - 1]} ${now.year}';
  }

  String _getPreviousBillingMonth(bool isPh) {
    final now = DateTime.now();
    int prevMonth = now.month - 1;
    int prevYear = now.year;
    if (prevMonth == 0) {
      prevMonth = 12;
      prevYear--;
    }
    final monthsEn = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final monthsPh = ['Enero', 'Pebrero', 'Marso', 'Abril', 'Mayo', 'Hunyo', 'Hulyo', 'Agosto', 'Setyembre', 'Oktubre', 'Nobyembre', 'Disyembre'];
    return isPh ? '${monthsPh[prevMonth - 1]} $prevYear' : '${monthsEn[prevMonth - 1]} $prevYear';
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _tariffController.dispose();
    super.dispose();
  }

  bool _validateCurrentStep(bool isPh) {
    if (_currentStep == 0) {
      final budget = double.tryParse(_budgetController.text) ?? 0.0;
      if (budget <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isPh ? 'Mangyaring maglagay ng wastong limitasyon sa budget.' : 'Please enter a valid monthly budget limit.'),
            backgroundColor: AppColors.adminRed,
          ),
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _submitGuestSetup() async {
    setState(() => _isLoading = true);

    final budget = double.tryParse(_budgetController.text) ?? 0.0;
    final tariff = double.tryParse(_tariffController.text) ?? 12.35;
    final isPh = ref.read(settingsProvider).language == 'ph';

    try {
      final db = await DatabaseHelper.instance.database;

      await db.insert(
        'user_settings',
        {
          'id': 1,
          'monthly_budget': budget,
          'tariff_rate': tariff,
          'household_size': _householdSize,
          'language': isPh ? 'ph' : 'en',
          'theme_mode': ref.read(settingsProvider).themeMode == ThemeMode.dark ? 'dark' : 'light',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (mounted) {
        // ISO 25010 Usability: Direct Onboarding Loop Prompt
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text(isPh ? 'Matagumpay na Nai-save!' : 'Setup Complete!', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
            content: Text(isPh
              ? 'Gusto mo bang magdagdag na ng mga appliances ngayon, o dumiretso sa dashboard?'
              : 'Would you like to add your household appliances now, or proceed to the dashboard?',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8), height: 1.4),
            ),
            actions: [
                          TextButton(
                            // Option 1: Skip entirely and go to Dashboard
                            onPressed: () => Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const DashboardShell()),
                              (route) => false
                            ),
                            child: Text(isPh ? 'Mamaya na' : 'Skip for now', style: const TextStyle(color: AppColors.appYellow)),
                          ),
                          FilledButton(
                            // Option 2: Go to the Multi-Add Onboarding Screen
                            onPressed: () {
                              Navigator.pop(ctx); // Close the dialog
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const OnboardingDevicesScreen())
                              );
                            },
                            style: FilledButton.styleFrom(backgroundColor: AppColors.appYellow, foregroundColor: Colors.black87),
                            child: Text(isPh ? 'Magdagdag ng Gamit' : 'Add Appliances', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving setup: $e'), backgroundColor: AppColors.adminRed));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = textColor.withOpacity(0.6);
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final isPh = ref.watch(settingsProvider).language == 'ph';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(isPh ? 'Setup ng Bisita' : 'Guest Setup', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _buildLanguageToggle(context, ref, isPh, textColor, surfaceColor),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.appYellow.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.appYellow.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.track_changes, color: AppColors.appYellow, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isPh ? 'TARGET NA BUWAN NG BILL' : 'TARGET BILLING MONTH', style: const TextStyle(color: AppColors.appYellow, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        Text(_getTargetBillingMonth(isPh), style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                canvasColor: Colors.transparent,
                colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.appYellow, onSurface: textColor),
              ),
              child: Stepper(
                type: StepperType.vertical,
                currentStep: _currentStep,
                elevation: 0,
                onStepContinue: () {
                  if (_validateCurrentStep(isPh)) {
                    if (_currentStep < 1) setState(() => _currentStep += 1);
                    else _submitGuestSetup();
                  }
                },
                onStepCancel: () {
                  if (_currentStep > 0) setState(() => _currentStep -= 1);
                  else Navigator.pop(context);
                },
                controlsBuilder: (context, details) {
                  final isLastStep = _currentStep == 1;
                  return Padding(
                    padding: const EdgeInsets.only(top: 30.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: _isLoading ? null : details.onStepContinue,
                            style: FilledButton.styleFrom(
                              backgroundColor: isLastStep ? Colors.orange.shade700 : AppColors.appYellow,
                              foregroundColor: isLastStep ? Colors.white : Colors.black87,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(isLastStep ? (isPh ? 'Tapusin' : 'Complete Setup') : (isPh ? 'Magpatuloy' : 'Continue'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        if (_currentStep > 0) ...[
                          const SizedBox(width: 12),
                          TextButton(onPressed: _isLoading ? null : details.onStepCancel, child: Text(isPh ? 'Bumalik' : 'Back', style: TextStyle(color: hintColor, fontSize: 16))),
                        ]
                      ],
                    ),
                  );
                },
                steps: [
                  Step(
                    title: Text(isPh ? 'Batayang Pinansyal' : 'Financial Baseline', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                    subtitle: Text(isPh ? 'Limitasyon sa budget' : 'Optimization limits', style: TextStyle(color: hintColor, fontSize: 12)),
                    isActive: _currentStep >= 0,
                    state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: surfaceColor.withOpacity(0.6), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.appYellow.withOpacity(0.2))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('TARGET BUDGET', style: TextStyle(color: AppColors.appYellow, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
                              const SizedBox(height: 4),
                              Text(isPh ? 'Magkano ang limitasyon mo ngayong buwan?' : 'How much are you willing to spend this month?', style: TextStyle(color: hintColor, fontSize: 12, height: 1.4)),
                              const SizedBox(height: 16),
                              CustomTextField(controller: _budgetController, hint: 'e.g. 1500', icon: Icons.account_balance_wallet_outlined, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: surfaceColor.withOpacity(0.6), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.appYellow.withOpacity(0.2))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isPh ? 'NAKARAANG HALAGA (PREVIOUS RATE)' : 'PREVIOUS UTILITY RATE', style: const TextStyle(color: AppColors.appYellow, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
                              const SizedBox(height: 4),
                              Text(isPh ? 'Suriin ang electric bill noong nakaraang ${_getPreviousBillingMonth(true)} para sa eksaktong ₱/kWh.' : 'Check your electric bill from ${_getPreviousBillingMonth(false)} for the exact ₱/kWh rate.', style: TextStyle(color: hintColor, fontSize: 12, height: 1.4)),
                              const SizedBox(height: 16),
                              CustomTextField(controller: _tariffController, hint: 'e.g. 12.35', icon: Icons.bolt, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Step(
                    title: Text(isPh ? 'Uri ng Bahayan' : 'Household Class', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                    subtitle: Text(isPh ? 'Antas ng paggamit' : 'Sets the kVA scale', style: TextStyle(color: hintColor, fontSize: 12)),
                    isActive: _currentStep >= 1,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text(isPh ? 'Piliin ang uri ng bahay upang matukoy ang limitasyon sa kuryente.' : 'Select your setup size to enforce safe power distribution limits.', style: TextStyle(color: hintColor, fontSize: 12, height: 1.4)),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: surfaceColor.withOpacity(0.5), borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            children: [
                              _buildRadioOption('Small (0 - 5 kVA)', isPh ? 'Basic na gamit lamang: Fan, TV, ilaw, atbp.' : 'Basic appliances only. Fans, TV, fridge, and lights.', textColor, hintColor),
                              _buildRadioOption('Medium (6 - 15 kVA)', isPh ? 'Pangkaraniwang bahay. May 1-2 aircon, ref, atbp.' : 'Standard home. 1-2 air conditioners, fridge, etc.', textColor, hintColor),
                              _buildRadioOption('Large (16 - 25 kVA)', isPh ? 'Malakas na konsumo. Maraming aircon at malaking gamit.' : 'Heavy usage. Multiple ACs, large appliances.', textColor, hintColor),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageToggle(BuildContext context, WidgetRef ref, bool isPh, Color textColor, Color surfaceColor) {
    return Container(
      decoration: BoxDecoration(color: surfaceColor.withOpacity(0.6), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.appYellow.withOpacity(0.3))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLangOption(ref, 'EN', 'en', !isPh, textColor),
          _buildLangOption(ref, 'PH', 'ph', isPh, textColor),
        ],
      ),
    );
  }

  Widget _buildLangOption(WidgetRef ref, String label, String langCode, bool isSelected, Color textColor) {
    return GestureDetector(
      onTap: () => ref.read(settingsProvider.notifier).setLanguage(langCode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: isSelected ? AppColors.appYellow : Colors.transparent, borderRadius: BorderRadius.circular(18)),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.black87 : textColor, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildRadioOption(String title, String description, Color textColor, Color hintColor) {
    String value = title.split(' ').first;
    bool isSelected = _householdSize == value;

    return GestureDetector(
      onTap: () => setState(() => _householdSize = value),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? textColor.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.appYellow.withOpacity(0.4) : Colors.transparent),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: isSelected ? AppColors.appYellow : hintColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: isSelected ? textColor : hintColor, fontSize: 15, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  const SizedBox(height: 6),
                  Text(description, style: TextStyle(color: hintColor, fontSize: 11, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
