import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../services/database_helper.dart';

class Appliance {
  final String id;
  final int presetId;
  final String customName;
  final double presetWattage;
  final double userAssignedHours;
  final double adjustedHours;
  final bool isLocked;

  Appliance({
    required this.id,
    required this.presetId,
    required this.customName,
    required this.presetWattage,
    required this.userAssignedHours,
    required this.adjustedHours,
    required this.isLocked,
  });

  Appliance copyWith({double? adjustedHours, bool? isLocked}) {
    return Appliance(
      id: id,
      presetId: presetId,
      customName: customName,
      presetWattage: presetWattage,
      userAssignedHours: userAssignedHours,
      adjustedHours: adjustedHours ?? this.adjustedHours,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}

// UPGRADED: Using the modern Riverpod 2.x Notifier class
class InventoryNotifier extends Notifier<List<Appliance>> {
  @override
  List<Appliance> build() {
    // The build method replaces the old constructor initialization
    Future.microtask(() => _loadInventory());
    return [];
  }

  Future<void> _loadInventory() async {
    // We start with the current empty state and run the optimization math
    await _optimizeAndSave(state);
  }

  Future<void> addAppliance({
    required int presetId,
    required String customName,
    required double defaultHours,
    required double wattage,
  }) async {
    final newItem = Appliance(
      id: const Uuid().v4(),
      presetId: presetId,
      customName: customName,
      presetWattage: wattage,
      userAssignedHours: defaultHours,
      adjustedHours: defaultHours,
      isLocked: false,
    );

    final newState = [...state, newItem];
    await _optimizeAndSave(newState);
  }

  Future<void> removeAppliance(String id) async {
    final newState = state.where((item) => item.id != id).toList();
    await _optimizeAndSave(newState);
  }

  Future<void> toggleLock(String id, bool currentLockState) async {
    final newState = state.map((item) {
      if (item.id == id) {
        return item.copyWith(isLocked: !currentLockState);
      }
      return item;
    }).toList();
    await _optimizeAndSave(newState);
  }

  // --- THE PROPORTIONAL REDUCTION ALGORITHM ---
  // --- THE OFFICIAL BUDGET OPTIMIZATION ENGINE ---
    Future<void> _optimizeAndSave(List<Appliance> currentState) async {
      final db = await DatabaseHelper.instance.database;
      final settings = await db.query('user_settings', limit: 1);

      double budget = 0.0;
      double tariff = 12.35; // Aligned with ALECO June 2026 Mainland Rate

      if (settings.isNotEmpty) {
        budget = (settings.first['monthly_budget'] as num).toDouble();
        tariff = (settings.first['tariff_rate'] as num).toDouble();
      }

      if (budget <= 0) {
        state = currentState;
        return;
      }

      // Step 1: Calculate the Monthly Energy Allowance
      final double energyAllowanceKwh = budget / tariff;

      // Step 3: Calculate the Total Energy Consumption of Locked Appliances
      double lockedMonthlyKwh = 0.0;
      for (var item in currentState) {
        if (item.isLocked) {
          // Formula: (Power * Quantity * Hours * 30) / 1000
          // Note: Assuming Quantity = 1 for the current data model iteration
          lockedMonthlyKwh += (item.presetWattage * 1 * item.userAssignedHours * 30) / 1000;
        }
      }

      // Step 4: Determine the Remaining Energy Allowance
      double remainingEnergy = energyAllowanceKwh - lockedMonthlyKwh;
      if (remainingEnergy < 0) remainingEnergy = 0;

      // Step 5: Calculate the Total Energy Consumption of Unlocked Appliances
      double unlockedMonthlyKwh = 0.0;
      for (var item in currentState) {
        if (!item.isLocked) {
          unlockedMonthlyKwh += (item.presetWattage * 1 * item.userAssignedHours * 30) / 1000;
        }
      }

      // Step 6: Determine the Recommended Operating Hours
      double reductionFactor = 1.0;
      if (unlockedMonthlyKwh > remainingEnergy && unlockedMonthlyKwh > 0) {
        reductionFactor = remainingEnergy / unlockedMonthlyKwh;
      }

      // Apply Reduction Factor
      final optimizedState = currentState.map((item) {
        if (item.isLocked) {
          return item.copyWith(adjustedHours: item.userAssignedHours);
        } else {
          return item.copyWith(adjustedHours: item.userAssignedHours * reductionFactor);
        }
      }).toList();

      state = optimizedState;
    }
}

// UPGRADED: Modern Provider Syntax
final inventoryProvider = NotifierProvider<InventoryNotifier, List<Appliance>>(
  () {
    return InventoryNotifier();
  },
);
