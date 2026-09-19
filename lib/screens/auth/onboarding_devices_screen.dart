import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../services/database_helper.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/settings_provider.dart';
import '../dashboard/dashboard_shell.dart';

enum ApplianceInputMode { preset, slider, free }

class OnboardingDevicesScreen extends ConsumerStatefulWidget {
  const OnboardingDevicesScreen({super.key});

  @override
  ConsumerState<OnboardingDevicesScreen> createState() =>
      _OnboardingDevicesScreenState();
}

class _OnboardingDevicesScreenState
    extends ConsumerState<OnboardingDevicesScreen> {
  final TextEditingController _customNameController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController();
  final TextEditingController _customWattageController =
      TextEditingController();

  ApplianceInputMode _currentMode = ApplianceInputMode.preset;
  List<Map<String, dynamic>> _presets = [];
  List<String> _categories = [];
  String? _selectedCategory;
  Map<String, dynamic>? _selectedPreset;

  bool _isLoading = true;
  int _quantity = 1;
  double _sliderWattage = 0.0;
  double _maxSliderWattage = 2000.0;

  static const List<Map<String, dynamic>> _fallbackCatalog = [
    {
      'id': 1,
      'category': 'Cooling',
      'appliance_name': 'Inverter AC (1.0 HP)',
      'preset_wattage': 750.0,
    },
    {
      'id': 2,
      'category': 'Cooling',
      'appliance_name': 'Non-Inverter AC (1.0 HP)',
      'preset_wattage': 1000.0,
    },
    {
      'id': 3,
      'category': 'Cooling',
      'appliance_name': 'Electric Fan',
      'preset_wattage': 65.0,
    },
    {
      'id': 4,
      'category': 'Entertainment',
      'appliance_name': 'LED TV (32")',
      'preset_wattage': 50.0,
    },
    {
      'id': 5,
      'category': 'Entertainment',
      'appliance_name': 'LED TV (43")',
      'preset_wattage': 80.0,
    },
    {
      'id': 6,
      'category': 'Kitchen',
      'appliance_name': 'Inverter Refrigerator',
      'preset_wattage': 120.0,
    },
    {
      'id': 7,
      'category': 'Kitchen',
      'appliance_name': 'Standard Refrigerator',
      'preset_wattage': 150.0,
    },
    {
      'id': 8,
      'category': 'Kitchen',
      'appliance_name': 'Microwave',
      'preset_wattage': 1000.0,
    },
    {
      'id': 9,
      'category': 'Kitchen',
      'appliance_name': 'Rice Cooker',
      'preset_wattage': 400.0,
    },
    {
      'id': 10,
      'category': 'Laundry',
      'appliance_name': 'Washing Machine',
      'preset_wattage': 500.0,
    },
    {
      'id': 11,
      'category': 'Laundry',
      'appliance_name': 'Iron',
      'preset_wattage': 1000.0,
    },
    {
      'id': 12,
      'category': 'Lighting',
      'appliance_name': 'LED Bulb',
      'preset_wattage': 9.0,
    },
    {
      'id': 13,
      'category': 'Lighting',
      'appliance_name': 'Fluorescent Tube',
      'preset_wattage': 20.0,
    },
    {
      'id': 14,
      'category': 'Computing',
      'appliance_name': 'Laptop',
      'preset_wattage': 65.0,
    },
    {
      'id': 15,
      'category': 'Computing',
      'appliance_name': 'Desktop PC',
      'preset_wattage': 250.0,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadPresets();
  }

  @override
  void dispose() {
    _customNameController.dispose();
    _hoursController.dispose();
    _customWattageController.dispose();
    super.dispose();
  }

  Future<void> _loadPresets() async {
    List<Map<String, dynamic>> finalData = _fallbackCatalog;
    try {
      final db = await DatabaseHelper.instance.database;
      final data = await db.query(
        'appliance_presets',
        orderBy: 'category, appliance_name',
      );
      if (data.isNotEmpty) finalData = data;
    } catch (_) {}

    if (mounted) {
      setState(() {
        _presets = finalData;
        _categories = finalData
            .map((p) => p['category'] as String)
            .toSet()
            .toList();
        if (_categories.isNotEmpty) _selectedCategory = _categories.first;
        _isLoading = false;
      });
    }
  }

  void _onPresetSelected(Map<String, dynamic>? preset) {
    setState(() {
      _selectedPreset = preset;
      if (preset != null) {
        if (_customNameController.text.isEmpty) {
          _customNameController.text = preset['appliance_name'];
        }
        final double baseWattage = (preset['preset_wattage'] as num).toDouble();
        _maxSliderWattage = preset.containsKey('max_wattage')
            ? (preset['max_wattage'] as num).toDouble()
            : baseWattage * 2.0;
        _sliderWattage = baseWattage;
      }
    });
  }

  void _addApplianceToList() async {
    final isPh = ref.read(settingsProvider).language == 'ph';

    if (_currentMode != ApplianceInputMode.free && _selectedPreset == null) {
      _showError(
        isPh
            ? 'Pumili ng gamit mula sa listahan.'
            : 'Please select an appliance from the catalog.',
      );
      return;
    }
    if (_currentMode == ApplianceInputMode.free &&
        _customWattageController.text.trim().isEmpty) {
      _showError(
        isPh
            ? 'Ilagay ang iyong custom na wattage.'
            : 'Please enter a custom wattage.',
      );
      return;
    }
    if (_customNameController.text.trim().isEmpty ||
        _hoursController.text.trim().isEmpty) {
      _showError(
        isPh
            ? 'Pakikumpleto ang lahat ng field.'
            : 'Please complete all fields.',
      );
      return;
    }

    final double hours = double.tryParse(_hoursController.text) ?? 0.0;
    if (hours <= 0 || hours > 24) {
      _showError(
        isPh
            ? 'Maglagay ng tamang oras (1-24).'
            : 'Enter valid hours per day (1-24).',
      );
      return;
    }

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
        presetId = null;
        break;
    }

    if (finalWattage <= 0) {
      _showError(
        isPh
            ? 'Ang wattage ay dapat higit sa 0.'
            : 'Wattage must be greater than 0.',
      );
      return;
    }

    final inventoryNotifier = ref.read(inventoryProvider.notifier);
    final String baseName = _customNameController.text.trim();

    for (int i = 0; i < _quantity; i++) {
      String displayName = _quantity > 1 ? '$baseName (#${i + 1})' : baseName;

      // THE FIX: We pass the category down to the provider, and the provider
      // automatically handles both the SQLite cache AND the Supabase cloud sync!
      await inventoryNotifier.addAppliance(
        presetId: presetId ?? 9999,
        customName: displayName,
        category: _selectedCategory ?? 'Custom',
        defaultHours: hours,
        wattage: finalWattage,
        quantity: 1,
      );
    }

    setState(() {
      _selectedPreset = null;
      _customNameController.clear();
      _hoursController.clear();
      _customWattageController.clear();
      _quantity = 1;
    });

    FocusScope.of(context).unfocus();
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
    final isPh = ref.watch(settingsProvider).language == 'ph';
    final devices = ref.watch(inventoryProvider);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.appYellow),
        ),
      );
    }

    final filteredPresets = _presets
        .where((p) => p['category'] == _selectedCategory)
        .toList();

    double currentPreviewWattage = 0.0;
    if (_currentMode == ApplianceInputMode.preset && _selectedPreset != null)
      currentPreviewWattage = (_selectedPreset!['preset_wattage'] as num)
          .toDouble();
    else if (_currentMode == ApplianceInputMode.slider)
      currentPreviewWattage = _sliderWattage;
    else if (_currentMode == ApplianceInputMode.free)
      currentPreviewWattage =
          double.tryParse(_customWattageController.text) ?? 0.0;

    double h = double.tryParse(_hoursController.text) ?? 0.0;
    double dailyKwh = (currentPreviewWattage * _quantity * h) / 1000;

    return Container(
      decoration: AppTheme.globalBackground(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            isPh ? 'I-setup ang mga Gamit' : 'Setup Inventory',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPh
                            ? 'Magdagdag ng mga Appliances'
                            : 'Add Your Appliances',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isPh
                            ? 'Ilagay lahat ng gamit sa bahay upang masimulan ang pag-optimize ng Kislap.'
                            : 'Add all your household appliances so Kislap can optimize your schedule.',
                        style: TextStyle(
                          color: hintColor,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- MODE SELECTOR ---
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: surfaceColor.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.appYellow.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildModeTab(
                              isPh ? 'Nakatakda' : 'Preset',
                              ApplianceInputMode.preset,
                              textColor,
                            ),
                            _buildModeTab(
                              isPh ? 'I-scroll' : 'Scroll',
                              ApplianceInputMode.slider,
                              textColor,
                            ),
                            _buildModeTab(
                              isPh ? 'Sarili' : 'Custom',
                              ApplianceInputMode.free,
                              textColor,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // --- DYNAMIC INPUT SECTIONS ---
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
                            if (_currentMode != ApplianceInputMode.free) ...[
                              _buildSectionTitle(
                                isPh ? '1. KATEGORYA' : '1. CATEGORY',
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 38,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _categories.length,
                                  itemBuilder: (context, index) {
                                    final cat = _categories[index];
                                    final isSelected = _selectedCategory == cat;
                                    return GestureDetector(
                                      onTap: () => setState(() {
                                        _selectedCategory = cat;
                                        _selectedPreset = null;
                                        _customNameController.clear();
                                      }),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        margin: const EdgeInsets.only(right: 8),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.appYellow
                                              : surfaceColor,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.appYellow
                                                : hintColor.withOpacity(0.2),
                                          ),
                                        ),
                                        child: Text(
                                          cat,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.black87
                                                : textColor,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 25),

                              _buildSectionTitle(
                                isPh ? '2. URI NG GAMIT' : '2. APPLIANCE TYPE',
                              ),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<Map<String, dynamic>>(
                                decoration: _inputDecoration(
                                  surfaceColor,
                                  hintColor,
                                  Icons.category_outlined,
                                ),
                                dropdownColor: surfaceColor,
                                hint: Text(
                                  isPh
                                      ? 'Pumili sa listahan...'
                                      : 'Select from catalog...',
                                  style: TextStyle(
                                    color: hintColor,
                                    fontSize: 13,
                                  ),
                                ),
                                value: _selectedPreset,
                                isExpanded: true,
                                items: filteredPresets
                                    .map(
                                      (
                                        preset,
                                      ) => DropdownMenuItem<Map<String, dynamic>>(
                                        value: preset,
                                        child: Text(
                                          '${preset['appliance_name']} (${preset['preset_wattage']}W)',
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _onPresetSelected,
                              ),
                              const SizedBox(height: 25),
                            ],

                            if (_currentMode == ApplianceInputMode.preset &&
                                _selectedPreset != null) ...[
                              _buildSectionTitle(
                                isPh
                                    ? 'NAKATAKDANG WATTAGE'
                                    : 'FIXED PRESET WATTAGE',
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '${_selectedPreset!['preset_wattage']} Watts',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 25),
                            ],

                            if (_currentMode == ApplianceInputMode.slider &&
                                _selectedPreset != null) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildSectionTitle(
                                    isPh
                                        ? 'AYUSIN ANG WATTAGE'
                                        : 'ADJUST WATTAGE',
                                  ),
                                  Text(
                                    '${_sliderWattage.toStringAsFixed(0)} W',
                                    style: const TextStyle(
                                      color: AppColors.appYellow,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                              Slider(
                                value: _sliderWattage,
                                min: 0,
                                max: _maxSliderWattage,
                                activeColor: AppColors.appYellow,
                                inactiveColor: hintColor.withOpacity(0.2),
                                onChanged: (val) =>
                                    setState(() => _sliderWattage = val),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '0W',
                                    style: TextStyle(
                                      color: hintColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    'Max: ${_maxSliderWattage.toStringAsFixed(0)}W',
                                    style: TextStyle(
                                      color: hintColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 25),
                            ],

                            if (_currentMode == ApplianceInputMode.free) ...[
                              _buildSectionTitle(
                                isPh ? 'SARILING WATTAGE' : 'CUSTOM WATTAGE',
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _customWattageController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration:
                                    _inputDecoration(
                                      surfaceColor,
                                      hintColor,
                                      Icons.bolt,
                                    ).copyWith(
                                      hintText: isPh
                                          ? 'Halimbawa, 450'
                                          : 'e.g., 450',
                                      suffixText: 'Watts',
                                      suffixStyle: TextStyle(color: hintColor),
                                    ),
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 25),
                            ],

                            _buildSectionTitle(
                              isPh ? 'PANGALAN NG GAMIT' : 'IDENTIFIER (NAME)',
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _customNameController,
                              style: TextStyle(color: textColor, fontSize: 16),
                              decoration:
                                  _inputDecoration(
                                    surfaceColor,
                                    hintColor,
                                    Icons.label_outline,
                                  ).copyWith(
                                    hintText: isPh
                                        ? 'Halimbawa, AC sa Kwarto'
                                        : 'e.g., Master Bedroom AC',
                                  ),
                            ),
                            const SizedBox(height: 25),

                            _buildSectionTitle(isPh ? 'BILANG' : 'QUANTITY'),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _buildQtyButton(
                                  Icons.remove,
                                  () => setState(() {
                                    if (_quantity > 1) _quantity--;
                                  }),
                                ),
                                Expanded(
                                  child: Text(
                                    '$_quantity',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                _buildQtyButton(
                                  Icons.add,
                                  () => setState(() => _quantity++),
                                ),
                              ],
                            ),
                            const SizedBox(height: 25),

                            _buildSectionTitle(
                              isPh
                                  ? 'ORAS KADA ARAW'
                                  : 'BASELINE USAGE (HOURS/DAY)',
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _hoursController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration:
                                  _inputDecoration(
                                    surfaceColor,
                                    hintColor,
                                    Icons.schedule,
                                    iconColor: Colors.greenAccent,
                                  ).copyWith(
                                    hintText: isPh
                                        ? 'Oras kada araw'
                                        : 'Hours per day',
                                    suffixText: 'hrs',
                                    suffixStyle: TextStyle(color: hintColor),
                                  ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // --- LIVE ESTIMATION PREVIEW ---
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isPh
                                      ? 'Tinatayang Konsumo'
                                      : 'Estimated Consumption',
                                  style: TextStyle(
                                    color: hintColor,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  isPh
                                      ? '(${currentPreviewWattage.toStringAsFixed(0)}W × $_quantity piraso × ${h.toStringAsFixed(1)}h)'
                                      : '(${currentPreviewWattage.toStringAsFixed(0)}W × $_quantity units × ${h.toStringAsFixed(1)}h)',
                                  style: TextStyle(
                                    color: hintColor,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${dailyKwh.toStringAsFixed(2)} kWh/day',
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // --- SUBMIT ACTION ---
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _addApplianceToList,
                          icon: const Icon(Icons.add, color: Colors.black87),
                          label: Text(
                            isPh ? 'Idagdag sa Listahan' : 'Add to List',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.appYellow,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // --- INVENTORY LIST ---
                      Text(
                        isPh ? 'IYONG LISTAHAN' : 'YOUR INVENTORY',
                        style: TextStyle(
                          color: hintColor,
                          fontSize: 11,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      if (devices.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: surfaceColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: textColor.withOpacity(0.05),
                            ),
                          ),
                          child: Text(
                            isPh
                                ? 'Wala ka pang naidadagdag na gamit.'
                                : 'No appliances added yet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: hintColor, fontSize: 13),
                          ),
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: textColor.withOpacity(0.05),
                                ),
                              ),
                              child: ListTile(
                                title: Text(
                                  '${device.customName} (x${device.quantity})',
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${device.presetWattage}W • ${device.userAssignedHours} hrs/day',
                                  style: TextStyle(
                                    color: hintColor,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.adminRed,
                                  ),
                                  onPressed: () => ref
                                      .read(inventoryProvider.notifier)
                                      .removeAppliance(device.id),
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
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const DashboardShell()),
                      (route) => false,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      isPh ? 'Kumpleto na ang Setup' : 'Complete Setup',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
      style: const TextStyle(
        color: AppColors.appYellow,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildQtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.appYellow.withOpacity(0.3)),
        ),
        child: Icon(icon, color: AppColors.appYellow),
      ),
    );
  }

  InputDecoration _inputDecoration(
    Color surfaceColor,
    Color hintColor,
    IconData icon, {
    Color? iconColor,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: surfaceColor.withOpacity(0.8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      prefixIcon: Icon(icon, color: iconColor ?? hintColor),
      hintStyle: TextStyle(color: hintColor, fontSize: 14),
    );
  }
}
