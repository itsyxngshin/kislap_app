import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/settings_provider.dart';
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
  bool _showFormulas = false;
  String _sortOrder = 'Highest kWh';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final db = await DatabaseHelper.instance.database;

      final settings = await db.query('user_settings', limit: 1);
      if (settings.isNotEmpty && mounted) {
        setState(() {
          _targetBudget = (settings.first['monthly_budget'] as num).toDouble();
        });
      }

      final pastBills = await db.query(
        'recording_periods',
        orderBy: 'period_month DESC',
        limit: 1,
      );
      if (pastBills.isNotEmpty && mounted) {
        setState(() {
          _activeRate = (pastBills.first['billing_rate'] as num).toDouble();
        });
      } else if (settings.isNotEmpty && mounted) {
        setState(() {
          _activeRate = (settings.first['tariff_rate'] as num).toDouble();
          if (_activeRate <= 0) _activeRate = 12.35;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
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
    if (lower.contains('fridge') || lower.contains('refrigerator'))
      return Icons.kitchen;
    if (lower.contains('light') || lower.contains('bulb'))
      return Icons.lightbulb_outline;
    if (lower.contains('wash')) return Icons.local_laundry_service_outlined;
    if (lower.contains('laptop') || lower.contains('computer'))
      return Icons.computer;
    return Icons.electrical_services;
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = textColor.withOpacity(0.6);
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final isPh = ref.watch(settingsProvider).language == 'ph';

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.appYellow),
        ),
      );
    }

    final devices = ref.watch(inventoryProvider);

    double originalDailyKwh = 0;
    double optimizedDailyKwh = 0;

    for (var device in devices) {
      // FIX: Base math accounts for quantity
      final double kw = (device.presetWattage * device.quantity) / 1000;
      originalDailyKwh += kw * device.userAssignedHours;
      optimizedDailyKwh += kw * device.adjustedHours;
    }

    // Sort Logic execution
    List<dynamic> sortedDevices = List.from(devices);
    if (_sortOrder == 'Highest kWh') {
      sortedDevices.sort(
        (a, b) => ((b.presetWattage * b.quantity * b.adjustedHours)).compareTo(
          a.presetWattage * a.quantity * a.adjustedHours,
        ),
      );
    } else if (_sortOrder == 'Lowest kWh') {
      sortedDevices.sort(
        (a, b) => ((a.presetWattage * a.quantity * a.adjustedHours)).compareTo(
          b.presetWattage * b.quantity * b.adjustedHours,
        ),
      );
    } else if (_sortOrder == 'Name (A-Z)') {
      sortedDevices.sort(
        (a, b) => a.customName.toString().toLowerCase().compareTo(
          b.customName.toString().toLowerCase(),
        ),
      );
    }

    final double optimizedWeeklyKwh = optimizedDailyKwh * 7;
    final double optimizedMonthlyKwh = optimizedDailyKwh * 30;

    final double originalMonthlyCost = (originalDailyKwh * 30) * _activeRate;
    final double optimizedDailyCost = optimizedDailyKwh * _activeRate;
    final double optimizedWeeklyCost = optimizedWeeklyKwh * _activeRate;
    final double optimizedMonthlyCost = optimizedMonthlyKwh * _activeRate;

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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: 120,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPh ? 'Pagsusuri' : 'Analysis',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 25),

              Text(
                isPh ? 'PAGSUSURI NG TREND' : 'TREND ANALYSIS',
                style: TextStyle(
                  color: hintColor,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: trendColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: trendColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(trendIcon, color: trendColor, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            trendTitle,
                            style: TextStyle(
                              color: trendColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      trendDesc,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              Text(
                isPh ? 'KABUUANG KONSUMO' : 'HOUSEHOLD TOTALS',
                style: TextStyle(
                  color: hintColor,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: surfaceColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      isPh ? 'Araw-araw' : 'Daily',
                      optimizedDailyKwh,
                      optimizedDailyCost,
                      textColor,
                      hintColor,
                    ),
                    const Divider(color: Colors.white12, height: 24),
                    _buildSummaryRow(
                      isPh ? 'Lingguhan' : 'Weekly',
                      optimizedWeeklyKwh,
                      optimizedWeeklyCost,
                      textColor,
                      hintColor,
                    ),
                    const Divider(color: Colors.white12, height: 24),
                    _buildSummaryRow(
                      isPh ? 'Buwanan' : 'Monthly',
                      optimizedMonthlyKwh,
                      optimizedMonthlyCost,
                      AppColors.appYellow,
                      hintColor,
                      isBold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              GestureDetector(
                onTap: () => setState(() => _showFormulas = !_showFormulas),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.appYellow.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.appYellow.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.calculate_outlined,
                                color: AppColors.appYellow,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                isPh
                                    ? 'PAANO KINAKALKULA NG KISLAP'
                                    : 'HOW KISLAP COMPUTES',
                                style: const TextStyle(
                                  color: AppColors.appYellow,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            _showFormulas
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: hintColor,
                          ),
                        ],
                      ),
                      if (_showFormulas) ...[
                        const SizedBox(height: 16),
                        Divider(color: AppColors.appYellow.withOpacity(0.2)),
                        const SizedBox(height: 16),
                        _buildMathRow(
                          isPh ? '1. Kuryente (kWh)' : '1. Consumption (kWh)',
                          isPh
                              ? 'Paano kinukuha ang pang-araw-araw na konsumo:'
                              : 'How daily power usage is determined:',
                          '(Wattage × Quantity ÷ 1000) × Hours', // FIX: Explicitly documents Quantity in math
                          textColor,
                          hintColor,
                        ),
                        const SizedBox(height: 16),
                        _buildMathRow(
                          isPh
                              ? '2. Optimization (Pagbawas)'
                              : '2. Optimization Engine',
                          isPh
                              ? 'Kung lampas sa budget, binabawasan nang pantay-pantay ang oras ng mga naka-unlock na gamit. Ang mga naka-lock (🔒) ay hindi ginagalaw.'
                              : 'If over budget, unlocked items are reduced proportionally to fit the financial limit. Locked items (🔒) are never touched.',
                          'Remaining Budget ÷ Unlocked kWh',
                          textColor,
                          hintColor,
                        ),
                        const SizedBox(height: 16),
                        _buildMathRow(
                          isPh ? '3. Est. Bayad (Cost)' : '3. Estimated Cost',
                          isPh
                              ? 'Pinararami ang konsumo sa halaga ng kuryente sa inyong rehiyon.'
                              : 'Multiplying the total power used by your local grid utility rate.',
                          'Total kWh × Tariff Rate (₱/kWh)',
                          textColor,
                          hintColor,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // NEW: Sorted Appliance Breakdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isPh ? 'DETALYENG GASTUSIN' : 'APPLIANCE BREAKDOWN',
                    style: TextStyle(
                      color: hintColor,
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.sort, color: hintColor, size: 20),
                    color: surfaceColor,
                    onSelected: (val) => setState(() => _sortOrder = val),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'Highest kWh',
                        child: Text(
                          isPh ? 'Pinakamataas na kWh' : 'Highest kWh',
                          style: TextStyle(color: textColor, fontSize: 13),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'Lowest kWh',
                        child: Text(
                          isPh ? 'Pinakamababang kWh' : 'Lowest kWh',
                          style: TextStyle(color: textColor, fontSize: 13),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'Name (A-Z)',
                        child: Text(
                          isPh ? 'Pangalan (A-Z)' : 'Name (A-Z)',
                          style: TextStyle(color: textColor, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              ...sortedDevices.map((device) {
                final bool isReduced =
                    device.adjustedHours < device.userAssignedHours;
                final Color statusColor = device.isLocked
                    ? AppColors.appYellow
                    : (isReduced ? Colors.orange : Colors.greenAccent);

                // Multiply by Quantity to show the true total impact in the breakdown
                final double devKw =
                    (device.presetWattage * device.quantity) / 1000;
                final double devDailyKwh = devKw * device.adjustedHours;
                final double devWeeklyKwh = devDailyKwh * 7;
                final double devMonthlyKwh = devDailyKwh * 30;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: device.isLocked
                          ? AppColors.appYellow.withOpacity(0.3)
                          : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getApplianceIcon(device.customName),
                              color: statusColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${device.customName} (x${device.quantity})',
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  isPh
                                      ? 'Lakas: ${device.presetWattage.toStringAsFixed(0)}W  |  Target: ${_formatTime(device.userAssignedHours)}'
                                      : 'Power: ${device.presetWattage.toStringAsFixed(0)}W  |  Target: ${_formatTime(device.userAssignedHours)}',
                                  style: TextStyle(
                                    color: hintColor,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatTime(device.adjustedHours),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                device.isLocked
                                    ? (isPh ? 'Naka-lock' : 'Locked')
                                    : (isReduced
                                          ? (isPh ? 'Binawasan' : 'Reduced')
                                          : (isPh
                                                ? 'Na-optimize'
                                                : 'Optimized')),
                                style: TextStyle(
                                  color: hintColor,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatCol(
                              isPh ? 'Arawan' : 'Daily',
                              devDailyKwh,
                              devDailyKwh * _activeRate,
                              textColor,
                              hintColor,
                            ),
                            _buildStatCol(
                              isPh ? 'Lingguhan' : 'Weekly',
                              devWeeklyKwh,
                              devWeeklyKwh * _activeRate,
                              textColor,
                              hintColor,
                            ),
                            _buildStatCol(
                              isPh ? 'Buwanan' : 'Monthly',
                              devMonthlyKwh,
                              devMonthlyKwh * _activeRate,
                              textColor,
                              hintColor,
                            ),
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

  Widget _buildSummaryRow(
    String label,
    double kwh,
    double cost,
    Color mainColor,
    Color hintColor, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: hintColor,
            fontSize: isBold ? 14 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Row(
          children: [
            Text(
              '${kwh.toStringAsFixed(1)} kWh',
              style: TextStyle(color: hintColor, fontSize: 13),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 80,
              child: Text(
                '₱${cost.toStringAsFixed(2)}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: mainColor,
                  fontSize: isBold ? 16 : 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCol(
    String label,
    double kwh,
    double cost,
    Color textColor,
    Color hintColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: hintColor, fontSize: 10, letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          '${kwh.toStringAsFixed(2)} kWh',
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '₱${cost.toStringAsFixed(0)}',
          style: TextStyle(
            color: Colors.greenAccent.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMathRow(
    String title,
    String desc,
    String formula,
    Color textColor,
    Color hintColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          desc,
          style: TextStyle(color: hintColor, fontSize: 12, height: 1.4),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            formula,
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 12,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
