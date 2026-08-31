import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/social_button.dart';
import 'sign_up_screen.dart';
import '../dashboard/dashboard_shell.dart';
import '../admin/admin_dashboard_shell.dart'; // <-- Routing to the new Admin Shell
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

  // --- Centralized Routing & Sync Logic ---
  Future<void> _handleSuccessfulLogin(User? user) async {
    if (user != null) {
      // 1. Sync User's personal inventory
      await SyncService.mergeOfflineDataToCloud(user.id);

      // 2. Fetch the latest Admin-controlled presets
      await SyncService.syncGlobalPresets();

      // 3. Role-Based Access Control (RBAC) Check
      final profileData = await Supabase.instance.client
          .from('profiles')
          .select('role_id')
          .eq('id', user.id)
          .maybeSingle();

      final int roleId = profileData?['role_id'] as int? ?? 1;

      if (mounted) {
        if (roleId == 2) {
          // Route Admin
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboardShell()),
            (route) => false,
          );
        } else {
          // Route Standard User
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const DashboardShell()),
            (route) => false,
          );
        }
      }
    }
  }

  // --- Standard Email Sign In ---
  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authResponse = await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: password);

      await _handleSuccessfulLogin(authResponse.user);
    } on AuthException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.adminRed,
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.adminRed,
          ),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;

      // Removed .initialize() here because it is initialized globally in main.dart!
      final googleUser = await googleSignIn.authenticate();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) throw 'Missing Google ID Token.';

      final authResponse = await Supabase.instance.client.auth
          .signInWithIdToken(provider: OAuthProvider.google, idToken: idToken);

      await _handleSuccessfulLogin(authResponse.user);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In Error: $e'),
            backgroundColor: AppColors.adminRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              CustomTextField(
                controller: _emailController,
                hint: 'name@email.com',
                icon: Icons.email_outlined,
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

              // Updated Social Button Row
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
            ],
          ),
        ),
      ),
    );
  }
}
