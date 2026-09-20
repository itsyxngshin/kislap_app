import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // <-- Added for Scroll Wheels
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
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

  // THE FIX: State variables for the scroll wheels
  int _selectedHours = 1;
  int _selectedMinutes = 0;

  @override
  void initState() {
    super.initState();
    _loadPresets();
  }

  @override
  void dispose() {
    _customNameController.dispose();
    _customWattageController.dispose();
    super.dispose();
  }

  Future<void> _loadPresets() async {
    List<Map<String, dynamic>> finalData = [];
    try {
      final supabaseData = await Supabase.instance.client
          .from('appliance_presets')
          .select('*')
          .order('category', ascending: true)
          .order('appliance_name', ascending: true);

      if (supabaseData.isNotEmpty) {
        finalData = List<Map<String, dynamic>>.from(supabaseData);
        final db = await DatabaseHelper.instance.database;
        Batch batch = db.batch();
        batch.delete('appliance_presets');
        for (var preset in finalData) {
          batch.insert('appliance_presets', {
            'id': preset['id'],
            'category': preset['category'],
            'appliance_name': preset['appliance_name'],
            'preset_wattage': (preset['preset_wattage'] as num).toDouble(),
            'min_wattage':
                preset.containsKey('min_wattage') &&
                    preset['min_wattage'] != null
                ? (preset['min_wattage'] as num).toDouble()
                : (preset['preset_wattage'] as num).toDouble(),
            'max_wattage':
                preset.containsKey('max_wattage') &&
                    preset['max_wattage'] != null
                ? (preset['max_wattage'] as num).toDouble()
                : (preset['preset_wattage'] as num).toDouble(),
          });
        }
        await batch.commit(noResult: true);
      } else {
        throw 'Supabase catalog is empty.';
      }
    } catch (e) {
      try {
        final db = await DatabaseHelper.instance.database;
        final localData = await db.query(
          'appliance_presets',
          orderBy: 'category, appliance_name',
        );
        if (localData.isNotEmpty)
          finalData = List<Map<String, dynamic>>.from(localData);
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _presets = finalData;
        _categories = finalData
            .map((p) => p['category'] as String)
            .toSet()
            .toList();
        if (_categories.isNotEmpty && _selectedCategory == null)
          _selectedCategory = _categories.first;
        _isLoading = false;
      });
    }
  }

  void _onPresetSelected(Map<String, dynamic>? preset) {
    setState(() {
      _selectedPreset = preset;
      if (preset != null) {
        if (_customNameController.text.isEmpty)
          _customNameController.text = preset['appliance_name'];
        final double baseWattage = (preset['preset_wattage'] as num).toDouble();
        _maxSliderWattage = preset.containsKey('max_wattage')
            ? (preset['max_wattage'] as num).toDouble()
            : baseWattage * 2.0;
        _sliderWattage = baseWattage;
      }
    });
  }

  // THE FIX: Scroll Wheel Modal Function
  void _showTimePicker() {
    final isPh = ref.read(settingsProvider).language == 'ph';
    final textColor = Theme.of(context).colorScheme.onSurface;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext builder) {
        return SizedBox(
          height: 280,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  isPh ? 'Piliin ang Oras' : 'Select Usage Duration',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Expanded(
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    textTheme: CupertinoTextThemeData(
                      pickerTextStyle: TextStyle(
                        color: textColor,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  child: CupertinoTimerPicker(
                    mode: CupertinoTimerPickerMode.hm,
                    initialTimerDuration: Duration(
                      hours: _selectedHours,
                      minutes: _selectedMinutes,
                    ),
                    onTimerDurationChanged: (Duration newDuration) {
                      setState(() {
                        _selectedHours = newDuration.inHours;
                        _selectedMinutes = newDuration.inMinutes % 60;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
    if (_customNameController.text.trim().isEmpty) {
      _showError(
        isPh
            ? 'Magbigay ng pangalan ng gamit.'
            : 'Please provide an identifier name.',
      );
      return;
    }

    // Mathematical conversion from wheel to double
    final double finalHours = _selectedHours + (_selectedMinutes / 60.0);

    if (finalHours <= 0 || finalHours > 24) {
      _showError(
        isPh
            ? 'Ang oras ay dapat higit sa 0 at hindi lalampas ng 24.'
            : 'Duration must be greater than 0 and max 24 hours.',
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
      await inventoryNotifier.addAppliance(
        presetId: presetId ?? 9999,
        customName: displayName,
        category: _selectedCategory ?? 'Custom',
        defaultHours: finalHours,
        wattage: finalWattage,
        quantity: 1,
      );
    }

    setState(() {
      _selectedPreset = null;
      _customNameController.clear();
      _customWattageController.clear();
      _quantity = 1;
      _selectedHours = 1;
      _selectedMinutes = 0;
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

    // Live UI conversion
    double h = _selectedHours + (_selectedMinutes / 60.0);
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
                              isPh ? 'I-slide' : 'Range Slider',
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
                              DropdownButtonFormField<String>(
                                decoration: _inputDecoration(
                                  surfaceColor,
                                  hintColor,
                                  Icons.grid_view,
                                ),
                                dropdownColor: surfaceColor,
                                hint: Text(
                                  isPh
                                      ? 'Pumili ng kategorya...'
                                      : 'Select a category...',
                                  style: TextStyle(
                                    color: hintColor,
                                    fontSize: 13,
                                  ),
                                ),
                                value: _selectedCategory,
                                isExpanded: true,
                                items: _categories
                                    .map(
                                      (cat) => DropdownMenuItem<String>(
                                        value: cat,
                                        child: Text(
                                          cat,
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedCategory = val;
                                    _selectedPreset = null;
                                    _customNameController.clear();
                                  });
                                },
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
                                            fontSize: 14,
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
                            // THE FIX: Converted TextField to a custom button that opens the Wheel
                            GestureDetector(
                              onTap: _showTimePicker,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: surfaceColor.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.schedule,
                                      color: Colors.greenAccent,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      isPh
                                          ? '$_selectedHours oras $_selectedMinutes min'
                                          : '$_selectedHours hrs $_selectedMinutes mins',
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(Icons.unfold_more, color: hintColor),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

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
