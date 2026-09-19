import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_text_field.dart';

class AdminPresetManagementScreen extends StatefulWidget {
  const AdminPresetManagementScreen({super.key});

  @override
  State<AdminPresetManagementScreen> createState() => _AdminPresetManagementScreenState();
}

class _AdminPresetManagementScreenState extends State<AdminPresetManagementScreen> {
  bool _isLoading = true;
  List<dynamic> _cloudPresets = [];
  List<String> _categories = [];
  String? _selectedFilterCategory;

  // The comprehensive category list from your massive 170-item seed
  final List<String> _allCategories = [
    'Cooling & Air Conditioning', 'Kitchen & Cooking', 'Small Kitchen Appliances',
    'Laundry & Cleaning', 'Entertainment & Work From Home', 'Bathroom & Personal Care',
    'Lighting & Household Utilities', 'Home Content Creation & Accent Lighting',
    'Health, Wellness & Comfort', 'Garage, DIY & Power Tools', 'Miscellaneous Device Chargers',
    'Smart Home & Security', 'Specialty Care & Hobby', 'Outdoor & Pool',
    'E-Mobility Charging (Home)', 'Home Office & Utilities',
    'Senior Care & Medical Home Appliances', 'Vintage & Retro Household Appliances',
    'Legacy & Older Residential Lighting'
  ];

  @override
  void initState() {
    super.initState();
    _fetchCloudPresets();
  }

  Future<void> _fetchCloudPresets() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('appliance_presets')
          .select()
          .order('category', ascending: true)
          .order('appliance_name', ascending: true);
      
      if (mounted) {
        setState(() {
          _cloudPresets = data;
          _categories = data.map((p) => p['category'] as String).toSet().toList();
          if (_selectedFilterCategory == null && _categories.isNotEmpty) {
            _selectedFilterCategory = _categories.first;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading presets: $e'), backgroundColor: AppColors.adminRed));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deletePreset(int id) async {
    try {
      await Supabase.instance.client.from('appliance_presets').delete().eq('id', id);
      _fetchCloudPresets();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preset deleted successfully.'), backgroundColor: Colors.greenAccent));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.adminRed));
    }
  }

  void _showPresetModal({Map<String, dynamic>? existingPreset}) {
    final nameController = TextEditingController(text: existingPreset?['appliance_name']);
    final wattsController = TextEditingController(text: existingPreset?['preset_wattage']?.toString());
    final minWattsController = TextEditingController(text: existingPreset?['min_wattage']?.toString());
    final maxWattsController = TextEditingController(text: existingPreset?['max_wattage']?.toString());
    
    String selectedCategory = existingPreset?['category'] ?? _allCategories.first;

    final textColor = Theme.of(context).colorScheme.onSurface;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
            decoration: BoxDecoration(color: surfaceColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(existingPreset == null ? 'Add Global Preset' : 'Edit Global Preset', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  Text('Category', style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 12)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _allCategories.contains(selectedCategory) ? selectedCategory : _allCategories.first,
                    isExpanded: true,
                    decoration: InputDecoration(filled: true, fillColor: textColor.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                    dropdownColor: surfaceColor,
                    items: _allCategories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: textColor, fontSize: 14)))).toList(),
                    onChanged: (val) => setModalState(() => selectedCategory = val!),
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(controller: nameController, hint: 'Appliance Name (e.g. 1.5HP AC)', icon: Icons.label_outline),
                  const SizedBox(height: 16),

                  CustomTextField(controller: wattsController, hint: 'Base Wattage (W)', icon: Icons.bolt, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(child: CustomTextField(controller: minWattsController, hint: 'Min W', icon: Icons.remove, keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                      const SizedBox(width: 16),
                      Expanded(child: CustomTextField(controller: maxWattsController, hint: 'Max W', icon: Icons.add, keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                    ],
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        if (nameController.text.isEmpty || wattsController.text.isEmpty || minWattsController.text.isEmpty || maxWattsController.text.isEmpty) return;

                        final payload = {
                          'appliance_name': nameController.text.trim(),
                          'category': selectedCategory,
                          'preset_wattage': double.parse(wattsController.text.trim()),
                          'min_wattage': double.parse(minWattsController.text.trim()),
                          'max_wattage': double.parse(maxWattsController.text.trim()),
                        };

                        try {
                          if (existingPreset == null) {
                            await Supabase.instance.client.from('appliance_presets').insert(payload);
                          } else {
                            await Supabase.instance.client.from('appliance_presets').update(payload).eq('id', existingPreset['id']);
                          }
                          if (mounted) {
                            Navigator.pop(context);
                            _fetchCloudPresets();
                          }
                        } catch (e) {
                           if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e'), backgroundColor: AppColors.adminRed));
                        }
                      },
                      style: FilledButton.styleFrom(backgroundColor: AppColors.adminRed, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: Text(existingPreset == null ? 'Publish to Cloud' : 'Update Cloud Preset', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = textColor.withOpacity(0.6);
    final surfaceColor = Theme.of(context).colorScheme.surface;

    final filteredPresets = _cloudPresets.where((p) => p['category'] == _selectedFilterCategory).toList();

    return Container(
      decoration: AppTheme.globalBackground(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Preset Manager', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 22)),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.adminRed))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- CATEGORY FILTER CHIPS ---
                  Container(
                    height: 50,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = _selectedFilterCategory == cat;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedFilterCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.adminRed : surfaceColor.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSelected ? AppColors.adminRed : hintColor.withOpacity(0.2)),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                color: isSelected ? Colors.white : textColor,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // --- LIST OF PRESETS ---
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 120),
                      itemCount: filteredPresets.length,
                      itemBuilder: (context, index) {
                        final preset = filteredPresets[index];
                        return Card(
                          color: surfaceColor.withOpacity(0.5),
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: textColor.withOpacity(0.05))),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            title: Text(preset['appliance_name'], style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                            subtitle: Text('${preset['preset_wattage']}W (Range: ${preset['min_wattage']} - ${preset['max_wattage']}W)', style: TextStyle(color: hintColor, fontSize: 12)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent), onPressed: () => _showPresetModal(existingPreset: preset)),
                                IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.adminRed), onPressed: () => _deletePreset(preset['id'])),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 80.0),
          child: FloatingActionButton.extended(
            onPressed: () => _showPresetModal(),
            backgroundColor: AppColors.adminRed,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('New Preset', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}