import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../providers/settings_provider.dart';
import 'admin_preset_management_screen.dart';
import 'admin_manual_screen.dart';
import 'admin_overview_screen.dart';

class AdminDashboardShell extends ConsumerStatefulWidget {
  const AdminDashboardShell({super.key});

  @override
  ConsumerState<AdminDashboardShell> createState() => _AdminDashboardShellState();
}

class _AdminDashboardShellState extends ConsumerState<AdminDashboardShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AdminOverviewScreen(), // High-level system metrics
    const AdminPresetManagementScreen(), // The Cloud CRUD Interface
    const AdminManualScreen(), // Static PDF/Text guide for admins
  ];

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = textColor.withOpacity(0.6);
    final isPh = ref.watch(settingsProvider).language == 'ph';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 30),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: textColor.withOpacity(0.1), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(Icons.admin_panel_settings_outlined, Icons.admin_panel_settings, isPh ? 'Oversight' : 'Oversight', 0, textColor, hintColor),
                  _buildNavItem(Icons.storage_outlined, Icons.storage, isPh ? 'Mga Preset' : 'Presets', 1, textColor, hintColor),
                  _buildNavItem(Icons.menu_book_outlined, Icons.menu_book, isPh ? 'Manwal' : 'Manual', 2, textColor, hintColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, IconData activeIcon, String label, int index, Color textColor, Color hintColor) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isSelected ? activeIcon : icon, color: isSelected ? AppColors.adminRed : hintColor, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: isSelected ? AppColors.adminRed : hintColor, fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
