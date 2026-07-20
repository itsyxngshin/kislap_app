import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // <-- 1. Import Riverpod
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'screens/auth/onboarding_screen.dart';
import 'services/sync_service.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://yaquyjfowoyomxcibemy.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlhcXV5amZvd295b214Y2liZW15Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM4ODU2MDEsImV4cCI6MjA5OTQ2MTYwMX0.l8u3R8elcOQnrj9ZcGhaQZAlErYYLJZ-bcF3LzCRHHM',
  );

  // Background catalog sync check on application boot
  SyncService.syncCatalogDown();

  runApp(
    // 2. Wrap the entire app in a ProviderScope
    const ProviderScope(child: KislapApp()),
  );
}

class KislapApp extends StatelessWidget {
  const KislapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'Kislap',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          home: const OnboardingScreen(),
        );
      },
    );
  }
}
