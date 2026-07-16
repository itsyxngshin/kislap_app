import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../auth/sign_in_screen.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // Analytics State
  int _totalUsers = 0;
  double _globalDailyKwh = 0;

  // Rate Management State
  final TextEditingController _mainlandRateController = TextEditingController();
  final TextEditingController _islandRateController = TextEditingController();
  bool _isUpdatingRate = false;
  bool _isLoadingData = true;
  DateTime _selectedMonth = DateTime(2026, 7, 1);
  final List<DateTime> _monthOptions = List.generate(24, (i) => DateTime(2025 + (i ~/ 12), (i % 12) + 1, 1));

  // Lockdown & Maintenance State
  bool _isMaintenanceMode = false;
  final TextEditingController _lockMessageController = TextEditingController();
  bool _isUpdatingSettings = false;

  @override
  void initState() {
    super.initState();
    _fetchRatesForSelectedMonth();
    _fetchAdminAnalytics();
    _fetchSystemSettings();
  }

  String _toDbDate(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-01';
  String _formatMonth(DateTime date) => '${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1]} ${date.year}';

  // --- DATABASE QUERIES ---

  Future<void> _fetchAdminAnalytics() async {
    try {
      final supabase = Supabase.instance.client;
      final userCountResponse = await supabase.from('profiles').select('id').count(CountOption.exact);
      final allAppliances = await supabase.from('appliances').select('watts, hours_per_day, quantity');
      
      double totalKwh = 0;
      for (var app in allAppliances) {
        totalKwh += ((app['watts'] / 1000) * app['hours_per_day'] * app['quantity']);
      }

      if (mounted) {
        setState(() {
          _totalUsers = userCountResponse.count ?? 0;
          _globalDailyKwh = totalKwh;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchRatesForSelectedMonth() async {
    setState(() => _isLoadingData = true);
    try {
      final data = await Supabase.instance.client.from('billing_rates').select().eq('billing_month', _toDbDate(_selectedMonth)).maybeSingle();
      if (mounted) {
        setState(() {
          if (data != null) {
            _mainlandRateController.text = data['mainland_rate'].toString();
            _islandRateController.text = data['island_rate'].toString();
          } else {
            _mainlandRateController.clear();
            _islandRateController.clear();
          }
          _isLoadingData = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingData = false);
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

  Future<void> _saveRates() async {
    if (_mainlandRateController.text.isEmpty || _islandRateController.text.isEmpty) return;
    setState(() => _isUpdatingRate = true);
    final String dbDate = _toDbDate(_selectedMonth);
    
    try {
      final supabase = Supabase.instance.client;
      final existing = await supabase.from('billing_rates').select().eq('billing_month', dbDate).maybeSingle();

      if (existing != null) {
        await supabase.from('billing_rates').update({
          'mainland_rate': double.parse(_mainlandRateController.text),
          'island_rate': double.parse(_islandRateController.text),
        }).eq('billing_month', dbDate);
      } else {
        await supabase.from('billing_rates').insert({
          'billing_month': dbDate,
          'mainland_rate': double.parse(_mainlandRateController.text),
          'island_rate': double.parse(_islandRateController.text),
        });
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rates saved for ${_formatMonth(_selectedMonth)}!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e'), backgroundColor: AppColors.adminRed));
    } finally {
      if (mounted) setState(() => _isUpdatingRate = false);
    }
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
    if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const SignInScreen()), (route) => false);
  }

  @override
  void dispose() {
    _mainlandRateController.dispose();
    _islandRateController.dispose();
    _lockMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = textColor.withValues(alpha: 0.6);
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return DefaultTabController(
      length: 3, // Three tabs: Analytics, Rates, Lockdown
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
              IconButton(icon: Icon(Icons.logout, color: textColor), onPressed: _signOut)
            ],
            bottom: TabBar(
              indicatorColor: AppColors.appYellow,
              labelColor: AppColors.appYellow,
              unselectedLabelColor: hintColor,
              tabs: const [
                Tab(icon: Icon(Icons.analytics_outlined), text: 'Analytics'),
                Tab(icon: Icon(Icons.bolt), text: 'Rates'),
                Tab(icon: Icon(Icons.lock_person_outlined), text: 'Lockdown'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              // --- TAB 1: ANALYTICS ---
              _buildAnalyticsTab(surfaceColor, textColor, hintColor),

              // --- TAB 2: RATES ---
              _buildRatesTab(surfaceColor, textColor, hintColor),

              // --- TAB 3: LOCKDOWN / MAINTENANCE ---
              _buildLockdownTab(surfaceColor, textColor, hintColor),
            ],
          ),
        ),
      ),
    );
  }

  // --- TAB UI BUILDERS ---

  Widget _buildAnalyticsTab(Color surfaceColor, Color textColor, Color hintColor) {
    return RefreshIndicator(
      onRefresh: _fetchAdminAnalytics,
      color: AppColors.appYellow,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: surfaceColor.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.group, color: Colors.blueAccent, size: 24),
                        const SizedBox(height: 8),
                        Text('$_totalUsers', style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)),
                        Text('Total Users', style: TextStyle(color: hintColor, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: surfaceColor.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.bolt, color: AppColors.appYellow, size: 24),
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

  Widget _buildRatesTab(Color surfaceColor, Color textColor, Color hintColor) {
    return _isLoadingData
        ? const Center(child: CircularProgressIndicator(color: AppColors.appYellow))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select Billing Month', style: TextStyle(color: hintColor, fontSize: 13)),
                const SizedBox(height: 8),
                DropdownButtonFormField<DateTime>(
                  value: _selectedMonth,
                  dropdownColor: surfaceColor,
                  icon: Icon(Icons.calendar_today, color: hintColor, size: 20),
                  style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: surfaceColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  items: _monthOptions.map((date) {
                    return DropdownMenuItem(value: date, child: Text(_formatMonth(date)));
                  }).toList(),
                  onChanged: (DateTime? newValue) {
                    if (newValue != null) {
                      setState(() => _selectedMonth = newValue);
                      _fetchRatesForSelectedMonth(); 
                    }
                  },
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: surfaceColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.adminRed.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rate Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(height: 8),
                      Text(
                        'Enter the exact ₱/kWh rates for ${_formatMonth(_selectedMonth)}.',
                        style: TextStyle(color: hintColor, fontSize: 13, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Text('Mainland Rate (₱ / kWh)', style: TextStyle(color: hintColor, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: _mainlandRateController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.bolt, color: AppColors.appYellow),
                    filled: true,
                    fillColor: surfaceColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Island Rate (₱ / kWh)', style: TextStyle(color: hintColor, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: _islandRateController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.waves, color: Colors.cyanAccent),
                    filled: true,
                    fillColor: surfaceColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isUpdatingRate ? null : _saveRates,
                    icon: _isUpdatingRate 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 2))
                        : const Icon(Icons.save),
                    label: Text(_isUpdatingRate ? 'Saving...' : 'Save Rates', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
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
              color: AppColors.adminRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.adminRed.withValues(alpha: 0.3)),
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
          
          // Toggle row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: surfaceColor.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
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
                  activeColor: AppColors.adminRed,
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
              hintStyle: TextStyle(color: hintColor.withValues(alpha: 0.5)),
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
              style: FilledButton.styleFrom(backgroundColor: AppColors.adminRed, foregroundColor: Colors.white),
              icon: _isUpdatingSettings 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.gavel),
              label: Text(_isUpdatingSettings ? 'Applying Lock...' : 'Save System Status', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoricalGraph(Color surfaceColor, Color textColor) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor.withValues(alpha: 0.5),
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
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(1, 120),
                      FlSpot(2, 210),
                      FlSpot(3, 180),
                      FlSpot(4, 300),
                      FlSpot(5, 280),
                      FlSpot(6, 400),
                    ],
                    isCurved: true,
                    color: AppColors.appYellow,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.appYellow.withValues(alpha: 0.2),
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