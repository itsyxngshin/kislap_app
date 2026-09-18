import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/navigation_provider.dart'; // <-- Navigation Provider
import '../../services/database_helper.dart';
import 'add_device_screen.dart';
import '../../services/export_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  double _activeRate = 12.35;
  double _targetBudget = 0.0;
  bool _isLoadingSettings = true;
  String _sortOrder = 'Highest kWh';

  @override
  void initState() {
    super.initState();
    _fetchLocalSettings();
  }

  Future<void> _fetchLocalSettings() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final settings = await db.query('user_settings', limit: 1);
      if (settings.isNotEmpty && mounted) {
        setState(() => _targetBudget = (settings.first['monthly_budget'] as num).toDouble());
      }
      final now = DateTime.now();
      int prevMonth = now.month == 1 ? 12 : now.month - 1;
      int prevYear = now.month == 1 ? now.year - 1 : now.year;
      String targetPeriod = '$prevYear-${prevMonth.toString().padLeft(2, '0')}-01';

      final pastBills = await db.query('recording_periods', where: 'period_month = ?', whereArgs: [targetPeriod], limit: 1);
      if (pastBills.isNotEmpty && mounted) {
        setState(() => _activeRate = (pastBills.first['billing_rate'] as num).toDouble());
      } else if (settings.isNotEmpty && mounted) {
        setState(() {
          _activeRate = (settings.first['tariff_rate'] as num).toDouble();
          if (_activeRate <= 0) _activeRate = 12.35;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingSettings = false);
  }

  String _formatTime(double totalHours) {
    final int hours = totalHours.floor();
    final int minutes = ((totalHours - hours) * 60).round();
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    return '${minutes}m';
  }

  IconData _getApplianceIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('aircon') || lower.contains('ac')) return Icons.ac_unit;
    if (lower.contains('fan')) return Icons.mode_fan_off_outlined;
    if (lower.contains('tv') || lower.contains('television')) return Icons.tv;
    if (lower.contains('fridge') || lower.contains('refrigerator')) return Icons.kitchen;
    if (lower.contains('light') || lower.contains('bulb')) return Icons.lightbulb_outline;
    if (lower.contains('wash')) return Icons.local_laundry_service_outlined;
    return Icons.electrical_services;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = textColor.withOpacity(0.6);
    final isPh = ref.watch(settingsProvider).language == 'ph';

    if (_isLoadingSettings) {
      return const Scaffold(backgroundColor: Colors.transparent, body: Center(child: CircularProgressIndicator(color: AppColors.appYellow)));
    }

    final devices = ref.watch(inventoryProvider);
    double originalDailyKwh = 0.0, optimizedDailyKwh = 0.0;
    for (var device in devices) {
      final double kw = (device.presetWattage * device.quantity) / 1000;
      originalDailyKwh += kw * device.userAssignedHours;
      optimizedDailyKwh += kw * device.adjustedHours;
    }

    final double optimizedMonthlyCost = optimizedDailyKwh * _activeRate * 30;

    List<dynamic> sortedDevices = List.from(devices);
    if (_sortOrder == 'Highest kWh') {
      sortedDevices.sort((a, b) => ((b.presetWattage * b.quantity * b.adjustedHours)).compareTo(a.presetWattage * a.quantity * a.adjustedHours));
    } else if (_sortOrder == 'Lowest kWh') {
      sortedDevices.sort((a, b) => ((a.presetWattage * a.quantity * a.adjustedHours)).compareTo(b.presetWattage * b.quantity * b.adjustedHours));
    } else if (_sortOrder == 'Name (A-Z)') {
      sortedDevices.sort((a, b) => a.customName.toString().toLowerCase().compareTo(b.customName.toString().toLowerCase()));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: AppTheme.globalBackground(context),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTimeOfDayHeader(isPh, textColor, hintColor),
                const SizedBox(height: 25),

                _buildSummaryCard(optimizedMonthlyCost: optimizedMonthlyCost, isDark: isDark, isPh: isPh, textColor: textColor, hintColor: hintColor),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(child: _buildMetricCard(icon: Icons.bolt, iconColor: Colors.orange.shade400, value: optimizedDailyKwh.toStringAsFixed(1), unit: ' kWh', label: isPh ? 'Konsumo ngayon' : "Today's draw", isDark: isDark, textColor: textColor, hintColor: hintColor)),
                    const SizedBox(width: 15),
                    Expanded(child: _buildMetricCard(icon: Icons.account_balance_wallet_outlined, iconColor: Colors.green.shade600, value: '₱', unit: (optimizedDailyKwh * _activeRate).toStringAsFixed(0), label: isPh ? 'Est. gastos ngayon' : "Est. cost today", isDark: isDark, textColor: textColor, hintColor: hintColor)),
                  ],
                ),
                const SizedBox(height: 35),

                Text(isPh ? 'Mga Aksyon' : 'Quick Actions', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildQuickAction(Icons.add, isPh ? 'Magdagdag' : 'Add item', isPrimary: true, isDark: isDark, hintColor: hintColor, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddDeviceScreen()))),

                    // THE FIX: Switch tabs using Riverpod instead of Navigator.push
                    _buildQuickAction(
                      Icons.show_chart_rounded,
                      isPh ? 'Pagsusuri' : 'Analysis',
                      isDark: isDark, hintColor: hintColor,
                      onTap: () => ref.read(dashboardTabProvider.notifier).state = 2, // Switches to Analysis Tab
                    ),
                    _buildQuickAction(
                      Icons.settings_outlined,
                      isPh ? 'Setting' : 'Configuration',
                      isDark: isDark, hintColor: hintColor,
                      onTap: () => ref.read(dashboardTabProvider.notifier).state = 4, // Switches to Settings Tab
                    ),
                    _buildQuickAction(Icons.ios_share_rounded, isPh ? 'I-export' : 'Export', isDark: isDark, hintColor: hintColor, onTap: () async {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isPh ? 'Binubuo ang Excel file...' : 'Generating Excel file...')));
                      await ExportService.exportScheduleToExcel(inventory: devices, tariffRate: _activeRate, targetBudget: _targetBudget);
                    }),
                  ],
                ),
                const SizedBox(height: 40),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isPh ? 'Na-optimize na Iskedyul' : 'Optimized Schedule', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.sort_rounded, color: hintColor, size: 22),
                      color: isDark ? Colors.grey.shade900 : Colors.white,
                      onSelected: (val) => setState(() => _sortOrder = val),
                      itemBuilder: (context) => [
                        PopupMenuItem(value: 'Highest kWh', child: Text(isPh ? 'Pinakamataas na kWh' : 'Highest kWh', style: TextStyle(color: textColor))),
                        PopupMenuItem(value: 'Lowest kWh', child: Text(isPh ? 'Pinakamababang kWh' : 'Lowest kWh', style: TextStyle(color: textColor))),
                        PopupMenuItem(value: 'Name (A-Z)', child: Text(isPh ? 'Pangalan (A-Z)' : 'Name (A-Z)', style: TextStyle(color: textColor))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (devices.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(24)),
                    child: Center(child: Text(isPh ? 'Wala pang nailagay na gamit.' : 'No appliances added yet.', style: TextStyle(color: hintColor))),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedDevices.length,
                    itemBuilder: (context, index) => _buildApplianceCard(sortedDevices[index], isDark, textColor, hintColor, isPh),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- STUNNING TIME OF DAY HEADER ---
  Widget _buildTimeOfDayHeader(bool isPh, Color textColor, Color hintColor) {
    final hour = DateTime.now().hour;
    String greeting;
    IconData timeIcon;
    List<Color> gradientColors;

    if (hour < 12) {
      greeting = isPh ? 'Magandang Umaga' : 'Good Morning';
      timeIcon = Icons.wb_sunny_rounded;
      gradientColors = [Colors.orange.shade300, Colors.yellow.shade500];
    } else if (hour < 17) {
      greeting = isPh ? 'Magandang Hapon' : 'Good Afternoon';
      timeIcon = Icons.brightness_5_rounded;
      gradientColors = [Colors.deepOrange.shade400, Colors.orange.shade300];
    } else {
      greeting = isPh ? 'Magandang Gabi' : 'Good Evening';
      timeIcon = Icons.nights_stay_rounded;
      gradientColors = [Colors.indigo.shade400, Colors.deepPurple.shade400];
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: gradientColors.first.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Icon(timeIcon, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(greeting, style: TextStyle(fontSize: 14, color: hintColor, letterSpacing: 0.5)),
            Text(isPh ? 'Ang Iyong Buod' : 'Your Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 0.5)),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard({required double optimizedMonthlyCost, required bool isDark, required bool isPh, required Color textColor, required Color hintColor}) {
    final bool systemBreached = optimizedMonthlyCost > _targetBudget;
    final Color statusColor = systemBreached ? (isDark ? AppColors.adminRed : Colors.red.shade700) : (isDark ? Colors.greenAccent : Colors.green.shade700);
    double progress = _targetBudget > 0 ? (optimizedMonthlyCost / _targetBudget).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface.withOpacity(0.6) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isPh ? 'BUWANANG ESTIMATE' : 'MONTHLY ESTIMATE', style: TextStyle(color: hintColor, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                child: Text(systemBreached ? (isPh ? 'Sumobra' : 'Over Budget') : (isPh ? 'Pasok sa Limit' : 'On Track'), style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₱', style: TextStyle(color: isDark ? AppColors.appYellow : Colors.orange.shade800, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Text(optimizedMonthlyCost.toStringAsFixed(2), style: TextStyle(color: textColor, fontSize: 40, fontWeight: FontWeight.w900, height: 1.0)),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(height: 8, decoration: BoxDecoration(color: isDark ? Colors.black38 : Colors.grey.shade200, borderRadius: BorderRadius.circular(10))),
              AnimatedContainer(
                duration: const Duration(milliseconds: 800), curve: Curves.easeOutCubic,
                height: 8, width: MediaQuery.of(context).size.width * 0.7 * progress,
                decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(10)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({required IconData icon, required Color iconColor, required String value, required String unit, required String label, required bool isDark, required Color textColor, required Color hintColor}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface.withOpacity(0.4) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: iconColor.withOpacity(0.15), shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 20)),
          const SizedBox(height: 16),
          RichText(text: TextSpan(children: [TextSpan(text: value, style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)), TextSpan(text: unit, style: TextStyle(color: hintColor, fontSize: 14))])),
          Text(label, style: TextStyle(color: hintColor, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildApplianceCard(dynamic item, bool isDark, Color textColor, Color hintColor, bool isPh) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface.withOpacity(0.4) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: item.isLocked ? (isDark ? AppColors.appYellow.withOpacity(0.5) : Colors.orange.shade400) : (isDark ? Colors.white12 : Colors.black.withOpacity(0.05))),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: item.isLocked ? (isDark ? AppColors.appYellow.withOpacity(0.15) : Colors.orange.shade50) : (isDark ? Colors.black26 : Colors.grey.shade100), shape: BoxShape.circle),
            child: Icon(_getApplianceIcon(item.customName), color: item.isLocked ? (isDark ? AppColors.appYellow : Colors.orange.shade700) : hintColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${item.customName} (x${item.quantity})', style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(isPh ? 'Target: ${_formatTime(item.userAssignedHours)}' : 'Target: ${_formatTime(item.userAssignedHours)}', style: TextStyle(color: hintColor, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_formatTime(item.adjustedHours), style: TextStyle(color: isDark ? Colors.greenAccent : Colors.green.shade700, fontSize: 15, fontWeight: FontWeight.bold)),
              Text(isPh ? 'na-optimize' : 'optimized', style: TextStyle(color: hintColor, fontSize: 10)),
            ],
          ),
          IconButton(
            icon: Icon(item.isLocked ? Icons.lock_rounded : Icons.lock_open_rounded, color: item.isLocked ? (isDark ? AppColors.appYellow : Colors.orange.shade700) : hintColor.withOpacity(0.5)),
            onPressed: () => ref.read(inventoryProvider.notifier).toggleLock(item.id, item.isLocked),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, {bool isPrimary = false, required bool isDark, required Color hintColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 60, width: 60,
            decoration: BoxDecoration(
              gradient: isPrimary ? LinearGradient(colors: [Colors.orange.shade400, Colors.orange.shade700]) : null,
              color: isPrimary ? null : (isDark ? Colors.white10 : Colors.white),
              borderRadius: BorderRadius.circular(20),
              boxShadow: isPrimary ? [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : (isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
            ),
            child: Icon(icon, color: isPrimary ? Colors.white : hintColor.withOpacity(0.8), size: 28),
          ),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(color: hintColor, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
