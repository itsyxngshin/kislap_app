import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('My Devices', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                Icon(Icons.search, color: AppColors.textHintColor),
              ],
            ),
            const SizedBox(height: 20),

            // Horizontal Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All · 12', isSelected: true),
                  const SizedBox(width: 10),
                  _buildFilterChip('Cooling · 4'),
                  const SizedBox(width: 10),
                  _buildFilterChip('Kitchen · 5'),
                  const SizedBox(width: 10),
                  _buildFilterChip('Entertainment · 3'),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Device List
            _buildDeviceCard(
              name: 'Air conditioner',
              category: 'Cooling',
              specs: '1200W · 8 hrs/day',
              icon: Icons.ac_unit,
              iconColor: AppColors.appYellow,
              dailyKwh: '9.6',
              monthlyKwh: '288',
              estCost: '₱3,191',
            ),
            const SizedBox(height: 15),
            
            _buildDeviceCard(
              name: 'Refrigerator',
              category: 'Kitchen',
              specs: '180W · 24 hrs/day',
              icon: Icons.kitchen,
              iconColor: Colors.greenAccent,
              dailyKwh: '4.32',
              monthlyKwh: '129.6',
              estCost: '₱1,438',
            ),
            const SizedBox(height: 15),

            _buildDeviceCard(
              name: 'Electric fan',
              category: 'Cooling',
              specs: '65W · 12 hrs/day',
              icon: Icons.air,
              iconColor: AppColors.appYellow,
              dailyKwh: '0.78',
              monthlyKwh: '23.4',
              estCost: '₱260',
            ),
          ],
        ),
      ),
    );
  }

  // Helper for the Filter Chips
  Widget _buildFilterChip(String label, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.appYellow : AppColors.inputBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.black87 : AppColors.textHintColor,
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  // Helper for the Device Cards
  Widget _buildDeviceCard({
    required String name,
    required String category,
    required String specs,
    required IconData icon,
    required Color iconColor,
    required String dailyKwh,
    required String monthlyKwh,
    required String estCost,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Top Row: Icon, Name, Tag
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
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
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(category, style: TextStyle(color: iconColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.white10, height: 1),
          ),
          
          // Bottom Row: Metrics
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