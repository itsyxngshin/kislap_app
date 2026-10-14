import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../providers/settings_provider.dart';

class TermsOfServiceScreen extends ConsumerWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = textColor.withOpacity(0.75);
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final isPh = ref.watch(settingsProvider).language == 'ph';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          isPh ? 'Mga Tuntunin ng Serbisyo' : 'Terms of Service',
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
                  const Icon(Icons.gavel_rounded, color: AppColors.appYellow, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isPh
                          ? 'Kasunduan sa Paggamit: Sa pag-download o paggamit ng Kislap, sumasang-ayon ka na sumailalim sa mga legal na tuntuning ito.'
                          : 'End-User Agreement: By downloading or using Kislap, you agree to be legally bound by these terms and conditions.',
                      style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildSection(
              context,
              title: isPh
                  ? '1. Kalikasan ng Serbisyo at Limitasyon sa Pananagutan (Estimates Disclaimer)'
                  : '1. Nature of Service & Estimation Disclaimer',
              body: isPh
                  ? '• Hindi Aktwal na Metro: Ang Kislap ay isang analytical tool na nagkakalkula ng tantyang konsumo (kWh at Peso) gamit ang pormulang: Daily kWh = (Wattage × Bilang × Oras) ÷ 1000. Hindi ito pisikal na nakakabit sa iyong metro ng kuryente.\n'
                    '• Pagkakaiba sa Aktwal na Bill: Ang tunay na konsumo ay maaaring magbago dahil sa inverter compressor cycles, temperatura ng paligid, kalumaan ng appliance, at buwanang pagbabago sa singil ng kooperatiba o Meralco.\n'
                    '• Walang Pananagutan sa "Bill Shock": Hindi ginagarantiya ng Kislap at ng mga developer nito na magtutugma nang eksakto ang tantya ng app sa iyong aktwal na electric bill, at wala kaming pananagutang pinansyal o legal sa anumang sobrang bayarin.'
                  : '• Not a Physical Meter: Kislap is a mathematical estimation utility computing projected energy usage via standard power formulas: Daily kWh = (Wattage × Quantity × Hours) ÷ 1000. It does not physically measure electrical currents.\n'
                    '• Real-World Variance: Actual electricity usage fluctuates due to inverter duty cycles, ambient temperature, voltage drops, appliance wear, and monthly utility generation/transmission rate adjustments.\n'
                    '• No Financial Liability: Kislap and its developers do not guarantee that projections will match your utility bill and hold zero financial or legal liability for billing discrepancies or budget overruns.',
              surfaceColor: surfaceColor,
              textColor: textColor,
              hintColor: hintColor,
            ),

            _buildSection(
              context,
              title: isPh
                  ? '2. Kaligtasang Elektrikal at Responsibilidad ng Gumagamit'
                  : '2. Electrical Safety & User Responsibilities',
              body: isPh
                  ? '• Katumpakan ng Input: Ikaw ang may buong responsibilidad sa paglalagay ng tamang wattage (W), bilang ng gamit, oras ng paggamit, at tamang tariff rate (₱/kWh) mula sa iyong bill.\n'
                    '• Ligtas na Paggamit ng Appliances: Ang mga rekomendasyon sa schedule at kVA load tier (Small, Medium, Large) ay gabay lamang at hindi kapalit ng lisensyadong electrician. Ikaw ang may responsibilidad sa pisikal na pagbuhay, pagpatay, at pagbabantay sa iyong mga appliances upang maiwasan ang overheating o sunog.'
                  : '• Input Accuracy: You are solely responsible for verifying the accuracy of the wattage (W), runtime hours, household kVA tier, and utility tariff rate (₱/kWh) entered into the app.\n'
                    '• Physical Safety: Scheduling recommendations and kVA load warnings are for informational guidance only and do not replace a licensed electrician. You retain full responsibility for safely operating and monitoring your physical appliances to prevent electrical hazards.',
              surfaceColor: surfaceColor,
              textColor: textColor,
              hintColor: hintColor,
            ),

            _buildSection(
              context,
              title: isPh
                  ? '3. Paggawa ng Account at Guest Mode'
                  : '3. User Accounts & Guest Mode Limitations',
              body: isPh
                  ? '• Registered Users: Responsibilidad mong pangalagaan ang seguridad ng iyong email at password o Google Sign-In account.\n'
                    '• Guest Mode: Kung gagamitin ang Guest Mode, ang iyong datos ay naka-save lamang sa lokal na SQLite database ng iyong telepono. Kapag na-uninstall ang app o nasira ang telepono nang hindi naisasalin (merge) sa cloud account, permanenteng mawawala ang lokal na datos.'
                  : '• Registered Accounts: You are responsible for maintaining the confidentiality of your login credentials and for all activities under your account.\n'
                    '• Guest Mode: In Guest Mode, data is saved strictly within your device\'s local SQLite storage. Uninstalling the app or losing your device before merging data to a cloud account will result in permanent data loss.',
              surfaceColor: surfaceColor,
              textColor: textColor,
              hintColor: hintColor,
            ),

            _buildSection(
              context,
              title: isPh
                  ? '4. Katanggap-tanggap na Paggamit at Patakaran sa Platform'
                  : '4. Acceptable Use & Developer Program Policies',
              body: isPh
                  ? 'Alinsunod sa Google Play Developer Program Policies, mahigpit na ipinagbabawal ang:\n'
                    '• Pag-reverse-engineer, pag-decompile, o pagnanakaw ng source code at optimization algorithm ng Kislap.\n'
                    '• Pag-spam, pag-abuso, o hindi awtorisadong pag-access sa aming Supabase cloud servers at APIs.\n'
                    '• Paggamit sa app sa anumang ilegal o mapanlinlang na gawain.\n'
                    'May karapatan kaming i-suspend o burahin ang iyong account nang walang abiso kung lalabagin ang mga tuntuning ito.'
                  : 'In compliance with Google Play Developer Program Policies, you agree not to:\n'
                    '• Reverse-engineer, decompile, or attempt to extract Kislap\'s source code or optimization algorithms.\n'
                    '• Abuse, spam, overload, or attempt unauthorized access to our Supabase cloud database or APIs.\n'
                    '• Use the application for any unlawful or fraudulent activity.\n'
                    'We reserve the right to suspend or terminate accounts that violate these rules.',
              surfaceColor: surfaceColor,
              textColor: textColor,
              hintColor: hintColor,
            ),

            _buildSection(
              context,
              title: isPh
                  ? '5. Distribusyon sa App Store at Cryptographic Signing'
                  : '5. Platform Distribution & App Signing',
              body: isPh
                  ? '• Ang kasunduang ito ay sa pagitan mo lamang at ng mga developer ng Kislap, at hindi ng Google LLC o Apple Inc. Walang obligasyon ang Google o Apple na magbigay ng maintenance o warranty para sa app.\n'
                    '• Ang opisyal na bersyon ng Kislap ay gumagamit ng Google Play App Signing upang matiyak na ligtas at hindi nabago ang code. Sumasang-ayon kang i-download lamang ang app mula sa opisyal na store at tanggapin ang mga kinakailangang software updates.'
                  : '• These Terms are between you and Kislap\'s developers only, not Google LLC or Apple Inc. The platform store bears no obligation to provide maintenance, support, or warranty services.\n'
                    '• Official Android releases are cryptographically signed and distributed via Google Play App Signing. You agree to install the app only from authorized channels and accept software updates necessary for security and accuracy.',
              surfaceColor: surfaceColor,
              textColor: textColor,
              hintColor: hintColor,
            ),

            _buildSection(
              context,
              title: isPh
                  ? '6. Pagsunod sa US Export Laws at Encryption'
                  : '6. US Export Laws, Encryption & Sanctions Compliance',
              body: isPh
                  ? 'Gumagamit ang Kislap ng cryptographic security functions (gaya ng TLS/HTTPS encryption at password hashing) kaya ito ay sumasailalim sa United States Export Administration Regulations (EAR) at internasyonal na batas sa export.\n'
                    'Sa paggamit ng app, pinatutunayan mo na:\n'
                    '• Wala ka sa anumang bansa na sumasailalim sa trade embargo o sanctions ng gobyerno ng Estados Unidos.\n'
                    '• Hindi ka kabilang sa anumang listahan ng mga pinagbabawalang partido (prohibited/restricted parties list).\n'
                    '• Hindi mo gagamitin o ipapamahagi ang app nang labag sa mga batas ng export.'
                  : 'Because Kislap utilizes cryptographic security functions (TLS/HTTPS data encryption and password hashing), it is subject to United States Export Administration Regulations (EAR) and international export laws.\n'
                    'By using the app, you represent and certify that:\n'
                    '• You are not located in or a resident of any country subject to a U.S. Government trade embargo or sanctions.\n'
                    '• You are not listed on any U.S. Government list of prohibited or restricted parties.\n'
                    '• You will comply with all applicable local and international export control laws.',
              surfaceColor: surfaceColor,
              textColor: textColor,
              hintColor: hintColor,
            ),

            _buildSection(
              context,
              title: isPh
                  ? '7. Availability ng Serbisyo at Pagkawala ng Datos'
                  : '7. Service Availability & Warranty Disclaimer',
              body: isPh
                  ? 'Ibinibigay ang Kislap nang "AS IS" at "AS AVAILABLE". Bagama\'t gumagamit kami ng Supabase at Vercel cloud architecture, hindi namin ginagarantiya na walang magiging downtime o aberya ang system. Hinihikayat ang mga user na regular na i-export ang kanilang schedule sa Excel (.xlsx) bilang lokal na backup.'
                  : 'Kislap is provided on an "AS IS" and "AS AVAILABLE" basis without warranties of any kind. We do not guarantee uninterrupted cloud service and are not liable for data loss caused by device failure or server downtime. Users are encouraged to back up their schedules using the in-app Excel (.xlsx) export tool.',
              surfaceColor: surfaceColor,
              textColor: textColor,
              hintColor: hintColor,
            ),

            _buildSection(
              context,
              title: isPh
                  ? '8. Karapatang-Ari (Intellectual Property) at Batas'
                  : '8. Intellectual Property & Governing Law',
              body: isPh
                  ? 'Ang lahat ng code, disenyo, logo, appliance presets, at optimization algorithms ng Kislap ay eksklusibong pag-aari ng mga developer nito sa ilalim ng R.A. 8293 (Intellectual Property Code of the Philippines). Ang mga tuntuning ito ay pinamamahalaan ng mga batas ng Republika ng Pilipinas.'
                  : 'All source code, UI designs, branding, appliance presets, and optimization algorithms within Kislap are the exclusive intellectual property of its developers under R.A. 8293 (Intellectual Property Code of the Philippines). These Terms are governed by the laws of the Republic of the Philippines.',
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
          Text(body, style: TextStyle(color: hintColor, fontSize: 13, height: 1.55)),
        ],
      ),
    );
  }
}