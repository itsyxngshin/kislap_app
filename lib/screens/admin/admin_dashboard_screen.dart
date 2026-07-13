import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../auth/sign_in_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final TextEditingController _mainlandRateController = TextEditingController();
  final TextEditingController _islandRateController = TextEditingController();
  
  bool _isUpdating = false;
  bool _isLoadingData = true;
  
  // Default to July 2026 (the current active period in our prototype)
  DateTime _selectedMonth = DateTime(2026, 7, 1);
  
  // Generate a list of 24 months (all of 2025 and 2026) for the dropdown
  final List<DateTime> _monthOptions = List.generate(24, (i) => DateTime(2025 + (i ~/ 12), (i % 12) + 1, 1));

  @override
  void initState() {
    super.initState();
    _fetchRatesForSelectedMonth();
  }

  // Helper to format DateTime into "YYYY-MM-01" for Postgres
  String _toDbDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-01';
  }

  // Helper to format DateTime into "Month YYYY" for the UI Dropdown
  String _formatMonth(DateTime date) {
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${monthNames[date.month - 1]} ${date.year}';
  }

  Future<void> _fetchRatesForSelectedMonth() async {
    setState(() => _isLoadingData = true);
    final String dbDate = _toDbDate(_selectedMonth);

    try {
      // maybeSingle() returns null if the month doesn't exist yet, avoiding a crash
      final data = await Supabase.instance.client
          .from('billing_rates')
          .select()
          .eq('billing_month', dbDate)
          .maybeSingle();

      if (mounted) {
        setState(() {
          if (data != null) {
            _mainlandRateController.text = data['mainland_rate'].toString();
            _islandRateController.text = data['island_rate'].toString();
          } else {
            // Clear the fields so the admin can enter new rates
            _mainlandRateController.clear();
            _islandRateController.clear();
          }
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load rates: $e')));
      }
    }
  }

  Future<void> _saveRates() async {
    if (_mainlandRateController.text.isEmpty || _islandRateController.text.isEmpty) return;

    setState(() => _isUpdating = true);
    final String dbDate = _toDbDate(_selectedMonth);
    
    try {
      final supabase = Supabase.instance.client;
      
      // 1. Check if the month already exists
      final existing = await supabase.from('billing_rates').select().eq('billing_month', dbDate).maybeSingle();

      if (existing != null) {
        // 2. If it exists, UPDATE it
        await supabase.from('billing_rates').update({
          'mainland_rate': double.parse(_mainlandRateController.text),
          'island_rate': double.parse(_islandRateController.text),
        }).eq('billing_month', dbDate);
      } else {
        // 3. If it's a new month, INSERT it
        await supabase.from('billing_rates').insert({
          'billing_month': dbDate,
          'mainland_rate': double.parse(_mainlandRateController.text),
          'island_rate': double.parse(_islandRateController.text),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rates saved for ${_formatMonth(_selectedMonth)}!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e'), backgroundColor: AppColors.adminRed));
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const SignInScreen()), (route) => false);
    }
  }

  @override
  void dispose() {
    _mainlandRateController.dispose();
    _islandRateController.dispose();
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
          title: const Row(
            children: [
              Icon(Icons.admin_panel_settings, color: AppColors.adminRed),
              SizedBox(width: 10),
              Text('Admin Control', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: _signOut)
          ],
        ),
        body: _isLoadingData
            ? const Center(child: CircularProgressIndicator(color: AppColors.appYellow))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    // Month Selector Dropdown
                    const Text('Select Billing Month', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<DateTime>(
                      value: _selectedMonth,
                      dropdownColor: AppColors.inputBackground,
                      icon: const Icon(Icons.calendar_today, color: AppColors.textHintColor, size: 20),
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.inputBackground,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: _monthOptions.map((date) {
                        return DropdownMenuItem(value: date, child: Text(_formatMonth(date)));
                      }).toList(),
                      onChanged: (DateTime? newValue) {
                        if (newValue != null) {
                          setState(() => _selectedMonth = newValue);
                          _fetchRatesForSelectedMonth(); // Fetch new data when changed
                        }
                      },
                    ),
                    const SizedBox(height: 30),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.adminRed.withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Rate Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 8),
                          Text(
                            'Enter the exact ₱/kWh rates for ${_formatMonth(_selectedMonth)}. If fields are blank, this month has not been configured yet.',
                            style: const TextStyle(color: AppColors.textHintColor, fontSize: 13, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    const Text('Mainland Rate (₱ / kWh)', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _mainlandRateController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.bolt, color: AppColors.appYellow),
                        filled: true,
                        fillColor: AppColors.inputBackground,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text('Island Rate (₱ / kWh)', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _islandRateController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.waves, color: Colors.cyanAccent),
                        filled: true,
                        fillColor: AppColors.inputBackground,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isUpdating ? null : _saveRates,
                        icon: _isUpdating 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 2))
                            : const Icon(Icons.save),
                        label: Text(
                          _isUpdating ? 'Saving...' : 'Save Rates',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.appYellow,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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