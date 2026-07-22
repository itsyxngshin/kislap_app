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
  // Updated fallback rate to align with the regional ALECO June 2026 data
  double _activeRate = 12.35;

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
          if (_activeRate <= 0) _activeRate = 12.35;
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
                'My Planning Space\n(Lugar ng Pagpaplano)',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.appYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.appYellow.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.appYellow, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Lock (🔒) essential items. Leave flexible items unlocked (🔓) for automatic budget optimization.\n\n(I-lock ang mahahalagang gamit. Iwanang naka-unlock ang iba para sa awtomatikong pag-optimize ng budget.)',
                        style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              if (devices.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: surfaceColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        "No items added yet. Click 'Add item' on the Home tab!\n\n(Wala pang nailagay na gamit. I-click ang 'Add item' sa Home tab!)",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: hintColor, fontSize: 14, height: 1.4),
                      ),
                    ),
                  ),
                )
              else
                ...devices.map((device) {
                  // Math Engine logic based on Adjusted Hours
                  final double dailyKwh = (device.presetWattage / 1000) * device.adjustedHours;
                  final double monthlyKwh = dailyKwh * 30;
                  final double monthlyCost = monthlyKwh * _activeRate;

                  final bool isReduced = device.adjustedHours < device.userAssignedHours;
                  final Color lockColor = device.isLocked ? AppColors.appYellow : (isReduced ? Colors.orange : Colors.greenAccent);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: device.isLocked
                              ? AppColors.appYellow.withValues(alpha: 0.4)
                              : textColor.withValues(alpha: 0.05),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: device.isLocked ? AppColors.appYellow.withValues(alpha: 0.15) : surfaceColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.electrical_services,
                                  color: device.isLocked ? AppColors.appYellow : hintColor,
                                  size: 22,
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
                                      '${device.presetWattage.toStringAsFixed(0)}W · ${device.adjustedHours.toStringAsFixed(1)} hrs/day',
                                      style: TextStyle(color: hintColor, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              // The Lock Toggle
                              Column(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      device.isLocked ? Icons.lock : Icons.lock_open,
                                      color: lockColor,
                                      size: 26,
                                    ),
                                    onPressed: () {
                                      // Instantly update SQLite and the UI state
                                      ref.read(inventoryProvider.notifier).toggleLock(device.id, device.isLocked);
                                    },
                                  ),
                                  Text(
                                    device.isLocked ? 'Locked' : 'Unlocked',
                                    style: TextStyle(color: lockColor, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Divider(color: hintColor.withValues(alpha: 0.1), height: 1),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildMetricColumn(
                                  'Daily (Araw)',
                                  '${dailyKwh.toStringAsFixed(2)} kWh',
                                  textColor,
                                  hintColor,
                                ),
                                _buildMetricColumn(
                                  'Monthly (Buwan)',
                                  '${monthlyKwh.toStringAsFixed(1)} kWh',
                                  textColor,
                                  hintColor,
                                ),
                                _buildMetricColumn(
                                  'Est. Cost (Bayad)',
                                  '₱${monthlyCost.toStringAsFixed(0)}',
                                  device.isLocked ? AppColors.appYellow : Colors.greenAccent,
                                  hintColor,
                                ),
                              ],
                            ),
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

  Widget _buildMetricColumn(String label, String value, Color valueColor, Color hintColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: hintColor, fontSize: 10)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
