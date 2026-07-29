import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/settings_provider.dart'; // <-- Added Provider
import '../../services/database_helper.dart';

class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  double _activeRate = 12.35;
  double _targetBudget = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final db = await DatabaseHelper.instance.database;
    final settings = await db.query('user_settings', limit: 1);
    if (settings.isNotEmpty && mounted) {
      setState(() {
        _activeRate = (settings.first['tariff_rate'] as num).toDouble();
        _targetBudget = (settings.first['monthly_budget'] as num).toDouble();
        if (_activeRate <= 0) _activeRate = 12.35;
        _isLoading = false;
      });
    }
  }

  // --- UI HELPER: Time Formatter ---
  String _formatTime(double totalHours) {
    final int hours = totalHours.floor();
    final int minutes = ((totalHours - hours) * 60).round();
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    return '${minutes}m';
  }

  // --- UI HELPER: Dynamic Appliance Icons ---
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
    final hintColor = textColor.withValues(alpha: 0.6);
    final surfaceColor = Theme.of(context).colorScheme.surface;

    final isPh = ref.watch(settingsProvider).language == 'ph'; // Live language check

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: AppTheme.globalBackground(context),
          child: const Center(child: CircularProgressIndicator(color: AppColors.appYellow)),
        ),
      );
    }

    final devices = ref.watch(inventoryProvider);

    // Household Totals Calculation
    double originalDailyKwh = 0;
    double optimizedDailyKwh = 0;

    for (var device in devices) {
      final double kw = device.presetWattage / 1000;
      originalDailyKwh += kw * device.userAssignedHours;
      optimizedDailyKwh += kw * device.adjustedHours;
    }

    final double optimizedWeeklyKwh = optimizedDailyKwh * 7;
    final double optimizedMonthlyKwh = optimizedDailyKwh * 30;

    final double originalMonthlyCost = (originalDailyKwh * 30) * _activeRate;
    final double optimizedDailyCost = optimizedDailyKwh * _activeRate;
    final double optimizedWeeklyCost = optimizedWeeklyKwh * _activeRate;
    final double optimizedMonthlyCost = optimizedMonthlyKwh * _activeRate;

    // Trend Analysis Logic
    final double monthlySavings = originalMonthlyCost - optimizedMonthlyCost;
    final bool isOverBudget = optimizedMonthlyCost > _targetBudget;
    final bool isSaving = monthlySavings > 0;

    String trendTitle = '';
    String trendDesc = '';
    Color trendColor = Colors.greenAccent;
    IconData trendIcon = Icons.trending_down;

    if (isOverBudget) {
      trendColor = AppColors.adminRed;
      trendIcon = Icons.warning_amber_rounded;
      trendTitle = isPh ? 'Sumobra sa Budget' : 'Budget Exceeded';
      trendDesc = isPh
        ? 'Kahit na may optimization, ang iyong mga naka-lock na appliances ay lalampas sa ₱${_targetBudget.toStringAsFixed(0)} na budget. Maaari mong i-unlock ang ilang gamit.'
        : 'Even with optimization, your essential (locked) appliances exceed your ₱${_targetBudget.toStringAsFixed(0)} budget. Consider unlocking items.';
    } else if (isSaving) {
      trendColor = Colors.greenAccent;
      trendIcon = Icons.trending_down;
      trendTitle = isPh ? 'Bumaba ang Konsumo' : 'Decreased Usage Trend';
      trendDesc = isPh
        ? 'Dahil sa optimization, nakatipid ka ng ₱${monthlySavings.toStringAsFixed(0)} sa inaasahang buwanang bill. Pasok na pasok ka sa iyong budget.'
        : 'By optimizing your schedule, your projected monthly bill decreases by ₱${monthlySavings.toStringAsFixed(0)}. You are staying safely within your budget.';
    } else {
      trendColor = AppColors.appYellow;
      trendIcon = Icons.trending_flat;
      trendTitle = isPh ? 'Walang Bawas sa Konsumo' : 'Stable Usage Trend';
      trendDesc = isPh
        ? 'Ang iyong orihinal na konsumo ay pasok na sa iyong budget. Walang binawas na oras sa iyong mga appliances.'
        : 'Your unregulated usage is already within your budget. No operating hours were reduced.';
    }

    return Scaffold( // FIX: Wrapped in Scaffold
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: textColor), onPressed: () => Navigator.pop(context)),
        title: Text(isPh ? 'Pagsusuri' : 'Analysis', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
      ),
      body: Container(
        decoration: AppTheme.globalBackground(context),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TREND ANALYSIS CARD
              Text(isPh ? 'PAGSUSURI NG TREND' : 'TREND ANALYSIS', style: TextStyle(color: hintColor, fontSize: 11, letterSpacing: 1.2)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: trendColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(trendIcon, color: trendColor, size: 28),
                        const SizedBox(width: 12),
                        Expanded(child: Text(trendTitle, style: TextStyle(color: trendColor, fontWeight: FontWeight.bold, fontSize: 16))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(trendDesc, style: TextStyle(color: textColor, fontSize: 13, height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // 2. HOUSEHOLD TOTALS
              Text(isPh ? 'KABUUANG KONSUMO' : 'HOUSEHOLD TOTALS', style: TextStyle(color: hintColor, fontSize: 11, letterSpacing: 1.2)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: surfaceColor.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    _buildSummaryRow(isPh ? 'Araw-araw' : 'Daily', optimizedDailyKwh, optimizedDailyCost, textColor, hintColor),
                    const Divider(color: Colors.white12, height: 24),
                    _buildSummaryRow(isPh ? 'Lingguhan' : 'Weekly', optimizedWeeklyKwh, optimizedWeeklyCost, textColor, hintColor),
                    const Divider(color: Colors.white12, height: 24),
                    _buildSummaryRow(isPh ? 'Buwanan' : 'Monthly', optimizedMonthlyKwh, optimizedMonthlyCost, AppColors.appYellow, hintColor, isBold: true),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // 3. APPLIANCE BREAKDOWN
              Text(isPh ? 'DETALYENG GASTUSIN' : 'APPLIANCE BREAKDOWN', style: TextStyle(color: hintColor, fontSize: 11, letterSpacing: 1.2)),
              const SizedBox(height: 10),

              ...devices.map((device) {
                final bool isReduced = device.adjustedHours < device.userAssignedHours;
                final Color statusColor = device.isLocked ? AppColors.appYellow : (isReduced ? Colors.orange : Colors.greenAccent);

                final double devKw = device.presetWattage / 1000;
                final double devDailyKwh = devKw * device.adjustedHours;
                final double devWeeklyKwh = devDailyKwh * 7;
                final double devMonthlyKwh = devDailyKwh * 30;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: device.isLocked ? AppColors.appYellow.withValues(alpha: 0.3) : Colors.transparent),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: Icon(_getApplianceIcon(device.customName), color: statusColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(device.customName, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15)),
                                Text(isPh ? 'Lakas: ${device.presetWattage.toStringAsFixed(0)}W  |  Target: ${_formatTime(device.userAssignedHours)}' : 'Power: ${device.presetWattage.toStringAsFixed(0)}W  |  Target: ${_formatTime(device.userAssignedHours)}', style: TextStyle(color: hintColor, fontSize: 11)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(_formatTime(device.adjustedHours), style: TextStyle(color: statusColor, fontSize: 16, fontWeight: FontWeight.bold)),
                              Text(device.isLocked ? (isPh ? 'Naka-lock' : 'Locked') : (isReduced ? (isPh ? 'Binawasan' : 'Reduced') : (isPh ? 'Na-optimize' : 'Optimized')), style: TextStyle(color: hintColor, fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatCol(isPh ? 'Arawan' : 'Daily', devDailyKwh, devDailyKwh * _activeRate, textColor, hintColor),
                            _buildStatCol(isPh ? 'Lingguhan' : 'Weekly', devWeeklyKwh, devWeeklyKwh * _activeRate, textColor, hintColor),
                            _buildStatCol(isPh ? 'Buwanan' : 'Monthly', devMonthlyKwh, devMonthlyKwh * _activeRate, textColor, hintColor),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double kwh, double cost, Color mainColor, Color hintColor, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: hintColor, fontSize: isBold ? 14 : 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Row(
          children: [
            Text('${kwh.toStringAsFixed(1)} kWh', style: TextStyle(color: hintColor, fontSize: 13)),
            const SizedBox(width: 16),
            SizedBox(
              width: 80,
              child: Text('₱${cost.toStringAsFixed(2)}', textAlign: TextAlign.right, style: TextStyle(color: mainColor, fontSize: isBold ? 16 : 14, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCol(String label, double kwh, double cost, Color textColor, Color hintColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: hintColor, fontSize: 10, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text('${kwh.toStringAsFixed(2)} kWh', style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
        Text('₱${cost.toStringAsFixed(0)}', style: TextStyle(color: Colors.greenAccent.withValues(alpha: 0.8), fontSize: 12)),
      ],
    );
  }
}
