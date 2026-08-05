class ApplianceItem {
  final int? id;
  final int presetId;
  final String customName;
  final String category;
  final double presetWattage;
  final int quantity; // <-- NEW: Added quantity
  final double userAssignedHours;
  final double adjustedHours;
  final bool isLocked;

  ApplianceItem({
    this.id,
    required this.presetId,
    required this.customName,
    required this.category,
    required this.presetWattage,
    required this.quantity, // <-- NEW: Required parameter
    required this.userAssignedHours,
    required this.adjustedHours,
    required this.isLocked,
  });

  // Convert a SQLite Row map into an ApplianceItem object
  factory ApplianceItem.fromMap(Map<String, dynamic> map) {
    return ApplianceItem(
      id: map['id'] as int?,
      presetId: map['preset_id'] as int,
      customName: map['custom_name'] as String,
      category: map['category'] as String,
      // FIX: Use (as num).toDouble() to safely parse SQLite REALs that might be whole numbers
      presetWattage: (map['preset_wattage'] as num).toDouble(),
      quantity:
          map['quantity'] as int? ??
          1, // <-- NEW: Parses quantity with a fallback of 1
      userAssignedHours: (map['user_assigned_hours'] as num).toDouble(),
      adjustedHours: (map['adjusted_hours'] as num).toDouble(),
      isLocked: (map['is_locked'] as int) == 1,
    );
  }

  // Copy wrapper to easily mutate states like toggling a lock
  ApplianceItem copyWith({
    int? id,
    int? presetId,
    String? customName,
    String? category,
    double? presetWattage,
    int? quantity, // <-- NEW: Added to copyWith
    double? userAssignedHours,
    double? adjustedHours,
    bool? isLocked,
  }) {
    return ApplianceItem(
      id: id ?? this.id,
      presetId: presetId ?? this.presetId,
      customName: customName ?? this.customName,
      category: category ?? this.category,
      presetWattage: presetWattage ?? this.presetWattage,
      quantity: quantity ?? this.quantity, // <-- NEW: Merges state
      userAssignedHours: userAssignedHours ?? this.userAssignedHours,
      adjustedHours: adjustedHours ?? this.adjustedHours,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}
