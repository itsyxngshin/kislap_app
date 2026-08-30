import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class AdminManualScreen extends StatelessWidget {
  const AdminManualScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Admin Manual', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false, // Root tab
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SYSTEM MANAGEMENT GUIDE', style: TextStyle(color: AppColors.adminRed, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 20),

            _buildManualSection(
              context,
              '1. Preset Management',
              'The Presets tab allows you to globally Add, Edit, and Delete appliance baselines. Changes made here will immediately sync to all users worldwide upon their next login. Ensure wattage figures are based on verified Philippine audits (e.g., DOE or Meralco benchmarks).'
            ),

            _buildManualSection(
              context,
              '2. Adding New Categories',
              'When adding a new preset, assign it to a logical category (e.g., "Cooling", "Kitchen"). This keeps the user dropdown menus organized and easy to navigate.'
            ),

            _buildManualSection(
              context,
              '3. Cloud Synchronization',
              'Presets are securely stored in Supabase. You must have an active internet connection to publish updates. If an error occurs during saving, check your network or contact the database administrator.'
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualSection(BuildContext context, String title, String content) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(content, style: TextStyle(color: textColor.withOpacity(0.7), height: 1.5, fontSize: 13)),
        ],
      ),
    );
  }
}
