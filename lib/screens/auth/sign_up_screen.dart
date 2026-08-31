import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/social_button.dart';
import '../../services/database_helper.dart';
import '../dashboard/dashboard_shell.dart';
import 'onboarding_devices_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isGoogleAuth = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _tariffController = TextEditingController(
    text: '12.35',
  );
  String _householdSize = 'Small';

  String _getPreviousBillingMonth() {
    final now = DateTime.now();
    int prevMonth = now.month - 1;
    int prevYear = now.year;
    if (prevMonth == 0) {
      prevMonth = 12;
      prevYear--;
    }
    final monthsEn = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
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

  // --- NEW: Reusable Modal Prompt ---
  void _showModalPrompt(String title, String message, {bool isError = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isError
                ? AppColors.adminRed.withOpacity(0.3)
                : AppColors.appYellow.withOpacity(0.3),
          ),
        ),
        title: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? AppColors.adminRed : AppColors.appYellow,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            height: 1.4,
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(
              backgroundColor: isError
                  ? AppColors.adminRed
                  : AppColors.appYellow,
              foregroundColor: isError ? Colors.white : Colors.black87,
            ),
            child: const Text(
              'OK',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0 && !_isGoogleAuth) {
      if (_nameController.text.trim().isEmpty ||
          _emailController.text.trim().isEmpty ||
          _passwordController.text.trim().isEmpty) {
        _showModalPrompt(
          'Incomplete Data',
          'Please fill out all account details to proceed.',
          isError: true,
        );
        return false;
      }
      if (_passwordController.text.length < 6) {
        _showModalPrompt(
          'Weak Password',
          'Your password must be at least 6 characters long.',
          isError: true,
        );
        return false;
      }
    } else if (_currentStep == 1) {
      final budget = double.tryParse(_budgetController.text) ?? 0.0;
      if (budget <= 0) {
        _showModalPrompt(
          'Invalid Budget',
          'Please enter a valid monthly budget limit above 0.',
          isError: true,
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _signUpWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'https://kislap-app.vercel.app',
      );
    } catch (e) {
      if (mounted) {
        _showModalPrompt('Google Sign-Up Error', e.toString(), isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitRegistration() async {
    setState(() => _isLoading = true);

    final budget = double.tryParse(_budgetController.text) ?? 0.0;
    final tariff = double.tryParse(_tariffController.text) ?? 12.35;

    try {
      User? user = Supabase.instance.client.auth.currentUser;

      if (!_isGoogleAuth) {
        final authResponse = await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          data: {
            'full_name': _nameController.text.trim(),
            'monthly_budget': budget,
            'tariff_rate': tariff,
            'household_size': _householdSize,
          },
        );
        user = authResponse.user;
      } else if (user != null) {
        await Supabase.instance.client
            .from('profiles')
            .update({
              'monthly_budget': budget,
              'tariff_rate': tariff,
              'household_size': _householdSize,
            })
            .eq('id', user.id);
      }

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

      if (mounted) _showOnboardingPrompt();
    } on AuthException catch (e) {
      if (mounted)
        _showModalPrompt('Registration Failed', e.message, isError: true);
    } catch (e) {
      if (mounted)
        _showModalPrompt(
          'Unexpected Error',
          'An unexpected error occurred: $e',
          isError: true,
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Uses your existing Setup Complete modal!
  void _showOnboardingPrompt() {
    final surfaceColor = Theme.of(context).colorScheme.surface;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.appYellow.withOpacity(0.5)),
        ),
        title: const Text(
          'Setup Complete!',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Would you like to add your household appliances now, or proceed to the dashboard?',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const DashboardShell()),
              (route) => false,
            ),
            child: const Text(
              'Skip for now',
              style: TextStyle(color: AppColors.appYellow),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const OnboardingDevicesScreen(),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.appYellow,
              foregroundColor: Colors.black87,
            ),
            child: const Text(
              'Add Appliances',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
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
          leading: const BackButton(),
          title: Text(
            'Account Setup',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
        ),
        body: Theme(
          data: Theme.of(context).copyWith(
            canvasColor: Colors.transparent,
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.appYellow,
              onSurface: textColor,
            ),
          ),
          child: Stepper(
            type: StepperType.vertical,
            currentStep: _currentStep,
            elevation: 0,
            onStepContinue: () {
              if (_validateCurrentStep()) {
                if (_currentStep < 2)
                  setState(() => _currentStep += 1);
                else
                  _submitRegistration();
              }
            },
            onStepCancel: () {
              if (_currentStep > 0)
                setState(() => _currentStep -= 1);
              else
                Navigator.pop(context);
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
                          backgroundColor: isLastStep
                              ? Colors.orange.shade700
                              : AppColors.appYellow,
                          foregroundColor: isLastStep
                              ? Colors.white
                              : Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                isLastStep
                                    ? 'Complete Registration'
                                    : 'Continue',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    if (_currentStep > 0) ...[
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: _isLoading ? null : details.onStepCancel,
                        child: Text('Back', style: TextStyle(color: hintColor)),
                      ),
                    ],
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: Text(
                  'Account Details',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Your login credentials',
                  style: TextStyle(color: hintColor),
                ),
                isActive: _currentStep >= 0,
                state: _currentStep > 0
                    ? StepState.complete
                    : StepState.indexed,
                content: _isGoogleAuth
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 12),
                            Text(
                              'Authenticated via Google',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          const SizedBox(height: 10),
                          CustomTextField(
                            controller: _nameController,
                            hint: 'Full Name',
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 15),
                          CustomTextField(
                            controller: _emailController,
                            hint: 'name@email.com',
                            icon: Icons.email_outlined,
                          ),
                          const SizedBox(height: 15),
                          CustomTextField(
                            controller: _passwordController,
                            hint: 'Create a password',
                            icon: Icons.lock_outline,
                            isPassword: true,
                          ),
                          const SizedBox(height: 25),

                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: hintColor.withOpacity(0.3),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Text(
                                  'or',
                                  style: TextStyle(
                                    color: hintColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: hintColor.withOpacity(0.3),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            child: SocialButton(
                              icon: Icons.g_mobiledata,
                              label: 'Sign up with Google',
                              onPressed: _isLoading ? () {} : _signUpWithGoogle,
                            ),
                          ),
                        ],
                      ),
              ),
              Step(
                title: Text(
                  'Financial Baseline',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Optimization limits',
                  style: TextStyle(color: hintColor),
                ),
                isActive: _currentStep >= 1,
                state: _currentStep > 1
                    ? StepState.complete
                    : StepState.indexed,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceColor.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.appYellow.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Target Budget',
                            style: TextStyle(
                              color: AppColors.appYellow,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'How much are you willing to spend on electricity this month?',
                            style: TextStyle(
                              color: hintColor,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _budgetController,
                            hint: 'e.g. 1500',
                            icon: Icons.account_balance_wallet_outlined,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceColor.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.appYellow.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Previous Utility Rate',
                            style: TextStyle(
                              color: AppColors.appYellow,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Check your electric bill from ${_getPreviousBillingMonth()} for the exact ₱/kWh rate.',
                            style: TextStyle(
                              color: hintColor,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _tariffController,
                            hint: 'e.g. 12.35',
                            icon: Icons.bolt,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Step(
                title: Text(
                  'Household Class',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Sets the kVA scale',
                  style: TextStyle(color: hintColor),
                ),
                isActive: _currentStep >= 2,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      'Select your setup size to enforce safe power distribution limits.',
                      style: TextStyle(color: hintColor, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: surfaceColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _buildRadioOption(
                            'Small (0 - 5 kVA)',
                            'Basic appliances only. Fans, TV, fridge, and lights.',
                            textColor,
                            hintColor,
                          ),
                          _buildRadioOption(
                            'Medium (6 - 15 kVA)',
                            'Standard home. 1-2 air conditioners, washing machine, fridge, etc.',
                            textColor,
                            hintColor,
                          ),
                          _buildRadioOption(
                            'Large (16 - 25 kVA)',
                            'Heavy usage. Multiple split-type ACs, water heaters, large appliances.',
                            textColor,
                            hintColor,
                          ),
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

  Widget _buildRadioOption(
    String title,
    String description,
    Color textColor,
    Color hintColor,
  ) {
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
          border: Border.all(
            color: isSelected
                ? AppColors.appYellow.withOpacity(0.4)
                : Colors.transparent,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.appYellow : hintColor,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? textColor : hintColor,
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      color: hintColor,
                      fontSize: 12,
                      height: 1.4,
                    ),
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
