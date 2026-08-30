import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class AdminOverviewScreen extends StatelessWidget {
  const AdminOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('System Oversight', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false, // Hides the back button since this is a root tab
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.admin_panel_settings, size: 80, color: AppColors.adminRed.withOpacity(0.5)),
            const SizedBox(height: 20),
            Text('Admin Dashboard Active', style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Use the navigation bar below to manage presets.', style: TextStyle(color: textColor.withOpacity(0.6))),
          ],
        ),
      ),
    );
  }
}
