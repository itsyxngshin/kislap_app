import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../providers/inventory_provider.dart';
import '../../services/database_helper.dart';
import 'add_device_screen.dart';
import '../../services/export_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  double _activeRate = 11.08;
  double _targetBudget = 1500.0;
  bool _isLoadingSettings = true;

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
          _targetBudget = (settings.first['monthly_budget'] as num).toDouble();
        });
      }
    } catch (_) {}
    setState(() => _isLoadingSettings = false);
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = textColor.withValues(alpha: 0.6);
    final surfaceColor = Theme.of(context).colorScheme.surface;

    if (_isLoadingSettings) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.appYellow),
      );
    }

    // Reactively watch the inventory list
    final devices = ref.watch(inventoryProvider);

    // Run the aggregate math instantly
    double totalDailyKwh = 0.0;
    for (var device in devices) {
      totalDailyKwh += (device.presetWattage / 1000) * device.adjustedHours;
    }

    final double totalDailyCost = totalDailyKwh * _activeRate;
    final double totalMonthlyCost = totalDailyCost * 30;

    // Budget progress percentage (capped at 1.0 for the UI circle)
    double budgetPercentage = _targetBudget > 0
        ? (totalMonthlyCost / _targetBudget)
        : 0.0;
    if (budgetPercentage > 1.0) budgetPercentage = 1.0;

    return Container(
      decoration: AppTheme.globalBackground(context),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: 120,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Stack(
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        color: textColor,
                        size: 28,
                      ),
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.adminRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Hero Estimator Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: surfaceColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      height: 80,
                      width: 80,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: budgetPercentage,
                            backgroundColor: hintColor.withValues(alpha: 0.2),
                            color: totalMonthlyCost > _targetBudget
                                ? AppColors.adminRed
                                : AppColors.appYellow,
                            strokeWidth: 8,
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${(budgetPercentage * 100).toInt()}%',
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  'of budget',
                                  style: TextStyle(
                                    color: hintColor,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ESTIMATED BILL',
                            style: TextStyle(
                              color: hintColor,
                              fontSize: 12,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '₱${totalMonthlyCost.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppColors.appYellow,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: totalMonthlyCost > _targetBudget
                                  ? AppColors.adminRed.withValues(alpha: 0.2)
                                  : Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              totalMonthlyCost > _targetBudget
                                  ? 'Budget Breached'
                                  : 'On Track',
                              style: TextStyle(
                                color: totalMonthlyCost > _targetBudget
                                    ? AppColors.adminRed
                                    : Colors.greenAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Secondary Metric Cards
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.bolt,
                            color: AppColors.appYellow,
                            size: 20,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${totalDailyKwh.toStringAsFixed(1)} kWh',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Today's use",
                            style: TextStyle(color: hintColor, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Colors.greenAccent,
                            size: 20,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '₱${totalDailyCost.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Est. cost today",
                            style: TextStyle(color: hintColor, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              Text(
                'Quick Actions',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildQuickAction(Icons.add, 'Add item', isPrimary: true, surfaceColor: surfaceColor, hintColor: hintColor, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddDeviceScreen())); 
                  }),
                  _buildQuickAction(Icons.show_chart, 'Reports', surfaceColor: surfaceColor, hintColor: hintColor, onTap: () {
                    // Navigate to reports if needed
                  }),
                  _buildQuickAction(Icons.settings, 'Config', surfaceColor: surfaceColor, hintColor: hintColor, onTap: () {
                    // Navigate to settings if needed
                  }),
                  
                  // UPDATED EXPORT BUTTON
                  _buildQuickAction(Icons.ios_share, 'Export', surfaceColor: surfaceColor, hintColor: hintColor, onTap: () async {
                    // Show a quick loading indicator
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Generating Excel file...'), duration: Duration(seconds: 1)),
                    );
                    
                    // Call the export service
                    await ExportService.exportScheduleToExcel(
                      inventory: devices, // This is the active Riverpod state (ref.watch(inventoryProvider))
                      tariffRate: _activeRate,
                      targetBudget: _targetBudget,
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    IconData icon,
    String label, {
    bool isPrimary = false,
    required Color surfaceColor,
    required Color hintColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: isPrimary
                  ? AppColors.appYellow
                  : surfaceColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: isPrimary ? Colors.black87 : hintColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: hintColor, fontSize: 12)),
        ],
      ),
    );
  }
}
