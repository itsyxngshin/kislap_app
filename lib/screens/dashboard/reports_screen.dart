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
  double _activeRate = 12.35; // Default to regional rate
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

    final devices = ref.watch(inventoryProvider);

    double dailyKwhSum = 0;
    double highestDeviceKwh = 0;
    String highestDeviceName = 'None';

    for (var device in devices) {
      final double dailyKwh = (device.presetWattage / 1000) * device.adjustedHours;
      dailyKwhSum += dailyKwh;

      if (dailyKwh > highestDeviceKwh) {
        highestDeviceKwh = dailyKwh;
        highestDeviceName = device.customName;
      }
    }

    final double monthlyKwh = dailyKwhSum * 30;
    final double monthlyCost = monthlyKwh * _activeRate;
    final double avgDailyCost = dailyKwhSum * _activeRate;

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
          padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monthly Report\n(Buwanang Ulat)',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor, height: 1.2),
              ),
              const SizedBox(height: 25),

              // Top Stats Grid
              Row(
                children: [
                  Expanded(child: _buildStatCard('Consumption\n(Konsumo)', '${monthlyKwh.toStringAsFixed(1)} kWh', surfaceColor, hintColor, textColor)),
                  const SizedBox(width: 15),
                  Expanded(child: _buildStatCard('Est. Bill\n(Est. na Bayarin)', '₱${monthlyCost.toStringAsFixed(0)}', surfaceColor, hintColor, textColor, isHighlight: true)),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: _buildStatCard('Avg Daily Cost\n(Gastos Kada Araw)', '₱${avgDailyCost.toStringAsFixed(0)}', surfaceColor, hintColor, textColor)),
                  const SizedBox(width: 15),
                  Expanded(child: _buildStatCard('Top Device\n(Pinakamalakas)', highestDeviceName, surfaceColor, hintColor, textColor, isTextSmall: true)),
                ],
              ),
              const SizedBox(height: 30),

              // Premium Tricolor Bar Chart
              if (_simulatedDailyUsage.isNotEmpty && monthlyKwh > 0)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: surfaceColor.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: textColor.withValues(alpha: 0.05)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CONSUMPTION TREND (TAKBO NG KONSUMO)', style: TextStyle(color: hintColor, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 30),
                      SizedBox(
                        height: 220,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: (_simulatedDailyUsage.reduce(max) * 1.2).ceilToDouble(),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                    if (value >= 0 && value < 7) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(days[value.toInt()], style: TextStyle(color: hintColor, fontSize: 11, fontWeight: FontWeight.bold)),
                                      );
                                    }
                                    return const Text('');
                                  },
                                  reservedSize: 30,
                                ),
                              ),
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            barGroups: List.generate(7, (index) => _buildPremiumBarGroup(index, _simulatedDailyUsage[index])),
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

  Widget _buildStatCard(String title, String value, Color surfaceColor, Color hintColor, Color textColor, {bool isHighlight = false, bool isTextSmall = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isHighlight ? AppColors.appYellow.withValues(alpha: 0.3) : Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: hintColor, fontSize: 11, height: 1.3)),
          const SizedBox(height: 12),
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

  BarChartGroupData _buildPremiumBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          width: 16,
          gradient: const LinearGradient(
            colors: [Colors.greenAccent, AppColors.appYellow, AppColors.adminRed],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          borderRadius: BorderRadius.circular(6),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: (_simulatedDailyUsage.reduce(max) * 1.2).ceilToDouble(),
            color: Colors.black26,
          ),
        ),
      ],
    );
  }
}
