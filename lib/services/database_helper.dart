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
        options: OpenDatabaseOptions(version: 1, onCreate: _onCreate),
      );
    } else {
      String path = join(await getDatabasesPath(), 'kislap.db');
      db = await openDatabase(path, version: 1, onCreate: _onCreate);
    }

    // AUTO-SEED CHECK: Ensures Vercel users who already created the DB get the catalog!
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
        household_size TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_inventory (
        id TEXT PRIMARY KEY,
        preset_id INTEGER,
        custom_name TEXT NOT NULL,
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

  // Self-healing seed function
  Future<void> _ensurePresetsPopulated(Database db) async {
    try {
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM appliance_presets',
      );
      final count = Sqflite.firstIntValue(countResult) ?? 0;

      if (count == 0) {
        final List<Map<String, dynamic>> defaultPresets = [
                  // 1. Air Conditioning & Cooling
                  {'appliance_name': 'Window Aircon (0.75 HP)', 'category': 'Cooling', 'preset_wattage': 760.0}, // Avg of 720-800W
                  {'appliance_name': 'Inverter Window Aircon (1.0 HP)', 'category': 'Cooling', 'preset_wattage': 650.0},
                  {'appliance_name': 'Inverter Split Type (1.5 HP)', 'category': 'Cooling', 'preset_wattage': 1050.0},
                  {'appliance_name': 'Desk/Stand Fan (12"-16")', 'category': 'Cooling', 'preset_wattage': 55.0},

                  // 2. Refrigeration & Kitchen
                  {'appliance_name': 'Conventional Refrigerator (6-8 cu.ft.)', 'category': 'Kitchen', 'preset_wattage': 150.0},
                  {'appliance_name': 'Inverter Refrigerator (9-12 cu.ft.)', 'category': 'Kitchen', 'preset_wattage': 115.0},
                  {'appliance_name': 'Rice Cooker (1.0L-1.8L)', 'category': 'Kitchen', 'preset_wattage': 575.0},
                  {'appliance_name': 'Microwave Oven', 'category': 'Kitchen', 'preset_wattage': 1000.0},
                  {'appliance_name': 'Induction Cooker', 'category': 'Kitchen', 'preset_wattage': 1750.0},
                  {'appliance_name': 'Water Dispenser (Hot & Cold)', 'category': 'Kitchen', 'preset_wattage': 590.0}, // 500W heat + 90W cool

                  // 3. Laundry & Housekeeping
                  {'appliance_name': 'Twin Tub Washing Machine', 'category': 'Laundry', 'preset_wattage': 375.0},
                  {'appliance_name': 'Flat/Steam Iron', 'category': 'Laundry', 'preset_wattage': 1125.0},

                  // 4. Personal Care, Computing & Lighting
                  {'appliance_name': 'Shower Water Heater (Instant)', 'category': 'Bathroom', 'preset_wattage': 3750.0},
                  {'appliance_name': 'LED Smart TV (32"-43")', 'category': 'Entertainment', 'preset_wattage': 40.0},
                  {'appliance_name': 'Laptop (Standard Office/Student)', 'category': 'Electronics', 'preset_wattage': 47.5},
                  {'appliance_name': 'Wi-Fi Router / Fiber Modem', 'category': 'Electronics', 'preset_wattage': 14.0},
                  {'appliance_name': 'LED Light Bulb', 'category': 'Lighting', 'preset_wattage': 9.0},
                ];

        for (var preset in defaultPresets) {
          await db.insert('appliance_presets', preset);
        }
      }
    } catch (_) {}
  }
}
