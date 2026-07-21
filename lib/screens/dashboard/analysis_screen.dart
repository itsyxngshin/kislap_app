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
  double _activeRate = 11.08;
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
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.appYellow),
        ),
      );
    }

    final devices = ref.watch(inventoryProvider);

    // Calculate Original vs Optimized Data
    double originalDailyKwh = 0;
    double optimizedDailyKwh = 0;

    for (var device in devices) {
      final double kw = device.presetWattage / 1000;
      originalDailyKwh += kw * device.userAssignedHours;
      optimizedDailyKwh += kw * device.adjustedHours;
    }

    final double originalMonthlyCost = originalDailyKwh * _activeRate * 30;
    final double optimizedMonthlyCost = optimizedDailyKwh * _activeRate * 30;

    // Chart scaling logic
    final double maxCost = originalMonthlyCost > _targetBudget
        ? originalMonthlyCost
        : _targetBudget;

    return Container(
      decoration: AppTheme.globalBackground(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Data Analysis',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'IMPACT SUMMARY',
                style: TextStyle(
                  color: hintColor,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),

              // Big Number Comparison
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: surfaceColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Original Cost',
                            style: TextStyle(color: hintColor, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₱${originalMonthlyCost.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppColors.adminRed,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: hintColor.withValues(alpha: 0.3),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Optimized Cost',
                            style: TextStyle(color: hintColor, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₱${optimizedMonthlyCost.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              Text(
                'FINANCIAL TRAJECTORY CHART',
                style: TextStyle(
                  color: hintColor,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),

              // Visual Bar Chart
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: surfaceColor.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: textColor.withValues(alpha: 0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBarRow(
                      'Target Budget',
                      _targetBudget,
                      maxCost,
                      AppColors.appYellow,
                      textColor,
                      hintColor,
                    ),
                    const SizedBox(height: 20),
                    _buildBarRow(
                      'Unregulated Usage',
                      originalMonthlyCost,
                      maxCost,
                      AppColors.adminRed,
                      textColor,
                      hintColor,
                    ),
                    const SizedBox(height: 20),
                    _buildBarRow(
                      'System Optimized',
                      optimizedMonthlyCost,
                      maxCost,
                      Colors.greenAccent,
                      textColor,
                      hintColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              Text(
                'DEVICE LEVEL ADJUSTMENTS',
                style: TextStyle(
                  color: hintColor,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),

              ...devices.map((device) {
                final bool isReduced =
                    device.adjustedHours < device.userAssignedHours;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: device.isLocked
                          ? AppColors.appYellow.withValues(alpha: 0.3)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        device.isLocked ? Icons.lock : Icons.auto_graph,
                        color: device.isLocked
                            ? AppColors.appYellow
                            : (isReduced ? Colors.orange : Colors.greenAccent),
                        size: 20,
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              device.customName,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${device.userAssignedHours}h requested',
                              style: TextStyle(color: hintColor, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${device.adjustedHours.toStringAsFixed(1)}h',
                        style: TextStyle(
                          color: device.isLocked
                              ? AppColors.appYellow
                              : (isReduced
                                    ? Colors.orange
                                    : Colors.greenAccent),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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

  Widget _buildBarRow(
    String label,
    double value,
    double maxScale,
    Color barColor,
    Color textColor,
    Color hintColor,
  ) {
    // Prevent division by zero
    double percentage = maxScale > 0 ? (value / maxScale) : 0;
    if (percentage > 1.0) percentage = 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '₱${value.toStringAsFixed(0)}',
              style: TextStyle(color: hintColor, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage,
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: barColor.withValues(alpha: 0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
