import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
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
  final TextEditingController _tariffController = TextEditingController(text: '11.08'); 
  String _householdSize = 'Small';

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
          const SnackBar(content: Text('Please enter a valid monthly budget limit.'), backgroundColor: AppColors.adminRed),
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _submitGuestSetup() async {
    setState(() => _isLoading = true);

    final budget = double.tryParse(_budgetController.text) ?? 0.0;
    final tariff = double.tryParse(_tariffController.text) ?? 11.08;

    try {
      // Save directly to the local SQLite engine for offline use
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'user_settings',
        {
          'monthly_budget': budget,
          'tariff_rate': tariff,
          'household_size': _householdSize,
        },
        where: 'id = ?',
        whereArgs: [1],
      );

      // Navigate straight to the dashboard
      if (mounted) {
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
    return Container(
      decoration: AppColors.globalGradient,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Guest Setup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: Theme(
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
                        ),
                        child: _isLoading 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(isLastStep ? 'Enter Dashboard' : 'Continue', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    if (_currentStep > 0) ...[
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: _isLoading ? null : details.onStepCancel,
                        child: const Text('Back', style: TextStyle(color: AppColors.textHintColor)),
                      ),
                    ]
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: const Text('Financial Baseline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                subtitle: const Text('Optimization limits', style: TextStyle(color: AppColors.textHintColor)),
                isActive: _currentStep >= 0,
                state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                content: Column(
                  children: [
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: _budgetController,
                      hint: 'Target Monthly Budget (₱)',
                      icon: Icons.account_balance_wallet_outlined,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      controller: _tariffController,
                      hint: 'Local Tariff Rate (₱/kWh)',
                      icon: Icons.bolt,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ],
                ),
              ),
              Step(
                title: const Text('Household Class', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                subtitle: const Text('Sets the kVA scale', style: TextStyle(color: AppColors.textHintColor)),
                isActive: _currentStep >= 1,
                content: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.inputBackground, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          _buildRadioOption('Small (0 - 5 kVA)'),
                          _buildRadioOption('Medium (6 - 15 kVA)'),
                          _buildRadioOption('Large (16 - 25 kVA)'),
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
    );
  }

  Widget _buildRadioOption(String title) {
    String value = title.split(' ').first; 
    bool isSelected = _householdSize == value;
    
    return GestureDetector(
      onTap: () => setState(() => _householdSize = value),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(12)
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: isSelected ? Colors.greenAccent : Colors.white54, size: 20),
          ],
        ),
      ),
    );
  }
}