import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // State variables to hold the user's preferences
  String _selectedLocation = 'island'; 
  bool _isDarkMode = true;
  bool _highUsageAlerts = true;
  bool _weeklySummary = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Profile Header
            Row(
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: const BoxDecoration(
                    color: AppColors.appYellow,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('MF', style: TextStyle(color: AppColors.navBackground, fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 15),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Maria Francia', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('maria@gmail.com', style: TextStyle(color: AppColors.textHintColor, fontSize: 14)),
                  ],
                )
              ],
            ),
            const SizedBox(height: 40),

            // 2. Location Settings (The Rate Toggle)
            const Text('LOCATION', style: TextStyle(color: AppColors.textHintColor, fontSize: 12, letterSpacing: 1.2)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.inputBackground.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildLocationOption('Philippines - ₱11.0806/kWh', 'mainland'),
                  _buildLocationOption('Island - ₱11.3339/kWh', 'island'),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 3. Appearance Settings
            const Text('APPEARANCE', style: TextStyle(color: AppColors.textHintColor, fontSize: 12, letterSpacing: 1.2)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.inputBackground.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: _buildSwitchOption(
                title: 'Dark Mode',
                icon: Icons.dark_mode_outlined,
                value: _isDarkMode,
                onChanged: (val) => setState(() => _isDarkMode = val),
              ),
            ),
            const SizedBox(height: 30),

            // 4. Notification Settings
            const Text('NOTIFICATIONS', style: TextStyle(color: AppColors.textHintColor, fontSize: 12, letterSpacing: 1.2)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.inputBackground.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildSwitchOption(
                    title: 'High usage alerts',
                    value: _highUsageAlerts,
                    onChanged: (val) => setState(() => _highUsageAlerts = val),
                  ),
                  const Divider(color: Colors.white10, height: 1, indent: 16, endIndent: 16),
                  _buildSwitchOption(
                    title: 'Weekly summary',
                    value: _weeklySummary,
                    onChanged: (val) => setState(() => _weeklySummary = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // 5. Sign Out Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // This will eventually call Supabase Auth SignOut
                },
                icon: const Icon(Icons.logout, color: AppColors.textHintColor),
                label: const Text('Sign out', style: TextStyle(color: AppColors.textHintColor, fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.textHintColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for Location Radio Buttons
  Widget _buildLocationOption(String title, String value) {
    bool isSelected = _selectedLocation == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedLocation = value),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(color: isSelected ? Colors.white : AppColors.textHintColor, fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.appYellow : AppColors.textHintColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // Helper for Switch Toggles
  Widget _buildSwitchOption({required String title, IconData? icon, required bool value, required Function(bool) onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.appYellow, size: 20),
                const SizedBox(width: 12),
              ],
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.black87,
            activeTrackColor: AppColors.appYellow,
            inactiveThumbColor: AppColors.textHintColor,
            inactiveTrackColor: Colors.white10,
          ),
        ],
      ),
    );
  }
}