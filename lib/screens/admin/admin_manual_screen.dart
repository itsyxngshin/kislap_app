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
              '1. Preset Management (Catalog)',
              'The Presets tab allows you to globally Add, Edit, and Delete appliance baselines. When setting wattages, you must provide a Base Wattage, a Min Wattage, and a Max Wattage. This dictates the slider limits users see when adding appliances.'
            ),

            _buildManualSection(
              context,
              '2. Rate Management',
              'On the Oversight tab, you can input the monthly electricity rates (₱/kWh) for both Mainland and Island grids. Always ensure you are saving the rates for the correct Billing Month using the dropdown calendar.'
            ),

            _buildManualSection(
              context,
              '3. System-Wide Kill Switch',
              'The Maintenance Mode toggle acts as a kill switch. Activating it instantly locks out all standard users from the application. Use this only during critical database migrations or emergencies. You can provide a custom message explaining the downtime.'
            ),

            _buildManualSection(
              context,
              '4. Cloud Synchronization',
              'Presets and settings are securely stored in Supabase. You must have an active internet connection to publish updates. Changes made in the Admin Panel immediately affect all active users worldwide.'
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
