import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  bool _isLoading = true;
  double _totalMonthlyKwh = 0.0;
  Map<String, double> _categoryBreakdown = {};
  
  // Define a color palette for our categories
  final Map<String, Color> _categoryColors = {
    'Cooling': AppColors.appYellow,
    'Kitchen': Colors.greenAccent,
    'Entertainment': AppColors.adminRed,
    'Lighting': Colors.cyanAccent,
    'Other': Colors.grey.shade400,
  };

  @override
  void initState() {
    super.initState();
    _fetchAnalysisData();
  }

  Future<void> _fetchAnalysisData() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final devices = await supabase.from('appliances').select().eq('user_id', userId);
      
      double totalKwh = 0;
      Map<String, double> breakdown = {};

      for (var device in devices) {
        final double monthlyKwh = (device['watts'] / 1000) * device['hours_per_day'] * device['quantity'] * 30;
        final String category = device['category'] ?? 'Other';
        
        totalKwh += monthlyKwh;
        breakdown[category] = (breakdown[category] ?? 0) + monthlyKwh;
      }

      if (mounted) {
        setState(() {
          _totalMonthlyKwh = totalKwh;
          _categoryBreakdown = breakdown;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.appYellow));

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Analysis', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),

            // Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.inputBackground.withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total consumption, this month', style: TextStyle(color: AppColors.textHintColor, fontSize: 13)),
                  const SizedBox(height: 8),
                  Text(
                    '${_totalMonthlyKwh.toStringAsFixed(1)} kWh',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: const Text('Live Estimate', style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Dynamic Pie Chart
            if (_totalMonthlyKwh > 0)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.inputBackground.withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    SizedBox(
                      height: 120,
                      width: 120,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: 30,
                          sections: _categoryBreakdown.entries.map((entry) {
                            final double percentage = (entry.value / _totalMonthlyKwh) * 100;
                            final color = _categoryColors[entry.key] ?? Colors.grey.shade400;
                            return PieChartSectionData(color: color, value: percentage, title: '', radius: 25);
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 30),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _categoryBreakdown.entries.map((entry) {
                          final double percentage = (entry.value / _totalMonthlyKwh) * 100;
                          final color = _categoryColors[entry.key] ?? Colors.grey.shade400;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildLegendItem(color, entry.key, '${percentage.toStringAsFixed(1)}%'),
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
    );
  }

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
}