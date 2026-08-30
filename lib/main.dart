import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'services/sync_service.dart';
import 'screens/auth/splash_screen.dart'; // Handles initial branding & auth routing
import 'providers/settings_provider.dart';

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
    const ProviderScope(child: KislapApp()),
  );
}

class KislapApp extends ConsumerWidget {
  const KislapApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listens to the SQLite-backed settings provider!
    final currentSettings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'Kislap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: currentSettings.themeMode, // Instantly updates when toggled
      home: const SplashScreen(),
    );
  }

  Future<void> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      serverClientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
    );

    final googleUser = await googleSignIn.signIn();
    final googleAuth = await googleUser!.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (accessToken == null || idToken == null) throw 'Missing Google Auth Tokens';

    // Securely passes the Google tokens to your Supabase backend
    await Supabase.instance.client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }
}
