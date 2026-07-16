import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../auth/sign_in_screen.dart';
import '../../main.dart'; // Needed for themeNotifier

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLocation = 'mainland'; 
  String _fullName = 'Loading...';
  String _email = '';
  
  // Removed the local _isDarkMode variable!
  final bool _highUsageAlerts = true;
  final bool _weeklySummary = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      
      if (user == null) {
        if (mounted) {
          setState(() {
            _fullName = 'Guest User';
            _email = 'Not logged in';
            _selectedLocation = 'mainland';
            _isLoading = false;
          });
        }
        return;
      } else {
        _email = user.email ?? '';
        
        final profileData = await supabase
            .from('profiles')
            .select('full_name, location')
            .eq('id', user.id)
            .single();

        if (mounted) {
          setState(() {
            _fullName = profileData['full_name'] ?? 'User';
            _selectedLocation = profileData['location'] ?? 'mainland';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateLocation(String newLocation) async {
    setState(() => _selectedLocation = newLocation);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await Supabase.instance.client
            .from('profiles')
            .update({'location': newLocation})
            .eq('id', userId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save location'), backgroundColor: AppColors.adminRed));
      }
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const SignInScreen()), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.appYellow));
    
    // Grabbing the dynamic colors for the current theme
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = textColor.withValues(alpha: 0.6);
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Row(
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: const BoxDecoration(color: AppColors.appYellow, shape: BoxShape.circle),
                  child: Center(
                    child: Text(_fullName.isNotEmpty ? _fullName[0].toUpperCase() : '?', style: const TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_fullName, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(_email, style: TextStyle(color: hintColor, fontSize: 14)),
                  ],
                )
              ],
            ),
            const SizedBox(height: 40),

            // Location Settings 
            Text('LOCATION', style: TextStyle(color: hintColor, fontSize: 12, letterSpacing: 1.2)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: surfaceColor.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _buildLocationOption('Mainland (₱11.0806/kWh)', 'mainland', textColor, hintColor),
                  _buildLocationOption('Island (₱11.3339/kWh)', 'island', textColor, hintColor),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            // Appearance Toggles
            Text('APPEARANCE', style: TextStyle(color: hintColor, fontSize: 12, letterSpacing: 1.2)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(color: surfaceColor.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16)),
              child: ValueListenableBuilder<ThemeMode>(
                valueListenable: themeNotifier,
                builder: (_, currentMode, __) {
                  return _buildSwitchOption(
                    title: 'Dark Mode', 
                    icon: currentMode == ThemeMode.dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined, 
                    value: currentMode == ThemeMode.dark, 
                    textColor: textColor,
                    onChanged: (isDark) {
                      themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
                    }
                  );
                },
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _email == 'Not logged in' 
                    ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignInScreen()))
                    : _signOut,
                icon: Icon(_email == 'Not logged in' ? Icons.login : Icons.logout, color: hintColor),
                label: Text(_email == 'Not logged in' ? 'Log in' : 'Sign out', style: TextStyle(color: hintColor, fontSize: 16)),
                style: OutlinedButton.styleFrom(side: BorderSide(color: hintColor), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationOption(String title, String value, Color textColor, Color hintColor) {
    bool isSelected = _selectedLocation == value;
    return GestureDetector(
      onTap: () => _updateLocation(value),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: isSelected ? textColor.withValues(alpha: 0.05) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(color: isSelected ? textColor : hintColor, fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: isSelected ? AppColors.appYellow : hintColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchOption({required String title, IconData? icon, required bool value, required Color textColor, required Function(bool) onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[Icon(icon, color: AppColors.appYellow, size: 20), const SizedBox(width: 12)],
              Text(title, style: TextStyle(color: textColor, fontSize: 14)),
            ],
          ),
          Switch(
            value: value, 
            onChanged: onChanged, 
            activeColor: AppColors.appYellow, 
            inactiveThumbColor: textColor.withValues(alpha: 0.5), 
            inactiveTrackColor: textColor.withValues(alpha: 0.1)
          ),
        ],
      ),
    );
  }
}