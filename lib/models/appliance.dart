class Appliance {
  final String id;
  final int presetId;
  final String customName;
  final String category;
  final double presetWattage;
  final int quantity;
  final double userAssignedHours;
  final double adjustedHours;
  final bool isLocked;

  Appliance({
    required this.id,
    required this.presetId,
    required this.customName,
    required this.category,
    required this.presetWattage,
    required this.quantity,
    required this.userAssignedHours,
    required this.adjustedHours,
    required this.isLocked,
  });

  Appliance copyWith({
    String? customName,
    String? category,
    double? presetWattage,
    int? quantity,
    double? userAssignedHours,
    double? adjustedHours,
    bool? isLocked,
  }) {
    return Appliance(
      id: id,
      presetId: presetId,
      customName: customName ?? this.customName,
      category: category ?? this.category,
      presetWattage: presetWattage ?? this.presetWattage,
      quantity: quantity ?? this.quantity,
      userAssignedHours: userAssignedHours ?? this.userAssignedHours,
      adjustedHours: adjustedHours ?? this.adjustedHours,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  Map<String, dynamic> toSqliteMap() {
    return {
      'id': id,
      'preset_id': presetId,
      'custom_name': customName,
      'preset_wattage': presetWattage,
      'quantity': quantity,
      'user_assigned_hours': userAssignedHours,
      'adjusted_hours': adjustedHours,
      'is_locked': isLocked ? 1 : 0,
    };
  }

  Map<String, dynamic> toSupabaseMap(String userId) {
    return {
      'id': id,
      'user_id': userId,
      'name': customName,
      'category': category,
      'watts': presetWattage,
      'hours_per_day': adjustedHours,
      'quantity': quantity,
    };
  }
}
