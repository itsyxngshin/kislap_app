import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../providers/inventory_provider.dart';
import '../../services/database_helper.dart';

class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> {
  double _activeRate = 11.08; // Fallback rate

  @override
  void initState() {
    super.initState();
    _fetchLocalRate();
  }

  // Fetch the user's localized rate from SQLite
  Future<void> _fetchLocalRate() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final settings = await db.query('user_settings', limit: 1);
      if (settings.isNotEmpty && mounted) {
        setState(() {
          _activeRate = (settings.first['tariff_rate'] as num).toDouble();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // 1. Riverpod automatically injects the latest appliance array here!
    final devices = ref.watch(inventoryProvider);

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
                'My Planning Space',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Lock (🔒) essential items. Leave flexible items unlocked (🔓) for automatic budget optimization.',
                style: TextStyle(color: hintColor, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),

              if (devices.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Text(
                      "No items added yet. Click 'Add device' on the Home tab!",
                      style: TextStyle(color: hintColor),
                    ),
                  ),
                )
              else
                ...devices.map((device) {
                  // Math Engine logic based on Adjusted Hours
                  final double dailyKwh =
                      (device.presetWattage / 1000) * device.adjustedHours;
                  final double monthlyKwh = dailyKwh * 30;
                  final double monthlyCost = monthlyKwh * _activeRate;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.appYellow.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.electrical_services,
                                  color: AppColors.appYellow,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      device.customName,
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${device.presetWattage}W · ${device.adjustedHours.toStringAsFixed(1)} hrs/day',
                                      style: TextStyle(
                                        color: hintColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // The Lock Toggle!
                              IconButton(
                                icon: Icon(
                                  device.isLocked
                                      ? Icons.lock
                                      : Icons.lock_open,
                                  color: device.isLocked
                                      ? Colors.green
                                      : AppColors.appYellow,
                                  size: 28,
                                ),
                                onPressed: () {
                                  // Instantly update SQLite and the UI state
                                  ref
                                      .read(inventoryProvider.notifier)
                                      .toggleLock(device.id!, device.isLocked);
                                },
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Divider(
                              color: hintColor.withValues(alpha: 0.1),
                              height: 1,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildMetricColumn(
                                'Daily',
                                '${dailyKwh.toStringAsFixed(2)} kWh',
                                textColor,
                                hintColor,
                              ),
                              _buildMetricColumn(
                                'Monthly',
                                '${monthlyKwh.toStringAsFixed(1)} kWh',
                                textColor,
                                hintColor,
                              ),
                              _buildMetricColumn(
                                'Est. cost',
                                '₱${monthlyCost.toStringAsFixed(0)}',
                                AppColors.appYellow,
                                hintColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricColumn(
    String label,
    String value,
    Color valueColor,
    Color hintColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: hintColor, fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
