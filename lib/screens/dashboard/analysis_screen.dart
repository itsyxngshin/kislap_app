import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../providers/inventory_provider.dart';

class AnalysisScreen extends ConsumerWidget {
  const AnalysisScreen({super.key});

  // Define a color palette for our categories
  final Map<String, Color> _categoryColors = const {
    'Cooling': AppColors.appYellow,
    'Kitchen': Colors.greenAccent,
    'Entertainment': AppColors.adminRed,
    'Lighting': Colors.cyanAccent,
    'Other': Colors.grey,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Instantly pull the active inventory from Riverpod
    final devices = ref.watch(inventoryProvider);

    // 2. Compute the breakdown locally
    double totalMonthlyKwh = 0.0;
    Map<String, double> categoryBreakdown = {};

    for (var device in devices) {
      final double monthlyKwh =
          (device.presetWattage / 1000) * device.adjustedHours * 30;
      final String category = device.category;

      totalMonthlyKwh += monthlyKwh;
      categoryBreakdown[category] =
          (categoryBreakdown[category] ?? 0) + monthlyKwh;
    }

    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = textColor.withValues(alpha: 0.6);
    final surfaceColor = Theme.of(context).colorScheme.surface;

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
                'Analysis',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 20),

              // Summary Card
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
                      'Total consumption, this month',
                      style: TextStyle(color: hintColor, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${totalMonthlyKwh.toStringAsFixed(1)} kWh',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Live Estimate',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Dynamic Pie Chart
              if (totalMonthlyKwh > 0)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: surfaceColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 120,
                        width: 120,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 4,
                            centerSpaceRadius: 30,
                            sections: categoryBreakdown.entries.map((entry) {
                              final double percentage =
                                  (entry.value / totalMonthlyKwh) * 100;
                              final color =
                                  _categoryColors[entry.key] ?? Colors.grey;
                              return PieChartSectionData(
                                color: color,
                                value: percentage,
                                title: '',
                                radius: 25,
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 30),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: categoryBreakdown.entries.map((entry) {
                            final double percentage =
                                (entry.value / totalMonthlyKwh) * 100;
                            final color =
                                _categoryColors[entry.key] ?? Colors.grey;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _buildLegendItem(
                                color,
                                entry.key,
                                '${percentage.toStringAsFixed(1)}%',
                                textColor,
                                hintColor,
                              ),
                            );
                          }).toList(),
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

  Widget _buildLegendItem(
    Color color,
    String label,
    String percentage,
    Color textColor,
    Color hintColor,
  ) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: TextStyle(color: hintColor, fontSize: 13)),
        ),
        Text(
          percentage,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
