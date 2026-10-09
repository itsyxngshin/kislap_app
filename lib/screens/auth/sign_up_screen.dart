import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/social_button.dart';
import '../../services/database_helper.dart';
import '../../services/sync_service.dart';
import '../common/privacy_policy_screen.dart'; // <-- Add Import
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
  bool _hasAgreedToPrivacy = false; // <-- Add Consent State

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _tariffController = TextEditingController(
    text: '12.35',
  );
  String _householdSize = 'Small';

  bool _isEmailValid = false;
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSymbol = false;

  void _validateEmail(String email) {
    final regex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    );
    setState(() => _isEmailValid = regex.hasMatch(email));
  }

  void _validatePassword(String password) {
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
      _hasSymbol = password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
    });
  }

  bool get _isPasswordValid =>
      _hasMinLength &&
      _hasUppercase &&
      _hasLowercase &&
      _hasNumber &&
      _hasSymbol;

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
      if (_nameController.text.trim().isEmpty) {
        _showModalPrompt(
          'Incomplete Data',
          'Please enter your full name.',
          isError: true,
        );
        return false;
      }
      if (!_isEmailValid) {
        _showModalPrompt(
          'Invalid Email',
          'Please enter a properly formatted email address.',
          isError: true,
        );
        return false;
      }
      if (!_isPasswordValid) {
        _showModalPrompt(
          'Weak Password',
          'Please meet all the password security requirements.',
          isError: true,
        );
        return false;
      }
      // --- NEW: DPA Consent Validation ---
      if (!_hasAgreedToPrivacy) {
        _showModalPrompt(
          'Consent Required',
          'In compliance with the Data Privacy Act of 2012, please review and accept the Privacy Policy before proceeding.',
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

  Future<void> _checkLocalDataAndPrompt(User user) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final localInventory = await db
          .query('user_appliances')
          .catchError((_) => <Map<String, dynamic>>[]);

      if (localInventory.isNotEmpty) {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: const Text(
              'Sync Offline Data',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'We found appliances saved locally from Guest Mode. Do you want to merge them into your new cloud account?',
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  setState(() => _isLoading = true);
                  await db.delete('user_appliances').catchError((_) => 0);
                  if (mounted) _showOnboardingPrompt();
                },
                child: const Text(
                  'Discard Local',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  setState(() => _isLoading = true);
                  await SyncService.mergeOfflineDataToCloud(user.id);
                  await SyncService.syncGlobalPresets();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const DashboardShell()),
                      (route) => false,
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.appYellow,
                  foregroundColor: Colors.black87,
                ),
                child: const Text('Merge to Cloud'),
              ),
            ],
          ),
        );
      } else {
        if (mounted) _showOnboardingPrompt();
      }
    } catch (e) {
      if (mounted) _showOnboardingPrompt();
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
            'privacy_consent': true, // Keep an audit trail in Supabase metadata
            'consent_timestamp': DateTime.now().toUtc().toIso8601String(),
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

      final now = DateTime.now();
      int prevMonth = now.month - 1;
      int prevYear = now.year;
      if (prevMonth == 0) {
        prevMonth = 12;
        prevYear--;
      }
      final String paddedMonth = prevMonth.toString().padLeft(2, '0');
      final String periodMonth = '$prevYear-$paddedMonth-01';
      final int lastDay = DateTime(prevYear, prevMonth + 1, 0).day;
      final String endDate = '$prevYear-$paddedMonth-$lastDay';
      final String periodName = _getPreviousBillingMonth();

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

      await db.insert('recording_periods', {
        'period_month': periodMonth,
        'period_name': periodName,
        'start_date': periodMonth,
        'end_date': endDate,
        'billing_rate': tariff,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      if (user != null) {
        await Supabase.instance.client.from('recording_periods').upsert({
          'user_id': user.id,
          'period_month': periodMonth,
          'period_name': periodName,
          'start_date': periodMonth,
          'end_date': endDate,
          'billing_rate': tariff,
        }, onConflict: 'user_id, period_month');
      }

      if (mounted) await _checkLocalDataAndPrompt(user!);
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          CustomTextField(
                            controller: _nameController,
                            hint: 'Full Name',
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 15),

                          TextField(
                            controller: _emailController,
                            onChanged: _validateEmail,
                            style: TextStyle(color: textColor),
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: 'Email Address',
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: hintColor,
                              ),
                              suffixIcon: _emailController.text.isNotEmpty
                                  ? Icon(
                                      _isEmailValid
                                          ? Icons.check_circle
                                          : Icons.error,
                                      color: _isEmailValid
                                          ? Colors.green
                                          : AppColors.adminRed,
                                    )
                                  : null,
                              errorText:
                                  _emailController.text.isNotEmpty &&
                                      !_isEmailValid
                                  ? 'Please enter a valid email format (e.g., name@email.com)'
                                  : null,
                              filled: true,
                              fillColor: surfaceColor.withOpacity(0.5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),

                          TextField(
                            controller: _passwordController,
                            onChanged: _validatePassword,
                            obscureText: true,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              hintText: 'Create a password',
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: hintColor,
                              ),
                              filled: true,
                              fillColor: surfaceColor.withOpacity(0.5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: surfaceColor.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Password Requirements:',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildRequirementRow(
                                  'At least 8 characters',
                                  _hasMinLength,
                                  hintColor,
                                ),
                                _buildRequirementRow(
                                  'One uppercase letter (A-Z)',
                                  _hasUppercase,
                                  hintColor,
                                ),
                                _buildRequirementRow(
                                  'One lowercase letter (a-z)',
                                  _hasLowercase,
                                  hintColor,
                                ),
                                _buildRequirementRow(
                                  'One number (0-9)',
                                  _hasNumber,
                                  hintColor,
                                ),
                                _buildRequirementRow(
                                  'One special character (!@#\$&*)',
                                  _hasSymbol,
                                  hintColor,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // --- NEW: DPA Explicit Consent Checkbox ---
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _hasAgreedToPrivacy
                                  ? Colors.green.withOpacity(0.08)
                                  : surfaceColor.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _hasAgreedToPrivacy
                                    ? Colors.green.withOpacity(0.4)
                                    : textColor.withOpacity(0.12),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Checkbox(
                                  value: _hasAgreedToPrivacy,
                                  activeColor: AppColors.appYellow,
                                  checkColor: Colors.black87,
                                  onChanged: (val) => setState(
                                    () => _hasAgreedToPrivacy = val ?? false,
                                  ),
                                ),
                                Expanded(
                                  child: Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        'I agree to the ',
                                        style: TextStyle(
                                          color: hintColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const PrivacyPolicyScreen(),
                                          ),
                                        ),
                                        child: const Text(
                                          'Privacy Policy',
                                          style: TextStyle(
                                            color: AppColors.appYellow,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        ' (R.A. 10173).',
                                        style: TextStyle(
                                          color: hintColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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

  Widget _buildRequirementRow(String text, bool isMet, Color hintColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isMet ? Colors.greenAccent : hintColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isMet ? Colors.white : hintColor,
              fontSize: 12,
            ),
          ),
        ],
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
