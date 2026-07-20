import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../services/database_helper.dart';
import '../../providers/inventory_provider.dart';

class AddDeviceScreen extends ConsumerStatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  ConsumerState<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends ConsumerState<AddDeviceScreen> {
  final TextEditingController _customNameController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController(
    text: '0',
  );

  List<Map<String, dynamic>> _presets = [];
  Map<String, dynamic>? _selectedPreset;
  bool _isLoadingPresets = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadLocalPresets();
  }

  // Load master catalog options directly from local SQLite storage
  Future<void> _loadLocalPresets() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final presets = await db.query('appliance_presets');
      if (mounted && presets.isNotEmpty) {
        setState(() {
          _presets = presets;
          _selectedPreset = presets.first;
          _customNameController.text = _selectedPreset!['appliance_name'];
        });
      }
    } catch (_) {}
    setState(() => _isLoadingPresets = false);
  }

  @override
  void dispose() {
    _customNameController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _saveUniqueDevice() async {
    if (_customNameController.text.isEmpty ||
        _hoursController.text.isEmpty ||
        _selectedPreset == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please verify inputs')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final double hours = double.parse(_hoursController.text.trim());

      // Save directly via the Riverpod state notifier to seamlessly trigger UI refreshes
      await ref
          .read(inventoryProvider.notifier)
          .addAppliance(
            presetId: _selectedPreset!['id'] as int,
            customName: _customNameController.text.trim(),
            defaultHours: hours,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unique device item added!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: AppColors.adminRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = textColor.withValues(alpha: 0.6);
    final surfaceColor = Theme.of(context).colorScheme.surface;

    if (_isLoadingPresets) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.appYellow),
        ),
      );
    }

    return Container(
      decoration: AppTheme.globalBackground(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Add Item Instance',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Catalog Base',
                style: TextStyle(color: hintColor, fontSize: 13),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<Map<String, dynamic>>(
                value: _selectedPreset,
                dropdownColor: surfaceColor,
                icon: Icon(Icons.keyboard_arrow_down, color: hintColor),
                style: TextStyle(color: textColor, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _presets.map((preset) {
                  return DropdownMenuItem(
                    value: preset,
                    child: Text(
                      '${preset['appliance_name']} (${preset['preset_wattage']}W)',
                    ),
                  );
                }).toList(),
                onChanged: (Map<String, dynamic>? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedPreset = newValue;
                      _customNameController.text = newValue['appliance_name'];
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              Text(
                'Custom Display Tag Name',
                style: TextStyle(color: hintColor, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _customNameController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'e.g., Living Room Fan, Kitchen Microwave',
                  hintStyle: TextStyle(color: hintColor.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Baseline Daily Use Hours',
                style: TextStyle(color: hintColor, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _hoursController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  suffixText: 'hrs/day',
                  suffixStyle: TextStyle(color: hintColor),
                  filled: true,
                  fillColor: surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveUniqueDevice,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.black87,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Add to Planning space',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
}
