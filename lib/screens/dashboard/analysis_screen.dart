import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_colors.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Analysis', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),

            // 1. Total Consumption Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.inputBackground.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total consumption, this month', style: TextStyle(color: AppColors.textHintColor, fontSize: 13)),
                  const SizedBox(height: 8),
                  const Text(
                    '325.5 kWh',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.adminRed.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                    child: const Text('- 8% vs last month', style: TextStyle(color: AppColors.adminRed, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),
                  // A simple illustrative trendline using an Icon for the prototype
                  const Center(
                    child: Icon(Icons.trending_up, color: AppColors.appYellow, size: 60),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. The Pie Chart Breakdown
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.inputBackground.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  // The interactive chart
                  SizedBox(
                    height: 120,
                    width: 120,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 30,
                        sections: [
                          PieChartSectionData(color: AppColors.appYellow, value: 62, title: '', radius: 25), // AC
                          PieChartSectionData(color: Colors.greenAccent, value: 15, title: '', radius: 25), // Fridge
                          PieChartSectionData(color: AppColors.adminRed, value: 15, title: '', radius: 25), // Washer
                          PieChartSectionData(color: Colors.grey.shade400, value: 8, title: '', radius: 25), // Others
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 30),
                  // The Legend
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendItem(AppColors.appYellow, 'AC', '62%'),
                        const SizedBox(height: 10),
                        _buildLegendItem(Colors.greenAccent, 'Fridge', '15%'),
                        const SizedBox(height: 10),
                        _buildLegendItem(AppColors.adminRed, 'Washer', '15%'),
                        const SizedBox(height: 10),
                        _buildLegendItem(Colors.grey.shade400, 'Others', '8%'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 3. AI Recommendations
            const Text('Recommendations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 15),
            
            _buildRecommendationCard(
              'Cut AC runtime by 1 hour a day to save roughly ₱280 a month.',
            ),
            const SizedBox(height: 10),
            _buildRecommendationCard(
              'Unplug devices left in standby, phantom load adds up over a month.',
            ),
          ],
        ),
      ),
    );
  }

  // Helper for the Pie Chart Legend
  Widget _buildLegendItem(Color color, String label, String percentage) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13))),
        Text(percentage, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  // Helper for Recommendation Cards
  Widget _buildRecommendationCard(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
          ),
        ],
      ),
    );
  }
}