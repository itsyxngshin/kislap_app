import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../auth/sign_in_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLocation = 'mainland'; 
  String _fullName = 'Loading...';
  String _email = '';
  
  bool _isDarkMode = true;
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
      }

      else{
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save location'), backgroundColor: AppColors.adminRed));
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
                    child: Text(_fullName.isNotEmpty ? _fullName[0].toUpperCase() : '?', style: const TextStyle(color: AppColors.navBackground, fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_fullName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(_email, style: const TextStyle(color: AppColors.textHintColor, fontSize: 14)),
                  ],
                )
              ],
            ),
            const SizedBox(height: 40),

            // Location Settings 
            const Text('LOCATION', style: TextStyle(color: AppColors.textHintColor, fontSize: 12, letterSpacing: 1.2)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.inputBackground.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _buildLocationOption('Mainland (₱11.0806/kWh)', 'mainland'),
                  _buildLocationOption('Island (₱11.3339/kWh)', 'island'),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            // UI Toggles (Local state for prototype)
            const Text('APPEARANCE', style: TextStyle(color: AppColors.textHintColor, fontSize: 12, letterSpacing: 1.2)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(color: AppColors.inputBackground.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16)),
              child: _buildSwitchOption(title: 'Dark Mode', icon: Icons.dark_mode_outlined, value: _isDarkMode, onChanged: (val) => setState(() => _isDarkMode = val)),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                // If they are a guest, send them to Log In. Otherwise, Sign Out.
                onPressed: _email == 'Not logged in' 
                    ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignInScreen()))
                    : _signOut,
                icon: Icon(_email == 'Not logged in' ? Icons.login : Icons.logout, color: AppColors.textHintColor),
                label: Text(_email == 'Not logged in' ? 'Log in' : 'Sign out', style: const TextStyle(color: AppColors.textHintColor, fontSize: 16)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.textHintColor), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationOption(String title, String value) {
    bool isSelected = _selectedLocation == value;
    return GestureDetector(
      onTap: () => _updateLocation(value),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: isSelected ? Colors.white.withValues(alpha: 0.05) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(color: isSelected ? Colors.white : AppColors.textHintColor, fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: isSelected ? AppColors.appYellow : AppColors.textHintColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchOption({required String title, IconData? icon, required bool value, required Function(bool) onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[Icon(icon, color: AppColors.appYellow, size: 20), const SizedBox(width: 12)],
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
          Switch(value: value, onChanged: onChanged, activeThumbColor: Colors.black87, activeTrackColor: AppColors.appYellow, inactiveThumbColor: AppColors.textHintColor, inactiveTrackColor: Colors.white10),
        ],
      ),
    );
  }
}