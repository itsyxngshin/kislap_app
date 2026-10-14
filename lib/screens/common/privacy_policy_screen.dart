import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../providers/settings_provider.dart';

class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

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
                          ? 'Sumusunod ang Kislap sa R.A. 10173 (Data Privacy Act of 2012), Google Play Data Safety, at Google API User Data Policies.'
                          : 'Kislap strictly complies with R.A. 10173 (Philippine Data Privacy Act of 2012), Google Play Data Safety, and Google API User Data Policies.',
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
                  ? '1. Mga Prinsipyo sa Data Privacy (R.A. 10173)'
                  : '1. Core Data Privacy Principles (R.A. 10173)',
              body: isPh
                  ? 'Pinangangalagaan ng Kislap ang iyong impormasyon batay sa tatlong pangunahing prinsipyo ng National Privacy Commission (NPC):\n'
                    '• Transparency: Ipinaaalam nang malinaw kung anong datos ang kinokolekta at bakit.\n'
                    '• Legitimate Purpose: Ginagamit lamang ang datos sa pagkalkula ng kuryente, pagbabadyet, at pag-optimize ng appliances.\n'
                    '• Proportionality: Kinokolekta lamang ang pinakamababang impormasyon na kailangan upang gumana ang app.'
                  : 'Kislap processes personal and household data strictly under the statutory principles of the National Privacy Commission (NPC):\n'
                    '• Transparency: Clear disclosure of what data is collected and how it is handled.\n'
                    '• Legitimate Purpose: Data is used exclusively for energy auditing, budget tracking, and schedule optimization.\n'
                    '• Proportionality: We collect only the minimum dataset required to operate the app.',
              surfaceColor: surfaceColor,
              textColor: textColor,
              hintColor: hintColor,
            ),

            _buildSection(
              context,
              title: isPh
                  ? '2. Detalyadong Impormasyon na Kinokolekta Namin'
                  : '2. Detailed Information We Collect',
              body: isPh
                  ? '• Pagkakakilanlan at Account: Buong pangalan, email address, user UUID, at consent timestamp. Ang mga password ay sumasailalim sa cryptographic salting at hashing—hindi kailanman nakikita o sine-save ng Kislap ang iyong plain-text password.\n'
                    '• Google Sign-In (OAuth 2.0): Kung magla-login gamit ang Google, kinukuha lamang namin ang iyong basic profile (Pangalan, Email, at Avatar URL) sa pamamagitan ng Google People API. Hindi namin ina-access ang iyong Google Contacts, Drive, o lokasyon.\n'
                    '• Financial at Tariff Baseline: Buwanang budget sa kuryente (₱), utility tariff rate (₱/kWh), at petsa ng billing cycle.\n'
                    '• Appliance Load at kVA Inventory: Pangalan ng appliance, kategorya, wattage (W), bilang, oras ng paggamit, essential lock status, at kVA household classification (Small, Medium, Large).\n'
                    '• Hindi Kinokolekta: Hindi kami nangongolekta ng GPS location, contacts, camera/microphone audio, o credit card details.'
                  : '• Identity & Credentials: Full name, email address, user UUID, and consent timestamps. Passwords are cryptographically salted and hashed—plain-text passwords are never visible or stored.\n'
                    '• Google Sign-In (OAuth 2.0): When authenticating via Google, we access only basic profile details (Name, Email, Avatar URL) via the Google People API. We never access your Contacts, Google Drive, or private files.\n'
                    '• Financial & Tariff Baselines: Monthly electricity budget cap (₱), utility tariff rate (₱/kWh), and billing period dates.\n'
                    '• Appliance Load & kVA Profiles: Custom appliance names, categories, wattage (W), quantities, target vs. optimized runtime hours, essential lock status, and household kVA tier (Small, Medium, Large).\n'
                    '• What We Do Not Collect: We do not collect GPS location, phone contacts, microphone/camera data, or payment card numbers.',
              surfaceColor: surfaceColor,
              textColor: textColor,
              hintColor: hintColor,
            ),

            _buildSection(
              context,
              title: isPh
                  ? '3. Layunin at Legal na Basehan ng Pagproseso'
                  : '3. Purpose & Legal Basis of Processing',
              body: isPh
                  ? 'Sa ilalim ng Section 12 ng R.A. 10173, pinoproseso namin ang iyong datos batay sa iyong malinaw na pahintulot (explicit consent) upang:\n'
                    '• Kalkulahin ang arawan at buwanang konsumo sa kWh at Philippine Peso (₱).\n'
                    '• Magbigay ng awtomatikong rekomendasyon sa pagbabawas ng oras ng appliances kapag lumampas sa iyong target budget.\n'
                    '• I-save at i-sync ang iyong appliance inventory at historical billing records sa pagitan ng iyong cellphone at cloud.\n'
                    '• Makabuo ng nada-download na Excel (.xlsx) optimization report sa iyong device.'
                  : 'Under Section 12 of R.A. 10173, data is processed based on your explicit and informed consent for the following purposes:\n'
                    '• Computing real-time daily and monthly kilowatt-hour (kWh) and Peso (₱) estimates.\n'
                    '• Running the optimization algorithm to recommend reduced runtime hours when projections exceed your budget.\n'
                    '• Synchronizing appliance inventories and historical billing periods across your devices.\n'
                    '• Generating downloadable Excel (.xlsx) optimization reports locally on your device.',
              surfaceColor: surfaceColor,
              textColor: textColor,
              hintColor: hintColor,
            ),

            _buildSection(
              context,
              title: isPh
                  ? '4. Seguridad, Cryptography at Pag-iimbak ng Datos'
                  : '4. Storage Architecture & Cryptographic Security',
              body: isPh
                  ? '• Guest Mode (Offline SQLite): Ang datos sa Guest Mode ay nakaimbak lamang sa pribadong SQLite database sa loob ng iyong cellphone at hindi ipinapadala sa aming servers maliban kung magre-register ka at pipiliing i-merge ito.\n'
                    '• Cloud Database (Supabase PostgreSQL): Para sa mga registered users, ang datos ay protektado ng Row Level Security (RLS), kung saan tanging ang iyong authenticated token lamang ang makakabasa o makakapagbago ng iyong sariling records.\n'
                    '• Encryption: Lahat ng komunikasyon sa pagitan ng app at cloud ay naka-encrypt gamit ang TLS 1.2/1.3 (HTTPS), at AES-256 encryption naman sa cloud storage.\n'
                    '• Auto-Wipe sa Pag-logout: Kapag nag-sign out ka, awtomatikong binubura ng Kislap ang lokal na SQLite cache upang walang maiwang pribadong datos sa hiniram o shared na device.'
                  : '• Guest Mode (Local SQLite): Guest data remains strictly sandboxed inside your device\'s local SQLite storage and is never uploaded to our servers unless you register and explicitly choose "Merge to Cloud."\n'
                    '• Cloud Database (Supabase PostgreSQL): Registered user data is protected by strict Row Level Security (RLS) policies, ensuring only your authenticated session token can read or mutate your records.\n'
                    '• Cryptographic Encryption: All data in transit is encrypted via TLS 1.2/1.3 (HTTPS), and cloud databases are encrypted at rest (AES-256).\n'
                    '• Sign-Out Cache Wiping: Logging out automatically clears local SQLite tables on your device to prevent data exposure on shared phones.',
              surfaceColor: surfaceColor,
              textColor: textColor,
              hintColor: hintColor,
            ),

            _buildSection(
              context,
              title: isPh
                  ? '5. Mga Third-Party Sub-Processor at Walang Pagbebenta ng Datos'
                  : '5. Third-Party Sub-Processors & No-Sale Guarantee',
              body: isPh
                  ? 'HINDI namin kailanman ibinebenta, pinauupahan, o ipinagpapalit ang iyong personal o household energy data sa mga advertiser o data brokers. Gumagamit lamang kami ng mga pinagkakatiwalaang cloud infrastructure providers:\n'
                    '• Supabase Inc.: Para sa secure na PostgreSQL cloud database at authentication.\n'
                    '• Google Identity Services: Para sa ligtas na OAuth 2.0 Sign-In (sumusunod sa Google API Services User Data Policy).\n'
                    '• Vercel Inc.: Para sa web application hosting.'
                  : 'We NEVER sell, rent, trade, or monetize your personal or household energy data to third-party advertisers or data brokers. We rely solely on trusted infrastructure sub-processors:\n'
                    '• Supabase Inc.: Cloud PostgreSQL database hosting and authentication.\n'
                    '• Google Identity Services: OAuth 2.0 authentication (adhering strictly to the Google API Services User Data Policy).\n'
                    '• Vercel Inc.: Secure web application delivery and hosting.',
              surfaceColor: surfaceColor,
              textColor: textColor,
              hintColor: hintColor,
            ),

            _buildSection(
              context,
              title: isPh
                  ? '6. Pagpapanatili at Pagbura ng Account (Data Deletion)'
                  : '6. Data Retention & Mandatory Account Deletion',
              body: isPh
                  ? 'Pinananatili lamang namin ang iyong datos habang aktibo ang iyong account. Alinsunod sa R.A. 10173, Google Play, at App Store rules, maaari mong burahin ang iyong account anumang oras:\n'
                    '• In-App Deletion: Pumunta sa Settings > Account > Delete Account & Data. Agad nitong buburahin nang permanente ang iyong profile, appliance inventory, at billing history mula sa Supabase cloud at lokal na SQLite storage.\n'
                    '• Email Request: Kung na-uninstall mo na ang app, maaari kang mag-email sa privacy.kislap@gmail.com na may subject na "Account Deletion Request" upang ipabura ang iyong cloud records.'
                  : 'We retain your data only while your account remains active. In compliance with R.A. 10173, Google Play Data Safety, and App Store guidelines, you can permanently delete your account at any time:\n'
                    '• Instant In-App Deletion: Go to Settings > Account > Delete Account & Data. This immediately purges your auth credentials, profile, appliance logs, and billing history from our Supabase servers and wipes local device storage.\n'
                    '• Remote Email Request: If you have uninstalled the app, email privacy.kislap@gmail.com with the subject "Account Deletion Request" to have your cloud data purged within 7 business days.',
              surfaceColor: surfaceColor,
              textColor: textColor,
              hintColor: hintColor,
            ),

            _buildSection(
              context,
              title: isPh
                  ? '7. Mga Karapatan Mo Bilang Data Subject (Sections 16–18, DPA)'
                  : '7. Your Data Subject Rights (Sections 16–18, R.A. 10173)',
              body: isPh
                  ? 'Sa ilalim ng Data Privacy Act ng Pilipinas, mayroon kang ganap na karapatang:\n'
                    '1. Maabisuhan (Right to be Informed) kung paano pinoproseso ang iyong datos.\n'
                    '2. Tumutol (Right to Object) o bawiin ang iyong pahintulot.\n'
                    '3. Ma-access (Right to Access) ang iyong nakaimbak na profile at appliance records.\n'
                    '4. Magwasto (Right to Rectification) ng anumang maling detalye, budget, o wattage sa loob ng app.\n'
                    '5. Magpabura (Right to Erasure/Blocking) ng iyong buong account.\n'
                    '6. Data Portability: Kunin ang kopya ng iyong datos sa pamamagitan ng in-app Excel (.xlsx) Export feature.\n'
                    '7. Maghain ng reklamo sa National Privacy Commission (https://privacy.gov.ph).'
                  : 'Under the Philippine Data Privacy Act of 2012, you hold the statutory right to:\n'
                    '1. Right to be Informed of how your data is collected and processed.\n'
                    '2. Right to Object or withdraw your consent at any time.\n'
                    '3. Right to Access your stored profile and household energy logs.\n'
                    '4. Right to Rectification to edit or update budgets, tariffs, and appliances directly in the app.\n'
                    '5. Right to Erasure or Blocking to permanently delete your account and cloud records.\n'
                    '6. Right to Data Portability to download your schedules via the in-app Excel (.xlsx) Export feature.\n'
                    '7. Right to Lodge a Complaint with the National Privacy Commission (https://privacy.gov.ph).',
              surfaceColor: surfaceColor,
              textColor: textColor,
              hintColor: hintColor,
            ),

            _buildSection(
              context,
              title: isPh
                  ? '8. Pakikipag-ugnayan sa Data Protection Officer (DPO)'
                  : '8. Contact Our Data Protection Officer (DPO)',
              body: isPh
                  ? 'Para sa mga katanungan, puna, o pormal na kahilingan ukol sa iyong data privacy rights, makipag-ugnayan sa aming Data Protection Officer:\n'
                    'Email: privacy.kislap@gmail.com\n'
                    'Jurisdiction: Republika ng Pilipinas'
                  : 'For inquiries, feedback, or formal requests to exercise your statutory data privacy rights, please contact our Data Protection Officer:\n'
                    'Email: privacy.kislap@gmail.com\n'
                    'Jurisdiction: Republic of the Philippines',
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
