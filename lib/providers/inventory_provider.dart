import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import '../services/database_helper.dart';

class Appliance {
  final String id;
  final int presetId;
  final String customName;
  final double presetWattage;
  final int quantity; // <-- NEW: Added quantity parameter
  final double userAssignedHours;
  final double adjustedHours;
  final bool isLocked;

  Appliance({
    required this.id,
    required this.presetId,
    required this.customName,
    required this.presetWattage,
    required this.quantity, // <-- NEW: Required parameter
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
      quantity: quantity, // <-- NEW: Maintain quantity on copy
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

  // --- 1. THE FIX: ACTUALLY LOAD FROM SQLITE ---
  Future<void> _loadInventory() async {
    final db = await DatabaseHelper.instance.database;

    // Fetch all saved appliances from the database
    final data = await db.query('user_appliances');

    // Convert the raw SQLite map into your Appliance objects
    final loadedAppliances = data.map((row) {
      return Appliance(
        id: row['id'] as String,
        presetId: row['preset_id'] as int,
        customName: row['custom_name'] as String,
        presetWattage: (row['preset_wattage'] as num).toDouble(),
        quantity:
            row['quantity'] as int? ??
            1, // <-- NEW: Safely parse quantity with a fallback
        userAssignedHours: (row['user_assigned_hours'] as num).toDouble(),
        adjustedHours: (row['adjusted_hours'] as num).toDouble(),
        isLocked:
            (row['is_locked'] as int) == 1, // SQLite stores booleans as 0 or 1
      );
    }).toList();

    // Run the optimization on the loaded appliances in case the user
    // changed their budget/tariff while the app was closed!
    await _optimizeAndSave(loadedAppliances);
  }

  Future<void> addAppliance({
    required int presetId,
    required String customName,
    required double defaultHours,
    required double wattage,
    required int quantity, // <-- NEW: Accept quantity from UI
  }) async {
    final newItem = Appliance(
      id: const Uuid().v4(),
      presetId: presetId,
      customName: customName,
      presetWattage: wattage,
      quantity: quantity, // <-- NEW: Pass to model
      userAssignedHours: defaultHours,
      adjustedHours: defaultHours,
      isLocked: false,
    );

    final newState = [...state, newItem];
    await _optimizeAndSave(newState);
  }

  Future<void> editAppliance({
      required String id,
      required String customName,
      required int quantity,
      required double userAssignedHours,
    }) async {
      final newState = state.map((item) {
        if (item.id == id) {
          return item.copyWith(
            customName: customName,
            quantity: quantity,
            userAssignedHours: userAssignedHours,
            adjustedHours: userAssignedHours, // Resets before running the optimization engine
          );
        }
        return item;
      }).toList();
  
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

    List<Appliance> optimizedState = currentState;

    // Only run the math if there is a budget set
    if (budget > 0) {
      // Step 1: Calculate the Monthly Energy Allowance
      final double energyAllowanceKwh = budget / tariff;

      // Step 2: Calculate the Total Energy Consumption of Locked Appliances
      double lockedMonthlyKwh = 0.0;
      for (var item in currentState) {
        if (item.isLocked) {
          // NEW: Multiply by item.quantity instead of hardcoded 1
          lockedMonthlyKwh +=
              (item.presetWattage *
                  item.quantity *
                  item.userAssignedHours *
                  30) /
              1000;
        }
      }

      // Step 3: Determine the Remaining Energy Allowance
      double remainingEnergy = energyAllowanceKwh - lockedMonthlyKwh;
      if (remainingEnergy < 0) remainingEnergy = 0;

      // Step 4: Calculate the Total Energy Consumption of Unlocked Appliances
      double unlockedMonthlyKwh = 0.0;
      for (var item in currentState) {
        if (!item.isLocked) {
          // NEW: Multiply by item.quantity instead of hardcoded 1
          unlockedMonthlyKwh +=
              (item.presetWattage *
                  item.quantity *
                  item.userAssignedHours *
                  30) /
              1000;
        }
      }

      // Step 5: Determine the Recommended Operating Hours
      double reductionFactor = 1.0;
      if (unlockedMonthlyKwh > remainingEnergy && unlockedMonthlyKwh > 0) {
        reductionFactor = remainingEnergy / unlockedMonthlyKwh;
      }

      // Apply Reduction Factor
      optimizedState = currentState.map((item) {
        if (item.isLocked) {
          return item.copyWith(adjustedHours: item.userAssignedHours);
        } else {
          return item.copyWith(
            adjustedHours: item.userAssignedHours * reductionFactor,
          );
        }
      }).toList();
    }

    // Update the UI State instantly
    state = optimizedState;

    // --- 2. THE FIX: ACTUALLY SAVE TO SQLITE ---
    // We use a database "batch" to safely clear the old inventory and save the new one
    // simultaneously, preventing corrupted data.
    Batch batch = db.batch();
    batch.delete('user_appliances');

    for (var item in optimizedState) {
      batch.insert('user_appliances', {
        'id': item.id,
        'preset_id': item.presetId,
        'custom_name': item.customName,
        'preset_wattage': item.presetWattage,
        'quantity': item.quantity, // <-- NEW: Save quantity to DB
        'user_assigned_hours': item.userAssignedHours,
        'adjusted_hours': item.adjustedHours,
        'is_locked': item.isLocked ? 1 : 0, // SQLite needs 1/0 for booleans
      });
    }

    await batch.commit();
  }
}

// UPGRADED: Modern Provider Syntax
final inventoryProvider = NotifierProvider<InventoryNotifier, List<Appliance>>(
  () {
    return InventoryNotifier();
  },
);
