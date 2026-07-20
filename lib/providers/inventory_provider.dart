import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/appliance_item.dart';
import '../services/database_helper.dart';
import '../services/optimization_engine.dart';

class InventoryNotifier extends Notifier<List<ApplianceItem>> {
  final _dbHelper = DatabaseHelper.instance;

  @override
  List<ApplianceItem> build() {
    loadInventory();
    return [];
  }

  // Fetch items from local SQLite executing a JOIN to grab preset details
  Future<void> loadInventory() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        u.id, u.preset_id, u.custom_name, u.user_assigned_hours, u.adjusted_hours, u.is_locked,
        p.category, p.preset_wattage
      FROM user_inventory u
      JOIN appliance_presets p ON u.preset_id = p.id
    ''');

    state = maps.map((map) => ApplianceItem.fromMap(map)).toList();
  }

  // Add an item instance
  Future<void> addAppliance({
    required int presetId,
    required String customName,
    required double defaultHours,
  }) async {
    final db = await _dbHelper.database;
    
    await db.insert('user_inventory', {
      'preset_id': presetId,
      'custom_name': customName,
      'user_assigned_hours': defaultHours,
      'adjusted_hours': defaultHours, 
      'is_locked': 0,
    });

    await loadInventory(); 
    await _optimizeAndSave();
  }

  // Delete an explicit item entry
  Future<void> removeAppliance(int id) async {
    final db = await _dbHelper.database;
    await db.delete('user_inventory', where: 'id = ?', whereArgs: [id]);
    
    await loadInventory();
    await _optimizeAndSave();
  }

  // Toggle lock status
  Future<void> toggleLock(int id, bool currentLockStatus) async {
    final db = await _dbHelper.database;
    final int newLockValue = currentLockStatus ? 0 : 1;

    await db.update(
      'user_inventory',
      {'is_locked': newLockValue},
      where: 'id = ?',
      whereArgs: [id],
    );

    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(isLocked: !currentLockStatus) else item
    ];

    await _optimizeAndSave();
  }

  // Run optimization engine and save results
  Future<void> _optimizeAndSave() async {
    final db = await _dbHelper.database;
    
    final settings = await db.query('user_settings', limit: 1);
    if (settings.isEmpty) return;
    
    final double budget = (settings.first['monthly_budget'] as num).toDouble();
    final double rate = (settings.first['tariff_rate'] as num).toDouble();

    final optimizedInventory = OptimizationEngine.runProportionalReduction(
      inventory: state,
      monthlyBudget: budget,
      tariffRate: rate,
    );

    for (var item in optimizedInventory) {
      await db.update(
        'user_inventory',
        {'adjusted_hours': item.adjustedHours},
        where: 'id = ?',
        whereArgs: [item.id],
      );
    }

    state = optimizedInventory;
  }
}

// Global NotifierProvider Node
final inventoryProvider = NotifierProvider<InventoryNotifier, List<ApplianceItem>>(InventoryNotifier.new);