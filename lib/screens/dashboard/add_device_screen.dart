import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../services/database_helper.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/settings_provider.dart';

class AddDeviceScreen extends ConsumerStatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  ConsumerState<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends ConsumerState<AddDeviceScreen> {
  final TextEditingController _customNameController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController();

  List<Map<String, dynamic>> _presets = [];
  List<String> _categories = [];
  String? _selectedCategory;

  int _quantity = 1;
  int? _selectedPresetId;
  Map<String, dynamic>? _selectedPresetMap;

  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPresets();
  }

  @override
  void dispose() {
    _customNameController.dispose();
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
            _selectedCategory = _categories.first; // Default to the first category
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _saveDevice(bool isPh) async {
    if (_selectedPresetId == null ||
        _customNameController.text.trim().isEmpty ||
        _hoursController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPh ? 'Kumpletuhin ang form.' : 'Please complete all fields.',
          ),
          backgroundColor: AppColors.adminRed,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final double hours = double.parse(_hoursController.text);

      await ref.read(inventoryProvider.notifier).addAppliance(
            presetId: _selectedPresetId!,
            customName: _customNameController.text.trim(),
            defaultHours: hours,
            wattage: (_selectedPresetMap!['preset_wattage'] as num).toDouble(),
            quantity: _quantity,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isPh ? 'Nailagay na ang gamit!' : 'Device added!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding device: $e'),
            backgroundColor: AppColors.adminRed,
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = textColor.withOpacity(0.6);
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final isPh = ref.watch(settingsProvider).language == 'ph';

    // Dynamically filter the dropdown choices based on the selected category tile
    final filteredPresets = _presets.where((p) => p['category'] == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isPh ? 'Magdagdag ng Gamit' : 'Add Appliance',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            height: 1.2,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.appYellow))
          : _presets.isEmpty
              ? Center(
                  child: Text(
                    isPh
                        ? 'Walang nahanap na presets. Mag-sync sa cloud.'
                        : 'No appliance presets found.\nPlease sync with the cloud.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: hintColor, height: 1.5),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: surfaceColor.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.appYellow.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPh ? '1. URI NG KATEGORYA' : '1. APPLIANCE CATEGORY',
                              style: const TextStyle(
                                color: AppColors.appYellow,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // UX Enhancement: Horizontal Category Tiles
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
                                        _selectedPresetMap = null;
                                        _customNameController.clear();
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
                            const SizedBox(height: 24),

                            Text(
                              isPh ? '2. PUMILI SA LISTAHAN' : '2. SELECT FROM LIST',
                              style: const TextStyle(
                                color: AppColors.appYellow,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 10),

                            DropdownButtonFormField<int>(
                              value: _selectedPresetId,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: surfaceColor.withOpacity(0.8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: const Icon(
                                  Icons.category_outlined,
                                  color: AppColors.appYellow,
                                ),
                              ),
                              dropdownColor: surfaceColor,
                              icon: Icon(Icons.keyboard_arrow_down, color: hintColor),
                              hint: Text(
                                isPh ? 'Pumili sa ibaba...' : 'Select from below...',
                                style: TextStyle(color: hintColor, fontSize: 13),
                              ),
                              isExpanded: true,
                              items: filteredPresets
                                  .map(
                                    (preset) => DropdownMenuItem<int>(
                                      value: preset['id'] as int,
                                      child: Text(
                                        '${preset['appliance_name']} (${preset['preset_wattage']}W)',
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedPresetId = value;
                                  _selectedPresetMap = _presets.firstWhere((p) => p['id'] == value);
                                  if (_customNameController.text.isEmpty && _selectedPresetMap != null) {
                                    _customNameController.text = _selectedPresetMap!['appliance_name'];
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 30),

                            Text(
                              isPh ? 'BILANG (QUANTITY)' : 'QUANTITY',
                              style: const TextStyle(
                                color: AppColors.appYellow,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: surfaceColor.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    onPressed: _quantity > 1
                                        ? () => setState(() => _quantity--)
                                        : null,
                                    icon: const Icon(Icons.remove_circle_outline),
                                    color: _quantity > 1 ? AppColors.appYellow : hintColor,
                                  ),
                                  Text(
                                    '$_quantity',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => setState(() => _quantity++),
                                    icon: const Icon(Icons.add_circle_outline),
                                    color: AppColors.appYellow,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 30),

                            Text(
                              isPh ? 'PANGALAN NG GAMIT' : 'CUSTOM IDENTIFIER',
                              style: const TextStyle(
                                color: AppColors.appYellow,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _customNameController,
                              style: TextStyle(color: textColor, fontSize: 16),
                              decoration: InputDecoration(
                                hintText: 'e.g., Master Bedroom AC',
                                hintStyle: TextStyle(color: hintColor, fontSize: 14),
                                filled: true,
                                fillColor: surfaceColor.withOpacity(0.8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: Icon(
                                  Icons.label_outline,
                                  color: hintColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),

                            Text(
                              isPh ? 'ORAS NG PAGGAMIT' : 'BASELINE USAGE',
                              style: const TextStyle(
                                color: AppColors.appYellow,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _hoursController,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                hintText: isPh ? 'Oras kada araw' : 'Hours per day',
                                hintStyle: TextStyle(
                                  color: hintColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                ),
                                filled: true,
                                fillColor: surfaceColor.withOpacity(0.8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: const Icon(
                                  Icons.schedule,
                                  color: Colors.greenAccent,
                                ),
                                suffixText: 'hrs',
                                suffixStyle: TextStyle(color: hintColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isSaving ? null : () => _saveDevice(isPh),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.orange.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 5,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  isPh ? 'Idagdag' : 'Add to Inventory',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
