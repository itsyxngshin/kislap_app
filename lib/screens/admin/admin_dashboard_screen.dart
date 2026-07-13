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
  String _currentBillingMonth = '2026-07-01'; // Based on our SQL setup

  @override
  void initState() {
    super.initState();
    _fetchCurrentRates();
  }

  Future<void> _fetchCurrentRates() async {
    try {
      // Get the most recent billing rate record
      final data = await Supabase.instance.client
          .from('billing_rates')
          .select()
          .order('billing_month', ascending: false)
          .limit(1)
          .single();

      if (mounted) {
        setState(() {
          _mainlandRateController.text = data['mainland_rate'].toString();
          _islandRateController.text = data['island_rate'].toString();
          _currentBillingMonth = data['billing_month'].toString();
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

  Future<void> _updateRates() async {
    if (_mainlandRateController.text.isEmpty || _islandRateController.text.isEmpty) return;

    setState(() => _isUpdating = true);
    
    try {
      await Supabase.instance.client
          .from('billing_rates')
          .update({
            'mainland_rate': double.parse(_mainlandRateController.text),
            'island_rate': double.parse(_islandRateController.text),
          })
          .eq('billing_month', _currentBillingMonth); // Update the active month

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Global rates successfully updated!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating: $e'), backgroundColor: AppColors.adminRed));
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SignInScreen()),
        (route) => false,
      );
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
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _signOut,
            )
          ],
        ),
        body: _isLoadingData
            ? const Center(child: CircularProgressIndicator(color: AppColors.appYellow))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                          const Text(
                            'Rate Management',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Updating rates for billing month: $_currentBillingMonth. These changes reflect globally.',
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
                        onPressed: _isUpdating ? null : _updateRates,
                        icon: _isUpdating 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.cloud_upload),
                        label: Text(
                          _isUpdating ? 'Pushing Updates...' : 'Update Global Rates',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.adminRed,
                          foregroundColor: Colors.white,
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