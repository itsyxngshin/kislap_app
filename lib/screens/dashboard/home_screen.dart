import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/database_helper.dart';
import 'add_device_screen.dart';
import 'settings_screen.dart';
import 'analysis_screen.dart';
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
        setState(() {
          _targetBudget = (settings.first['monthly_budget'] as num).toDouble();
        });
      }

      final now = DateTime.now();
      int prevMonth = now.month - 1;
      int prevYear = now.year;
      if (prevMonth == 0) {
        prevMonth = 12;
        prevYear--;
      }
      String paddedMonth = prevMonth.toString().padLeft(2, '0');
      String targetPeriod = '$prevYear-$paddedMonth-01';

      final pastBills = await db.query(
        'recording_periods',
        where: 'period_month = ?',
        whereArgs: [targetPeriod],
        limit: 1,
      );

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

  String _getGreeting(bool isPh) {
    final hour = DateTime.now().hour;
    if (hour < 12) return isPh ? 'Magandang Umaga' : 'Good Morning';
    if (hour < 17) return isPh ? 'Magandang Hapon' : 'Good Afternoon';
    return isPh ? 'Magandang Gabi' : 'Good Evening';
  }

  IconData _getApplianceIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('aircon') || lower.contains('ac')) return Icons.ac_unit;
    if (lower.contains('fan')) return Icons.mode_fan_off_outlined;
    if (lower.contains('tv') || lower.contains('television')) return Icons.tv;
    if (lower.contains('fridge') || lower.contains('refrigerator')) return Icons.kitchen;
    if (lower.contains('light') || lower.contains('bulb')) return Icons.lightbulb_outline;
    if (lower.contains('wash')) return Icons.local_laundry_service_outlined;
    if (lower.contains('laptop') || lower.contains('computer')) return Icons.computer;
    return Icons.electrical_services;
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = textColor.withOpacity(0.6);
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final isPh = ref.watch(settingsProvider).language == 'ph';

    if (_isLoadingSettings) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: const Center(child: CircularProgressIndicator(color: AppColors.appYellow)),
      );
    }

    final devices = ref.watch(inventoryProvider);

    double originalDailyKwh = 0.0;
    double optimizedDailyKwh = 0.0;
    for (var device in devices) {
      final double kw = (device.presetWattage * device.quantity) / 1000;
      originalDailyKwh += kw * device.userAssignedHours;
      optimizedDailyKwh += kw * device.adjustedHours;
    }

    final double originalMonthlyCost = originalDailyKwh * _activeRate * 30;
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
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(left: 24, right: 24, top: 30, bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Text(
                _getGreeting(isPh),
                style: TextStyle(fontSize: 16, color: hintColor, letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              Text(
                isPh ? 'Ang Iyong Buod' : 'Your Dashboard',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 0.5),
              ),
              const SizedBox(height: 25),

              // PREMIUM BUDGET CARD
              _buildSummaryCard(
                originalMonthlyCost: originalMonthlyCost,
                optimizedMonthlyCost: optimizedMonthlyCost,
                surfaceColor: surfaceColor,
                textColor: textColor,
                hintColor: hintColor,
                isPh: isPh,
              ),
              const SizedBox(height: 20),

              // DAILY METRICS
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.bolt,
                      iconColor: AppColors.appYellow,
                      value: '${optimizedDailyKwh.toStringAsFixed(1)}',
                      unit: ' kWh',
                      label: isPh ? 'Konsumo ngayon' : "Today's draw",
                      surfaceColor: surfaceColor,
                      textColor: textColor,
                      hintColor: hintColor,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.account_balance_wallet_outlined,
                      iconColor: Colors.greenAccent,
                      value: '₱',
                      unit: (optimizedDailyKwh * _activeRate).toStringAsFixed(0),
                      label: isPh ? 'Est. gastos ngayon' : "Est. cost today",
                      surfaceColor: surfaceColor,
                      textColor: textColor,
                      hintColor: hintColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 35),

              // QUICK ACTIONS
              Text(
                isPh ? 'Mga Aksyon' : 'Quick Actions',
                style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildQuickAction(
                    Icons.add,
                    isPh ? 'Magdagdag' : 'Add item',
                    isPrimary: true,
                    surfaceColor: surfaceColor,
                    hintColor: hintColor,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddDeviceScreen())),
                  ),
                  _buildQuickAction(
                    Icons.show_chart_rounded,
                    isPh ? 'Pagsusuri' : 'Analysis',
                    surfaceColor: surfaceColor,
                    hintColor: hintColor,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalysisScreen())),
                  ),
                  _buildQuickAction(
                    Icons.settings_outlined,
                    isPh ? 'Setting' : 'Config',
                    surfaceColor: surfaceColor,
                    hintColor: hintColor,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                  ),
                  _buildQuickAction(
                    Icons.ios_share_rounded,
                    isPh ? 'I-export' : 'Export',
                    surfaceColor: surfaceColor,
                    hintColor: hintColor,
                    onTap: () async {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isPh ? 'Binubuo ang Excel file...' : 'Generating Excel file...'), duration: const Duration(seconds: 1)));
                      await ExportService.exportScheduleToExcel(inventory: devices, tariffRate: _activeRate, targetBudget: _targetBudget);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // LIST HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isPh ? 'Na-optimize na Iskedyul' : 'Optimized Schedule',
                    style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Text('${devices.length} ${isPh ? 'gamit' : 'items'}', style: TextStyle(color: hintColor, fontSize: 13)),
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.sort_rounded, color: textColor.withOpacity(0.8), size: 22),
                        color: surfaceColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        onSelected: (val) => setState(() => _sortOrder = val),
                        itemBuilder: (context) => [
                          PopupMenuItem(value: 'Highest kWh', child: Text(isPh ? 'Pinakamataas na kWh' : 'Highest kWh', style: TextStyle(color: textColor))),
                          PopupMenuItem(value: 'Lowest kWh', child: Text(isPh ? 'Pinakamababang kWh' : 'Lowest kWh', style: TextStyle(color: textColor))),
                          PopupMenuItem(value: 'Name (A-Z)', child: Text(isPh ? 'Pangalan (A-Z)' : 'Name (A-Z)', style: TextStyle(color: textColor))),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // DYNAMIC LIST
              if (devices.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  decoration: BoxDecoration(color: surfaceColor.withOpacity(0.3), borderRadius: BorderRadius.circular(24)),
                  child: Column(
                    children: [
                      Icon(Icons.electric_bolt_rounded, size: 48, color: hintColor.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text(isPh ? 'Wala pang nailagay na gamit.' : 'No appliances added yet.', style: TextStyle(color: hintColor, fontSize: 15)),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sortedDevices.length,
                  itemBuilder: (context, index) {
                    return _buildApplianceCard(sortedDevices[index], surfaceColor, textColor, hintColor, isPh);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required double originalMonthlyCost,
    required double optimizedMonthlyCost,
    required Color surfaceColor,
    required Color textColor,
    required Color hintColor,
    required bool isPh,
  }) {
    final bool originalBreached = originalMonthlyCost > _targetBudget;
    final bool systemBreached = optimizedMonthlyCost > _targetBudget;
    final Color statusColor = systemBreached ? AppColors.adminRed : Colors.greenAccent;
    double progress = _targetBudget > 0 ? (optimizedMonthlyCost / _targetBudget).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            surfaceColor.withOpacity(0.8),
            surfaceColor.withOpacity(0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isPh ? 'BUWANANG ESTIMATE' : 'MONTHLY ESTIMATE',
                style: TextStyle(color: hintColor, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(systemBreached ? Icons.warning_amber_rounded : Icons.check_circle_outline, color: statusColor, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      systemBreached ? (isPh ? 'Sumobra' : 'Over Budget') : (isPh ? 'Pasok sa Limit' : 'On Track'),
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('₱', style: TextStyle(color: AppColors.appYellow, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Text(
                optimizedMonthlyCost.toStringAsFixed(2),
                style: TextStyle(color: textColor, fontSize: 42, fontWeight: FontWeight.w900, height: 1.0, letterSpacing: -0.5),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Rate: ₱${_activeRate.toStringAsFixed(2)}/kWh', style: TextStyle(color: hintColor, fontSize: 13)),
              Text('Limit: ₱${_targetBudget.toStringAsFixed(0)}', style: TextStyle(color: hintColor, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 24),

          // Sleek Animated Progress Bar
          Stack(
            children: [
              Container(height: 8, decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(10))),
              AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                height: 8,
                width: MediaQuery.of(context).size.width * 0.8 * progress, // Responsive width
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: statusColor.withOpacity(0.5), blurRadius: 6, offset: const Offset(0, 2))],
                ),
              ),
            ],
          ),

          if (originalBreached && !systemBreached) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.adminRed.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: AppColors.appYellow, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isPh ? 'Orihinal na Bill: ₱${originalMonthlyCost.toStringAsFixed(0)}\nMatagumpay na kinontrol ng Kislap ang iyong konsumo.'
                           : 'Unregulated Bill: ₱${originalMonthlyCost.toStringAsFixed(0)}\nKislap successfully protected your budget limit.',
                      style: TextStyle(color: textColor.withOpacity(0.9), fontSize: 11, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String unit,
    required String label,
    required Color surfaceColor,
    required Color textColor,
    required Color hintColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: value, style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold)),
                TextSpan(text: unit, style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: hintColor, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildApplianceCard(dynamic item, Color surfaceColor, Color textColor, Color hintColor, bool isPh) {
    final bool isLocked = item.isLocked;
    final double originalDailyKwh = (item.presetWattage * item.quantity / 1000) * item.userAssignedHours;
    final double optimizedDailyKwh = (item.presetWattage * item.quantity / 1000) * item.adjustedHours;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isLocked ? surfaceColor.withOpacity(0.8) : surfaceColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isLocked ? AppColors.appYellow.withOpacity(0.5) : Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: isLocked ? AppColors.appYellow.withOpacity(0.15) : Colors.black26, shape: BoxShape.circle),
            child: Icon(_getApplianceIcon(item.customName), color: isLocked ? AppColors.appYellow : hintColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.customName} (x${item.quantity})',
                  style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  isPh ? 'Dati: ${originalDailyKwh.toStringAsFixed(1)} kWh • Bago: ${optimizedDailyKwh.toStringAsFixed(1)} kWh'
                       : 'Orig: ${originalDailyKwh.toStringAsFixed(1)} kWh • Opt: ${optimizedDailyKwh.toStringAsFixed(1)} kWh',
                  style: TextStyle(color: hintColor, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_formatTime(item.adjustedHours), style: const TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(isPh ? 'na-optimize' : 'optimized', style: TextStyle(color: hintColor, fontSize: 10)),
            ],
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(isLocked ? Icons.lock_rounded : Icons.lock_open_rounded, color: isLocked ? AppColors.appYellow : hintColor.withOpacity(0.5), size: 24),
            onPressed: () => ref.read(inventoryProvider.notifier).toggleLock(item.id, isLocked),
            splashRadius: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, {bool isPrimary = false, required Color surfaceColor, required Color hintColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 65,
            width: 65,
            decoration: BoxDecoration(
              gradient: isPrimary ? LinearGradient(colors: [Colors.orange.shade400, Colors.orange.shade700], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
              color: isPrimary ? null : surfaceColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              boxShadow: isPrimary ? [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))] : [],
            ),
            child: Icon(icon, color: isPrimary ? Colors.white : hintColor.withOpacity(0.8), size: 30),
          ),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(color: hintColor, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
