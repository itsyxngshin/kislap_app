class AppliancePreset {
  final String name;
  final double
  estimatedWatts; // FIX: Changed to double to match database structure
  final String category;

  AppliancePreset({
    required this.name,
    required this.estimatedWatts,
    required this.category,
  });
}

// Updated to match the comprehensive PH audit data injected into SQLite
final List<AppliancePreset> commonAppliances = [
  AppliancePreset(
    name: 'Custom / Other',
    estimatedWatts: 0.0,
    category: 'Other',
  ),
  AppliancePreset(
    name: 'Window Aircon (0.75 HP)',
    estimatedWatts: 760.0,
    category: 'Cooling',
  ),
  AppliancePreset(
    name: 'Inverter Window (1.0 HP)',
    estimatedWatts: 650.0,
    category: 'Cooling',
  ),
  AppliancePreset(
    name: 'Inverter Split Type (1.5 HP)',
    estimatedWatts: 1050.0,
    category: 'Cooling',
  ),
  AppliancePreset(
    name: 'Desk/Stand Fan (12"-16")',
    estimatedWatts: 55.0,
    category: 'Cooling',
  ),
  AppliancePreset(
    name: 'Conventional Fridge (6-8 cu.ft)',
    estimatedWatts: 150.0,
    category: 'Kitchen',
  ),
  AppliancePreset(
    name: 'Inverter Fridge (9-12 cu.ft)',
    estimatedWatts: 115.0,
    category: 'Kitchen',
  ),
  AppliancePreset(
    name: 'Rice Cooker (1.0L-1.8L)',
    estimatedWatts: 575.0,
    category: 'Kitchen',
  ),
  AppliancePreset(
    name: 'Microwave Oven',
    estimatedWatts: 1000.0,
    category: 'Kitchen',
  ),
  AppliancePreset(
    name: 'Induction Cooker',
    estimatedWatts: 1750.0,
    category: 'Kitchen',
  ),
  AppliancePreset(
    name: 'Twin Tub Washing Machine',
    estimatedWatts: 375.0,
    category: 'Laundry',
  ),
  AppliancePreset(
    name: 'Flat / Steam Iron',
    estimatedWatts: 1125.0,
    category: 'Laundry',
  ),
  AppliancePreset(
    name: 'Shower Water Heater',
    estimatedWatts: 3750.0,
    category: 'Bathroom',
  ),
  AppliancePreset(
    name: 'LED Smart TV (32"-43")',
    estimatedWatts: 40.0,
    category: 'Electronics',
  ),
  AppliancePreset(
    name: 'Laptop (Standard)',
    estimatedWatts: 47.5,
    category: 'Electronics',
  ),
  AppliancePreset(
    name: 'Wi-Fi Router / Fiber Modem',
    estimatedWatts: 14.0,
    category: 'Electronics',
  ),
  AppliancePreset(
    name: 'LED Light Bulb',
    estimatedWatts: 9.0,
    category: 'Lighting',
  ),
  AppliancePreset(
    name: 'LED Light Bulb',
    estimatedWatts: 12.0,
    category: 'Lighting',
  ),
  AppliancePreset(
    name: 'LED Light Bulb',
    estimatedWatts: 15.0,
    category: 'Lighting',
  ),
];
