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
  final TextEditingController _hoursController = TextEditingController();

  Map<String, dynamic>? _selectedPreset;
  bool _isSaving = false;
  late Future<List<Map<String, dynamic>>> _presetsFuture;

  @override
  void initState() {
    super.initState();
    // Fetch presets from the local SQLite catalog immediately on load
    _presetsFuture = DatabaseHelper.instance.database.then((db) {
      return db.query('appliance_presets', orderBy: 'category, appliance_name');
    });
  }

  @override
  void dispose() {
    _customNameController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  void _saveDevice() async {
    if (_selectedPreset == null || _customNameController.text.trim().isEmpty || _hoursController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields.'), backgroundColor: AppColors.adminRed),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final double hours = double.parse(_hoursController.text);

      // Push the new device into the Riverpod state (which handles the math and SQLite insert)
      await ref.read(inventoryProvider.notifier).addAppliance(
        presetId: _selectedPreset!['id'],
        customName: _customNameController.text.trim(),
        defaultHours: hours,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device added and schedule optimized!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding device: $e'), backgroundColor: AppColors.adminRed),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = textColor.withValues(alpha: 0.6);
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return Container(
      decoration: AppTheme.globalBackground(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(icon: Icon(Icons.close, color: textColor), onPressed: () => Navigator.pop(context)),
          title: Text('Add Appliance', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _presetsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.appYellow));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No appliance presets found.\nPlease sync with the cloud.', style: TextStyle(color: hintColor)));
            }

            final presets = snapshot.data!;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Premium Glassmorphism Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: surfaceColor.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.appYellow.withValues(alpha: 0.2)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('APPLIANCE TYPE', style: TextStyle(color: AppColors.appYellow, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        const SizedBox(height: 10),

                        // The Fixed Dropdown
                        DropdownButtonFormField<Map<String, dynamic>>(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: surfaceColor.withValues(alpha: 0.8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            prefixIcon: const Icon(Icons.category_outlined, color: AppColors.appYellow),
                          ),
                          dropdownColor: surfaceColor,
                          icon: Icon(Icons.keyboard_arrow_down, color: hintColor),
                          hint: Text('Select from catalog...', style: TextStyle(color: hintColor)),
                          value: _selectedPreset,
                          isExpanded: true,
                          items: presets.map((preset) {
                            return DropdownMenuItem<Map<String, dynamic>>(
                              value: preset,
                              child: Text('${preset['appliance_name']} (${preset['preset_wattage']}W)', style: TextStyle(color: textColor, fontSize: 15)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedPreset = value;
                              // Auto-fill the custom name to speed up data entry
                              if (_customNameController.text.isEmpty && value != null) {
                                _customNameController.text = value['appliance_name'];
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 25),

                        Text('CUSTOM IDENTIFIER', style: TextStyle(color: AppColors.appYellow, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _customNameController,
                          style: TextStyle(color: textColor, fontSize: 16),
                          decoration: InputDecoration(
                            hintText: 'e.g., Master Bedroom AC',
                            hintStyle: TextStyle(color: hintColor),
                            filled: true,
                            fillColor: surfaceColor.withValues(alpha: 0.8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            prefixIcon: Icon(Icons.label_outline, color: hintColor),
                          ),
                        ),
                        const SizedBox(height: 25),

                        Text('BASELINE USAGE', style: TextStyle(color: AppColors.appYellow, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _hoursController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: 'Hours per day',
                            hintStyle: TextStyle(color: hintColor, fontWeight: FontWeight.normal),
                            filled: true,
                            fillColor: surfaceColor.withValues(alpha: 0.8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            prefixIcon: const Icon(Icons.schedule, color: Colors.greenAccent),
                            suffixText: 'hrs',
                            suffixStyle: TextStyle(color: hintColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Vibrant Orange Primary Action
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
                          : const Text('Add to Inventory', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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
}
