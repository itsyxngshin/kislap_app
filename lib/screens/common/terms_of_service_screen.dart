import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../providers/settings_provider.dart';

class TermsOfServiceScreen extends ConsumerWidget {
  const TermsOfServiceScreen({super.key});

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
          isPh ? 'Mga Tuntunin ng Serbisyo' : 'Terms of Service',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
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
                  const Icon(
                    Icons.gavel_rounded,
                    color: AppColors.appYellow,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isPh
                          ? 'Sa paggamit ng Kislap, sumasang-ayon ka sa mga sumusunod na tuntunin.'
                          : 'By using Kislap, you agree to the following terms and conditions.',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildSection(
              context,
              title: isPh
                  ? '1. Pagtatantya Lamang (Estimates)'
                  : '1. Estimates Only & Liability',
              body: isPh
                  ? 'Ang Kislap ay nagbibigay lamang ng pagtatantya (estimates) ng konsumo batay sa iyong nilagay na datos. Hindi ito aktwal na metro ng kuryente. Hindi mananagot ang Kislap sa anumang pagkakaiba ng kalkulasyon nito kumpara sa iyong aktwal na bill sa kuryente.'
                  : 'Kislap provides energy and cost projections based strictly on user inputs. It is not an actual electric meter. Kislap and its developers are not financially or legally liable for any discrepancies between the app\'s estimates and your actual utility bills.',
              surfaceColor: surfaceColor,
              textColor: textColor,
              hintColor: hintColor,
            ),

            _buildSection(
              context,
              title: isPh
                  ? '2. Responsibilidad ng Gumagamit'
                  : '2. User Responsibilities',
              body: isPh
                  ? 'Responsibilidad mo na ilagay ang tamang wattage at oras ng gamit. Ang app ay nagbibigay lamang ng rekomendasyon; ikaw pa rin ang may kontrol sa pisikal na pagpatay at pagbuhay ng iyong mga appliances.'
                  : 'You are responsible for ensuring accurate wattage and usage hours. The app provides scheduling recommendations, but you retain full responsibility for safely operating your appliances.',
              surfaceColor: surfaceColor,
              textColor: textColor,
              hintColor: hintColor,
            ),

            _buildSection(
              context,
              title: isPh
                  ? '3. Availability ng Serbisyo at Datos'
                  : '3. Service Availability & Data Loss',
              body: isPh
                  ? 'Ibinibigay ang app na "AS IS". Hindi namin ginagarantiya na walang magiging downtime ang aming cloud servers, at hindi kami mananagot kung sakaling mawala ang iyong lokal na datos dahil sa pagkasira ng iyong device.'
                  : 'The app is provided "AS IS". We do not guarantee uninterrupted cloud service and are not liable for the loss of appliance logs or data due to device failures, app uninstalls, or server downtime.',
              surfaceColor: surfaceColor,
              textColor: textColor,
              hintColor: hintColor,
            ),

            _buildSection(
              context,
              title: isPh ? '4. Pagputol ng Account' : '4. Account Termination',
              body: isPh
                  ? 'May karapatan kaming i-suspend o burahin ang iyong account kung mapatunayan na inaabuso mo ang aming system, servers, o nilalabag ang mga tuntuning ito.'
                  : 'We reserve the right to suspend or permanently delete your account if you attempt to reverse-engineer the app, spam our database, or violate these terms.',
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
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(color: hintColor, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
