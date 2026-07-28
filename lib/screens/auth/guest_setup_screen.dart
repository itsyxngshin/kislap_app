import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../services/database_helper.dart';
import '../dashboard/dashboard_shell.dart';

class GuestSetupScreen extends StatefulWidget {
  const GuestSetupScreen({super.key});

  @override
  State<GuestSetupScreen> createState() => _GuestSetupScreenState();
}

class _GuestSetupScreenState extends State<GuestSetupScreen> {
  int _currentStep = 0;
  bool _isLoading = false;

  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _tariffController = TextEditingController(text: '12.35'); // Default regional rate
  String _householdSize = 'Small';

  // Generates the current month string dynamically
  String _getCurrentBillingMonth() {
    final now = DateTime.now();
    final monthsEn = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final monthsPh = ['Enero', 'Pebrero', 'Marso', 'Abril', 'Mayo', 'Hunyo', 'Hulyo', 'Agosto', 'Setyembre', 'Oktubre', 'Nobyembre', 'Disyembre'];

    return '${monthsEn[now.month - 1]} ${now.year} (${monthsPh[now.month - 1]})';
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _tariffController.dispose();
    super.dispose();
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      final budget = double.tryParse(_budgetController.text) ?? 0.0;
      if (budget <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid monthly budget limit.\n(Mangyaring maglagay ng wastong budget.)'),
            backgroundColor: AppColors.adminRed
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

    try {
      final db = await DatabaseHelper.instance.database;

      // THE FIX: Uses raw insert with replace conflict resolution
      // This guarantees the settings save even if the table was previously empty.
      await db.insert(
        'user_settings',
        {
          'id': 1,
          'monthly_budget': budget,
          'tariff_rate': tariff,
          'household_size': _householdSize,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (mounted) {
        // Pushing to DashboardShell triggers a fresh initialization
        // This ensures the HomeScreen reads the newly saved SQLite row immediately
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DashboardShell()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving setup: $e'), backgroundColor: AppColors.adminRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return Container(
      decoration: AppTheme.globalBackground(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Guest Setup\n(Setup ng Bisita)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, height: 1.2)
          ),
        ),
        body: Column(
          children: [
            // DYNAMIC BILLING MONTH BADGE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.appYellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.appYellow.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_outlined, color: AppColors.appYellow, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PRESENT BILLING MONTH',
                            style: TextStyle(color: AppColors.appYellow, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)
                          ),
                          Text(
                            _getCurrentBillingMonth(),
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
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
                  colorScheme: const ColorScheme.dark(primary: AppColors.appYellow, onSurface: Colors.white),
                ),
                child: Stepper(
                  type: StepperType.vertical,
                  currentStep: _currentStep,
                  elevation: 0,
                  onStepContinue: () {
                    if (_validateCurrentStep()) {
                      if (_currentStep < 1) {
                        setState(() => _currentStep += 1);
                      } else {
                        _submitGuestSetup();
                      }
                    }
                  },
                  onStepCancel: () {
                    if (_currentStep > 0) {
                      setState(() => _currentStep -= 1);
                    } else {
                      Navigator.pop(context);
                    }
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
                                elevation: 5,
                              ),
                              child: _isLoading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text(
                                      isLastStep ? 'Enter Dashboard' : 'Continue',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)
                                    ),
                            ),
                          ),
                          if (_currentStep > 0) ...[
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: _isLoading ? null : details.onStepCancel,
                              child: const Text('Back', style: TextStyle(color: AppColors.textHintColor, fontSize: 16)),
                            ),
                          ]
                        ],
                      ),
                    );
                  },
                  steps: [
                    Step(
                      title: const Text('Financial Baseline\n(Batayang Pinansyal)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.2)),
                      subtitle: const Text('Optimization limits (Limitasyon sa budget)', style: TextStyle(color: AppColors.textHintColor, fontSize: 12)),
                      isActive: _currentStep >= 0,
                      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: surfaceColor.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.appYellow.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('TARGET BUDGET', style: TextStyle(color: AppColors.appYellow, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
                                const SizedBox(height: 4),
                                const Text('How much are you willing to spend this month?\n(Magkano ang limitasyon mo ngayong buwan?)', style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
                                const SizedBox(height: 16),
                                CustomTextField(
                                  controller: _budgetController,
                                  hint: 'e.g. 1500',
                                  icon: Icons.account_balance_wallet_outlined,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 15),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: surfaceColor.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.appYellow.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('UTILITY RATE (Halaga ng Kuryente)', style: TextStyle(color: AppColors.appYellow, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
                                const SizedBox(height: 4),
                                const Text('Check your electric bill for the exact ₱/kWh rate.\n(Tingnan ang iyong bill para sa eksaktong ₱/kWh.)', style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
                                const SizedBox(height: 16),
                                CustomTextField(
                                  controller: _tariffController,
                                  hint: 'e.g. 12.35',
                                  icon: Icons.bolt,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Step(
                      title: const Text('Household Class\n(Uri ng Bahayan)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.2)),
                      subtitle: const Text('Sets the kVA scale (Antas ng paggamit)', style: TextStyle(color: AppColors.textHintColor, fontSize: 12)),
                      isActive: _currentStep >= 1,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          const Text('Select your setup size to enforce safe power distribution limits.\n(Piliin ang uri ng bahay upang matukoy ang limitasyon sa kuryente.)', style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: surfaceColor.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16)),
                            child: Column(
                              children: [
                                _buildRadioOption('Small (0 - 5 kVA)', 'Basic appliances only. Fans, TV, fridge, and lights.\n(Basic na gamit lamang: Fan, TV, ilaw, atbp.)'),
                                _buildRadioOption('Medium (6 - 15 kVA)', 'Standard home. 1-2 air conditioners, fridge, etc.\n(May 1-2 aircon, ref, atbp.)'),
                                _buildRadioOption('Large (16 - 25 kVA)', 'Heavy usage. Multiple ACs, large appliances.\n(Malakas na konsumo: Maraming aircon at appliances.)'),
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
      ),
    );
  }

  Widget _buildRadioOption(String title, String description) {
    String value = title.split(' ').first;
    bool isSelected = _householdSize == value;

    return GestureDetector(
      onTap: () => setState(() => _householdSize = value),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.appYellow.withValues(alpha: 0.4) : Colors.transparent,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? Colors.greenAccent : Colors.white54,
              size: 22
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                    )
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
