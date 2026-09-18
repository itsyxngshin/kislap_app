import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../services/database_helper.dart';
import '../../providers/inventory_provider.dart';

enum ApplianceInputMode { preset, slider, free }

class AddDeviceScreen extends ConsumerStatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  ConsumerState<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends ConsumerState<AddDeviceScreen> {
  // Input Controllers
  final TextEditingController _customNameController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController();
  final TextEditingController _customWattageController = TextEditingController();

  // State Variables
  ApplianceInputMode _currentMode = ApplianceInputMode.preset;
  Map<String, dynamic>? _selectedPreset;
  late Future<List<Map<String, dynamic>>> _presetsFuture;

  bool _isSaving = false;
  int _quantity = 1;
  double _sliderWattage = 0.0;
  double _maxSliderWattage = 2000.0; // Dynamic based on preset's max_wattage

  @override
  void initState() {
    super.initState();
    _presetsFuture = DatabaseHelper.instance.database.then((db) {
      return db.query('appliance_presets', orderBy: 'category, appliance_name');
    });
  }

  @override
  void dispose() {
    _customNameController.dispose();
    _hoursController.dispose();
    _customWattageController.dispose();
    super.dispose();
  }

  void _onPresetSelected(Map<String, dynamic>? preset) {
    setState(() {
      _selectedPreset = preset;
      if (preset != null) {
        if (_customNameController.text.isEmpty) {
          _customNameController.text = preset['appliance_name'];
        }

        final double baseWattage = (preset['preset_wattage'] as num).toDouble();
        // Uses the database's max_wattage if available, otherwise safely doubles the base as fallback
        _maxSliderWattage = preset.containsKey('max_wattage')
            ? (preset['max_wattage'] as num).toDouble()
            : baseWattage * 2.0;

        _sliderWattage = baseWattage;
      }
    });
  }

  void _saveDevice() async {
    // 1. Validation based on mode
    if (_currentMode != ApplianceInputMode.free && _selectedPreset == null) {
      _showError('Please select an appliance from the catalog.');
      return;
    }

    if (_currentMode == ApplianceInputMode.free && _customWattageController.text.trim().isEmpty) {
      _showError('Please enter a custom wattage.');
      return;
    }

    if (_customNameController.text.trim().isEmpty || _hoursController.text.trim().isEmpty) {
      _showError('Please complete all fields. (Kumpletuhin ang form.)');
      return;
    }

    final double hours = double.tryParse(_hoursController.text) ?? 0.0;
    if (hours <= 0 || hours > 24) {
      _showError('Enter valid hours per day (1-24).');
      return;
    }

    // 2. Determine Final Wattage based on the selected UI mode
    double finalWattage = 0.0;
    int? presetId;

    switch (_currentMode) {
      case ApplianceInputMode.preset:
        finalWattage = (_selectedPreset!['preset_wattage'] as num).toDouble();
        presetId = _selectedPreset!['id'];
        break;
      case ApplianceInputMode.slider:
        finalWattage = _sliderWattage;
        presetId = _selectedPreset!['id'];
        break;
      case ApplianceInputMode.free:
        finalWattage = double.tryParse(_customWattageController.text) ?? 0.0;
        presetId = null; // Free input doesn't map strictly to a catalog ID
        break;
    }

    if (finalWattage <= 0) {
      _showError('Wattage must be greater than 0.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final inventoryNotifier = ref.read(inventoryProvider.notifier);
      final String baseName = _customNameController.text.trim();

      // 3. Add devices sequentially based on Quantity
      // This separates them in the DB so users can lock/unlock individual units later!
      for (int i = 0; i < _quantity; i++) {
              String displayName = _quantity > 1 ? '$baseName (#${i + 1})' : baseName;
              
              await inventoryNotifier.addAppliance(
                presetId: presetId ?? 9999, 
                customName: displayName,
                defaultHours: hours,
                wattage: finalWattage,
                quantity: 1, // <--- ADD THIS EXACT LINE
              );
            }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('$_quantity device(s) added successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) _showError('Error adding device: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.adminRed),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = textColor.withOpacity(0.6);
    final surfaceColor = Theme.of(context).colorScheme.surface;

    // Live Math Preview
    double currentPreviewWattage = 0.0;
    if (_currentMode == ApplianceInputMode.preset && _selectedPreset != null) {
      currentPreviewWattage = (_selectedPreset!['preset_wattage'] as num).toDouble();
    } else if (_currentMode == ApplianceInputMode.slider) {
      currentPreviewWattage = _sliderWattage;
    } else if (_currentMode == ApplianceInputMode.free) {
      currentPreviewWattage = double.tryParse(_customWattageController.text) ?? 0.0;
    }

    double h = double.tryParse(_hoursController.text) ?? 0.0;
    double dailyKwh = (currentPreviewWattage * _quantity * h) / 1000;

    return Container(
      decoration: AppTheme.globalBackground(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(icon: Icon(Icons.close, color: textColor), onPressed: () => Navigator.pop(context)),
          title: Text('Add Appliance\n(Magdagdag ng Gamit)', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18, height: 1.2)),
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _presetsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.appYellow));
            }
            final presets = snapshot.data ?? [];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 1. MODE SELECTOR ---
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: surfaceColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.appYellow.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        _buildModeTab('Preset', ApplianceInputMode.preset, textColor),
                        _buildModeTab('Scroll', ApplianceInputMode.slider, textColor),
                        _buildModeTab('Custom', ApplianceInputMode.free, textColor),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- 2. DYNAMIC INPUT SECTIONS ---
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: surfaceColor.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.appYellow.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // Dropdown applies to both Preset and Slider mode
                        if (_currentMode != ApplianceInputMode.free) ...[
                          _buildSectionTitle('APPLIANCE TYPE (URI NG GAMIT)'),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<Map<String, dynamic>>(
                            decoration: _inputDecoration(surfaceColor, hintColor, Icons.category_outlined),
                            dropdownColor: surfaceColor,
                            hint: Text('Select from catalog...', style: TextStyle(color: hintColor, fontSize: 13)),
                            value: _selectedPreset,
                            isExpanded: true,
                            items: presets.map((preset) => DropdownMenuItem<Map<String, dynamic>>(
                                  value: preset,
                                  child: Text('${preset['appliance_name']} (${preset['preset_wattage']}W)', style: TextStyle(color: textColor, fontSize: 15)),
                                )).toList(),
                            onChanged: _onPresetSelected,
                          ),
                          const SizedBox(height: 25),
                        ],

                        // Mode-Specific Wattage Display / Controls
                        if (_currentMode == ApplianceInputMode.preset && _selectedPreset != null) ...[
                          _buildSectionTitle('FIXED PRESET WATTAGE'),
                          const SizedBox(height: 10),
                          Text(
                            '${_selectedPreset!['preset_wattage']} Watts',
                            style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 25),
                        ],

                        if (_currentMode == ApplianceInputMode.slider && _selectedPreset != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSectionTitle('ADJUST WATTAGE'),
                              Text('${_sliderWattage.toStringAsFixed(0)} W', style: const TextStyle(color: AppColors.appYellow, fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                          Slider(
                            value: _sliderWattage,
                            min: 0,
                            max: _maxSliderWattage,
                            activeColor: AppColors.appYellow,
                            inactiveColor: hintColor.withOpacity(0.2),
                            onChanged: (val) => setState(() => _sliderWattage = val),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('0W', style: TextStyle(color: hintColor, fontSize: 12)),
                              Text('Max: ${_maxSliderWattage.toStringAsFixed(0)}W', style: TextStyle(color: hintColor, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 25),
                        ],

                        if (_currentMode == ApplianceInputMode.free) ...[
                          _buildSectionTitle('CUSTOM WATTAGE'),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _customWattageController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                            decoration: _inputDecoration(surfaceColor, hintColor, Icons.bolt).copyWith(
                              hintText: 'e.g., 450',
                              suffixText: 'Watts',
                              suffixStyle: TextStyle(color: hintColor),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 25),
                        ],

                        _buildSectionTitle('IDENTIFIER (PANGALAN)'),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _customNameController,
                          style: TextStyle(color: textColor, fontSize: 16),
                          decoration: _inputDecoration(surfaceColor, hintColor, Icons.label_outline).copyWith(hintText: 'e.g., Master Bedroom AC'),
                        ),
                        const SizedBox(height: 25),

                        // --- QUANTITY CONTROLLER ---
                        _buildSectionTitle('QUANTITY (BILANG)'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildQtyButton(Icons.remove, () => setState(() { if (_quantity > 1) _quantity--; })),
                            Expanded(
                              child: Text('$_quantity', textAlign: TextAlign.center, style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)),
                            ),
                            _buildQtyButton(Icons.add, () => setState(() => _quantity++)),
                          ],
                        ),
                        const SizedBox(height: 25),

                        _buildSectionTitle('BASELINE USAGE (ORAS KADA ARAW)'),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _hoursController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                          decoration: _inputDecoration(surfaceColor, hintColor, Icons.schedule, iconColor: Colors.greenAccent).copyWith(
                            hintText: 'Hours per day',
                            suffixText: 'hrs',
                            suffixStyle: TextStyle(color: hintColor),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- 3. LIVE ESTIMATION PREVIEW ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Estimated Consumption', style: TextStyle(color: hintColor, fontSize: 12)),
                            Text('(${currentPreviewWattage.toStringAsFixed(0)}W × $_quantity units × ${h.toStringAsFixed(1)}h)', style: TextStyle(color: hintColor, fontSize: 10)),
                          ],
                        ),
                        Text('${dailyKwh.toStringAsFixed(2)} kWh/day', style: const TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- 4. SUBMIT ACTION ---
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isSaving ? null : _saveDevice,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 5,
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Add to Inventory (Idagdag)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildModeTab(String label, ApplianceInputMode mode, Color textColor) {
    bool isSelected = _currentMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentMode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.appYellow : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.black87 : textColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(color: AppColors.appYellow, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
    );
  }

  Widget _buildQtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.appYellow.withOpacity(0.3))),
        child: Icon(icon, color: AppColors.appYellow),
      ),
    );
  }

  InputDecoration _inputDecoration(Color surfaceColor, Color hintColor, IconData icon, {Color? iconColor}) {
    return InputDecoration(
      filled: true,
      fillColor: surfaceColor.withOpacity(0.8),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      prefixIcon: Icon(icon, color: iconColor ?? hintColor),
      hintStyle: TextStyle(color: hintColor, fontSize: 14),
    );
  }
}
