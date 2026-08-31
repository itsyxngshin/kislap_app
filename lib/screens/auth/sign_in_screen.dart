import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/social_button.dart';
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- NEW: Reusable Modal Prompt ---
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
              Navigator.pop(ctx); // Close dialog
              if (onSuccess != null) onSuccess(); // Trigger routing if successful
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
      await SyncService.mergeOfflineDataToCloud(user.id);
      await SyncService.syncGlobalPresets();

      final profileData = await Supabase.instance.client
          .from('profiles')
          .select('role_id')
          .eq('id', user.id)
          .maybeSingle();

      final int roleId = profileData?['role_id'] as int? ?? 1;

      if (mounted) {
        if (roleId == 2) {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AdminDashboardShell()), (route) => false);
        } else {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const DashboardShell()), (route) => false);
        }
      }
    }
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showModalPrompt('Missing Information', 'Please enter both your email and password.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authResponse = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Trigger success modal, then route upon clicking OK
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
              CustomTextField(controller: _emailController, hint: 'name@email.com', icon: Icons.email_outlined),
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
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpScreen())),
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
