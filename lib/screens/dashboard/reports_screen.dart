import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_colors.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Monthly Report', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),

            // 1. Month Selector
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.inputBackground.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.chevron_left, color: Colors.white),
                  Text('July 2026', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Icon(Icons.chevron_right, color: Colors.white),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Top Stats Grid
            Row(
              children: [
                Expanded(child: _buildStatCard('Consumption', '352.5 kWh')),
                const SizedBox(width: 15),
                Expanded(child: _buildStatCard('Est. bill', '₱3,905', isHighlight: true)),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _buildStatCard('Avg daily cost', '₱130.18')),
                const SizedBox(width: 15),
                Expanded(child: _buildStatCard('Top device', 'Air conditioner', isTextSmall: true)),
              ],
            ),
            const SizedBox(height: 30),

            // 3. The Bar Chart
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.inputBackground.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Consumption trend, kWh/day', style: TextStyle(color: AppColors.textHintColor, fontSize: 13)),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 20,
                        barTouchData: BarTouchData(enabled: false), // Disable popups for prototype
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                // Show labels only on the first and last day
                                if (value == 0) return const Text('Jul 1', style: TextStyle(color: AppColors.textHintColor, fontSize: 10));
                                if (value == 6) return const Text('Jul 31', style: TextStyle(color: AppColors.textHintColor, fontSize: 10));
                                return const Text('');
                              },
                              reservedSize: 22,
                            ),
                          ),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          _buildBarGroup(0, 12),
                          _buildBarGroup(1, 15),
                          _buildBarGroup(2, 8),
                          _buildBarGroup(3, 18),
                          _buildBarGroup(4, 14),
                          _buildBarGroup(5, 10),
                          _buildBarGroup(6, 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for the grid stat cards
  Widget _buildStatCard(String title, String value, {bool isHighlight = false, bool isTextSmall = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textHintColor, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            value, 
            style: TextStyle(
              color: isHighlight ? AppColors.appYellow : Colors.white, 
              fontSize: isTextSmall ? 16 : 22, 
              fontWeight: FontWeight.bold
            ),
          ),
        ],
      ),
    );
  }

  // Helper to generate the chart bars
  BarChartGroupData _buildBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: AppColors.appYellow,
          width: 14,
          borderRadius: BorderRadius.circular(4),
        )
      ],
    );
  }
}