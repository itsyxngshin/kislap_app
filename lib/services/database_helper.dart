import 'dart:io';
import 'package:flutter/foundation.dart'; // Required to check kIsWeb
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kislap_local.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // 1. WEB SUPPORT (Vercel)
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return await openDatabase(filePath, version: 2, onCreate: _createDB);
    }

    // 2. WINDOWS / LINUX LAPTOP SIMULATION
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;

      // On desktop, we can just use the local project directory
      final path = join(await getDatabasesPath(), filePath);
      return await openDatabase(path, version: 2, onCreate: _createDB);
    }

    // 3. NATIVE ANDROID / iOS (Default Behavior)
    final dbDirectory = await getApplicationDocumentsDirectory();
    final path = join(dbDirectory.path, filePath);
    return await openDatabase(path, version: 2, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Master Appliance Presets (Maintained by Admin)
    await db.execute('''
      CREATE TABLE appliance_presets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        appliance_name TEXT NOT NULL,
        category TEXT NOT NULL,
        preset_wattage REAL NOT NULL,
        typical_setting TEXT NOT NULL
      )
    ''');

    // 2. User Inventory (Each row represents a unique physical item)
    await db.execute('''
      CREATE TABLE user_inventory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        preset_id INTEGER NOT NULL,
        custom_name TEXT NOT NULL, -- e.g., 'Master Bedroom AC', 'Living Room Fan'
        user_assigned_hours REAL NOT NULL, -- The user-defined baseline hours
        adjusted_hours REAL NOT NULL, -- Calculated by the optimization algorithm
        is_locked INTEGER NOT NULL DEFAULT 0, -- 1 = Locked, 0 = Unlocked
        FOREIGN KEY (preset_id) REFERENCES appliance_presets (id) ON DELETE CASCADE
      )
    ''');

    // 3. System Configuration
    await db.execute('''
      CREATE TABLE user_settings (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        tariff_rate REAL NOT NULL DEFAULT 0.0,
        monthly_budget REAL NOT NULL DEFAULT 0.0,
        household_size TEXT NOT NULL DEFAULT 'Small'
      )
    ''');
    // 4. Historical Tariff Ledger (For Monthly Variations)
    await db.execute('''
          CREATE TABLE monthly_tariffs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            billing_month TEXT NOT NULL, -- Format: YYYY-MM (e.g., '2026-07')
            tariff_rate REAL NOT NULL, -- The user-inputted ₱/kWh for this specific month
            UNIQUE(billing_month)
          )
        ''');

    await db.execute('''
          CREATE TABLE recording_periods (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            period_month TEXT NOT NULL UNIQUE,
            period_name TEXT NOT NULL,
            start_date TEXT NOT NULL,
            end_date TEXT NOT NULL,
            billing_rate REAL NOT NULL
          )
        ''');
  }
}
