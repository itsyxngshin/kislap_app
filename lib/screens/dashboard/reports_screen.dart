import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import '../../theme/app_colors.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = true;
  double _monthlyKwh = 0.0;
  double _monthlyCost = 0.0;
  double _avgDailyCost = 0.0;
  String _topDevice = 'None';
  List<double> _simulatedDailyUsage = [];

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  Future<void> _fetchReportData() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Fetch Profile, Rates, and Devices
      final profile = await supabase.from('profiles').select('location').eq('id', user.id).single();
      final location = profile['location'] as String;
      
      final rateData = await supabase.from('billing_rates').select().order('billing_month', ascending: false).limit(1).single();
      final rate = (location == 'island' ? rateData['island_rate'] : rateData['mainland_rate']) as num;

      final devices = await supabase.from('appliances').select().eq('user_id', user.id);
      
      double dailyKwhSum = 0;
      double highestDeviceKwh = 0;
      String highestDeviceName = 'None';

      for (var device in devices) {
        final double dailyKwh = (device['watts'] / 1000) * device['hours_per_day'] * device['quantity'];
        dailyKwhSum += dailyKwh;
        
        if (dailyKwh > highestDeviceKwh) {
          highestDeviceKwh = dailyKwh;
          highestDeviceName = device['name'];
        }
      }

      // Simulate 7 days of slightly varying usage around the average for the prototype chart
      final random = Random();
      final List<double> weeklyData = List.generate(7, (index) {
        // Varies by +/- 15% from the average
        final variance = dailyKwhSum * 0.15;
        return dailyKwhSum + (random.nextDouble() * variance * 2) - variance;
      });

      if (mounted) {
        setState(() {
          _monthlyKwh = dailyKwhSum * 30;
          _monthlyCost = _monthlyKwh * rate;
          _avgDailyCost = dailyKwhSum * rate;
          _topDevice = highestDeviceName;
          _simulatedDailyUsage = weeklyData;
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
            const Text('Monthly Report', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),

            // Top Stats Grid
            Row(
              children: [
                Expanded(child: _buildStatCard('Consumption', '${_monthlyKwh.toStringAsFixed(1)} kWh')),
                const SizedBox(width: 15),
                Expanded(child: _buildStatCard('Est. bill', '₱${_monthlyCost.toStringAsFixed(0)}', isHighlight: true)),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _buildStatCard('Avg daily cost', '₱${_avgDailyCost.toStringAsFixed(0)}')),
                const SizedBox(width: 15),
                Expanded(child: _buildStatCard('Top device', _topDevice, isTextSmall: true)),
              ],
            ),
            const SizedBox(height: 30),

            // The Bar Chart
            if (_simulatedDailyUsage.isNotEmpty && _monthlyKwh > 0)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.inputBackground.withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Consumption trend (Simulated)', style: TextStyle(color: AppColors.textHintColor, fontSize: 13)),
                    const SizedBox(height: 30),
                    SizedBox(
                      height: 200,
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
                                    return Text(days[value.toInt()], style: const TextStyle(color: AppColors.textHintColor, fontSize: 10));
                                  }
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
                          barGroups: List.generate(7, (index) => _buildBarGroup(index, _simulatedDailyUsage[index])),
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

  Widget _buildStatCard(String title, String value, {bool isHighlight = false, bool isTextSmall = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.inputBackground.withOpacity(0.5), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textHintColor, fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: isHighlight ? AppColors.appYellow : Colors.white, fontSize: isTextSmall ? 16 : 22, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [BarChartRodData(toY: y, color: AppColors.appYellow, width: 14, borderRadius: BorderRadius.circular(4))],
    );
  }
}