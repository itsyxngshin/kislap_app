import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // <-- 1. Import the package
import 'theme/app_colors.dart';
import 'screens/auth/onboarding_screen.dart';

void main() async {
  // 2. Ensure Flutter is ready before doing anything async
  WidgetsFlutterBinding.ensureInitialized();

  // 3. Initialize the Supabase connection
  await Supabase.initialize(
    url: 'YOUR_PROJECT_URL_HERE', // e.g., https://xyz.supabase.co
    anonKey: 'YOUR_ANON_PUBLIC_KEY_HERE', 
  );

  runApp(const KislapApp());
}

class KislapApp extends StatelessWidget {
  const KislapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kislap App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.appYellow, brightness: Brightness.dark),
      ),
      home: const OnboardingScreen(),
    );
  }
}