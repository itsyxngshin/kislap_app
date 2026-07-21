import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_text_field.dart';
import '../../services/database_helper.dart';
import 'otp_verification_screen.dart';

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
  final TextEditingController _tariffController = TextEditingController(text: '11.08');
  String _householdSize = 'Small';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _budgetController.dispose();
    _tariffController.dispose();
    super.dispose();
  }

  // Validates the current step before allowing the user to proceed
  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      if (_nameController.text.trim().isEmpty ||
          _emailController.text.trim().isEmpty ||
          _passwordController.text.trim().isEmpty) {
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.adminRed),
    );
  }

  Future<void> _submitRegistration() async {
    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final budget = double.tryParse(_budgetController.text) ?? 0.0;
    final tariff = double.tryParse(_tariffController.text) ?? 11.08;

    try {
      // 1. Send data to Supabase (Password is handled automatically by auth schema)
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': name,
          'monthly_budget': budget,
          'tariff_rate': tariff,
          'household_size': _householdSize,
        },
      );

      // 2. Save the baseline to the local SQLite engine
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

      // 3. Navigate to OTP
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OtpVerificationScreen(email: email)),
        );
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
          title: const Text('Setup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: Theme(
          // Overrides the Stepper colors to match our dark theme
          data: Theme.of(context).copyWith(
            canvasColor: Colors.transparent,
            colorScheme: const ColorScheme.dark(
              primary: AppColors.appYellow,
              onSurface: Colors.white,
            ),
          ),
          child: Stepper(
            type: StepperType.vertical,
            currentStep: _currentStep,
            elevation: 0,
            onStepContinue: () {
              if (_validateCurrentStep()) {
                if (_currentStep < 2) {
                  setState(() => _currentStep += 1);
                } else {
                  _submitRegistration();
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

            // Custom Navigation Buttons
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
                      TextButton(
                        onPressed: _isLoading ? null : details.onStepCancel,
                        child: const Text('Back', style: TextStyle(color: AppColors.textHintColor)),
                      ),
                    ]
                  ],
                ),
              );
            },

            // The 3 Registration Steps
            // ... inside your Stepper widget ...
                        steps: [
                          Step(
                            title: const Text('Account Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            subtitle: const Text('Your login credentials', style: TextStyle(color: AppColors.textHintColor)),
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
                            title: const Text('Financial Baseline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            subtitle: const Text('Optimization limits', style: TextStyle(color: AppColors.textHintColor)),
                            isActive: _currentStep >= 1,
                            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                            content: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 10),
                                // GUIDED UI: Budget
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.appYellow.withValues(alpha: 0.2)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Target Budget', style: TextStyle(color: AppColors.appYellow, fontWeight: FontWeight.bold, fontSize: 13)),
                                      const SizedBox(height: 4),
                                      const Text('How much are you willing to spend on electricity this month?', style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
                                      const SizedBox(height: 12),
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

                                // GUIDED UI: Tariff Rate
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.appYellow.withValues(alpha: 0.2)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Utility Rate', style: TextStyle(color: AppColors.appYellow, fontWeight: FontWeight.bold, fontSize: 13)),
                                      const SizedBox(height: 4),
                                      const Text('Check your latest electric bill (e.g., ALECO or CASURECO) for the exact ₱/kWh rate.', style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
                                      const SizedBox(height: 12),
                                      CustomTextField(
                                        controller: _tariffController,
                                        hint: 'e.g. 11.08',
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
                            title: const Text('Household Class', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            subtitle: const Text('Sets the kVA scale', style: TextStyle(color: AppColors.textHintColor)),
                            isActive: _currentStep >= 2,
                            content: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 10),
                                const Text('Select your setup size to enforce safe power distribution limits.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                const SizedBox(height: 12),
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
    String value = title.split(' ').first; // Extracts 'Small', 'Medium', or 'Large'
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
