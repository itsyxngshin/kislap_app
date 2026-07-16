import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // <-- Import Supabase
import '../../theme/app_colors.dart';
import '../../models/appliance_preset.dart';

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final TextEditingController _deviceNameController = TextEditingController();
  final TextEditingController _wattageController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController(text: '0');
  
  AppliancePreset? _selectedPreset;
  final int _quantity = 1;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedPreset = commonAppliances.first; 
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    _wattageController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  // --- THE DATABASE INSERTION LOGIC ---
  Future<void> _saveDeviceToDatabase() async {
    // 1. Basic validation
    if (_deviceNameController.text.isEmpty || _wattageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill out all fields')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      // Note: Because of Row Level Security (RLS), a user MUST be logged in to insert data. 
      // If no user is logged in (Guest Mode), we catch it here.
      if (userId == null) {
        throw Exception("You must be logged in to save devices. Guest saves are disabled.");
      }

      // 2. Push to Supabase
      await supabase.from('appliances').insert({
        'user_id': userId,
        'name': _deviceNameController.text.trim(),
        'category': _selectedPreset?.category ?? 'Other',
        'watts': double.parse(_wattageController.text.trim()),
        'hours_per_day': double.parse(_hoursController.text.trim()),
        'quantity': _quantity,
      });

      // 3. Success! Show a message and return to the previous screen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device saved successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      // 4. Handle any errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppColors.adminRed),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppColors.globalGradient,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Add Device', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Appliance Type (Estimates)', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              DropdownButtonFormField<AppliancePreset>(
                initialValue: _selectedPreset,
                dropdownColor: AppColors.inputBackground,
                icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textHintColor),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: commonAppliances.map((preset) {
                  return DropdownMenuItem(value: preset, child: Text(preset.name));
                }).toList(),
                onChanged: (AppliancePreset? newValue) {
                  setState(() {
                    _selectedPreset = newValue;
                    if (newValue != null && newValue.name != 'Custom / Other') {
                      _deviceNameController.text = newValue.name;
                      _wattageController.text = newValue.estimatedWatts.toString();
                    } else {
                      _deviceNameController.clear();
                      _wattageController.clear();
                    }
                  });
                },
              ),
              const SizedBox(height: 20),

              const Text('Device Name', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: _deviceNameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g. Ceiling fan, master bedroom',
                  hintStyle: const TextStyle(color: AppColors.textHintColor),
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),

              // Power Draw & Quantity Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Power Draw', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _wattageController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Watts',
                            hintStyle: const TextStyle(color: AppColors.textHintColor),
                            filled: true,
                            fillColor: AppColors.inputBackground,
                            suffixText: 'W',
                            suffixStyle: const TextStyle(color: AppColors.textHintColor),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Hours/day', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _hoursController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.inputBackground,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // The Save Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveDeviceToDatabase,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.appYellow,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 2))
                      : const Text('Save Device', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}