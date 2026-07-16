import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_text_field.dart';
import '../dashboard/dashboard_shell.dart';
import 'otp_verification_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields.'), backgroundColor: AppColors.adminRed),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Send the registration request to Supabase
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name}, // Matches new.raw_user_meta_data->>'full_name' in our SQL trigger
      );

      // 2. If successful, navigate directly into the app
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OtpVerificationScreen(email: email)),
        );
      }
    } on AuthException catch (e) {
      // Catch Supabase-specific errors (e.g., weak password, email taken)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.adminRed),
        );
      }
    } catch (e) {
      // Catch any other unexpected errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e'), backgroundColor: AppColors.adminRed),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Create Your Account', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              const Text('Start tracking usage in under a minute.', style: TextStyle(color: AppColors.textHintColor, fontSize: 14)),
              const SizedBox(height: 30),

              const Text('Full Name', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _nameController,
                hint: 'e.g., Adornado B. Cabalbag Jr.', 
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 20),

              const Text('Email', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _emailController,
                hint: 'name@email.com', 
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 20),

              const Text('Password', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _passwordController,
                hint: 'create a strong password', 
                icon: Icons.lock_outline, 
                isPassword: true,
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.appYellow,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 2))
                      : const Text('Create account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}