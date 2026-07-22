import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../providers/inventory_provider.dart';
import '../../services/database_helper.dart';
import 'add_device_screen.dart';
import 'settings_screen.dart';
import 'analysis_screen.dart';
import '../../services/export_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  double _activeRate = 11.08;
  double _targetBudget = 0.0;
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

          if (_activeRate <= 0) _activeRate = 11.08;
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

    final devices = ref.watch(inventoryProvider);

    // Calculate both Original and Optimized daily usage
    double originalDailyKwh = 0.0;
    double optimizedDailyKwh = 0.0;
    for (var device in devices) {
      final double kw = device.presetWattage / 1000;
      originalDailyKwh += kw * device.userAssignedHours;
      optimizedDailyKwh += kw * device.adjustedHours;
    }

    // Convert daily to monthly costs
    final double originalMonthlyCost = originalDailyKwh * _activeRate * 30;
    final double optimizedMonthlyCost = optimizedDailyKwh * _activeRate * 30;

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
              const SizedBox(height: 25),

              // Glassmorphism Summary Card with the new Dynamic Over-Budget Warning
              _buildSummaryCard(
                originalMonthlyCost: originalMonthlyCost,
                optimizedMonthlyCost: optimizedMonthlyCost,
                surfaceColor: surfaceColor,
                textColor: textColor,
                hintColor: hintColor,
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: textColor.withValues(alpha: 0.05),
                        ),
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
                            '${optimizedDailyKwh.toStringAsFixed(1)} kWh',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Today's draw",
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
                        border: Border.all(
                          color: textColor.withValues(alpha: 0.05),
                        ),
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
                            '₱${(optimizedDailyKwh * _activeRate).toStringAsFixed(0)}',
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
                  _buildQuickAction(
                    Icons.add,
                    'Add item',
                    isPrimary: true,
                    surfaceColor: surfaceColor,
                    hintColor: hintColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddDeviceScreen(),
                        ),
                      );
                    },
                  ),
                  _buildQuickAction(
                    Icons.show_chart,
                    'Reports',
                    surfaceColor: surfaceColor,
                    hintColor: hintColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AnalysisScreen(),
                        ),
                      );
                    },
                  ),
                  _buildQuickAction(
                    Icons.settings,
                    'Config',
                    surfaceColor: surfaceColor,
                    hintColor: hintColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildQuickAction(
                    Icons.ios_share,
                    'Export',
                    surfaceColor: surfaceColor,
                    hintColor: hintColor,
                    onTap: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Generating Excel file...'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                      await ExportService.exportScheduleToExcel(
                        inventory: devices,
                        tariffRate: _activeRate,
                        targetBudget: _targetBudget,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Optimized Schedule',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${devices.length} items',
                    style: TextStyle(color: hintColor, fontSize: 13),
                  ),
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
                    return _buildApplianceCard(
                      item,
                      surfaceColor,
                      textColor,
                      hintColor,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required double originalMonthlyCost,
    required double optimizedMonthlyCost,
    required Color surfaceColor,
    required Color textColor,
    required Color hintColor,
  }) {
    // If the original unoptimized usage breaches the target budget
    final bool originalBreached = originalMonthlyCost > _targetBudget;

    // If the user locked so many high-usage items that even the optimized algorithm breached the budget
    final bool systemBreached = optimizedMonthlyCost > _targetBudget;

    final Color statusColor = systemBreached
        ? AppColors.adminRed
        : Colors.greenAccent;

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
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'OPTIMIZED MONTHLY BILL',
                style: TextStyle(
                  color: hintColor,
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Icon(
                      systemBreached
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline,
                      color: statusColor,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      systemBreached ? 'Over Budget' : 'On Track',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
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
              const Text(
                '₱',
                style: TextStyle(
                  color: AppColors.appYellow,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                optimizedMonthlyCost.toStringAsFixed(2),
                style: TextStyle(
                  color: textColor,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Limit: ₱${_targetBudget.toStringAsFixed(0)}',
                    style: TextStyle(color: hintColor, fontSize: 13),
                  ),
                  Text(
                    'Rate: ₱${_activeRate.toStringAsFixed(2)}/kWh',
                    style: TextStyle(color: hintColor, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),

          // DYNAMIC PROJECTED BILL WARNING
          if (originalBreached && !systemBreached) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.adminRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.adminRed.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.adminRed,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Unregulated Projected Bill: ₱${originalMonthlyCost.toStringAsFixed(2)}\nSystem successfully scaled usage to protect your budget.',
                      style: const TextStyle(
                        color: AppColors.adminRed,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _targetBudget > 0
                  ? (optimizedMonthlyCost / _targetBudget).clamp(0.0, 1.0)
                  : 0,
              minHeight: 8,
              backgroundColor: Colors.black26,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplianceCard(
    dynamic item,
    Color surfaceColor,
    Color textColor,
    Color hintColor,
  ) {
    final bool isLocked = item.isLocked;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLocked
              ? AppColors.appYellow.withValues(alpha: 0.4)
              : textColor.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isLocked
                  ? AppColors.appYellow.withValues(alpha: 0.1)
                  : surfaceColor,
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
                Text(
                  item.customName,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'scaled',
                style: TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: Icon(
              isLocked ? Icons.lock : Icons.lock_open,
              color: isLocked ? AppColors.appYellow : hintColor,
              size: 22,
            ),
            onPressed: () => ref
                .read(inventoryProvider.notifier)
                .toggleLock(item.id, isLocked),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: hintColor, size: 20),
            onPressed: () =>
                ref.read(inventoryProvider.notifier).removeAppliance(item.id),
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
