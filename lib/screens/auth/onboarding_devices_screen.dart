import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/database_helper.dart';
import '../dashboard/dashboard_shell.dart';
import '../../widgets/custom_text_field.dart';

class OnboardingDevicesScreen extends ConsumerStatefulWidget {
  const OnboardingDevicesScreen({super.key});

  @override
  ConsumerState<OnboardingDevicesScreen> createState() => _OnboardingDevicesScreenState();
}

class _OnboardingDevicesScreenState extends ConsumerState<OnboardingDevicesScreen> {
  List<Map<String, dynamic>> _presets = [];
  List<String> _categories = [];
  String? _selectedCategory;
  int? _selectedPresetId;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController();
  int _quantity = 1;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPresets();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _loadPresets() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final data = await db.query('appliance_presets', orderBy: 'category, appliance_name');

      if (mounted) {
        setState(() {
          _presets = data;
          // Extract unique categories dynamically
          _categories = data.map((p) => p['category'] as String).toSet().toList();
          if (_categories.isNotEmpty) {
            _selectedCategory = _categories.first; // Default to first category
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addApplianceToList() {
    if (_selectedPresetId == null || _nameController.text.isEmpty || _hoursController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all appliance details.'), backgroundColor: AppColors.adminRed)
      );
      return;
    }

    final preset = _presets.firstWhere((p) => p['id'] == _selectedPresetId);
    final hours = double.tryParse(_hoursController.text) ?? 0.0;

    if (hours <= 0 || hours > 24) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Operating hours must be between 0.1 and 24.'), backgroundColor: AppColors.adminRed)
      );
      return;
    }

    ref.read(inventoryProvider.notifier).addAppliance(
      presetId: preset['id'] as int,
      customName: _nameController.text.trim(),
      defaultHours: hours,
      wattage: (preset['preset_wattage'] as num).toDouble(),
      quantity: _quantity,
    );

    // Reset the form for the next rapid entry
    setState(() {
      _selectedPresetId = null;
      _nameController.clear();
      _hoursController.clear();
      _quantity = 1;
    });

    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = textColor.withOpacity(0.6);
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final isPh = ref.watch(settingsProvider).language == 'ph';

    final devices = ref.watch(inventoryProvider);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator(color: AppColors.appYellow)),
      );
    }

    // Filter presets dynamically based on the active category tile
    final filteredPresets = _presets.where((p) => p['category'] == _selectedCategory).toList();

    return Container(
      decoration: AppTheme.globalBackground(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(isPh ? 'I-setup ang mga Gamit' : 'Setup Inventory', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isPh ? 'Magdagdag ng mga Appliances' : 'Add Your Appliances', style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(isPh ? 'Ilagay lahat ng gamit sa bahay upang masimulan ang pag-optimize ng Kislap.' : 'Add all your household appliances so Kislap can optimize your schedule.', style: TextStyle(color: hintColor, fontSize: 13, height: 1.4)),
                      const SizedBox(height: 24),

                      // --- UX ENHANCEMENT: RAPID ENTRY FORM WITH CATEGORY TILES ---
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: surfaceColor.withOpacity(0.6), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.appYellow.withOpacity(0.3))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isPh ? '1. Pumili ng Kategorya' : '1. Select Category', style: TextStyle(color: hintColor, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),

                            // Horizontal Category Tiles
                            SizedBox(
                              height: 38,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _categories.length,
                                itemBuilder: (context, index) {
                                  final cat = _categories[index];
                                  final isSelected = _selectedCategory == cat;

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedCategory = cat;
                                        _selectedPresetId = null; // Reset dropdown when category changes
                                        _nameController.clear();
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppColors.appYellow : surfaceColor,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: isSelected ? AppColors.appYellow : hintColor.withOpacity(0.2)),
                                      ),
                                      child: Text(
                                        cat,
                                        style: TextStyle(
                                          color: isSelected ? Colors.black87 : textColor,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 20),

                            Text(isPh ? '2. Pumili ng Gamit' : '2. Select Appliance', style: TextStyle(color: hintColor, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),

                            // Dropdown is now perfectly filtered and manageable!
                            DropdownButtonFormField<int>(
                              value: _selectedPresetId,
                              decoration: InputDecoration(filled: true, fillColor: textColor.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                              dropdownColor: surfaceColor,
                              hint: Text(isPh ? 'Pumili sa ibaba...' : 'Select from below...', style: TextStyle(color: hintColor)),
                              items: filteredPresets.map((p) => DropdownMenuItem(
                                value: p['id'] as int,
                                child: Text('${p['appliance_name']} (${p['preset_wattage']}W)', style: TextStyle(color: textColor))
                              )).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedPresetId = val;
                                  final preset = _presets.firstWhere((p) => p['id'] == val);
                                  _nameController.text = preset['appliance_name'];
                                });
                              },
                            ),
                            const SizedBox(height: 16),

                            CustomTextField(controller: _nameController, hint: isPh ? 'Pangalan (Hal. Kwarto AC)' : 'Custom Name (e.g., Bedroom AC)', icon: Icons.label_outline),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: CustomTextField(controller: _hoursController, hint: isPh ? 'Oras/Araw' : 'Hrs/Day', icon: Icons.access_time, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    height: 55,
                                    decoration: BoxDecoration(color: textColor.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        IconButton(onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null, icon: Icon(Icons.remove, size: 18, color: textColor)),
                                        Text('$_quantity', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                                        IconButton(onPressed: () => setState(() => _quantity++), icon: Icon(Icons.add, size: 18, color: textColor)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _addApplianceToList,
                                icon: const Icon(Icons.add, color: Colors.black87),
                                label: Text(isPh ? 'Idagdag sa Listahan' : 'Add to List', style: const TextStyle(fontWeight: FontWeight.bold)),
                                style: FilledButton.styleFrom(backgroundColor: AppColors.appYellow, foregroundColor: Colors.black87, padding: const EdgeInsets.symmetric(vertical: 16)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Live Inventory List
                      Text(isPh ? 'IYONG LISTAHAN' : 'YOUR INVENTORY', style: TextStyle(color: hintColor, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),

                      if (devices.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: surfaceColor.withOpacity(0.3), borderRadius: BorderRadius.circular(16), border: Border.all(color: textColor.withOpacity(0.05))),
                          child: Text(isPh ? 'Wala ka pang naidadagdag na gamit.' : 'No appliances added yet.', textAlign: TextAlign.center, style: TextStyle(color: hintColor, fontSize: 13)),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: devices.length,
                          itemBuilder: (context, index) {
                            final device = devices[index];
                            return Card(
                              color: surfaceColor.withOpacity(0.5),
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: textColor.withOpacity(0.05))),
                              child: ListTile(
                                title: Text('${device.customName} (x${device.quantity})', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                                subtitle: Text('${device.presetWattage}W • ${device.userAssignedHours} hrs/day', style: TextStyle(color: hintColor, fontSize: 12)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppColors.adminRed),
                                  onPressed: () => ref.read(inventoryProvider.notifier).removeAppliance(device.id),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),

              // Final Step Container
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const DashboardShell()), (route) => false);
                    },
                    style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: Text(isPh ? 'Kumpleto na ang Setup' : 'Complete Setup', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
