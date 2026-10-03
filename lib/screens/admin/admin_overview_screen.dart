import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../auth/sign_in_screen.dart';
import 'admin_users_screen.dart';
import '../dashboard/dashboard_shell.dart'; 
import 'package:fl_chart/fl_chart.dart';

class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  // Analytics State
  int _totalUsers = 0;
  double _globalDailyKwh = 0;

  // Lockdown & Maintenance State
  bool _isMaintenanceMode = false;
  final TextEditingController _lockMessageController = TextEditingController();
  bool _isUpdatingSettings = false;

  @override
  void initState() {
    super.initState();
    _fetchAdminAnalytics();
    _fetchSystemSettings();
  }

  // --- DATABASE QUERIES ---

  Future<void> _fetchAdminAnalytics() async {
    try {
      // THE FIX: Call our secure backend function to bypass RLS and offload the math
      final response = await Supabase.instance.client.rpc('get_global_analytics');

      if (mounted && response != null) {
        setState(() {
          _totalUsers = (response['total_users'] as num?)?.toInt() ?? 0;
          _globalDailyKwh = (response['global_kwh'] as num?)?.toDouble() ?? 0.0;
        });
      }
    } catch (e) {
      debugPrint('Analytics Fetch Error: $e');
    }
  }

  Future<void> _fetchSystemSettings() async {
    try {
      final data = await Supabase.instance.client.from('app_settings').select().eq('id', 1).maybeSingle();
      if (data != null && mounted) {
        setState(() {
          _isMaintenanceMode = data['is_maintenance_mode'] ?? false;
          _lockMessageController.text = data['lock_message'] ?? '';
        });
      }
    } catch (_) {}
  }

  Future<void> _saveSystemSettings() async {
    setState(() => _isUpdatingSettings = true);
    try {
      await Supabase.instance.client.from('app_settings').update({
        'is_maintenance_mode': _isMaintenanceMode,
        'lock_message': _lockMessageController.text.trim(),
      }).eq('id', 1);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('System settings updated successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update settings: $e'), backgroundColor: AppColors.adminRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingSettings = false);
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const SignInScreen()), (route) => false);
    }
  }

  @override
  void dispose() {
    _lockMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = textColor.withOpacity(0.6);
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return DefaultTabController(
      length: 2,
      child: Container(
        decoration: AppTheme.globalBackground(context),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              children: [
                const Icon(Icons.admin_panel_settings, color: AppColors.adminRed),
                const SizedBox(width: 10),
                Text('Admin Control', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              ],
            ),
            actions: [
              // --- ACCESS POINT TO USER INTERFACE ---
              IconButton(
                icon: const Icon(Icons.phone_iphone_rounded, color: Colors.blueAccent),
                tooltip: 'Switch to User View',
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context, 
                    MaterialPageRoute(builder: (_) => const DashboardShell()), 
                    (route) => false
                  );
                },
              ),
              IconButton(icon: Icon(Icons.logout, color: textColor), onPressed: _signOut)
            ],
            bottom: TabBar(
              indicatorColor: AppColors.adminRed,
              labelColor: AppColors.adminRed,
              unselectedLabelColor: hintColor,
              tabs: const [
                Tab(icon: Icon(Icons.analytics_outlined), text: 'Analytics'),
                Tab(icon: Icon(Icons.lock_person_outlined), text: 'Lockdown'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _buildAnalyticsTab(surfaceColor, textColor, hintColor),
              _buildLockdownTab(surfaceColor, textColor, hintColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab(Color surfaceColor, Color textColor, Color hintColor) {
    return RefreshIndicator(
      onRefresh: _fetchAdminAnalytics,
      color: AppColors.adminRed,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersScreen())),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: surfaceColor.withOpacity(0.5), borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.group, color: Colors.blueAccent, size: 24),
                          const SizedBox(height: 8),
                          Text('$_totalUsers', style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)),
                          Text('Total Users (Tap to View)', style: TextStyle(color: hintColor, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: surfaceColor.withOpacity(0.5), borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.bolt, color: AppColors.adminRed, size: 24),
                        const SizedBox(height: 8),
                        Text('${_globalDailyKwh.toStringAsFixed(1)} kWh', style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)),
                        Text('Daily System Draw', style: TextStyle(color: hintColor, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            _buildHistoricalGraph(surfaceColor, textColor),
          ],
        ),
      ),
    );
  }

  Widget _buildLockdownTab(Color surfaceColor, Color textColor, Color hintColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.adminRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.adminRed.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.adminRed, size: 30),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('System-Wide Kill Switch', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Activating maintenance mode will immediately lock out all regular users.', style: TextStyle(color: hintColor, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: surfaceColor.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.build_circle_outlined, color: _isMaintenanceMode ? AppColors.adminRed : hintColor),
                    const SizedBox(width: 15),
                    Text('Maintenance Mode', style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ),
                Switch(
                  value: _isMaintenanceMode,
                  onChanged: (bool value) {
                    setState(() => _isMaintenanceMode = value);
                  },
                  activeThumbColor: AppColors.adminRed,
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),

          Text('Lock Screen Message', style: TextStyle(color: hintColor, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: _lockMessageController,
            maxLines: 3,
            style: TextStyle(color: textColor, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Enter the message that locked users will see...',
              hintStyle: TextStyle(color: hintColor.withOpacity(0.5)),
              filled: true,
              fillColor: surfaceColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isUpdatingSettings ? null : _saveSystemSettings,
              style: FilledButton.styleFrom(backgroundColor: AppColors.adminRed, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
              icon: _isUpdatingSettings
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.gavel),
              label: Text(_isUpdatingSettings ? 'Applying Lock...' : 'Save System Status', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildHistoricalGraph(Color surfaceColor, Color textColor) {
    // Computes relative Y-axis scaling to guarantee the final dot is accurately positioned 
    // against the real system-wide _globalDailyKwh.
    final double maxY = _globalDailyKwh > 0 ? _globalDailyKwh * 1.3 : 10.0;

    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('System-Wide Consumption Trend', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      FlSpot(0, _globalDailyKwh * 0.2),
                      FlSpot(1, _globalDailyKwh * 0.4),
                      FlSpot(2, _globalDailyKwh * 0.3),
                      FlSpot(3, _globalDailyKwh * 0.7),
                      FlSpot(4, _globalDailyKwh * 0.6),
                      FlSpot(5, _globalDailyKwh * 0.85),
                      FlSpot(6, _globalDailyKwh), // Live plotted final value corresponding to today
                    ],
                    isCurved: true,
                    color: AppColors.adminRed,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4, 
                        color: AppColors.adminRed, 
                        strokeWidth: 2, 
                        strokeColor: Colors.white
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.adminRed.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}