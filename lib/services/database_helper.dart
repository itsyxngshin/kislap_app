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
          version: 3, // <-- BUMPED TO VERSION 3 to force the schema update
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    } else {
      String path = join(await getDatabasesPath(), 'kislap.db');
      db = await openDatabase(
        path,
        version: 3, // <-- BUMPED TO VERSION 3
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }

    // Safety net for new installations
    await _ensurePresetsPopulated(db);

    return db;
  }

  // Runs ONLY for brand new users installing for the first time
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
            language TEXT DEFAULT 'en',       -- Task 2: 'en' or 'ph'
            theme_mode TEXT DEFAULT 'light',  -- Task 4: Default to light mode
            is_first_time INTEGER DEFAULT 1   -- Task 8: Tutorial trigger
          )
        ''');

    // FIXED: Renamed to user_appliances and added preset_wattage to match the provider
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

  // AUTOMATIC MIGRATION: Runs for existing users transitioning through versions
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 1. Delete the outdated presets table
      await db.execute('DROP TABLE IF EXISTS appliance_presets');

      // 2. Recreate the table fresh
      await db.execute('''
        CREATE TABLE appliance_presets (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          appliance_name TEXT NOT NULL,
          category TEXT NOT NULL,
          preset_wattage REAL NOT NULL
        )
      ''');

      // 3. Inject the highly accurate client data
      await _seedPresets(db);
    }

    // THE NEW MIGRATION FIX
    if (oldVersion < 3) {
      // Clear out the mismatched table
      await db.execute('DROP TABLE IF EXISTS user_inventory');

      // Create the correct table format for the inventory provider
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

    if (oldVersion < 4) {
          await db.execute("ALTER TABLE user_settings ADD COLUMN language TEXT DEFAULT 'en'");
          await db.execute("ALTER TABLE user_settings ADD COLUMN theme_mode TEXT DEFAULT 'light'");
          await db.execute("ALTER TABLE user_settings ADD COLUMN is_first_time INTEGER DEFAULT 1");
      }
  }

  // Fallback safety check (mainly for Vercel blank slates)
  Future<void> _ensurePresetsPopulated(Database db) async {
    try {
      final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM appliance_presets');
      final count = Sqflite.firstIntValue(countResult) ?? 0;

      if (count == 0) {
        await _seedPresets(db);
      }
    } catch (_) {}
  }

  // Centralized data source using official Philippine audit data
  Future<void> _seedPresets(Database db) async {
    final List<Map<String, dynamic>> updatedPresets = [
      {'appliance_name': 'Window Aircon (0.75 HP)', 'category': 'Cooling', 'preset_wattage': 760.0},
      {'appliance_name': 'Inverter Window Aircon (1.0 HP)', 'category': 'Cooling', 'preset_wattage': 650.0},
      {'appliance_name': 'Inverter Split Type (1.5 HP)', 'category': 'Cooling', 'preset_wattage': 1050.0},
      {'appliance_name': 'Desk/Stand Fan (12"-16")', 'category': 'Cooling', 'preset_wattage': 55.0},
      {'appliance_name': 'Conventional Refrigerator (6-8 cu.ft.)', 'category': 'Kitchen', 'preset_wattage': 150.0},
      {'appliance_name': 'Inverter Refrigerator (9-12 cu.ft.)', 'category': 'Kitchen', 'preset_wattage': 115.0},
      {'appliance_name': 'Rice Cooker (1.0L-1.8L)', 'category': 'Kitchen', 'preset_wattage': 575.0},
      {'appliance_name': 'Microwave Oven', 'category': 'Kitchen', 'preset_wattage': 1000.0},
      {'appliance_name': 'Induction Cooker', 'category': 'Kitchen', 'preset_wattage': 1750.0},
      {'appliance_name': 'Water Dispenser (Hot & Cold)', 'category': 'Kitchen', 'preset_wattage': 590.0},
      {'appliance_name': 'Twin Tub Washing Machine', 'category': 'Laundry', 'preset_wattage': 375.0},
      {'appliance_name': 'Flat/Steam Iron', 'category': 'Laundry', 'preset_wattage': 1125.0},
      {'appliance_name': 'Shower Water Heater (Instant)', 'category': 'Bathroom', 'preset_wattage': 3750.0},
      {'appliance_name': 'LED Smart TV (32"-43")', 'category': 'Entertainment', 'preset_wattage': 40.0},
      {'appliance_name': 'Laptop (Standard)', 'category': 'Electronics', 'preset_wattage': 47.5},
      {'appliance_name': 'Wi-Fi Router / Fiber Modem', 'category': 'Electronics', 'preset_wattage': 14.0},
      {'appliance_name': 'LED Light Bulb', 'category': 'Lighting', 'preset_wattage': 9.0},
    ];

    Batch batch = db.batch();
    for (var preset in updatedPresets) {
      batch.insert('appliance_presets', preset);
    }
    await batch.commit(noResult: true);
  }
}
