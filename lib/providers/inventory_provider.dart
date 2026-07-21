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
  Future<void> _optimizeAndSave(List<Appliance> currentState) async {
    final db = await DatabaseHelper.instance.database;
    final settings = await db.query('user_settings', limit: 1);

    double budget = 0.0;
    double tariff = 11.08;

    if (settings.isNotEmpty) {
      budget = (settings.first['monthly_budget'] as num).toDouble();
      tariff = (settings.first['tariff_rate'] as num).toDouble();
    }

    if (budget <= 0) {
      // Safely assign state without the linter yelling at you
      state = currentState;
      return;
    }

    // 1. Calculate Allowances
    final double maxMonthlyKwh = budget / tariff;
    final double maxDailyKwh = maxMonthlyKwh / 30;

    // 2. Calculate Locked Consumption
    double lockedDailyKwh = 0.0;
    for (var item in currentState) {
      if (item.isLocked) {
        lockedDailyKwh += (item.presetWattage / 1000) * item.userAssignedHours;
      }
    }

    // 3. Calculate Remaining Budget for Unlocked Devices
    double remainingDailyKwh = maxDailyKwh - lockedDailyKwh;
    if (remainingDailyKwh < 0) remainingDailyKwh = 0;

    // 4. Calculate Intended Unlocked Consumption
    double intendedUnlockedKwh = 0.0;
    for (var item in currentState) {
      if (!item.isLocked) {
        intendedUnlockedKwh +=
            (item.presetWattage / 1000) * item.userAssignedHours;
      }
    }

    // 5. Determine Scaling Factor
    double scaleFactor = 1.0;
    if (intendedUnlockedKwh > remainingDailyKwh && intendedUnlockedKwh > 0) {
      scaleFactor = remainingDailyKwh / intendedUnlockedKwh;
    }

    // 6. Apply Scale Factor to Unlocked Devices
    final optimizedState = currentState.map((item) {
      if (item.isLocked) {
        return item.copyWith(adjustedHours: item.userAssignedHours);
      } else {
        return item.copyWith(
          adjustedHours: item.userAssignedHours * scaleFactor,
        );
      }
    }).toList();

    state = optimizedState;
    // Note: Local SQLite sync to 'user_inventory' table can be added here
  }
}

// UPGRADED: Modern Provider Syntax
final inventoryProvider = NotifierProvider<InventoryNotifier, List<Appliance>>(
  () {
    return InventoryNotifier();
  },
);
