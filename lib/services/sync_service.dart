import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class SyncService {
  static final _supabase = Supabase.instance.client;
  static final _dbHelper = DatabaseHelper.instance;

  /// Pulls the global appliance catalog from Supabase and updates SQLite.
  /// Fails silently if the device is offline, preserving existing local data.
  static Future<void> syncCatalogDown() async {
    try {
      // 1. Fetch the master catalog from Supabase
      final List<dynamic> cloudCatalog = await _supabase
          .from('preset_catalog')
          .select();

      // 2. Get the local SQLite instance
      final db = await _dbHelper.database;

      // 3. Use a Batch to execute operations efficiently
      Batch batch = db.batch();

      // 4. Clear the local catalog to avoid stale data/duplicates
      batch.delete('preset_catalog');

      // 5. Insert the fresh cloud data
      for (var item in cloudCatalog) {
        batch.insert('preset_catalog', {
          'id': item['id'],
          'appliance_type': item['appliance_type'],
          'category': item['category'],
          'preset_wattage': item['preset_wattage'],
          'default_hours': item['default_hours'],
          'priority_status':
              item['priority_status'], // E.g., 'Locked', 'Unlocked', 'Flexible'
        });
      }

      // 6. Commit the batch
      await batch.commit();
    } catch (e) {
      // If offline, Supabase throws an error. We catch it silently.
      // The app will simply continue using the existing SQLite data.
    }
  }

  /// Pulls the user's backed-up inventory from Supabase (e.g., on fresh login)
  static Future<void> syncUserInventoryDown(String userId) async {
    try {
      final List<dynamic> cloudInventory = await _supabase
          .from('user_inventory')
          .select()
          .eq('user_id', userId);

      final db = await _dbHelper.database;
      Batch batch = db.batch();

      batch.delete('user_inventory'); // Clear local before restoring

      for (var item in cloudInventory) {
        batch.insert('user_inventory', {
          'id': item['id'], // Preserve the exact ID
          'catalog_id': item['catalog_id'],
          'quantity': item['quantity'],
          'adjusted_hours': item['adjusted_hours'],
          'is_locked': item['is_locked']
              ? 1
              : 0, // Convert boolean to SQLite integer
        });
      }

      await batch.commit();
    } catch (e) {
      // Silently fail if offline
    }
  }

  static Future<void> mergeOfflineDataToCloud(String userId) async {
    try {
      final db = await _dbHelper.database;
      
      // 1. Grab all items the user created while offline (Guest Mode)
      final List<Map<String, dynamic>> localItems = await db.query('user_inventory');

      if (localItems.isNotEmpty) {
        // 2. Format them for Supabase and inject the new user_id
        final List<Map<String, dynamic>> cloudUploads = localItems.map((item) {
          return {
            'user_id': userId,
            'preset_id': item['preset_id'],
            'custom_name': item['custom_name'],
            'user_assigned_hours': item['user_assigned_hours'],
            'adjusted_hours': item['adjusted_hours'],
            'is_locked': item['is_locked'] == 1 ? true : false,
          };
        }).toList();

        // 3. Push the offline data to the cloud
        await _supabase.from('user_inventory').insert(cloudUploads);
      }

      // 4. Run the Down-Sync to refresh SQLite with the official Cloud IDs
      await syncUserInventoryDown(userId);

    } catch (e) {
      debugPrint('Merge Error: $e');
    }
  }
}
