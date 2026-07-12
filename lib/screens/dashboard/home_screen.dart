import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'add_device_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false, // Prevents padding conflicts with the floating nav bar
      child: SingleChildScrollView(
        // Extra bottom padding ensures content isn't hidden forever behind the floating bar
        padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Area
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Maria', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                Stack(
                  children: [
                    const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(color: AppColors.adminRed, shape: BoxShape.circle),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),

            // The Hero Estimator Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.inputBackground.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  // Budget Progress Ring
                  SizedBox(
                    height: 80,
                    width: 80,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: 0.73,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          color: AppColors.appYellow,
                          strokeWidth: 8,
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('73%', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                              Text('of budget', style: TextStyle(color: AppColors.textHintColor, fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Billing Numbers
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ESTIMATED BILL', style: TextStyle(color: AppColors.textHintColor, fontSize: 12, letterSpacing: 1.2)),
                        const SizedBox(height: 5),
                        const Text('₱1,184.25', style: TextStyle(color: AppColors.appYellow, fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.adminRed.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                          child: const Text('↑ 12% vs last month', style: TextStyle(color: AppColors.adminRed, fontSize: 11, fontWeight: FontWeight.bold)),
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
                    decoration: BoxDecoration(color: AppColors.inputBackground.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.bolt, color: AppColors.appYellow, size: 20),
                        const SizedBox(height: 10),
                        const Text('13.42 kWh', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("Today's use", style: TextStyle(color: AppColors.textHintColor, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.inputBackground.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.access_time, color: Colors.greenAccent, size: 20),
                        const SizedBox(height: 10),
                        const Text('₱148.43', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("Est. cost today", style: TextStyle(color: AppColors.textHintColor, fontSize: 12)),
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
                  // Direct link to the Add Device Screen
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddDeviceScreen()));
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
                const Text('Live draw', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {},
                  child: const Text('See all', style: TextStyle(color: AppColors.appYellow, fontSize: 13)),
                ),
              ],
            ),
            
            // Dummy Appliance Block
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.inputBackground.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.ac_unit, color: Colors.greenAccent, size: 24),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Refrigerator', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('180W · always on', style: TextStyle(color: AppColors.textHintColor, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Text('₱48.17', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Reusable widget for those square action buttons
  Widget _buildQuickAction(IconData icon, String label, {bool isPrimary = false, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: isPrimary ? AppColors.appYellow : AppColors.inputBackground.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: isPrimary ? Colors.black87 : Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: AppColors.textHintColor, fontSize: 12)),
        ],
      ),
    );
  }
}