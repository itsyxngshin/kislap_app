import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  // Master function to fetch all required data
  Future<Map<String, dynamic>> _fetchDeviceData() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) throw Exception("User not logged in");

    // 1. Fetch user's devices
    final devices = await supabase.from('appliances').select().eq('user_id', userId).order('created_at');
    
    // 2. Fetch user's location preference
    final profile = await supabase.from('profiles').select('location').eq('id', userId).single();
    final location = profile['location'] as String;

    // 3. Fetch the current billing rate
    final rateData = await supabase.from('billing_rates').select().order('billing_month', ascending: false).limit(1).single();
    
    final activeRate = location == 'island' ? rateData['island_rate'] : rateData['mainland_rate'];

    return {
      'devices': devices,
      'rate': activeRate,
    };
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _fetchDeviceData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.appYellow));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading devices: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          }

          final devices = snapshot.data!['devices'] as List<dynamic>;
          final rate = snapshot.data!['rate'] as num;

          return SingleChildScrollView(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('My Devices', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 20),

                if (devices.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Text("No devices added yet. Click 'Add device' on the Home tab!", style: TextStyle(color: AppColors.textHintColor)),
                    ),
                  )
                else
                  ...devices.map((device) {
                    // The Math: (Watts / 1000) * hours * 30 days
                    final double dailyKwh = (device['watts'] / 1000) * device['hours_per_day'] * device['quantity'];
                    final double monthlyKwh = dailyKwh * 30;
                    final double monthlyCost = monthlyKwh * rate;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: _buildDeviceCard(
                        name: device['name'],
                        category: device['category'],
                        specs: '${device['watts']}W · ${device['hours_per_day']} hrs/day',
                        icon: Icons.electrical_services,
                        iconColor: AppColors.appYellow,
                        dailyKwh: dailyKwh.toStringAsFixed(2),
                        monthlyKwh: monthlyKwh.toStringAsFixed(1),
                        estCost: '₱${monthlyCost.toStringAsFixed(0)}',
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDeviceCard({
    required String name, required String category, required String specs,
    required IconData icon, required Color iconColor,
    required String dailyKwh, required String monthlyKwh, required String estCost,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.inputBackground.withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(specs, style: const TextStyle(color: AppColors.textHintColor, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Text(category, style: TextStyle(color: iconColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Colors.white10, height: 1)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricColumn('Daily', '$dailyKwh kWh', Colors.white),
              _buildMetricColumn('Monthly', '$monthlyKwh kWh', Colors.white),
              _buildMetricColumn('Est. cost', estCost, AppColors.appYellow),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textHintColor, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}