import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_text_field.dart';

class AdminPresetManagementScreen extends StatefulWidget {
  const AdminPresetManagementScreen({super.key});

  @override
  State<AdminPresetManagementScreen> createState() => _AdminPresetManagementScreenState();
}

class _AdminPresetManagementScreenState extends State<AdminPresetManagementScreen> {
  bool _isLoading = true;
  List<dynamic> _cloudPresets = [];

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
          .order('category', ascending: true);
      if (mounted) setState(() => _cloudPresets = data);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading presets: $e'), backgroundColor: AppColors.adminRed));
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    String selectedCategory = existingPreset?['category'] ?? 'Cooling';

    final categories = ['Cooling', 'Kitchen', 'Laundry', 'Bathroom', 'Electronics', 'Lighting', 'Entertainment', 'Other'];
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(existingPreset == null ? 'Add Global Preset' : 'Edit Global Preset', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(filled: true, fillColor: textColor.withOpacity(0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                  dropdownColor: surfaceColor,
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: textColor)))).toList(),
                  onChanged: (val) => setModalState(() => selectedCategory = val!),
                ),
                const SizedBox(height: 16),

                CustomTextField(controller: nameController, hint: 'Appliance Name (e.g. 1.5HP AC)', icon: Icons.label_outline),
                const SizedBox(height: 16),

                CustomTextField(controller: wattsController, hint: 'Base Wattage (W)', icon: Icons.bolt, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty || wattsController.text.isEmpty) return;

                      final payload = {
                        'appliance_name': nameController.text.trim(),
                        'category': selectedCategory,
                        'preset_wattage': double.parse(wattsController.text.trim()),
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
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = textColor.withOpacity(0.6);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Global Presets Manager', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 22)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.adminRed))
          : ListView.builder(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 120),
              itemCount: _cloudPresets.length,
              itemBuilder: (context, index) {
                final preset = _cloudPresets[index];
                return Card(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: textColor.withOpacity(0.05))),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    title: Text(preset['appliance_name'], style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                    subtitle: Text('${preset['category']} • ${preset['preset_wattage']}W', style: TextStyle(color: hintColor)),
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: FloatingActionButton.extended(
          onPressed: () => _showPresetModal(),
          backgroundColor: AppColors.adminRed,
          icon: const Icon(Icons.cloud_upload_outlined, color: Colors.white),
          label: const Text('Add Preset', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
