import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/database_helper.dart';
import '../models/appliance.dart';

export '../models/appliance.dart';

class InventoryNotifier extends Notifier<List<Appliance>> {
  @override
  List<Appliance> build() {
    Future.microtask(() => _loadInventory());
    return [];
  }

  /// Kinukuha ang appliances mula sa Supabase kung naka-login; kung hindi, sa SQLite kukunin.
  Future<void> _loadInventory() async {
    final db = await DatabaseHelper.instance.database;
    final user = Supabase.instance.client.auth.currentUser;

    List<Appliance> loaded = [];

    if (user != null) {
      try {
        final cloudData = await Supabase.instance.client
            .from('appliances')
            .select()
            .eq('user_id', user.id);

        if (cloudData.isNotEmpty) {
          loaded = cloudData.map((row) {
            final double hours = (row['hours_per_day'] as num?)?.toDouble() ?? 0.0;
            return Appliance(
              id: row['id'].toString(),
              presetId: 9999,
              customName: row['name'] as String? ?? 'Appliance',
              category: row['category'] as String? ?? 'General',
              presetWattage: (row['watts'] as num?)?.toDouble() ?? 0.0,
              quantity: (row['quantity'] as int?) ?? 1,
              userAssignedHours: hours,
              adjustedHours: hours,
              isLocked: row['is_locked'] as bool? ?? false,
            );
          }).toList();

          // I-mirror ang cloud data sa lokal na SQLite cache
          Batch batch = db.batch();
          batch.delete('user_appliances');
          for (var item in loaded) {
            batch.insert('user_appliances', item.toSqliteMap());
          }
          await batch.commit(noResult: true);
        }
      } catch (e) {
        debugPrint('Cloud pull failed, falling back to local storage: $e');
      }
    }

    if (loaded.isEmpty) {
      final localData = await db.query('user_appliances');
      loaded = localData.map((row) {
        return Appliance(
          id: row['id'] as String,
          presetId: row['preset_id'] as int,
          customName: row['custom_name'] as String,
          category: 'General',
          presetWattage: (row['preset_wattage'] as num).toDouble(),
          quantity: row['quantity'] as int? ?? 1,
          userAssignedHours: (row['user_assigned_hours'] as num).toDouble(),
          adjustedHours: (row['adjusted_hours'] as num).toDouble(),
          isLocked: (row['is_locked'] as int) == 1,
        );
      }).toList();
    }

    await _optimizeAndSave(loaded, syncCloud: false);
  }

  Future<void> addAppliance({
    required int presetId,
    required String customName,
    required double defaultHours,
    required double wattage,
    required int quantity,
    String category = 'General',
  }) async {
    final newItem = Appliance(
      id: const Uuid().v4(),
      presetId: presetId,
      customName: customName,
      category: category,
      presetWattage: wattage,
      quantity: quantity,
      userAssignedHours: defaultHours,
      adjustedHours: defaultHours,
      isLocked: false,
    );

    final newState = [...state, newItem];
    await _optimizeAndSave(newState);

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client.from('appliances').insert(
          newItem.toSupabaseMap(user.id),
        );
      } catch (e) {
        debugPrint('Cloud insert error: $e');
      }
    }
  }

  // Idinagdag ang 'wattage' parameter
  Future<void> editAppliance({
    required String id,
    required String customName,
    required int quantity,
    required double userAssignedHours,
    String? category,
    double? wattage,
  }) async {
    Appliance? updatedItem;

    final newState = state.map<Appliance>((item) {
      if (item.id == id) {
        updatedItem = item.copyWith(
          customName: customName,
          category: category ?? item.category,
          quantity: quantity,
          userAssignedHours: userAssignedHours,
          adjustedHours: userAssignedHours,
          presetWattage: wattage ?? item.presetWattage,
        );
        return updatedItem!;
      }
      return item;
    }).toList();

    await _optimizeAndSave(newState);

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && updatedItem != null) {
      try {
        await Supabase.instance.client
            .from('appliances')
            .update(updatedItem!.toSupabaseMap(user.id))
            .eq('id', id)
            .eq('user_id', user.id);
      } catch (e) {
        debugPrint('Cloud update error: $e');
      }
    }
  }

  Future<void> removeAppliance(String id) async {
    final newState = state.where((item) => item.id != id).toList();
    await _optimizeAndSave(newState);

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client
            .from('appliances')
            .delete()
            .eq('id', id)
            .eq('user_id', user.id);
      } catch (e) {
        debugPrint('Cloud delete error: $e');
      }
    }
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

  Future<void> _optimizeAndSave(List<Appliance> currentState, {bool syncCloud = true}) async {
    final db = await DatabaseHelper.instance.database;
    final settings = await db.query('user_settings', limit: 1);

    double budget = 0.0;
    double tariff = 12.35;

    if (settings.isNotEmpty) {
      budget = (settings.first['monthly_budget'] as num).toDouble();
      tariff = (settings.first['tariff_rate'] as num).toDouble();
    }

    List<Appliance> optimizedState = currentState;

    if (budget > 0) {
      final double energyAllowanceKwh = budget / tariff;

      double lockedMonthlyKwh = 0.0;
      for (var item in currentState) {
        if (item.isLocked) {
          lockedMonthlyKwh +=
              (item.presetWattage * item.quantity * item.userAssignedHours * 30) / 1000;
        }
      }

      double remainingEnergy = energyAllowanceKwh - lockedMonthlyKwh;
      if (remainingEnergy < 0) remainingEnergy = 0;

      double unlockedMonthlyKwh = 0.0;
      for (var item in currentState) {
        if (!item.isLocked) {
          unlockedMonthlyKwh +=
              (item.presetWattage * item.quantity * item.userAssignedHours * 30) / 1000;
        }
      }

      double reductionFactor = 1.0;
      if (unlockedMonthlyKwh > remainingEnergy && unlockedMonthlyKwh > 0) {
        reductionFactor = remainingEnergy / unlockedMonthlyKwh;
      }

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

    state = optimizedState;

    Batch batch = db.batch();
    batch.delete('user_appliances');
    for (var item in optimizedState) {
      batch.insert('user_appliances', item.toSqliteMap());
    }
    await batch.commit(noResult: true);

    final user = Supabase.instance.client.auth.currentUser;
    if (syncCloud && user != null) {
      try {
        for (var item in optimizedState) {
          await Supabase.instance.client
              .from('appliances')
              .update({
                'hours_per_day': item.adjustedHours,
                'watts': item.presetWattage,
                'is_locked': item.isLocked,
              })
              .eq('id', item.id)
              .eq('user_id', user.id);
        }
      } catch (e) {
        debugPrint('Cloud batch hour adjustment error: $e');
      }
    }
  }
}

final inventoryProvider = NotifierProvider<InventoryNotifier, List<Appliance>>(
  () => InventoryNotifier(),
);
