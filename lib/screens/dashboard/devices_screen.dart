import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/database_helper.dart';

class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> {
  double _activeRate = 12.35;
  String _sortOrder = 'Highest kWh';

  @override
  void initState() {
    super.initState();
    _fetchLocalRate();
  }

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

  String _formatTime(double totalHours) {
    final int hours = totalHours.floor();
    final int minutes = ((totalHours - hours) * 60).round();
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    return '${minutes}m';
  }

  // ISO 25010: Universal Edit Implementation for Devices Screen
  void _showEditModal(dynamic item, bool isPh) {
    final nameController = TextEditingController(text: item.customName);
    final hoursController = TextEditingController(text: item.userAssignedHours.toString());
    int quantity = item.quantity;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
            decoration: BoxDecoration(color: surfaceColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isPh ? 'I-edit ang Gamit' : 'Edit Appliance', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(icon: Icon(Icons.close, color: textColor.withOpacity(0.6)), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController, style: TextStyle(color: textColor),
                  decoration: InputDecoration(labelText: isPh ? 'Pangalan' : 'Custom Name', filled: true, fillColor: textColor.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: hoursController, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: TextStyle(color: textColor),
                        decoration: InputDecoration(labelText: isPh ? 'Oras (Arawan)' : 'Daily Hours', suffixText: 'hrs', filled: true, fillColor: textColor.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: textColor.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          IconButton(onPressed: quantity > 1 ? () => setModalState(() => quantity--) : null, icon: const Icon(Icons.remove)),
                          Text('$quantity', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                          IconButton(onPressed: () => setModalState(() => quantity++), icon: const Icon(Icons.add)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      final newHours = double.tryParse(hoursController.text) ?? item.userAssignedHours;
                      ref.read(inventoryProvider.notifier).editAppliance(id: item.id, customName: nameController.text.trim(), quantity: quantity, userAssignedHours: newHours);
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(backgroundColor: AppColors.appYellow, foregroundColor: Colors.black87, padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: Text(isPh ? 'I-save ang Pagbabago' : 'Save Changes', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(inventoryProvider);
    final isPh = ref.watch(settingsProvider).language == 'ph';

    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = textColor.withOpacity(0.6);
    final surfaceColor = Theme.of(context).colorScheme.surface;

    List<dynamic> sortedDevices = List.from(devices);
    if (_sortOrder == 'Highest kWh') {
      sortedDevices.sort((a, b) => ((b.presetWattage * b.quantity * b.adjustedHours)).compareTo(a.presetWattage * a.quantity * a.adjustedHours));
    } else if (_sortOrder == 'Lowest kWh') {
      sortedDevices.sort((a, b) => ((a.presetWattage * a.quantity * a.adjustedHours)).compareTo(b.presetWattage * b.quantity * b.adjustedHours));
    } else if (_sortOrder == 'Name (A-Z)') {
      sortedDevices.sort((a, b) => a.customName.toString().toLowerCase().compareTo(b.customName.toString().toLowerCase()));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isPh ? 'Lugar ng Pagpaplano' : 'My Planning Space',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor, height: 1.2),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.sort, color: hintColor, size: 24),
                    color: surfaceColor,
                    onSelected: (val) => setState(() => _sortOrder = val),
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'Highest kWh', child: Text(isPh ? 'Pinakamataas na kWh' : 'Highest kWh', style: TextStyle(color: textColor, fontSize: 13))),
                      PopupMenuItem(value: 'Lowest kWh', child: Text(isPh ? 'Pinakamababang kWh' : 'Lowest kWh', style: TextStyle(color: textColor, fontSize: 13))),
                      PopupMenuItem(value: 'Name (A-Z)', child: Text(isPh ? 'Pangalan (A-Z)' : 'Name (A-Z)', style: TextStyle(color: textColor, fontSize: 13))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.appYellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.appYellow.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.appYellow, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isPh
                          ? 'I-lock (🔒) ang mahahalagang gamit. Iwanang naka-unlock (🔓) ang iba para sa awtomatikong pag-optimize ng budget.'
                          : 'Lock (🔒) essential items. Leave flexible items unlocked (🔓) for automatic budget optimization.',
                        style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 12, height: 1.4),
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
                      decoration: BoxDecoration(color: surfaceColor.withOpacity(0.3), borderRadius: BorderRadius.circular(16)),
                      child: Text(
                        isPh ? "Wala pang nailagay na gamit. I-click ang 'Magdagdag' sa Home tab!" : "No items added yet. Click 'Add item' on the Home tab!",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: hintColor, fontSize: 14, height: 1.4),
                      ),
                    ),
                  ),
                )
              else
                ...sortedDevices.map((device) {
                  final double dailyKwh = ((device.presetWattage * device.quantity) / 1000) * device.adjustedHours;
                  final double monthlyKwh = dailyKwh * 30;
                  final double monthlyCost = monthlyKwh * _activeRate;

                  final bool isReduced = device.adjustedHours < device.userAssignedHours;
                  final Color lockColor = device.isLocked ? AppColors.appYellow : (isReduced ? Colors.orange : Colors.greenAccent);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: device.isLocked ? AppColors.appYellow.withOpacity(0.4) : textColor.withOpacity(0.05)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: device.isLocked ? AppColors.appYellow.withOpacity(0.15) : surfaceColor, shape: BoxShape.circle),
                                child: Icon(Icons.electrical_services, color: device.isLocked ? AppColors.appYellow : hintColor, size: 22),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${device.customName} (x${device.quantity})', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text('${device.presetWattage.toStringAsFixed(0)}W • ${_formatTime(device.adjustedHours)} / ${isPh ? 'araw' : 'day'}', style: TextStyle(color: hintColor, fontSize: 12)),
                                  ],
                                ),
                              ),
                              // NEW: Edit Button
                              Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    color: AppColors.appYellow,
                                    iconSize: 24,
                                    onPressed: () => _showEditModal(device, isPh),
                                  ),
                                  Text(isPh ? 'I-edit' : 'Edit', style: const TextStyle(color: AppColors.appYellow, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(width: 5),
                              // Lock Button
                              Column(
                                children: [
                                  IconButton(
                                    icon: Icon(device.isLocked ? Icons.lock : Icons.lock_open, color: lockColor, size: 24),
                                    onPressed: () => ref.read(inventoryProvider.notifier).toggleLock(device.id, device.isLocked),
                                  ),
                                  Text(
                                    device.isLocked ? (isPh ? 'Naka-lock' : 'Locked') : (isPh ? 'Naka-unlock' : 'Unlocked'),
                                    style: TextStyle(color: lockColor, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 5),
                              // Delete Button
                              Column(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.delete_outline, color: hintColor, size: 24),
                                    onPressed: () => ref.read(inventoryProvider.notifier).removeAppliance(device.id),
                                  ),
                                  Text(isPh ? 'Burahin' : 'Remove', style: TextStyle(color: hintColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Divider(color: hintColor.withOpacity(0.1), height: 1),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildMetricColumn(isPh ? 'Araw-araw' : 'Daily', '${dailyKwh.toStringAsFixed(2)} kWh', textColor, hintColor),
                                _buildMetricColumn(isPh ? 'Buwanan' : 'Monthly', '${monthlyKwh.toStringAsFixed(1)} kWh', textColor, hintColor),
                                _buildMetricColumn(isPh ? 'Est. Bayad' : 'Est. Cost', '₱${monthlyCost.toStringAsFixed(0)}', device.isLocked ? AppColors.appYellow : Colors.greenAccent, hintColor),
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
        Text(value, style: TextStyle(color: valueColor, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
