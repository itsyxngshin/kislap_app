import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../auth/sign_in_screen.dart';
import '../../main.dart';
import '../../services/database_helper.dart';
import '../../widgets/custom_text_field.dart';
import '../../providers/inventory_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Financial & Profile State
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _tariffController = TextEditingController();
  String _householdSize = 'Small';
  String _fullName = 'Loading...';
  String _email = '';
  bool _isLoading = true;
  bool _isSaving = false;

  // Billing History State
  List<Map<String, dynamic>> _periods = [];
  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  final List<int> _years = List.generate(
    DateTime.now().year - 2023,
    (index) => 2024 + index,
  ).reversed.toList();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _tariffController.dispose();
    super.dispose();
  }

  // Generates the current month string dynamically
  String _getCurrentBillingMonth() {
    final now = DateTime.now();
    final monthsEn = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final monthsPh = ['Enero', 'Pebrero', 'Marso', 'Abril', 'Mayo', 'Hunyo', 'Hulyo', 'Agosto', 'Setyembre', 'Oktubre', 'Nobyembre', 'Disyembre'];

    return '${monthsEn[now.month - 1]} ${now.year} (${monthsPh[now.month - 1]})';
  }

  Future<void> _loadInitialData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _fullName = 'Guest User';
        _email = 'Local Offline Mode';
      } else {
        _email = user.email ?? '';
        final profileData = await Supabase.instance.client
            .from('profiles')
            .select('full_name')
            .eq('id', user.id)
            .maybeSingle();
        _fullName = profileData?['full_name'] ?? 'User';
      }
    } catch (_) {
      _fullName = 'Guest User';
      _email = 'Offline Mode';
    }

    try {
      final db = await DatabaseHelper.instance.database;

      final settings = await db.query('user_settings', limit: 1);
      if (settings.isNotEmpty) {
        final data = settings.first;
        _budgetController.text = (data['monthly_budget'] as num).toString();
        _tariffController.text = (data['tariff_rate'] as num).toString();
        _householdSize = data['household_size'] as String? ?? 'Small';
      }

      final periodData = await db.query(
        'recording_periods',
        orderBy: 'period_month DESC',
      );
      if (mounted) _periods = periodData;
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadPeriods() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final data = await db.query(
        'recording_periods',
        orderBy: 'period_month DESC',
      );
      if (mounted) {
        setState(() => _periods = data);
      }
    } catch (_) {}
  }

  Future<void> _saveConfiguration() async {
    setState(() => _isSaving = true);

    try {
      final double budget = double.tryParse(_budgetController.text) ?? 0.0;
      final double tariff = double.tryParse(_tariffController.text) ?? 0.0;

      final db = await DatabaseHelper.instance.database;

      await db.insert(
        'user_settings',
        {
          'id': 1,
          'monthly_budget': budget,
          'tariff_rate': tariff,
          'household_size': _householdSize,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration saved! (Na-save na!)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save configuration'),
            backgroundColor: AppColors.adminRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SignInScreen()),
        (route) => false,
      );
    }
  }

  void _showAddPeriodModal() {
    String selectedMonth = _months[DateTime.now().month - 1];
    int selectedYear = DateTime.now().year;
    final TextEditingController rateController = TextEditingController();

    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24, right: 24, top: 24,
              ),
              decoration: BoxDecoration(
                color: surfaceColor.withValues(alpha: 0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: AppColors.appYellow.withValues(alpha: 0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Log Previous Bill\n(Itala ang Nakaraang Bill)',
                        style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold, height: 1.2),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Record past billing rates to track your usage history.\n(I-record ang nakaraang singil para makita ang trend ng iyong paggamit.)',
                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: selectedMonth,
                          decoration: InputDecoration(
                            filled: true, fillColor: Colors.black26,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          dropdownColor: surfaceColor,
                          items: _months.map((m) => DropdownMenuItem(value: m, child: Text(m, style: TextStyle(color: textColor)))).toList(),
                          onChanged: (val) => setModalState(() => selectedMonth = val!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<int>(
                          value: selectedYear,
                          decoration: InputDecoration(
                            filled: true, fillColor: Colors.black26,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          dropdownColor: surfaceColor,
                          items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y.toString(), style: TextStyle(color: textColor)))).toList(),
                          onChanged: (val) => setModalState(() => selectedYear = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  CustomTextField(
                    controller: rateController,
                    hint: 'Utility Rate (₱/kWh)',
                    icon: Icons.bolt,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final rate = double.tryParse(rateController.text);
                        if (rate == null || rate <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid rate (Maglagay ng wastong halaga)'), backgroundColor: AppColors.adminRed));
                          return;
                        }

                        int monthIndex = _months.indexOf(selectedMonth) + 1;
                        String paddedMonth = monthIndex.toString().padLeft(2, '0');
                        String periodMonth = '$selectedYear-$paddedMonth-01';
                        int lastDay = DateTime(selectedYear, monthIndex + 1, 0).day;
                        String endDate = '$selectedYear-$paddedMonth-$lastDay';

                        try {
                          final db = await DatabaseHelper.instance.database;
                          await db.insert('recording_periods', {
                            'period_month': periodMonth,
                            'period_name': '$selectedMonth $selectedYear',
                            'start_date': periodMonth,
                            'end_date': endDate,
                            'billing_rate': rate,
                          });

                          if (mounted) {
                            Navigator.pop(context);
                            _loadPeriods();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Billing period saved!'), backgroundColor: Colors.green));
                          }
                        } catch (e) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Period already exists.'), backgroundColor: AppColors.adminRed));
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.appYellow,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save Period (I-save)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.appYellow));

    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = textColor.withValues(alpha: 0.6);
    final surfaceColor = Theme.of(context).colorScheme.surface;

    // Calculate current optimized consumption for the projection feature
    final devices = ref.watch(inventoryProvider);
    double optimizedDailyKwh = 0.0;
    for (var device in devices) {
      optimizedDailyKwh += (device.presetWattage / 1000) * device.adjustedHours;
    }
    final double optimizedMonthlyKwh = optimizedDailyKwh * 30;

    return Container(
      decoration: AppTheme.globalBackground(context),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Settings\n(Mga Setting)', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor, height: 1.2)),
              const SizedBox(height: 25),

              // 1. Profile Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: textColor.withValues(alpha: 0.05)),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 56, width: 56,
                      decoration: BoxDecoration(color: AppColors.appYellow.withValues(alpha: 0.2), shape: BoxShape.circle, border: Border.all(color: AppColors.appYellow.withValues(alpha: 0.5))),
                      child: Center(child: Text(_fullName.isNotEmpty ? _fullName[0].toUpperCase() : '?', style: const TextStyle(color: AppColors.appYellow, fontSize: 24, fontWeight: FontWeight.bold))),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_fullName, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(_email, style: TextStyle(color: hintColor, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 35),

              // 2. DYNAMIC PAST MONTH PROJECTION
              if (_periods.isNotEmpty && optimizedMonthlyKwh > 0) ...[
                Text('PREVIOUS RATE PROJECTION\n(PROYEKSYON BASE SA NAKARAAN)', style: TextStyle(color: hintColor, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.bold, height: 1.4)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.appYellow.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.appYellow.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.history_toggle_off, color: AppColors.appYellow, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'If you applied your rate from ${_periods.first['period_name']} (₱${_periods.first['billing_rate'].toStringAsFixed(2)}/kWh) to your current optimized setup (${optimizedMonthlyKwh.toStringAsFixed(1)} kWh):',
                              style: TextStyle(color: textColor.withValues(alpha: 0.9), fontSize: 12, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Projected Bill (Est. na Bayarin)', style: TextStyle(color: AppColors.appYellow.withValues(alpha: 0.8), fontSize: 11)),
                      Text(
                        '₱${(optimizedMonthlyKwh * _periods.first['billing_rate']).toStringAsFixed(2)}',
                        style: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 35),
              ],

              // 3. Financial Configuration
              Text('FINANCIAL BASELINE (BATAYANG PINANSYAL)', style: TextStyle(color: hintColor, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: surfaceColor.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16), border: Border.all(color: textColor.withValues(alpha: 0.05))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Monthly Budget Limit (Limitasyon sa Budget)', style: TextStyle(color: hintColor, fontSize: 12)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _budgetController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        prefixText: '₱ ', prefixStyle: TextStyle(color: textColor, fontSize: 18),
                        filled: true, fillColor: surfaceColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- DYNAMIC BILLING MONTH INDICATOR FOR TARIFF RATE ---
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.appYellow.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.appYellow.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, color: AppColors.appYellow, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Active Rate for ${_getCurrentBillingMonth()}\n(Halaga para sa buwang ito)',
                              style: const TextStyle(color: AppColors.appYellow, fontSize: 12, fontWeight: FontWeight.bold, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _tariffController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: textColor, fontSize: 16),
                      decoration: InputDecoration(
                        prefixText: '₱ ', suffixText: '/ kWh', suffixStyle: TextStyle(color: hintColor),
                        filled: true, fillColor: surfaceColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 35),

              // 4. Classification
              Text('HOUSEHOLD CLASSIFICATION (URI NG BAHAYAN)', style: TextStyle(color: hintColor, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: surfaceColor.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16), border: Border.all(color: textColor.withValues(alpha: 0.05))),
                child: Column(
                  children: [
                    _buildRadioOption('Small (0 - 5 kVA)', 'Small', 'Basic appliances only. Fans, TV, fridge, etc.\n(Basic na gamit lamang: Fan, TV, ilaw, atbp.)', textColor, hintColor),
                    _buildRadioOption('Medium (6 - 15 kVA)', 'Medium', 'Standard home. 1-2 air conditioners, fridge, etc.\n(May 1-2 aircon, ref, atbp.)', textColor, hintColor),
                    _buildRadioOption('Large (16 - 25 kVA)', 'Large', 'Heavy usage. Multiple ACs, large appliances.\n(Malakas na konsumo: Maraming aircon at appliances.)', textColor, hintColor),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveConfiguration,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Configuration (I-save)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),

              // 5. Billing History
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('BILLING HISTORY\n(KASAYSAYAN NG BILL)', style: TextStyle(color: hintColor, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.bold, height: 1.3)),
                  TextButton.icon(
                    onPressed: _showAddPeriodModal,
                    icon: const Icon(Icons.add, color: AppColors.appYellow, size: 16),
                    label: const Text('Add Month', style: TextStyle(color: AppColors.appYellow, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_periods.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: surfaceColor.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(16)),
                  child: Text('No past billing periods recorded.\n(Wala pang naitalang nakaraang bill.)', textAlign: TextAlign.center, style: TextStyle(color: hintColor, fontSize: 14)),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _periods.length,
                  itemBuilder: (context, index) {
                    final period = _periods[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: textColor.withValues(alpha: 0.05)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(period['period_name'], style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('Rate recorded (Naitalang halaga)', style: TextStyle(color: hintColor, fontSize: 11)),
                            ],
                          ),
                          Text('₱${period['billing_rate'].toStringAsFixed(2)}', style: const TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 40),

              // 6. Appearance Toggles
              Text('APPEARANCE (HITSURA)', style: TextStyle(color: hintColor, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(color: surfaceColor.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16), border: Border.all(color: textColor.withValues(alpha: 0.05))),
                child: ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeNotifier,
                  builder: (_, currentMode, _) {
                    return _buildSwitchOption(
                      title: 'Dark Mode (Madilim)',
                      icon: currentMode == ThemeMode.dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                      value: currentMode == ThemeMode.dark,
                      textColor: textColor,
                      onChanged: (isDark) {
                        themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),

              // 7. Account Actions
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _email == 'Offline Mode' || _email == 'Local Offline Mode'
                      ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignInScreen()))
                      : _signOut,
                  icon: Icon(_email == 'Offline Mode' || _email == 'Local Offline Mode' ? Icons.cloud_upload_outlined : Icons.logout, color: hintColor),
                  label: Text(_email == 'Offline Mode' || _email == 'Local Offline Mode' ? 'Sign in to Sync' : 'Sign out (Mag-log out)', style: TextStyle(color: hintColor, fontSize: 15)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: hintColor.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadioOption(String title, String value, String description, Color textColor, Color hintColor) {
    bool isSelected = _householdSize == value;
    return GestureDetector(
      onTap: () => setState(() => _householdSize = value),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? textColor.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.appYellow.withValues(alpha: 0.3) : Colors.transparent),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: isSelected ? AppColors.appYellow : hintColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: isSelected ? textColor : hintColor, fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  const SizedBox(height: 6),
                  Text(description, style: TextStyle(color: hintColor, fontSize: 11, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchOption({required String title, IconData? icon, required bool value, required Color textColor, required Function(bool) onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[Icon(icon, color: AppColors.appYellow, size: 20), const SizedBox(width: 12)],
              Text(title, style: TextStyle(color: textColor, fontSize: 14)),
            ],
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.appYellow,
            inactiveThumbColor: textColor.withValues(alpha: 0.5),
            inactiveTrackColor: textColor.withValues(alpha: 0.1),
          ),
        ],
      ),
    );
  }
}
