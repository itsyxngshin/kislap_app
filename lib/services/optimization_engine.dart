import '../models/appliance_item.dart';

class OptimizationEngine {
  /// Executes the Proportional Reduction Scaler algorithm
  static List<ApplianceItem> runProportionalReduction({
    required List<ApplianceItem> inventory,
    required double monthlyBudget,
    required double tariffRate,
  }) {
    if (inventory.isEmpty || monthlyBudget <= 0 || tariffRate <= 0) return inventory;

    double cLocked = 0.0;
    double cUnlockedBaseline = 0.0;

    // Steps 1 & 3: Isolate costs based on the lock status
    for (var item in inventory) {
      double kw = item.presetWattage / 1000;
      double monthlyCost = kw * item.userAssignedHours * 30 * tariffRate;

      if (item.isLocked) {
        cLocked += monthlyCost;
      } else {
        cUnlockedBaseline += monthlyCost;
      }
    }

    // Step 2: Determine Flexible Space
    double bFlexible = monthlyBudget - cLocked;

    // Handle Budget Breach: If fixed costs exceed the budget, all unlocked items are reduced to 0 hours.
    if (bFlexible <= 0) {
      return inventory.map((item) {
        return item.isLocked 
            ? item.copyWith(adjustedHours: item.userAssignedHours) 
            : item.copyWith(adjustedHours: 0.0);
      }).toList();
    }

    // If there are no unlocked items costing money, no adjustment is necessary.
    if (cUnlockedBaseline <= 0) {
      return inventory.map((item) => item.copyWith(adjustedHours: item.userAssignedHours)).toList();
    }

    // Step 4: Derive Scaling Factor (K)
    double k = bFlexible / cUnlockedBaseline;

    // Step 5: Apply Adjustment and format for human readability
    return inventory.map((item) {
      if (item.isLocked) {
        return item.copyWith(adjustedHours: item.userAssignedHours);
      } else {
        double hNew = item.userAssignedHours * k;
        
        // Constrain the hours between 0 and 24 per day
        hNew = hNew.clamp(0.0, 24.0);

        // Round to the nearest 0.25 (15-minute intervals)
        hNew = (hNew * 4).roundToDouble() / 4.0;

        return item.copyWith(adjustedHours: hNew);
      }
    }).toList();
  }
}