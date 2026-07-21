import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../providers/inventory_provider.dart';
import '../../services/database_helper.dart';
import 'add_device_screen.dart';
import 'settings_screen.dart';
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
    if (mounted) setState(() => _isLoadingSettings = false);
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

    // Reactively watch the inventory list state
    final devices = ref.watch(inventoryProvider);

    // Aggregate daily consumption and costs
    double totalDailyKwh = 0.0;
    for (var device in devices) {
      totalDailyKwh += (device.presetWattage / 1000) * device.adjustedHours;
    }

    final double totalDailyCost = totalDailyKwh * _activeRate;
    final double totalMonthlyCost = totalDailyCost * 30;

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
              // --- HEADER ---
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
              const SizedBox(height: 25),

              // --- 1. EXTRACTED GLASSMORPHISM SUMMARY CARD ---
              _buildSummaryCard(
                totalMonthlyCost: totalMonthlyCost,
                surfaceColor: surfaceColor,
                textColor: textColor,
                hintColor: hintColor,
              ),
              const SizedBox(height: 20),

              // --- 2. SECONDARY METRICS ---
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: textColor.withValues(alpha: 0.05)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.bolt, color: AppColors.appYellow, size: 20),
                          const SizedBox(height: 10),
                          Text(
                            '${totalDailyKwh.toStringAsFixed(1)} kWh',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text("Today's draw", style: TextStyle(color: hintColor, fontSize: 12)),
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
                        border: Border.all(color: textColor.withValues(alpha: 0.05)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.access_time, color: Colors.greenAccent, size: 20),
                          const SizedBox(height: 10),
                          Text(
                            '₱${totalDailyCost.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text("Est. cost today", style: TextStyle(color: hintColor, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // --- 3. QUICK ACTIONS ---
              Text('Quick Actions', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
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
                    Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen()));
                  }),
                  _buildQuickAction(Icons.ios_share, 'Export', surfaceColor: surfaceColor, hintColor: hintColor, onTap: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Generating Excel file...'), duration: Duration(seconds: 1)),
                    );

                    await ExportService.exportScheduleToExcel(
                      inventory: devices,
                      tariffRate: _activeRate,
                      targetBudget: _targetBudget,
                    );
                  }),
                ],
              ),
              const SizedBox(height: 30),

              // --- 4. OPTIMIZED SCHEDULE / APPLIANCE INVENTORY LIST ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Optimized Schedule', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('${devices.length} items', style: TextStyle(color: hintColor, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 15),

              if (devices.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: surfaceColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      'No appliances added yet.\nTap "Add item" to start optimizing.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: hintColor, fontSize: 14),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final item = devices[index];
                    return _buildApplianceCard(item, surfaceColor, textColor, hintColor);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // GLASSMORPHISM SUMMARY CARD HELPER
  Widget _buildSummaryCard({
    required double totalMonthlyCost,
    required Color surfaceColor,
    required Color textColor,
    required Color hintColor,
  }) {
    final bool isBreached = totalMonthlyCost > _targetBudget;
    final Color statusColor = isBreached ? AppColors.adminRed : Colors.greenAccent;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ESTIMATED MONTHLY BILL',
                style: TextStyle(color: hintColor, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Icon(isBreached ? Icons.warning_amber_rounded : Icons.check_circle_outline, color: statusColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      isBreached ? 'Over Budget' : 'On Track',
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('₱', style: TextStyle(color: AppColors.appYellow, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Text(
                totalMonthlyCost.toStringAsFixed(2),
                style: TextStyle(color: textColor, fontSize: 36, fontWeight: FontWeight.bold, height: 1.0),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Limit: ₱${_targetBudget.toStringAsFixed(0)}', style: TextStyle(color: hintColor, fontSize: 13)),
                  Text('Rate: ₱${_activeRate.toStringAsFixed(2)}/kWh', style: TextStyle(color: hintColor, fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Visual Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _targetBudget > 0 ? (totalMonthlyCost / _targetBudget).clamp(0.0, 1.0) : 0,
              minHeight: 8,
              backgroundColor: Colors.black26,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
        ],
      ),
    );
  }

  // APPLIANCE LIST ITEM CARD
  Widget _buildApplianceCard(dynamic item, Color surfaceColor, Color textColor, Color hintColor) {
    final bool isLocked = item.isLocked;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLocked ? AppColors.appYellow.withValues(alpha: 0.4) : textColor.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isLocked ? AppColors.appYellow.withValues(alpha: 0.1) : surfaceColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLocked ? Icons.lock_outline : Icons.lock_open_outlined,
              color: isLocked ? AppColors.appYellow : hintColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.customName, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  '${item.presetWattage}W • Target: ${item.userAssignedHours}h/day',
                  style: TextStyle(color: hintColor, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.adjustedHours.toStringAsFixed(1)} hrs',
                style: const TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Text('scaled', style: TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: Icon(
              isLocked ? Icons.lock : Icons.lock_open,
              color: isLocked ? AppColors.appYellow : hintColor,
              size: 22,
            ),
            onPressed: () {
              ref.read(inventoryProvider.notifier).toggleLock(item.id, isLocked);
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: hintColor, size: 20),
            onPressed: () {
              ref.read(inventoryProvider.notifier).removeAppliance(item.id);
            },
          ),
        ],
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
              color: isPrimary ? AppColors.appYellow : surfaceColor.withValues(alpha: 0.5),
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
