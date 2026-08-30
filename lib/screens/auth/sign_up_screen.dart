import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../services/database_helper.dart';
import '../dashboard/dashboard_shell.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  int _currentStep = 0;
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _tariffController = TextEditingController(text: '12.35');
  String _householdSize = 'Small';

  String _getPreviousBillingMonth() {
    final now = DateTime.now();
    int prevMonth = now.month - 1;
    int prevYear = now.year;
    if (prevMonth == 0) {
      prevMonth = 12;
      prevYear--;
    }
    final monthsEn = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${monthsEn[prevMonth - 1]} $prevYear';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _budgetController.dispose();
    _tariffController.dispose();
    super.dispose();
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      if (_nameController.text.trim().isEmpty || _emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
        _showError('Please fill out all account details.');
        return false;
      }
      if (_passwordController.text.length < 6) {
        _showError('Password must be at least 6 characters.');
        return false;
      }
    } else if (_currentStep == 1) {
      final budget = double.tryParse(_budgetController.text) ?? 0.0;
      if (budget <= 0) {
        _showError('Please enter a valid monthly budget limit.');
        return false;
      }
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: AppColors.adminRed));
  }

  Future<void> _submitRegistration() async {
    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final budget = double.tryParse(_budgetController.text) ?? 0.0;
    final tariff = double.tryParse(_tariffController.text) ?? 12.35;

    try {
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name, 'monthly_budget': budget, 'tariff_rate': tariff, 'household_size': _householdSize},
      );

      final db = await DatabaseHelper.instance.database;
      await db.update(
        'user_settings',
        {'monthly_budget': budget, 'tariff_rate': tariff, 'household_size': _householdSize},
        where: 'id = ?',
        whereArgs: [1],
      );

      if (mounted) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const DashboardShell()), (route) => false);
      }
    } on AuthException catch (e) {
      if (mounted) _showError(e.message);
    } catch (e) {
      if (mounted) _showError('An unexpected error occurred: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = textColor.withOpacity(0.6);
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return Container(
      decoration: AppTheme.globalBackground(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButton(), // ISO 25010: Standardized navigation
          title: Text('Account Setup', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        ),
        body: Theme(
          data: Theme.of(context).copyWith(
            canvasColor: Colors.transparent,
            colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.appYellow, onSurface: textColor),
          ),
          child: Stepper(
            type: StepperType.vertical,
            currentStep: _currentStep,
            elevation: 0,
            onStepContinue: () {
              if (_validateCurrentStep()) {
                if (_currentStep < 2) setState(() => _currentStep += 1);
                else _submitRegistration();
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) setState(() => _currentStep -= 1);
              else Navigator.pop(context);
            },
            controlsBuilder: (context, details) {
              final isLastStep = _currentStep == 2;
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
                            : Text(isLastStep ? 'Complete Registration' : 'Continue', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    if (_currentStep > 0) ...[
                      const SizedBox(width: 12),
                      TextButton(onPressed: _isLoading ? null : details.onStepCancel, child: Text('Back', style: TextStyle(color: hintColor))),
                    ],
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: Text('Account Details', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                subtitle: Text('Your login credentials', style: TextStyle(color: hintColor)),
                isActive: _currentStep >= 0,
                state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                content: Column(
                  children: [
                    const SizedBox(height: 10),
                    CustomTextField(controller: _nameController, hint: 'Full Name', icon: Icons.person_outline),
                    const SizedBox(height: 15),
                    CustomTextField(controller: _emailController, hint: 'name@email.com', icon: Icons.email_outlined),
                    const SizedBox(height: 15),
                    CustomTextField(controller: _passwordController, hint: 'Create a password', icon: Icons.lock_outline, isPassword: true),
                  ],
                ),
              ),
              Step(
                title: Text('Financial Baseline', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                subtitle: Text('Optimization limits', style: TextStyle(color: hintColor)),
                isActive: _currentStep >= 1,
                state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: surfaceColor.withOpacity(0.6), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.appYellow.withOpacity(0.2))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Target Budget', style: TextStyle(color: AppColors.appYellow, fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('How much are you willing to spend on electricity this month?', style: TextStyle(color: hintColor, fontSize: 12, height: 1.4)),
                          const SizedBox(height: 12),
                          CustomTextField(controller: _budgetController, hint: 'e.g. 1500', icon: Icons.account_balance_wallet_outlined, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: surfaceColor.withOpacity(0.6), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.appYellow.withOpacity(0.2))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Previous Utility Rate', style: TextStyle(color: AppColors.appYellow, fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('Check your electric bill from ${_getPreviousBillingMonth()} for the exact ₱/kWh rate.', style: TextStyle(color: hintColor, fontSize: 12, height: 1.4)),
                          const SizedBox(height: 12),
                          CustomTextField(controller: _tariffController, hint: 'e.g. 12.35', icon: Icons.bolt, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Step(
                title: Text('Household Class', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                subtitle: Text('Sets the kVA scale', style: TextStyle(color: hintColor)),
                isActive: _currentStep >= 2,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Text('Select your setup size to enforce safe power distribution limits.', style: TextStyle(color: hintColor, fontSize: 12)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: surfaceColor.withOpacity(0.5), borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          _buildRadioOption('Small (0 - 5 kVA)', 'Basic appliances only. Fans, TV, fridge, and lights.', textColor, hintColor),
                          _buildRadioOption('Medium (6 - 15 kVA)', 'Standard home. 1-2 air conditioners, washing machine, fridge, etc.', textColor, hintColor),
                          _buildRadioOption('Large (16 - 25 kVA)', 'Heavy usage. Multiple split-type ACs, water heaters, large appliances.', textColor, hintColor),
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
