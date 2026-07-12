import 'package:flutter/material.dart';
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
  
  AppliancePreset? _selectedPreset;

  @override
  void initState() {
    super.initState();
    _selectedPreset = commonAppliances.first; 
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    _wattageController.dispose();
    super.dispose();
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
                value: _selectedPreset,
                dropdownColor: AppColors.inputBackground,
                icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textHintColor),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: commonAppliances.map((preset) {
                  return DropdownMenuItem(
                    value: preset,
                    child: Text(preset.name),
                  );
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

              const Text('Power Draw', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: _wattageController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Watts (W)',
                  hintStyle: const TextStyle(color: AppColors.textHintColor),
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  suffixText: 'W',
                  suffixStyle: const TextStyle(color: AppColors.textHintColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.appYellow,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Device', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}