import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../../theme/app_colors.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/database_helper.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  double _activeRate = 12.35;
  String _rateSourceEn = 'Baseline setup rate';
  String _rateSourcePh = 'Base sa setup na rate';
  bool _isLoadingSettings = true;
  List<double> _calculatedDailyUsage = [];

  @override
  void initState() {
    super.initState();
    _fetchLocalSettings();
  }

  Future<void> _fetchLocalSettings() async {
    try {
      final db = await DatabaseHelper.instance.database;

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
        setState(() {
          _activeRate = (pastBills.first['billing_rate'] as num).toDouble();
          _rateSourceEn = "Based on previous month's rate";
          _rateSourcePh = "Base sa nakaraang buwan";
        });
      } else {
        final settings = await db.query('user_settings', limit: 1);
        if (settings.isNotEmpty && mounted) {
          setState(() {
            _activeRate = (settings.first['tariff_rate'] as num).toDouble();
            _rateSourceEn = "Baseline setup rate";
            _rateSourcePh = "Base sa setup na rate";
            if (_activeRate <= 0) _activeRate = 12.35;
          });
        }
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

  @override
  Widget build(BuildContext context) {
    final isPh = ref.watch(settingsProvider).language == 'ph';

    if (_isLoadingSettings) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.appYellow),
        ),
      );
    }

    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = textColor.withOpacity(0.6);
    final surfaceColor = Theme.of(context).colorScheme.surface;

    final devices = ref.watch(inventoryProvider);

    double dailyKwhSum = 0;
    double highestDeviceKwh = 0;
    String highestDeviceName = isPh ? 'Wala' : 'None';

    for (var device in devices) {
      final double dailyKwh =
          (device.presetWattage * device.quantity / 1000) *
          device.adjustedHours;
      dailyKwhSum += dailyKwh;

      if (dailyKwh > highestDeviceKwh) {
        highestDeviceKwh = dailyKwh;
        // Includes the quantity so users know multiple units drove up the rank
        highestDeviceName = '${device.customName} (x${device.quantity})';
      }
    }

    // Always sort reports by highest consumer downward for the data table
    List<dynamic> sortedDevices = List.from(devices);
    sortedDevices.sort(
      (a, b) => ((b.presetWattage * b.quantity * b.adjustedHours)).compareTo(
        a.presetWattage * a.quantity * a.adjustedHours,
      ),
    );

    final double monthlyKwh = dailyKwhSum * 30;
    final double monthlyCost = monthlyKwh * _activeRate;
    final double avgDailyCost = dailyKwhSum * _activeRate;

    if (_calculatedDailyUsage.isEmpty && dailyKwhSum > 0) {
      final List<double> dayFactors = [1.0, 0.95, 0.95, 0.95, 1.05, 1.10, 1.0];
      _calculatedDailyUsage = List.generate(7, (index) {
        return dailyKwhSum * dayFactors[index];
      });
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
                isPh ? 'Buwanang Ulat' : 'Monthly Report',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 25),

              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      isPh ? 'Konsumo' : 'Consumption',
                      '${monthlyKwh.toStringAsFixed(1)} kWh',
                      surfaceColor,
                      hintColor,
                      textColor,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildStatCard(
                      isPh ? 'Est. na Bayarin' : 'Est. Bill',
                      '₱${monthlyCost.toStringAsFixed(0)}',
                      surfaceColor,
                      hintColor,
                      textColor,
                      isHighlight: true,
                      subtitle: isPh ? _rateSourcePh : _rateSourceEn,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      isPh ? 'Gastos Kada Araw' : 'Avg Daily Cost',
                      '₱${avgDailyCost.toStringAsFixed(0)}',
                      surfaceColor,
                      hintColor,
                      textColor,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildStatCard(
                      isPh ? 'Pinakamalakas' : 'Top Device',
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

              if (_calculatedDailyUsage.isNotEmpty && monthlyKwh > 0)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: surfaceColor.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: textColor.withOpacity(0.05)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPh ? 'TAKBO NG KONSUMO' : 'CONSUMPTION TREND',
                        style: TextStyle(
                          color: hintColor,
                          fontSize: 11,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isPh
                            ? '* Isang kalkuladong distribusyon base sa iyong na-optimize na average, gamit ang mga karaniwang multiplier sa araw-araw.'
                            : '* A calculated distribution of your optimized average using standard daily multipliers.',
                        style: TextStyle(
                          color: hintColor,
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        height: 220,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: (_calculatedDailyUsage.reduce(max) * 1.2)
                                .ceilToDouble(),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final daysEn = [
                                      'Mon',
                                      'Tue',
                                      'Wed',
                                      'Thu',
                                      'Fri',
                                      'Sat',
                                      'Sun',
                                    ];
                                    final daysPh = [
                                      'Lun',
                                      'Mar',
                                      'Miy',
                                      'Huw',
                                      'Biy',
                                      'Sab',
                                      'Lin',
                                    ];
                                    if (value >= 0 && value < 7) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: Text(
                                          isPh
                                              ? daysPh[value.toInt()]
                                              : daysEn[value.toInt()],
                                          style: TextStyle(
                                            color: hintColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                  reservedSize: 30,
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
                              (index) => _buildSubtleBarGroup(
                                index,
                                _calculatedDailyUsage[index],
                                surfaceColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 30),
              Text(
                isPh ? 'DETALYENG GASTUSIN' : 'DETAILED BREAKDOWN',
                style: TextStyle(
                  color: hintColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: surfaceColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: textColor.withOpacity(0.05)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 20,
                    columns: [
                      DataColumn(
                        label: Text(
                          isPh ? 'Gamit' : 'Item',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          isPh ? 'Oras' : 'Opt. Hrs',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          isPh ? 'Buwanang kWh' : 'Monthly kWh',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    // FIX: Runs through the sortedDevices array, ensuring highest kWh drops down to lowest
                    rows: sortedDevices.map((device) {
                      final double monthlyKwh =
                          ((device.presetWattage * device.quantity / 1000) *
                              device.adjustedHours) *
                          30;
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              '${device.customName} (x${device.quantity})',
                              style: TextStyle(color: textColor),
                            ),
                          ),
                          DataCell(
                            Text(
                              _formatTime(device.adjustedHours),
                              style: const TextStyle(color: Colors.greenAccent),
                            ),
                          ),
                          DataCell(
                            Text(
                              monthlyKwh.toStringAsFixed(1),
                              style: TextStyle(color: textColor),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
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
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlight
              ? AppColors.appYellow.withOpacity(0.3)
              : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: hintColor, fontSize: 11, height: 1.3),
          ),
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
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: hintColor,
                fontSize: 9,
                fontStyle: FontStyle.italic,
                height: 1.2,
              ),
            ),
          ],
        ],
      ),
    );
  }

  BarChartGroupData _buildSubtleBarGroup(int x, double y, Color surfaceColor) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          width: 14,
          color: AppColors.appYellow.withOpacity(0.75),
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: (_calculatedDailyUsage.reduce(max) * 1.2).ceilToDouble(),
            color: Colors.black12,
          ),
        ),
      ],
    );
  }
}
