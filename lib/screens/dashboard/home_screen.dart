import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import 'add_device_screen.dart';
import '../../widgets/guest_view.dart'; // Make sure to import it at the top of the file!

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'Loading...';
  double _totalMonthlyCost = 0.0;
  double _totalDailyKwh = 0.0;
  double _totalDailyCost = 0.0;
  
  List<dynamic> _topDevices = [];
  bool _isLoading = true;
  bool _isGuest = false;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      
      if (user == null) {
        if (mounted) setState(() {
          _isGuest = true;
          _isLoading = false;
        });
        return;
      }
      _isGuest = false;

      // 1. Safely fetch Profile
      final profile = await supabase.from('profiles').select('full_name, location').eq('id', user.id).maybeSingle();
      final location = profile?['location'] as String? ?? 'mainland';
      final fullName = profile?['full_name'] as String? ?? 'User';
      _userName = fullName.split(' ')[0];

      // 2. Safely fetch Active Billing Rate
      final rateData = await supabase.from('billing_rates').select().order('billing_month', ascending: false).limit(1).maybeSingle();
      final double fallbackRate = location == 'island' ? 11.33 : 11.08;
      final rate = rateData != null 
          ? (location == 'island' ? rateData['island_rate'] : rateData['mainland_rate']) as num 
          : fallbackRate;

      // 3. Fetch Appliances & Run Math
      final devices = await supabase.from('appliances').select().eq('user_id', user.id);
      double dailyKwhSum = 0;
      
      final sortedDevices = List<Map<String, dynamic>>.from(devices);
      sortedDevices.sort((a, b) {
        final aKwh = (a['watts'] / 1000) * a['hours_per_day'] * a['quantity'];
        final bKwh = (b['watts'] / 1000) * b['hours_per_day'] * b['quantity'];
        return bKwh.compareTo(aKwh); 
      });

      for (var device in devices) {
        final double watts = device['watts'] / 1000;
        final double hours = device['hours_per_day'];
        final int qty = device['quantity'];
        dailyKwhSum += (watts * hours * qty);
      }

      if (mounted) {
        setState(() {
          _totalDailyKwh = dailyKwhSum;
          _totalDailyCost = dailyKwhSum * rate;
          _totalMonthlyCost = _totalDailyCost * 30;
          _topDevices = sortedDevices;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.appYellow));
    }

    if (_isGuest) {
      return const GuestView(
        icon: Icons.bolt,
        title: 'Unlock Your Dashboard',
        subtitle: 'Create an account to start adding appliances, tracking your energy usage, and estimating your monthly bill.',
      );
    }

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.appYellow,
        backgroundColor: AppColors.inputBackground,
        onRefresh: _fetchDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_userName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  Stack(
                    children: [
                      const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
                      Positioned(
                        right: 2, top: 2,
                        child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.adminRed, shape: BoxShape.circle)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Hero Estimator Card with Animations
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.inputBackground.withOpacity(0.5), borderRadius: BorderRadius.circular(24)),
                child: Row(
                  children: [
                    SizedBox(
                      height: 80,
                      width: 80,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: 0.73), // 73% budget prototype value
                        duration: const Duration(milliseconds: 1500),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(
                                value: value,
                                backgroundColor: Colors.white.withOpacity(0.1),
                                color: AppColors.appYellow,
                                strokeWidth: 8,
                              ),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('${(value * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                    const Text('of budget', style: TextStyle(color: AppColors.textHintColor, fontSize: 10)),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ESTIMATED BILL', style: TextStyle(color: AppColors.textHintColor, fontSize: 12, letterSpacing: 1.2)),
                          const SizedBox(height: 5),
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: _totalMonthlyCost),
                            duration: const Duration(milliseconds: 1500),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Text(
                                '₱${value.toStringAsFixed(0)}', 
                                style: const TextStyle(color: AppColors.appYellow, fontSize: 28, fontWeight: FontWeight.bold)
                              );
                            },
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.adminRed.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                            child: const Text('Tracking higher', style: TextStyle(color: AppColors.adminRed, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Secondary Metric Cards
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.inputBackground.withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.bolt, color: AppColors.appYellow, size: 20),
                          const SizedBox(height: 10),
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: _totalDailyKwh),
                            duration: const Duration(milliseconds: 1500),
                            builder: (context, value, child) => Text('${value.toStringAsFixed(1)} kWh', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                          const Text("Today's use", style: TextStyle(color: AppColors.textHintColor, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.inputBackground.withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.access_time, color: Colors.greenAccent, size: 20),
                          const SizedBox(height: 10),
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: _totalDailyCost),
                            duration: const Duration(milliseconds: 1500),
                            builder: (context, value, child) => Text('₱${value.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                          const Text("Est. cost today", style: TextStyle(color: AppColors.textHintColor, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Quick Actions Grid
              const Text('Quick Actions', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildQuickAction(Icons.add, 'Add device', isPrimary: true, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddDeviceScreen())).then((_) => _fetchDashboardData()); 
                  }),
                  _buildQuickAction(Icons.show_chart, 'Reports', onTap: () {}),
                  _buildQuickAction(Icons.access_time, 'Rate', onTap: () {}),
                  _buildQuickAction(Icons.ios_share, 'Export', onTap: () {}),
                ],
              ),
              const SizedBox(height: 30),

              // Live Draw Stream
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Top consumer', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(onPressed: () {}, child: const Text('See all', style: TextStyle(color: AppColors.appYellow, fontSize: 13))),
                ],
              ),
              
              if (_topDevices.isNotEmpty)
                _buildTopDeviceCard(_topDevices.first)
              else
                Container(
                  padding: const EdgeInsets.all(20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.inputBackground.withOpacity(0.5), borderRadius: BorderRadius.circular(16)),
                  child: const Text('No devices found.', style: TextStyle(color: AppColors.textHintColor)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, {bool isPrimary = false, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 60, width: 60,
            decoration: BoxDecoration(
              color: isPrimary ? AppColors.appYellow : AppColors.inputBackground.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: isPrimary ? Colors.black87 : Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: AppColors.textHintColor, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTopDeviceCard(Map<String, dynamic> device) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.inputBackground.withOpacity(0.5), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.bolt, color: Colors.greenAccent, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device['name'], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${device['watts']}W · ${device['hours_per_day']} hrs/day', style: const TextStyle(color: AppColors.textHintColor, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}