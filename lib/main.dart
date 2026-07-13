import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // <-- 1. Import the package
import 'theme/app_colors.dart';
import 'screens/auth/onboarding_screen.dart';

void main() async {
  // 2. Ensure Flutter is ready before doing anything async
  WidgetsFlutterBinding.ensureInitialized();

  // 3. Initialize the Supabase connection
  await Supabase.initialize(
    url: 'https://yaquyjfowoyomxcibemy.supabase.co', // e.g., https://xyz.supabase.co
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlhcXV5amZvd295b214Y2liZW15Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM4ODU2MDEsImV4cCI6MjA5OTQ2MTYwMX0.l8u3R8elcOQnrj9ZcGhaQZAlErYYLJZ-bcF3LzCRHHM', 
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