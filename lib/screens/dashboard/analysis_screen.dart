import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../providers/inventory_provider.dart';
import '../../services/database_helper.dart';

class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  double _activeRate = 12.35; // Default aligned with June 2026 Mainland Rate
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

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = textColor.withValues(alpha: 0.6);
    final surfaceColor = Theme.of(context).colorScheme.surface;

    if (_isLoading) {
      return Container(
        decoration: AppTheme.globalBackground(context),
        child: const Center(child: CircularProgressIndicator(color: AppColors.appYellow)),
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

    // Weekly and Monthly Extrapolations (Formulas: Daily * 7, Daily * 30)
    final double originalWeeklyKwh = originalDailyKwh * 7;
    final double originalMonthlyKwh = originalDailyKwh * 30;

    final double optimizedWeeklyKwh = optimizedDailyKwh * 7;
    final double optimizedMonthlyKwh = optimizedDailyKwh * 30;

    // Cost Extrapolations
    final double originalMonthlyCost = originalMonthlyKwh * _activeRate;
    final double optimizedDailyCost = optimizedDailyKwh * _activeRate;
    final double optimizedWeeklyCost = optimizedWeeklyKwh * _activeRate;
    final double optimizedMonthlyCost = optimizedMonthlyKwh * _activeRate;

    // Trend Analysis Logic
    final double monthlySavings = originalMonthlyCost - optimizedMonthlyCost;
    final bool isOverBudget = optimizedMonthlyCost > _targetBudget;
    final bool isSaving = monthlySavings > 0;

    String trendTitleEn = '';
    String trendTitlePh = '';
    String trendDescEn = '';
    String trendDescPh = '';
    Color trendColor = Colors.greenAccent;
    IconData trendIcon = Icons.trending_down;

    if (isOverBudget) {
      trendColor = AppColors.adminRed;
      trendIcon = Icons.warning_amber_rounded;
      trendTitleEn = 'Budget Exceeded';
      trendTitlePh = 'Sumobra sa Budget';
      trendDescEn = 'Even with optimization, your essential (locked) appliances exceed your ₱${_targetBudget.toStringAsFixed(0)} budget. Consider unlocking items.';
      trendDescPh = 'Kahit na may optimization, ang iyong mga naka-lock na appliances ay lalampas sa iyong budget. Maaari mong i-unlock ang ilang gamit.';
    } else if (isSaving) {
      trendColor = Colors.greenAccent;
      trendIcon = Icons.trending_down;
      trendTitleEn = 'Decreased Usage Trend';
      trendTitlePh = 'Bumaba ang Konsumo';
      trendDescEn = 'By optimizing your schedule, your projected monthly bill decreases by ₱${monthlySavings.toStringAsFixed(0)}. You are staying safely within your budget.';
      trendDescPh = 'Dahil sa optimization, nakatipid ka ng ₱${monthlySavings.toStringAsFixed(0)} sa inaasahang buwanang bill. Pasok na pasok ka sa iyong budget.';
    } else {
      trendColor = AppColors.appYellow;
      trendIcon = Icons.trending_flat;
      trendTitleEn = 'Stable Usage Trend';
      trendTitlePh = 'Walang Bawas sa Konsumo';
      trendDescEn = 'Your unregulated usage is already within your budget. No operating hours were reduced.';
      trendDescPh = 'Ang iyong orihinal na konsumo ay pasok na sa iyong budget. Walang binawas na oras sa iyong mga appliances.';
    }

    return Container(
      decoration: AppTheme.globalBackground(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(icon: Icon(Icons.arrow_back, color: textColor), onPressed: () => Navigator.pop(context)),
          title: Text('Analysis & Reports', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TREND ANALYSIS CARD (BILINGUAL)
              Text('TREND ANALYSIS (PAGSUSURI NG TREND)', style: TextStyle(color: hintColor, fontSize: 11, letterSpacing: 1.2)),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(trendTitleEn, style: TextStyle(color: trendColor, fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(trendTitlePh, style: TextStyle(color: trendColor.withValues(alpha: 0.7), fontSize: 13, fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(trendDescEn, style: TextStyle(color: textColor, fontSize: 13, height: 1.4)),
                    const SizedBox(height: 6),
                    Text(trendDescPh, style: TextStyle(color: hintColor, fontSize: 12, height: 1.4, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // 2. HOUSEHOLD TOTALS (As required by Step 8 of Engine Logic)
              Text('HOUSEHOLD TOTALS (KABUUANG KONSUMO)', style: TextStyle(color: hintColor, fontSize: 11, letterSpacing: 1.2)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: surfaceColor.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    _buildSummaryRow('Daily (Araw-araw)', optimizedDailyKwh, optimizedDailyCost, textColor, hintColor),
                    const Divider(color: Colors.white12, height: 24),
                    _buildSummaryRow('Weekly (Lingguhan)', optimizedWeeklyKwh, optimizedWeeklyCost, textColor, hintColor),
                    const Divider(color: Colors.white12, height: 24),
                    _buildSummaryRow('Monthly (Buwanan)', optimizedMonthlyKwh, optimizedMonthlyCost, AppColors.appYellow, hintColor, isBold: true),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // 3. APPLIANCE BREAKDOWN (Interactive & Detailed)
              Text('APPLIANCE BREAKDOWN (DETALYENG GASTUSIN)', style: TextStyle(color: hintColor, fontSize: 11, letterSpacing: 1.2)),
              const SizedBox(height: 10),

              ...devices.map((device) {
                final bool isReduced = device.adjustedHours < device.userAssignedHours;
                final Color statusColor = device.isLocked ? AppColors.appYellow : (isReduced ? Colors.orange : Colors.greenAccent);

                // Device specific math based on client formulas
                final double devKw = device.presetWattage / 1000;
                final double devDailyKwh = devKw * device.adjustedHours;
                final double devWeeklyKwh = devDailyKwh * 7;
                final double devMonthlyKwh = devDailyKwh * 30;

                final double devDailyCost = devDailyKwh * _activeRate;
                final double devWeeklyCost = devWeeklyKwh * _activeRate;
                final double devMonthlyCost = devMonthlyKwh * _activeRate;

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
                      // Header: Icon, Name, and Lock Toggle
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(device.isLocked ? Icons.lock : Icons.lock_open),
                            color: statusColor,
                            onPressed: () => ref.read(inventoryProvider.notifier).toggleLock(device.id, device.isLocked),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(device.customName, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15)),
                                Text('Power: ${device.presetWattage.toStringAsFixed(0)}W  |  Target: ${device.userAssignedHours.toStringAsFixed(1)}h', style: TextStyle(color: hintColor, fontSize: 11)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${device.adjustedHours.toStringAsFixed(1)}h', style: TextStyle(color: statusColor, fontSize: 18, fontWeight: FontWeight.bold)),
                              Text(device.isLocked ? 'Locked' : (isReduced ? 'Reduced' : 'Optimized'), style: TextStyle(color: hintColor, fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Detailed Data Table (Step 8 Requirement)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatCol('Daily', devDailyKwh, devDailyCost, textColor, hintColor),
                            _buildStatCol('Weekly', devWeeklyKwh, devWeeklyCost, textColor, hintColor),
                            _buildStatCol('Monthly', devMonthlyKwh, devMonthlyCost, textColor, hintColor),
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
