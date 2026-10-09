import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/social_button.dart';
import '../../services/database_helper.dart';
import 'sign_up_screen.dart';
import '../common/privacy_policy_screen.dart'; // <-- Add Import
import '../dashboard/dashboard_shell.dart';
import '../admin/admin_dashboard_shell.dart';
import '../../services/sync_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isEmailValid = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateEmail(String email) {
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    );
    setState(() => _isEmailValid = emailRegex.hasMatch(email));
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

  Future<void> _checkLocalDataAndPrompt(User user) async {
    try {
      final db = await DatabaseHelper.instance.database;

      final localInventory = await db
          .query('user_appliances')
          .catchError((_) => <Map<String, dynamic>>[]);
      final localPeriods = await db
          .query('recording_periods')
          .catchError((_) => <Map<String, dynamic>>[]);

      if (localInventory.isNotEmpty || localPeriods.isNotEmpty) {
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
              'We found appliances and billing rates saved locally from Guest Mode. Do you want to merge them into your cloud account?',
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  setState(() => _isLoading = true);

                  await db.delete('user_appliances').catchError((_) => 0);
                  await db.delete('recording_periods').catchError((_) => 0);
                  await db.delete('user_settings').catchError((_) => 0);

                  await _handleSuccessfulLogin(user, bypassSync: true);
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

                  for (var p in localPeriods) {
                    await Supabase.instance.client
                        .from('recording_periods')
                        .upsert({
                          'user_id': user.id,
                          'period_month': p['period_month'],
                          'period_name': p['period_name'],
                          'start_date': p['start_date'],
                          'end_date': p['end_date'],
                          'billing_rate': p['billing_rate'],
                        }, onConflict: 'user_id, period_month');
                  }

                  await _handleSuccessfulLogin(user, bypassSync: false);
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
        await _handleSuccessfulLogin(user, bypassSync: false);
      }
    } catch (e) {
      await _handleSuccessfulLogin(user, bypassSync: false);
    }
  }

  Future<void> _handleSuccessfulLogin(
    User? user, {
    bool bypassSync = false,
  }) async {
    if (user != null) {
      if (!bypassSync) {
        await SyncService.mergeOfflineDataToCloud(user.id);
      }
      await SyncService.syncGlobalPresets();

      final profileData = await Supabase.instance.client
          .from('profiles')
          .select('role_id')
          .eq('id', user.id)
          .maybeSingle();
      final int roleId = profileData?['role_id'] as int? ?? 1;

      if (mounted) {
        if (roleId == 2) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboardShell()),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const DashboardShell()),
            (route) => false,
          );
        }
      }
    }
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (!_isEmailValid) {
      _showModalPrompt(
        'Invalid Email',
        'Please enter a valid email format.',
        isError: true,
      );
      return;
    }
    if (password.isEmpty) {
      _showModalPrompt(
        'Missing Password',
        'Please enter your password.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authResponse = await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: password);
      if (mounted) {
        await _checkLocalDataAndPrompt(authResponse.user!);
      }
    } on AuthException catch (e) {
      if (mounted)
        _showModalPrompt('Authentication Failed', e.message, isError: true);
      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted)
        _showModalPrompt('Unexpected Error', e.toString(), isError: true);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'https://kislap-app.vercel.app',
      );
    } catch (e) {
      if (mounted) {
        _showModalPrompt('Google Sign-In Error', e.toString(), isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = textColor.withOpacity(0.6);
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: const BackButton(),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.show_chart_rounded,
                size: 50,
                color: AppColors.appYellow,
              ),
              const SizedBox(height: 20),

              Text(
                'Welcome back',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to keep tracking your usage.',
                style: TextStyle(color: hintColor, fontSize: 14),
              ),
              const SizedBox(height: 40),

              Text(
                'Email',
                style: TextStyle(
                  color: textColor.withOpacity(0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                onChanged: _validateEmail,
                style: TextStyle(color: textColor),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'name@email.com',
                  prefixIcon: Icon(Icons.email_outlined, color: hintColor),
                  suffixIcon: _emailController.text.isNotEmpty
                      ? Icon(
                          _isEmailValid ? Icons.check_circle : Icons.error,
                          color: _isEmailValid
                              ? Colors.green
                              : AppColors.adminRed,
                        )
                      : null,
                  errorText: _emailController.text.isNotEmpty && !_isEmailValid
                      ? 'Please enter a valid email format'
                      : null,
                  filled: true,
                  fillColor: surfaceColor.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Password',
                style: TextStyle(
                  color: textColor.withOpacity(0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _passwordController,
                hint: '••••••••',
                icon: Icons.lock_outline,
                isPassword: true,
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: AppColors.appYellow,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _signIn,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.appYellow,
                    foregroundColor: Colors.black87,
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
                            color: Colors.black87,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Sign in',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 30),

              Center(
                child: Text(
                  'or continue with',
                  style: TextStyle(color: hintColor, fontSize: 12),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: SocialButton(
                  icon: Icons.g_mobiledata,
                  label: 'Sign in with Google',
                  onPressed: _isLoading ? () {} : _signInWithGoogle,
                ),
              ),
              const SizedBox(height: 30),

              Center(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignUpScreen()),
                  ),
                  child: Text.rich(
                    TextSpan(
                      text: 'New here? ',
                      style: TextStyle(color: hintColor, fontSize: 13),
                      children: const [
                        TextSpan(
                          text: 'Create an Account',
                          style: TextStyle(
                            color: AppColors.appYellow,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // --- NEW: Google OAuth Privacy & DPA Footer ---
              const SizedBox(height: 40),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyScreen(),
                    ),
                  ),
                  child: Text(
                    'Privacy Policy & DPA Notice',
                    style: TextStyle(
                      color: hintColor.withOpacity(0.8),
                      fontSize: 11,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
