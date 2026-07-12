class AppliancePreset {
  final String name;
  final int estimatedWatts;
  final String category;

  AppliancePreset({required this.name, required this.estimatedWatts, required this.category});
}

final List<AppliancePreset> commonAppliances = [
  AppliancePreset(name: 'Custom / Other', estimatedWatts: 0, category: 'Other'),
  AppliancePreset(name: 'Inverter Aircon (1HP)', estimatedWatts: 750, category: 'Cooling'),
  AppliancePreset(name: 'Electric Fan (Stand)', estimatedWatts: 65, category: 'Cooling'),
  AppliancePreset(name: 'Refrigerator (Standard)', estimatedWatts: 150, category: 'Kitchen'),
  AppliancePreset(name: 'Rice Cooker', estimatedWatts: 400, category: 'Kitchen'),
  AppliancePreset(name: 'LED TV (43-inch)', estimatedWatts: 60, category: 'Entertainment'),
  AppliancePreset(name: 'Washing Machine', estimatedWatts: 500, category: 'Utility'),
];