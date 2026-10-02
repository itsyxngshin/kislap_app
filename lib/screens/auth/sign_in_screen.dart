import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/social_button.dart';
import '../../services/database_helper.dart';
import 'sign_up_screen.dart';
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
    final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    setState(() => _isEmailValid = emailRegex.hasMatch(email));
  }

  void _showModalPrompt(String title, String message, {bool isError = false, VoidCallback? onSuccess}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isError ? AppColors.adminRed.withOpacity(0.3) : AppColors.appYellow.withOpacity(0.3)),
        ),
        title: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: isError ? AppColors.adminRed : AppColors.appYellow, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
          ],
        ),
        content: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8), height: 1.4)),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (onSuccess != null) onSuccess();
            },
            style: FilledButton.styleFrom(
              backgroundColor: isError ? AppColors.adminRed : AppColors.appYellow,
              foregroundColor: isError ? Colors.white : Colors.black87,
            ),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSuccessfulLogin(User? user) async {
    if (user != null) {
      final db = await DatabaseHelper.instance.database;
      final localInventory = await db.query('user_inventory');
      final localPeriods = await db.query('recording_periods');

      if (localInventory.isNotEmpty || localPeriods.isNotEmpty) {
        if (!mounted) return;
        _showMergePrompt(user, localInventory, localPeriods);
      } else {
        _completeLoginFlow(user.id);
      }
    }
  }

  void _showMergePrompt(User user, List<Map<String, dynamic>> localInventory, List<Map<String, dynamic>> localPeriods) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sync Offline Data', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('We found appliances and billing rates saved locally on this device. Do you want to merge them into your cloud account?'),
        actions: [
          TextButton(
            onPressed: () async {
              final db = await DatabaseHelper.instance.database;
              await db.delete('user_inventory');
              await db.delete('recording_periods');
              Navigator.pop(ctx);
              _completeLoginFlow(user.id);
            },
            child: const Text('Discard Local', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              await _mergeDataToCloud(user.id, localInventory, localPeriods);
              setState(() => _isLoading = false);
              _completeLoginFlow(user.id);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.appYellow, foregroundColor: Colors.black87),
            child: const Text('Merge to Cloud', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _mergeDataToCloud(String userId, List<Map<String, dynamic>> inventory, List<Map<String, dynamic>> periods) async {
    try {
      final supabase = Supabase.instance.client;

      // Sync local offline power rates
      for (var p in periods) {
        await supabase.from('recording_periods').upsert({
          'user_id': userId,
          'period_month': p['period_month'],
          'period_name': p['period_name'],
          'start_date': p['start_date'],
          'end_date': p['end_date'],
          'billing_rate': p['billing_rate'],
        }, onConflict: 'user_id, period_month');
      }

      // Sync local appliances
      for (var i in inventory) {
        await supabase.from('appliances').insert({
          'user_id': userId,
          'name': i['custom_name'],
          'watts': i['preset_wattage'],
          'quantity': i['quantity'],
          'hours_per_day': i['user_assigned_hours'],
        });
      }

      // Sync baseline config
      final db = await DatabaseHelper.instance.database;
      final settings = await db.query('user_settings', limit: 1);
      if (settings.isNotEmpty) {
        await supabase.from('profiles').update({
          'tariff_rate': settings.first['tariff_rate'],
          'monthly_budget': settings.first['monthly_budget'],
          'household_size': settings.first['household_size'],
        }).eq('id', userId);
      }
    } catch (e) {
      debugPrint('Merge Error: $e');
    }
  }

  Future<void> _completeLoginFlow(String userId) async {
    await SyncService.mergeOfflineDataToCloud(userId);
    await SyncService.syncGlobalPresets();

    final profileData = await Supabase.instance.client.from('profiles').select('role_id').eq('id', userId).maybeSingle();
    final int roleId = profileData?['role_id'] as int? ?? 1;

    if (mounted) {
      if (roleId == 2) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AdminDashboardShell()), (route) => false);
      } else {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const DashboardShell()), (route) => false);
      }
    }
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (!_isEmailValid || password.isEmpty) {
      _showModalPrompt('Invalid Input', 'Please enter a valid email and password.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authResponse = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (mounted) {
        _showModalPrompt(
          'Login Successful',
          'Welcome back to Kislap! Let\'s get started.',
          isError: false,
          onSuccess: () => _handleSuccessfulLogin(authResponse.user),
        );
      }

    } on AuthException catch (e) {
      if (mounted) _showModalPrompt('Authentication Failed', e.message, isError: true);
    } catch (e) {
      if (mounted) _showModalPrompt('Unexpected Error', e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      appBar: AppBar(leading: const BackButton()),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.show_chart_rounded, size: 50, color: AppColors.appYellow),
              const SizedBox(height: 20),

              Text('Welcome back', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 8),
              Text('Sign in to keep tracking your usage.', style: TextStyle(color: hintColor, fontSize: 14)),
              const SizedBox(height: 40),

              Text('Email', style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              // Email Field with Dynamic Validation Check and Error Text
                            TextField(
                              controller: _emailController,
                              onChanged: _validateEmail,
                              style: TextStyle(color: textColor),
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: 'kislap@email.com',
                                prefixIcon: Icon(Icons.email_outlined, color: hintColor),
                                suffixIcon: _emailController.text.isNotEmpty
                                    ? Icon(_isEmailValid ? Icons.check_circle : Icons.error, color: _isEmailValid ? Colors.green : AppColors.adminRed)
                                    : null,
                                // Provide text error feedback to user
                                errorText: _emailController.text.isNotEmpty && !_isEmailValid
                                    ? 'Please enter a valid email format'
                                    : null,
                                filled: true,
                                fillColor: surfaceColor.withOpacity(0.5),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                            ),
              const SizedBox(height: 20),

              Text('Password', style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              CustomTextField(controller: _passwordController, hint: '••••••••', icon: Icons.lock_outline, isPassword: true),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Forgot Password?', style: TextStyle(color: AppColors.appYellow, fontSize: 13, fontWeight: FontWeight.bold)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 2))
                    : const Text('Sign in', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),

              Center(child: Text('or continue with', style: TextStyle(color: hintColor, fontSize: 12))),
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
                  onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SignUpScreen())),
                  child: Text.rich(
                    TextSpan(
                      text: 'New here? ',
                      style: TextStyle(color: hintColor, fontSize: 13),
                      children: const [
                        TextSpan(text: 'Create an Account', style: TextStyle(color: AppColors.appYellow, fontWeight: FontWeight.bold)),
                      ],
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
}
