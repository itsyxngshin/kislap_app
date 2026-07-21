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
          {
            'appliance_name': 'Inverter Aircon (1.0 HP)',
            'category': 'Cooling',
            'preset_wattage': 750.0,
          },
          {
            'appliance_name': 'Window Aircon (0.5 HP)',
            'category': 'Cooling',
            'preset_wattage': 500.0,
          },
          {
            'appliance_name': 'Electric Fan (Stand)',
            'category': 'Cooling',
            'preset_wattage': 65.0,
          },
          {
            'appliance_name': 'Refrigerator (Standard)',
            'category': 'Kitchen',
            'preset_wattage': 150.0,
          },
          {
            'appliance_name': 'Rice Cooker',
            'category': 'Kitchen',
            'preset_wattage': 400.0,
          },
          {
            'appliance_name': 'Microwave Oven',
            'category': 'Kitchen',
            'preset_wattage': 1000.0,
          },
          {
            'appliance_name': 'LED TV (32 inch)',
            'category': 'Entertainment',
            'preset_wattage': 45.0,
          },
          {
            'appliance_name': 'Wi-Fi Router',
            'category': 'Electronics',
            'preset_wattage': 10.0,
          },
          {
            'appliance_name': 'Laptop (Charging)',
            'category': 'Electronics',
            'preset_wattage': 65.0,
          },
          {
            'appliance_name': 'Washing Machine (Twin Tub)',
            'category': 'Laundry',
            'preset_wattage': 400.0,
          },
          {
            'appliance_name': 'Clothes Iron',
            'category': 'Laundry',
            'preset_wattage': 1000.0,
          },
          {
            'appliance_name': 'Water Heater',
            'category': 'Bathroom',
            'preset_wattage': 3000.0,
          },
          {
            'appliance_name': 'LED Bulb',
            'category': 'Lighting',
            'preset_wattage': 9.0,
          },
        ];

        for (var preset in defaultPresets) {
          await db.insert('appliance_presets', preset);
        }
      }
    } catch (_) {}
  }
}
