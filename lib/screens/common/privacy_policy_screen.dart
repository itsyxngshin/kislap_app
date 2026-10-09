import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../providers/settings_provider.dart';

class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = textColor.withOpacity(0.7);
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final isPh = ref.watch(settingsProvider).language == 'ph';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          isPh ? 'Patakaran sa Pagkapribado' : 'Privacy Policy',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: const BackButton(),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.appYellow.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.appYellow.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_outlined, color: AppColors.appYellow, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isPh
                          ? 'Sumusunod ang Kislap sa Data Privacy Act ng 2012 (R.A. 10173) at mga patakaran ng Google Play/App Store.'
                          : 'Kislap complies with the Philippine Data Privacy Act of 2012 (R.A. 10173), Google Play, and App Store guidelines.',
                      style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildSection(
              context,
              title: isPh ? '1. Impormasyong Kinokolekta Namin' : '1. Information We Collect',
              body: isPh
                  ? '• Pangalan at email para sa account creation o Google OAuth.\n'
                    '• Buwanang budget ng kuryente at utility rates (₱/kWh).\n'
                    '• Load data ng appliances (pangalan, wattage, oras ng paggamit).\n'
                    '• Hindi kailanman ibinebenta ang iyong data sa mga third-party.'
                  : '• Full name and email address for account creation or Google Sign-In.\n'
                    '• Target monthly electricity budget and utility tariff rates.\n'
                    '• Appliance load data (wattage, quantities, usage hours).\n'
                    '• We never sell or trade your data to third-party ad networks.',
              surfaceColor: surfaceColor,
              textColor: textColor,
              hintColor: hintColor,
            ),

            _buildSection(
              context,
              title: isPh ? '2. Layunin at Legal na Basehan' : '2. Purpose & Legal Basis',
              body: isPh
                  ? 'Pinoproseso ang datos batay sa iyong explicit consent upang makalkula ang konsumo, makabuo ng smart schedule para makatipid, at mai-save ang appliance profile sa cloud.'
                  : 'Data is processed under your explicit consent solely to compute real-time kWh consumption, generate bill-saving schedules, and synchronize your inventory.',
              surfaceColor: surfaceColor,
              textColor: textColor,
              hintColor: hintColor,
            ),

            _buildSection(
              context,
              title: isPh ? '3. Pagbura ng Account at Datos (Data Erasure)' : '3. Account & Data Deletion',
              body: isPh
                  ? 'Maaari mong burahin nang tuluyan ang iyong account at lahat ng datos sa cloud anumang oras sa pamamagitan ng "Delete Account" button sa Settings.'
                  : 'You retain the right to permanently delete your account and wipe all associated cloud records via the in-app "Delete Account" button in the Settings menu.',
              surfaceColor: surfaceColor,
              textColor: textColor,
              hintColor: hintColor,
            ),

            _buildSection(
              context,
              title: isPh ? '4. Data Protection Officer' : '4. Contact our DPO',
              body: isPh
                  ? 'Para sa mga katanungan sa privacy o pagtanggal ng datos:\nprivacy.kislap@gmail.com'
                  : 'For data privacy inquiries or deletion requests:\nprivacy.kislap@gmail.com',
              surfaceColor: surfaceColor,
              textColor: textColor,
              hintColor: hintColor,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String body,
    required Color surfaceColor,
    required Color textColor,
    required Color hintColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: textColor.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          Text(body, style: TextStyle(color: hintColor, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
}
