import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../providers/inventory_provider.dart';
import '../../services/database_helper.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  double _activeRate = 11.08;
  bool _isLoadingSettings = true;
  List<double> _simulatedDailyUsage = [];

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
          _activeRate = (settings.first['tariff_rate'] as num).toDouble();
        });
      }
    } catch (_) {}
    setState(() => _isLoadingSettings = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingSettings) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.appYellow),
      );
    }

    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = textColor.withValues(alpha: 0.6);
    final surfaceColor = Theme.of(context).colorScheme.surface;

    // Reactively watch inventory
    final devices = ref.watch(inventoryProvider);

    double dailyKwhSum = 0;
    double highestDeviceKwh = 0;
    String highestDeviceName = 'None';

    for (var device in devices) {
      final double dailyKwh =
          (device.presetWattage / 1000) * device.adjustedHours;
      dailyKwhSum += dailyKwh;

      if (dailyKwh > highestDeviceKwh) {
        highestDeviceKwh = dailyKwh;
        highestDeviceName = device.customName;
      }
    }

    final double monthlyKwh = dailyKwhSum * 30;
    final double monthlyCost = monthlyKwh * _activeRate;
    final double avgDailyCost = dailyKwhSum * _activeRate;

    // Simulate 7 days of slightly varying usage for the prototype chart
    if (_simulatedDailyUsage.isEmpty && dailyKwhSum > 0) {
      final random = Random();
      _simulatedDailyUsage = List.generate(7, (index) {
        final variance = dailyKwhSum * 0.15;
        return dailyKwhSum + (random.nextDouble() * variance * 2) - variance;
      });
    }

    return Container(
      decoration: AppTheme.globalBackground(context),
      child: SafeArea(
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
                'Monthly Report',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 20),

              // Top Stats Grid
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Consumption',
                      '${monthlyKwh.toStringAsFixed(1)} kWh',
                      surfaceColor,
                      hintColor,
                      textColor,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildStatCard(
                      'Est. bill',
                      '₱${monthlyCost.toStringAsFixed(0)}',
                      surfaceColor,
                      hintColor,
                      textColor,
                      isHighlight: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Avg daily cost',
                      '₱${avgDailyCost.toStringAsFixed(0)}',
                      surfaceColor,
                      hintColor,
                      textColor,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildStatCard(
                      'Top device',
                      highestDeviceName,
                      surfaceColor,
                      hintColor,
                      textColor,
                      isTextSmall: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // The Bar Chart
              if (_simulatedDailyUsage.isNotEmpty && monthlyKwh > 0)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: surfaceColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Consumption trend (Simulated)',
                        style: TextStyle(color: hintColor, fontSize: 13),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: (_simulatedDailyUsage.reduce(max) * 1.2)
                                .ceilToDouble(),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    const days = [
                                      'Mon',
                                      'Tue',
                                      'Wed',
                                      'Thu',
                                      'Fri',
                                      'Sat',
                                      'Sun',
                                    ];
                                    if (value >= 0 && value < 7) {
                                      return Text(
                                        days[value.toInt()],
                                        style: TextStyle(
                                          color: hintColor,
                                          fontSize: 10,
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                  reservedSize: 22,
                                ),
                              ),
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            barGroups: List.generate(
                              7,
                              (index) => _buildBarGroup(
                                index,
                                _simulatedDailyUsage[index],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color surfaceColor,
    Color hintColor,
    Color textColor, {
    bool isHighlight = false,
    bool isTextSmall = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: hintColor, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: isHighlight ? AppColors.appYellow : textColor,
              fontSize: isTextSmall ? 16 : 22,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: AppColors.appYellow,
          width: 14,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
