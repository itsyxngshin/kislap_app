import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Database db;

    if (kIsWeb) {
      var factory = databaseFactoryFfiWeb;
      db = await factory.openDatabase(
        'kislap_web.db',
        options: OpenDatabaseOptions(
          version: 8, // <-- BUMP TO 8
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    } else {
      String path = join(await getDatabasesPath(), 'kislap.db');
      db = await openDatabase(
        path,
        version: 8, // <-- BUMP TO 8
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }

    await _ensurePresetsPopulated(db);
    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS appliance_presets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        appliance_name TEXT NOT NULL,
        category TEXT NOT NULL,
        preset_wattage REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_settings (
        id INTEGER PRIMARY KEY,
        tariff_rate REAL NOT NULL,
        monthly_budget REAL NOT NULL,
        household_size TEXT,
        language TEXT DEFAULT 'en',
        theme_mode TEXT DEFAULT 'light',
        is_first_time INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_appliances (
        id TEXT PRIMARY KEY,
        preset_id INTEGER,
        custom_name TEXT NOT NULL,
        preset_wattage REAL NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1, -- NEW QUANTITY COLUMN
        user_assigned_hours REAL NOT NULL,
        adjusted_hours REAL NOT NULL,
        is_locked INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS recording_periods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        period_month TEXT NOT NULL UNIQUE,
        period_name TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        billing_rate REAL NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS appliance_presets');
      await db.execute('''
        CREATE TABLE appliance_presets (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          appliance_name TEXT NOT NULL,
          category TEXT NOT NULL,
          preset_wattage REAL NOT NULL
        )
      ''');
      await _seedPresets(db);
    }

    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS user_inventory');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_appliances (
          id TEXT PRIMARY KEY,
          preset_id INTEGER,
          custom_name TEXT NOT NULL,
          preset_wattage REAL NOT NULL,
          user_assigned_hours REAL NOT NULL,
          adjusted_hours REAL NOT NULL,
          is_locked INTEGER NOT NULL DEFAULT 0
        )
      ''');
    }

    if (oldVersion < 5) {
      try {
        await db.execute(
          "ALTER TABLE user_settings ADD COLUMN language TEXT DEFAULT 'en'",
        );
      } catch (_) {}
      try {
        await db.execute(
          "ALTER TABLE user_settings ADD COLUMN theme_mode TEXT DEFAULT 'light'",
        );
      } catch (_) {}
      try {
        await db.execute(
          "ALTER TABLE user_settings ADD COLUMN is_first_time INTEGER DEFAULT 1",
        );
      } catch (_) {}
    }

    // THE NEW MIGRATION: Adding Quantity to existing user inventories
    if (oldVersion < 6) {
      try {
        await db.execute(
          "ALTER TABLE user_appliances ADD COLUMN quantity INTEGER NOT NULL DEFAULT 1",
        );
      } catch (_) {}
      // Overwrite presets with the newly expanded PH audit list
      await db.execute('DELETE FROM appliance_presets');
      await _seedPresets(db);
    }

    // THE FIX: Hard reset for the presets catalog to remove duplicates
    if (oldVersion < 8) {
      // 1. Completely destroy the duplicated table
      await db.execute('DROP TABLE IF EXISTS appliance_presets');

      // 2. Rebuild the table structure perfectly clean
      await db.execute('''
            CREATE TABLE appliance_presets (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              appliance_name TEXT NOT NULL,
              category TEXT NOT NULL,
              preset_wattage REAL NOT NULL
            )
          ''');

      // 3. Inject a fresh, single batch of your updated presets
      await _seedPresets(db);
    }
  }

  Future<void> _ensurePresetsPopulated(Database db) async {
    try {
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM appliance_presets',
      );
      final count = Sqflite.firstIntValue(countResult) ?? 0;
      if (count == 0) await _seedPresets(db);
    } catch (_) {}
  }

  // Expanded database using Philippine audit averages
  Future<void> _seedPresets(Database db) async {
    final List<Map<String, dynamic>> updatedPresets = [
      // Cooling
      {
        'appliance_name': 'Window Aircon (0.75 HP)',
        'category': 'Cooling',
        'preset_wattage': 760.0,
      },
      {
        'appliance_name': 'Inverter Window (1.0 HP)',
        'category': 'Cooling',
        'preset_wattage': 650.0,
      },
      {
        'appliance_name': 'Inverter Split Type (1.5 HP)',
        'category': 'Cooling',
        'preset_wattage': 1050.0,
      },
      {
        'appliance_name': 'Inverter Split Type (2.0 HP)',
        'category': 'Cooling',
        'preset_wattage': 1550.0,
      },
      {
        'appliance_name': 'Desk/Stand Fan (12"-16")',
        'category': 'Cooling',
        'preset_wattage': 55.0,
      },
      {
        'appliance_name': 'Ceiling Fan',
        'category': 'Cooling',
        'preset_wattage': 150.0,
      },
      // Kitchen
      {
        'appliance_name': 'Conventional Fridge (6-8 cu.ft)',
        'category': 'Kitchen',
        'preset_wattage': 150.0,
      },
      {
        'appliance_name': 'Inverter Fridge (9-12 cu.ft)',
        'category': 'Kitchen',
        'preset_wattage': 115.0,
      },
      {
        'appliance_name': 'Chest Freezer',
        'category': 'Kitchen',
        'preset_wattage': 175.0,
      },
      {
        'appliance_name': 'Rice Cooker (1.0L-1.8L)',
        'category': 'Kitchen',
        'preset_wattage': 575.0,
      },
      {
        'appliance_name': 'Induction Cooker',
        'category': 'Kitchen',
        'preset_wattage': 1750.0,
      },
      {
        'appliance_name': 'Electric Stove (2-Burner)',
        'category': 'Kitchen',
        'preset_wattage': 2400.0,
      },
      {
        'appliance_name': 'Microwave Oven',
        'category': 'Kitchen',
        'preset_wattage': 1000.0,
      },
      {
        'appliance_name': 'Electric Water Kettle',
        'category': 'Kitchen',
        'preset_wattage': 2250.0,
      },
      {
        'appliance_name': 'Air Fryer',
        'category': 'Kitchen',
        'preset_wattage': 1550.0,
      },
      {
        'appliance_name': 'Water Dispenser (Hot & Cold)',
        'category': 'Kitchen',
        'preset_wattage': 590.0,
      },
      {
        'appliance_name': 'Blender / Food Processor',
        'category': 'Kitchen',
        'preset_wattage': 550.0,
      },
      // Laundry & Bath
      {
        'appliance_name': 'Twin Tub Washing Machine',
        'category': 'Laundry',
        'preset_wattage': 375.0,
      },
      {
        'appliance_name': 'Fully Auto Washing Machine',
        'category': 'Laundry',
        'preset_wattage': 600.0,
      },
      {
        'appliance_name': 'Clothes Dryer',
        'category': 'Laundry',
        'preset_wattage': 2050.0,
      },
      {
        'appliance_name': 'Flat / Steam Iron',
        'category': 'Laundry',
        'preset_wattage': 1125.0,
      },
      {
        'appliance_name': 'Vacuum Cleaner',
        'category': 'Laundry',
        'preset_wattage': 1000.0,
      },
      {
        'appliance_name': 'Shower Water Heater',
        'category': 'Bathroom',
        'preset_wattage': 3750.0,
      },
      // Electronics & Entertainment
      {
        'appliance_name': 'LED Smart TV (32"-43")',
        'category': 'Electronics',
        'preset_wattage': 40.0,
      },
      {
        'appliance_name': 'LED Smart TV (55"-65")',
        'category': 'Electronics',
        'preset_wattage': 105.0,
      },
      {
        'appliance_name': 'Desktop Computer (Office)',
        'category': 'Electronics',
        'preset_wattage': 200.0,
      },
      {
        'appliance_name': 'Gaming PC',
        'category': 'Electronics',
        'preset_wattage': 500.0,
      },
      {
        'appliance_name': 'Laptop (Standard)',
        'category': 'Electronics',
        'preset_wattage': 47.5,
      },
      {
        'appliance_name': 'Wi-Fi Router / Fiber Modem',
        'category': 'Electronics',
        'preset_wattage': 14.0,
      },
      {
        'appliance_name': 'LED Light Bulb',
        'category': 'Lighting',
        'preset_wattage': 9.0,
      },
      {
        'appliance_name': 'LED Light Bulb',
        'category': 'Lighting',
        'preset_wattage': 12.0,
      },
      {
        'appliance_name': 'LED Light Bulb',
        'category': 'Lighting',
        'preset_wattage': 15.0,
      },
      {
        'appliance_name': 'Videoke / Karaoke Speaker',
        'category': 'Entertainment',
        'preset_wattage': 100.0,
      },
    ];

    Batch batch = db.batch();
    for (var preset in updatedPresets) {
      batch.insert('appliance_presets', preset);
    }
    await batch.commit(noResult: true);
  }
}
