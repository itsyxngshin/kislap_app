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
          version: 9, // <-- BUMP TO 9
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    } else {
      String path = join(await getDatabasesPath(), 'kislap.db');
      db = await openDatabase(
        path,
        version: 9, // <-- BUMP TO 9
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

    if (oldVersion < 9) {
          // 1. Destroy the old table
          await db.execute('DROP TABLE IF EXISTS appliance_presets');

          // 2. Rebuild with the new schema
          await db.execute('''
            CREATE TABLE appliance_presets (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              category TEXT NOT NULL,
              appliance_name TEXT NOT NULL,
              preset_wattage REAL NOT NULL,
              min_wattage REAL NOT NULL,
              max_wattage REAL NOT NULL
            )
          ''');

          // 3. Inject the new 170-item list
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
      // (Paste the massive 170-item updatedPresets list here)
      final List<Map<String, dynamic>> updatedPresets = [
        {'category': 'Cooling & Air Conditioning', 'appliance_name': 'Stand Fan / Orbit Fan', 'preset_wattage': 65.0, 'min_wattage': 55.0, 'max_wattage': 75.0},
        {'category': 'Cooling & Air Conditioning', 'appliance_name': 'Desk Fan', 'preset_wattage': 40.0, 'min_wattage': 30.0, 'max_wattage': 45.0},
        {'category': 'Cooling & Air Conditioning', 'appliance_name': 'Ceiling Fan', 'preset_wattage': 70.0, 'min_wattage': 50.0, 'max_wattage': 90.0},
        {'category': 'Cooling & Air Conditioning', 'appliance_name': 'DC Inverter Fan', 'preset_wattage': 35.0, 'min_wattage': 20.0, 'max_wattage': 45.0},
        {'category': 'Cooling & Air Conditioning', 'appliance_name': 'Wall Fan', 'preset_wattage': 55.0, 'min_wattage': 45.0, 'max_wattage': 65.0},
        {'category': 'Cooling & Air Conditioning', 'appliance_name': 'Bathroom Exhaust Fan', 'preset_wattage': 25.0, 'min_wattage': 15.0, 'max_wattage': 35.0},
        {'category': 'Cooling & Air Conditioning', 'appliance_name': 'Kitchen Exhaust Fan', 'preset_wattage': 45.0, 'min_wattage': 30.0, 'max_wattage': 60.0},
        {'category': 'Kitchen & Cooking', 'appliance_name': 'Wine Cooler / Chiller', 'preset_wattage': 90.0, 'min_wattage': 70.0, 'max_wattage': 120.0},
        {'category': 'Small Kitchen Appliances', 'appliance_name': 'Electric Ice Cream Maker', 'preset_wattage': 30.0, 'min_wattage': 15.0, 'max_wattage': 50.0},
        {'category': 'Entertainment & Work From Home', 'appliance_name': '32-inch LED TV', 'preset_wattage': 50.0, 'min_wattage': 40.0, 'max_wattage': 60.0},
        {'category': 'Entertainment & Work From Home', 'appliance_name': 'Soundbar / Home Theater System', 'preset_wattage': 100.0, 'min_wattage': 50.0, 'max_wattage': 150.0},
        {'category': 'Entertainment & Work From Home', 'appliance_name': 'Nintendo Switch', 'preset_wattage': 15.0, 'min_wattage': 15.0, 'max_wattage': 18.0},
        {'category': 'Entertainment & Work From Home', 'appliance_name': 'Laptop Computer', 'preset_wattage': 65.0, 'min_wattage': 45.0, 'max_wattage': 90.0},
        {'category': 'Entertainment & Work From Home', 'appliance_name': 'Wi-Fi Router / Modem', 'preset_wattage': 12.0, 'min_wattage': 10.0, 'max_wattage': 15.0},
        {'category': 'Bathroom & Personal Care', 'appliance_name': 'Hair Straightener / Curling Iron', 'preset_wattage': 60.0, 'min_wattage': 40.0, 'max_wattage': 80.0},
        {'category': 'Lighting & Household Utilities', 'appliance_name': 'LED Bulb 3W', 'preset_wattage': 3.0, 'min_wattage': 3.0, 'max_wattage': 3.0},
        {'category': 'Lighting & Household Utilities', 'appliance_name': 'LED Bulb 5W', 'preset_wattage': 5.0, 'min_wattage': 5.0, 'max_wattage': 5.0},
        {'category': 'Lighting & Household Utilities', 'appliance_name': 'LED Bulb 7W', 'preset_wattage': 7.0, 'min_wattage': 7.0, 'max_wattage': 7.0},
        {'category': 'Lighting & Household Utilities', 'appliance_name': 'LED Bulb 9W-13W', 'preset_wattage': 11.0, 'min_wattage': 9.0, 'max_wattage': 13.0},
        {'category': 'Lighting & Household Utilities', 'appliance_name': 'LED Bulb 12W-15W', 'preset_wattage': 13.0, 'min_wattage': 12.0, 'max_wattage': 15.0},
        {'category': 'Lighting & Household Utilities', 'appliance_name': 'Smart LED Bulb', 'preset_wattage': 10.0, 'min_wattage': 9.0, 'max_wattage': 11.0},
        {'category': 'Lighting & Household Utilities', 'appliance_name': 'T8 LED Tube Light 2ft', 'preset_wattage': 10.0, 'min_wattage': 9.0, 'max_wattage': 10.0},
        {'category': 'Lighting & Household Utilities', 'appliance_name': 'T8 LED Tube Light 4ft', 'preset_wattage': 18.0, 'min_wattage': 16.0, 'max_wattage': 22.0},
        {'category': 'Lighting & Household Utilities', 'appliance_name': 'LED T8 Tube Light', 'preset_wattage': 20.0, 'min_wattage': 18.0, 'max_wattage': 22.0},
        {'category': 'Lighting & Household Utilities', 'appliance_name': 'LED Downlight 4in', 'preset_wattage': 8.0, 'min_wattage': 6.0, 'max_wattage': 9.0},
        {'category': 'Lighting & Household Utilities', 'appliance_name': 'LED Downlight 6in', 'preset_wattage': 15.0, 'min_wattage': 12.0, 'max_wattage': 18.0},
        {'category': 'Lighting & Household Utilities', 'appliance_name': 'LED Track Light', 'preset_wattage': 10.0, 'min_wattage': 7.0, 'max_wattage': 15.0},
        {'category': 'Lighting & Household Utilities', 'appliance_name': 'LED Strip Lights', 'preset_wattage': 40.0, 'min_wattage': 24.0, 'max_wattage': 60.0},
        {'category': 'Lighting & Household Utilities', 'appliance_name': 'Smart RGB LED Strip Lights', 'preset_wattage': 42.0, 'min_wattage': 36.0, 'max_wattage': 48.0},
        {'category': 'Lighting & Household Utilities', 'appliance_name': 'Chandelier LED Candle Bulb', 'preset_wattage': 4.0, 'min_wattage': 3.0, 'max_wattage': 5.0},
        {'category': 'Lighting & Household Utilities', 'appliance_name': 'Filament LED Vintage Bulb', 'preset_wattage': 6.0, 'min_wattage': 4.0, 'max_wattage': 8.0},
        {'category': 'Lighting & Household Utilities', 'appliance_name': 'Under-Cabinet LED Bar Light', 'preset_wattage': 8.0, 'min_wattage': 5.0, 'max_wattage': 12.0},
        {'category': 'Lighting & Household Utilities', 'appliance_name': 'Motion-Sensor LED Night Light', 'preset_wattage': 1.0, 'min_wattage': 0.5, 'max_wattage': 1.5},
        {'category': 'Lighting & Household Utilities', 'appliance_name': 'Fiber Optic Star Ceiling Light Engine', 'preset_wattage': 30.0, 'min_wattage': 16.0, 'max_wattage': 45.0},
        {'category': 'Lighting & Household Utilities', 'appliance_name': 'Outdoor LED Floodlight Small', 'preset_wattage': 25.0, 'min_wattage': 20.0, 'max_wattage': 30.0},
        {'category': 'Lighting & Household Utilities', 'appliance_name': 'Outdoor LED Floodlight', 'preset_wattage': 60.0, 'min_wattage': 30.0, 'max_wattage': 100.0},
        {'category': 'Lighting & Household Utilities', 'appliance_name': 'Wall-Mounted LED Bulkhead Light', 'preset_wattage': 12.0, 'min_wattage': 10.0, 'max_wattage': 15.0},
        {'category': 'Lighting & Household Utilities', 'appliance_name': 'Landscape LED Garden Spike Light', 'preset_wattage': 5.0, 'min_wattage': 3.0, 'max_wattage': 7.0},
        {'category': 'Lighting & Household Utilities', 'appliance_name': 'LED Bollard Light', 'preset_wattage': 10.0, 'min_wattage': 7.0, 'max_wattage': 12.0},
        {'category': 'Lighting & Household Utilities', 'appliance_name': 'Swimming Pool Under-Water LED Light', 'preset_wattage': 25.0, 'min_wattage': 12.0, 'max_wattage': 35.0},
        {'category': 'Lighting & Household Utilities', 'appliance_name': 'Rechargeable Emergency Light', 'preset_wattage': 10.0, 'min_wattage': 5.0, 'max_wattage': 15.0},
        {'category': 'Lighting & Household Utilities', 'appliance_name': 'Mosquito Zapper Fly Trap', 'preset_wattage': 12.0, 'min_wattage': 6.0, 'max_wattage': 20.0},
        {'category': 'Home Content Creation & Accent Lighting', 'appliance_name': 'Studio LED Ring Light', 'preset_wattage': 40.0, 'min_wattage': 24.0, 'max_wattage': 55.0},
        {'category': 'Home Content Creation & Accent Lighting', 'appliance_name': 'Festoon String Lights', 'preset_wattage': 50.0, 'min_wattage': 30.0, 'max_wattage': 75.0},
        {'category': 'Health, Wellness & Comfort', 'appliance_name': 'Air Purifier', 'preset_wattage': 45.0, 'min_wattage': 30.0, 'max_wattage': 60.0},
        {'category': 'Health, Wellness & Comfort', 'appliance_name': 'Humidifier', 'preset_wattage': 30.0, 'min_wattage': 20.0, 'max_wattage': 40.0},
        {'category': 'Health, Wellness & Comfort', 'appliance_name': 'Handheld Body Massager', 'preset_wattage': 20.0, 'min_wattage': 15.0, 'max_wattage': 30.0},
        {'category': 'Health, Wellness & Comfort', 'appliance_name': 'Electric Heating Pad / Hot Compress', 'preset_wattage': 50.0, 'min_wattage': 40.0, 'max_wattage': 60.0},
        {'category': 'Garage, DIY & Power Tools', 'appliance_name': 'Cordless Tool Battery Charger', 'preset_wattage': 65.0, 'min_wattage': 40.0, 'max_wattage': 90.0},
        {'category': 'Garage, DIY & Power Tools', 'appliance_name': 'Soldering Iron', 'preset_wattage': 45.0, 'min_wattage': 30.0, 'max_wattage': 60.0},
        {'category': 'Miscellaneous Device Chargers', 'appliance_name': 'Mobile Phone Fast Charger', 'preset_wattage': 30.0, 'min_wattage': 18.0, 'max_wattage': 65.0},
        {'category': 'Miscellaneous Device Chargers', 'appliance_name': 'Tablet Charger', 'preset_wattage': 20.0, 'min_wattage': 10.0, 'max_wattage': 30.0},
        {'category': 'Miscellaneous Device Chargers', 'appliance_name': 'Power Bank', 'preset_wattage': 15.0, 'min_wattage': 10.0, 'max_wattage': 22.5},
        {'category': 'Miscellaneous Device Chargers', 'appliance_name': 'Smart Watch / Fitness Band Charger', 'preset_wattage': 5.0, 'min_wattage': 5.0, 'max_wattage': 5.0},
        {'category': 'Miscellaneous Device Chargers', 'appliance_name': 'Rechargeable Mini Handheld Fan', 'preset_wattage': 5.0, 'min_wattage': 5.0, 'max_wattage': 5.0},
        {'category': 'Smart Home & Security', 'appliance_name': 'Smart CCTV Camera', 'preset_wattage': 8.0, 'min_wattage': 5.0, 'max_wattage': 12.0},
        {'category': 'Smart Home & Security', 'appliance_name': 'Smart Door Lock', 'preset_wattage': 8.0, 'min_wattage': 5.0, 'max_wattage': 10.0},
        {'category': 'Smart Home & Security', 'appliance_name': 'Robotic Vacuum Cleaner', 'preset_wattage': 45.0, 'min_wattage': 30.0, 'max_wattage': 60.0},
        {'category': 'Smart Home & Security', 'appliance_name': 'Smart Video Doorbell', 'preset_wattage': 8.0, 'min_wattage': 5.0, 'max_wattage': 10.0},
        {'category': 'Specialty Care & Hobby', 'appliance_name': 'Sewing Machine', 'preset_wattage': 75.0, 'min_wattage': 50.0, 'max_wattage': 100.0},
        {'category': 'Specialty Care & Hobby', 'appliance_name': 'Aquarium Water Pump & Filter', 'preset_wattage': 25.0, 'min_wattage': 10.0, 'max_wattage': 40.0},
        {'category': 'Specialty Care & Hobby', 'appliance_name': 'Aquarium Heater', 'preset_wattage': 100.0, 'min_wattage': 50.0, 'max_wattage': 300.0},
        {'category': 'Specialty Care & Hobby', 'appliance_name': 'Pet Water Fountain', 'preset_wattage': 3.0, 'min_wattage': 2.0, 'max_wattage': 5.0},
        {'category': 'Home Office & Utilities', 'appliance_name': 'Inkjet Printer', 'preset_wattage': 20.0, 'min_wattage': 15.0, 'max_wattage': 30.0},
        {'category': 'Home Office & Utilities', 'appliance_name': 'Biometric Scanner', 'preset_wattage': 10.0, 'min_wattage': 5.0, 'max_wattage': 15.0},
        {'category': 'Home Office & Utilities', 'appliance_name': 'Money Counting Machine', 'preset_wattage': 60.0, 'min_wattage': 40.0, 'max_wattage': 80.0},
        {'category': 'Senior Care & Medical Home Appliances', 'appliance_name': 'Anti-Decubitus Air Mattress Pump', 'preset_wattage': 10.0, 'min_wattage': 7.0, 'max_wattage': 15.0},
        {'category': 'Senior Care & Medical Home Appliances', 'appliance_name': 'CPAP / BiPAP Machine', 'preset_wattage': 50.0, 'min_wattage': 30.0, 'max_wattage': 75.0},
        {'category': 'Vintage & Retro Household Appliances', 'appliance_name': 'CRT TV 21-inch', 'preset_wattage': 100.0, 'min_wattage': 80.0, 'max_wattage': 120.0},
        {'category': 'Vintage & Retro Household Appliances', 'appliance_name': 'Cassette / CD Player Boombox', 'preset_wattage': 20.0, 'min_wattage': 15.0, 'max_wattage': 30.0},
        {'category': 'Vintage & Retro Household Appliances', 'appliance_name': 'VHS / VCD / DVD Player', 'preset_wattage': 30.0, 'min_wattage': 15.0, 'max_wattage': 250.0},
        {'category': 'Vintage & Retro Household Appliances', 'appliance_name': 'Vintage Sewing Machine Motor', 'preset_wattage': 90.0, 'min_wattage': 75.0, 'max_wattage': 100.0},
        {'category': 'Vintage & Retro Household Appliances', 'appliance_name': 'CFL Spiral Bulb', 'preset_wattage': 18.0, 'min_wattage': 11.0, 'max_wattage': 24.0},
        {'category': 'Vintage & Retro Household Appliances', 'appliance_name': 'Fluorescent Tube Light with Ballast', 'preset_wattage': 30.0, 'min_wattage': 20.0, 'max_wattage': 40.0},
        {'category': 'Cooling & Air Conditioning', 'appliance_name': 'Evaporative Air Cooler', 'preset_wattage': 100.0, 'min_wattage': 65.0, 'max_wattage': 150.0},
        {'category': 'Kitchen & Cooking', 'appliance_name': 'Refrigerator Standard 1-Door', 'preset_wattage': 125.0, 'min_wattage': 100.0, 'max_wattage': 150.0},
        {'category': 'Kitchen & Cooking', 'appliance_name': 'Refrigerator Two-Door Inverter', 'preset_wattage': 110.0, 'min_wattage': 80.0, 'max_wattage': 130.0},
        {'category': 'Kitchen & Cooking', 'appliance_name': 'Side-by-Side Inverter Refrigerator', 'preset_wattage': 200.0, 'min_wattage': 150.0, 'max_wattage': 250.0},
        {'category': 'Kitchen & Cooking', 'appliance_name': 'Chest Freezer', 'preset_wattage': 225.0, 'min_wattage': 150.0, 'max_wattage': 300.0},
        {'category': 'Kitchen & Cooking', 'appliance_name': 'Range Hood', 'preset_wattage': 150.0, 'min_wattage': 100.0, 'max_wattage': 250.0},
        {'category': 'Kitchen & Cooking', 'appliance_name': 'Food Waste Disposer', 'preset_wattage': 500.0, 'min_wattage': 350.0, 'max_wattage': 750.0},
        {'category': 'Kitchen & Cooking', 'appliance_name': 'Countertop Ice Maker', 'preset_wattage': 150.0, 'min_wattage': 100.0, 'max_wattage': 200.0},
        {'category': 'Kitchen & Cooking', 'appliance_name': 'Blender / Food Processor', 'preset_wattage': 450.0, 'min_wattage': 300.0, 'max_wattage': 600.0},
        {'category': 'Kitchen & Cooking', 'appliance_name': 'Water Dispenser', 'preset_wattage': 550.0, 'min_wattage': 500.0, 'max_wattage': 650.0},
        {'category': 'Small Kitchen Appliances', 'appliance_name': 'Coffee Maker', 'preset_wattage': 700.0, 'min_wattage': 550.0, 'max_wattage': 900.0},
        {'category': 'Small Kitchen Appliances', 'appliance_name': 'Food Steamer', 'preset_wattage': 600.0, 'min_wattage': 400.0, 'max_wattage': 800.0},
        {'category': 'Small Kitchen Appliances', 'appliance_name': 'Slow Cooker / Crockpot', 'preset_wattage': 180.0, 'min_wattage': 100.0, 'max_wattage': 250.0},
        {'category': 'Small Kitchen Appliances', 'appliance_name': 'Juicer', 'preset_wattage': 600.0, 'min_wattage': 400.0, 'max_wattage': 800.0},
        {'category': 'Small Kitchen Appliances', 'appliance_name': 'Stand Mixer', 'preset_wattage': 400.0, 'min_wattage': 300.0, 'max_wattage': 500.0},
        {'category': 'Small Kitchen Appliances', 'appliance_name': 'Hand Mixer', 'preset_wattage': 200.0, 'min_wattage': 150.0, 'max_wattage': 250.0},
        {'category': 'Laundry & Cleaning', 'appliance_name': 'Twin Tub Washing Machine Wash Motor', 'preset_wattage': 375.0, 'min_wattage': 300.0, 'max_wattage': 450.0},
        {'category': 'Laundry & Cleaning', 'appliance_name': 'Twin Tub Washing Machine Spin Dryer', 'preset_wattage': 175.0, 'min_wattage': 150.0, 'max_wattage': 200.0},
        {'category': 'Laundry & Cleaning', 'appliance_name': 'Fully Automatic Top-Load Washer', 'preset_wattage': 500.0, 'min_wattage': 400.0, 'max_wattage': 600.0},
        {'category': 'Laundry & Cleaning', 'appliance_name': 'Front-Load Inverter Washing Machine', 'preset_wattage': 325.0, 'min_wattage': 250.0, 'max_wattage': 400.0},
        {'category': 'Entertainment & Work From Home', 'appliance_name': '55-inch Smart LED TV', 'preset_wattage': 110.0, 'min_wattage': 70.0, 'max_wattage': 150.0},
        {'category': 'Entertainment & Work From Home', 'appliance_name': '65-inch to 75-inch 4K Smart TV', 'preset_wattage': 180.0, 'min_wattage': 120.0, 'max_wattage': 250.0},
        {'category': 'Entertainment & Work From Home', 'appliance_name': 'PlayStation 5 / Xbox Series X', 'preset_wattage': 185.0, 'min_wattage': 160.0, 'max_wattage': 210.0},
        {'category': 'Entertainment & Work From Home', 'appliance_name': 'Older Gen Console', 'preset_wattage': 120.0, 'min_wattage': 90.0, 'max_wattage': 150.0},
        {'category': 'Entertainment & Work From Home', 'appliance_name': 'Multimedia Projector', 'preset_wattage': 275.0, 'min_wattage': 200.0, 'max_wattage': 350.0},
        {'category': 'Entertainment & Work From Home', 'appliance_name': 'Videoke / Karaoke Machine', 'preset_wattage': 250.0, 'min_wattage': 150.0, 'max_wattage': 400.0},
        {'category': 'Entertainment & Work From Home', 'appliance_name': 'Desktop Computer', 'preset_wattage': 200.0, 'min_wattage': 150.0, 'max_wattage': 250.0},
        {'category': 'Lighting & Household Utilities', 'appliance_name': 'Domestic Water Pump 0.5 HP', 'preset_wattage': 450.0, 'min_wattage': 375.0, 'max_wattage': 500.0},
        {'category': 'Home Content Creation & Accent Lighting', 'appliance_name': 'Photography LED Softbox Light Panel', 'preset_wattage': 100.0, 'min_wattage': 60.0, 'max_wattage': 150.0},
        {'category': 'Health, Wellness & Comfort', 'appliance_name': 'Dehumidifier', 'preset_wattage': 350.0, 'min_wattage': 250.0, 'max_wattage': 420.0},
        {'category': 'Health, Wellness & Comfort', 'appliance_name': 'Massage Chair', 'preset_wattage': 150.0, 'min_wattage': 100.0, 'max_wattage': 200.0},
        {'category': 'Health, Wellness & Comfort', 'appliance_name': 'Nebulizer', 'preset_wattage': 90.0, 'min_wattage': 60.0, 'max_wattage': 120.0},
        {'category': 'E-Mobility Charging (Home)', 'appliance_name': 'E-Bike / E-Scooter Charger', 'preset_wattage': 200.0, 'min_wattage': 120.0, 'max_wattage': 300.0},
        {'category': 'Home Office & Utilities', 'appliance_name': 'Paper Shredder', 'preset_wattage': 250.0, 'min_wattage': 150.0, 'max_wattage': 350.0},
        {'category': 'Home Office & Utilities', 'appliance_name': 'Laminating Machine', 'preset_wattage': 450.0, 'min_wattage': 300.0, 'max_wattage': 600.0},
        {'category': 'Senior Care & Medical Home Appliances', 'appliance_name': 'Oxygen Concentrator', 'preset_wattage': 450.0, 'min_wattage': 300.0, 'max_wattage': 600.0},
        {'category': 'Senior Care & Medical Home Appliances', 'appliance_name': 'Electric Hospital Bed', 'preset_wattage': 150.0, 'min_wattage': 100.0, 'max_wattage': 200.0},
        {'category': 'Vintage & Retro Household Appliances', 'appliance_name': 'CRT TV 29-inch', 'preset_wattage': 175.0, 'min_wattage': 150.0, 'max_wattage': 200.0},
        {'category': 'Vintage & Retro Household Appliances', 'appliance_name': 'Incandescent Light Bulb', 'preset_wattage': 60.0, 'min_wattage': 40.0, 'max_wattage': 100.0},
        {'category': 'Legacy & Older Residential Lighting', 'appliance_name': 'Old Magnetic Ballast Fluorescent Tube', 'preset_wattage': 60.0, 'min_wattage': 60.0, 'max_wattage': 60.0},
        {'category': 'Cooling & Air Conditioning', 'appliance_name': '0.5 HP Window Air Conditioner', 'preset_wattage': 600.0, 'min_wattage': 500.0, 'max_wattage': 700.0},
        {'category': 'Cooling & Air Conditioning', 'appliance_name': '0.75 HP Window Air Conditioner', 'preset_wattage': 800.0, 'min_wattage': 700.0, 'max_wattage': 900.0},
        {'category': 'Cooling & Air Conditioning', 'appliance_name': '1.0 HP Window Air Conditioner', 'preset_wattage': 1000.0, 'min_wattage': 900.0, 'max_wattage': 1200.0},
        {'category': 'Cooling & Air Conditioning', 'appliance_name': '0.75 HP Air Conditioner Conventional', 'preset_wattage': 825.0, 'min_wattage': 750.0, 'max_wattage': 900.0},
        {'category': 'Cooling & Air Conditioning', 'appliance_name': '0.75 HP Air Conditioner Inverter', 'preset_wattage': 525.0, 'min_wattage': 450.0, 'max_wattage': 600.0},
        {'category': 'Cooling & Air Conditioning', 'appliance_name': '1.0 HP Air Conditioner Conventional', 'preset_wattage': 1000.0, 'min_wattage': 900.0, 'max_wattage': 1100.0},
        {'category': 'Cooling & Air Conditioning', 'appliance_name': '1.0 HP Air Conditioner Inverter', 'preset_wattage': 675.0, 'min_wattage': 600.0, 'max_wattage': 750.0},
        {'category': 'Cooling & Air Conditioning', 'appliance_name': '1.5 HP Air Conditioner Conventional', 'preset_wattage': 1300.0, 'min_wattage': 1200.0, 'max_wattage': 1400.0},
        {'category': 'Cooling & Air Conditioning', 'appliance_name': '1.5 HP Air Conditioner Inverter', 'preset_wattage': 900.0, 'min_wattage': 800.0, 'max_wattage': 1000.0},
        {'category': 'Cooling & Air Conditioning', 'appliance_name': '2.0 HP Air Conditioner Inverter', 'preset_wattage': 1400.0, 'min_wattage': 1200.0, 'max_wattage': 1600.0},
        {'category': 'Cooling & Air Conditioning', 'appliance_name': '1.0 HP Split-Type AC', 'preset_wattage': 850.0, 'min_wattage': 700.0, 'max_wattage': 1000.0},
        {'category': 'Cooling & Air Conditioning', 'appliance_name': '1.5 HP Split-Type AC', 'preset_wattage': 1200.0, 'min_wattage': 1000.0, 'max_wattage': 1400.0},
        {'category': 'Cooling & Air Conditioning', 'appliance_name': '2.0 HP Split-Type AC', 'preset_wattage': 1500.0, 'min_wattage': 1300.0, 'max_wattage': 1800.0},
        {'category': 'Kitchen & Cooking', 'appliance_name': 'Small Rice Cooker 3 cups', 'preset_wattage': 300.0, 'min_wattage': 230.0, 'max_wattage': 350.0},
        {'category': 'Kitchen & Cooking', 'appliance_name': 'Rice Cooker 5 cups', 'preset_wattage': 450.0, 'min_wattage': 400.0, 'max_wattage': 500.0},
        {'category': 'Kitchen & Cooking', 'appliance_name': 'Rice Cooker 8 cups', 'preset_wattage': 500.0, 'min_wattage': 500.0, 'max_wattage': 650.0},
        {'category': 'Kitchen & Cooking', 'appliance_name': 'Rice Cooker Small', 'preset_wattage': 500.0, 'min_wattage': 400.0, 'max_wattage': 600.0},
        {'category': 'Kitchen & Cooking', 'appliance_name': 'Rice Cooker Large', 'preset_wattage': 800.0, 'min_wattage': 700.0, 'max_wattage': 1000.0},
        {'category': 'Kitchen & Cooking', 'appliance_name': 'Rice Cooker 10 cups', 'preset_wattage': 700.0, 'min_wattage': 650.0, 'max_wattage': 800.0},
        {'category': 'Kitchen & Cooking', 'appliance_name': 'Rice Cooker 15 cups', 'preset_wattage': 1000.0, 'min_wattage': 900.0, 'max_wattage': 1100.0},
        {'category': 'Kitchen & Cooking', 'appliance_name': 'Microwave Oven', 'preset_wattage': 1200.0, 'min_wattage': 900.0, 'max_wattage': 1500.0},
        {'category': 'Kitchen & Cooking', 'appliance_name': 'Air Fryer', 'preset_wattage': 1500.0, 'min_wattage': 1200.0, 'max_wattage': 1800.0},
        {'category': 'Kitchen & Cooking', 'appliance_name': 'Electric Kettle / Airpot', 'preset_wattage': 1800.0, 'min_wattage': 1500.0, 'max_wattage': 2200.0},
        {'category': 'Kitchen & Cooking', 'appliance_name': 'Induction Cooker', 'preset_wattage': 1800.0, 'min_wattage': 1500.0, 'max_wattage': 2100.0},
        {'category': 'Kitchen & Cooking', 'appliance_name': 'Electric Oven', 'preset_wattage': 1600.0, 'min_wattage': 1200.0, 'max_wattage': 2000.0},
        {'category': 'Kitchen & Cooking', 'appliance_name': 'Built-in Electric Convection Oven', 'preset_wattage': 3000.0, 'min_wattage': 2500.0, 'max_wattage': 3500.0},
        {'category': 'Kitchen & Cooking', 'appliance_name': 'Automatic Dishwasher', 'preset_wattage': 1800.0, 'min_wattage': 1200.0, 'max_wattage': 2400.0},
        {'category': 'Kitchen & Cooking', 'appliance_name': 'Built-in Induction Cooktop', 'preset_wattage': 5000.0, 'min_wattage': 3000.0, 'max_wattage': 7000.0},
        {'category': 'Small Kitchen Appliances', 'appliance_name': 'Espresso Machine', 'preset_wattage': 1250.0, 'min_wattage': 1100.0, 'max_wattage': 1450.0},
        {'category': 'Small Kitchen Appliances', 'appliance_name': 'Bread Toaster', 'preset_wattage': 900.0, 'min_wattage': 800.0, 'max_wattage': 1050.0},
        {'category': 'Small Kitchen Appliances', 'appliance_name': 'Sandwich Maker / Panini Press', 'preset_wattage': 900.0, 'min_wattage': 700.0, 'max_wattage': 1200.0},
        {'category': 'Small Kitchen Appliances', 'appliance_name': 'Waffle Maker', 'preset_wattage': 900.0, 'min_wattage': 750.0, 'max_wattage': 1200.0},
        {'category': 'Laundry & Cleaning', 'appliance_name': 'Front-Load Inverter Washing Machine with Heater', 'preset_wattage': 1200.0, 'min_wattage': 500.0, 'max_wattage': 1800.0},
        {'category': 'Laundry & Cleaning', 'appliance_name': 'Tumble Clothes Dryer', 'preset_wattage': 3000.0, 'min_wattage': 2000.0, 'max_wattage': 4000.0},
        {'category': 'Laundry & Cleaning', 'appliance_name': 'Flat Clothes Iron', 'preset_wattage': 1200.0, 'min_wattage': 1000.0, 'max_wattage': 1500.0},
        {'category': 'Laundry & Cleaning', 'appliance_name': 'Vacuum Cleaner', 'preset_wattage': 1200.0, 'min_wattage': 800.0, 'max_wattage': 1600.0},
        {'category': 'Entertainment & Work From Home', 'appliance_name': '85-inch 8K Premium TV', 'preset_wattage': 375.0, 'min_wattage': 300.0, 'max_wattage': 450.0},
        {'category': 'Entertainment & Work From Home', 'appliance_name': 'Gaming Desktop', 'preset_wattage': 600.0, 'min_wattage': 400.0, 'max_wattage': 750.0},
        {'category': 'Bathroom & Personal Care', 'appliance_name': 'Instant Single-Point Water Heater', 'preset_wattage': 3500.0, 'min_wattage': 3000.0, 'max_wattage': 4500.0},
        {'category': 'Bathroom & Personal Care', 'appliance_name': 'Storage Multipoint Water Heater', 'preset_wattage': 5000.0, 'min_wattage': 4000.0, 'max_wattage': 6000.0},
        {'category': 'Bathroom & Personal Care', 'appliance_name': 'Shower Heater with Pump', 'preset_wattage': 4500.0, 'min_wattage': 3500.0, 'max_wattage': 5500.0},
        {'category': 'Bathroom & Personal Care', 'appliance_name': 'Hair Dryer', 'preset_wattage': 1500.0, 'min_wattage': 1200.0, 'max_wattage': 2000.0},
        {'category': 'Lighting & Household Utilities', 'appliance_name': 'Domestic Water Pump 1.0 HP', 'preset_wattage': 800.0, 'min_wattage': 750.0, 'max_wattage': 950.0},
        {'category': 'Garage, DIY & Power Tools', 'appliance_name': 'Electric Pressure Washer', 'preset_wattage': 1800.0, 'min_wattage': 1400.0, 'max_wattage': 2100.0},
        {'category': 'Garage, DIY & Power Tools', 'appliance_name': 'Handheld Corded Drill', 'preset_wattage': 650.0, 'min_wattage': 500.0, 'max_wattage': 850.0},
        {'category': 'Garage, DIY & Power Tools', 'appliance_name': 'Angle Grinder', 'preset_wattage': 750.0, 'min_wattage': 600.0, 'max_wattage': 900.0},
        {'category': 'Smart Home & Security', 'appliance_name': 'CCTV NVR/DVR System', 'preset_wattage': 60.0, 'min_wattage': 40.0, 'max_wattage': 90.0},
        {'category': 'Smart Home & Security', 'appliance_name': 'Automatic Gate Motor', 'preset_wattage': 500.0, 'min_wattage': 300.0, 'max_wattage': 800.0},
        {'category': 'Specialty Care & Hobby', 'appliance_name': '3D Printer', 'preset_wattage': 275.0, 'min_wattage': 200.0, 'max_wattage': 350.0},
        {'category': 'Specialty Care & Hobby', 'appliance_name': 'Hydroponic Grow Lights', 'preset_wattage': 100.0, 'min_wattage': 50.0, 'max_wattage': 200.0},
        {'category': 'Outdoor & Pool', 'appliance_name': 'Pool Pump', 'preset_wattage': 1000.0, 'min_wattage': 500.0, 'max_wattage': 1500.0},
        {'category': 'Outdoor & Pool', 'appliance_name': 'Pool Filtration System', 'preset_wattage': 1200.0, 'min_wattage': 750.0, 'max_wattage': 2000.0},
        {'category': 'E-Mobility Charging (Home)', 'appliance_name': 'EV Level 1 Charger', 'preset_wattage': 1600.0, 'min_wattage': 1300.0, 'max_wattage': 1900.0},
        {'category': 'E-Mobility Charging (Home)', 'appliance_name': 'EV Level 2 Wallbox Charger', 'preset_wattage': 7400.0, 'min_wattage': 3500.0, 'max_wattage': 7400.0},
        {'category': 'Home Office & Utilities', 'appliance_name': 'Laser Printer', 'preset_wattage': 550.0, 'min_wattage': 400.0, 'max_wattage': 700.0},
        {'category': 'Vintage & Retro Household Appliances', 'appliance_name': 'Vintage Halogen Floodlight Torch', 'preset_wattage': 1000.0, 'min_wattage': 500.0, 'max_wattage': 1500.0},
      ];

      Batch batch = db.batch();
      for (var preset in updatedPresets) {
        batch.insert('appliance_presets', {
          'category': preset['category'],
          'appliance_name': preset['appliance_name'],
          'preset_wattage': preset['preset_wattage'],
          'min_wattage': preset['min_wattage'],
          'max_wattage': preset['max_wattage'],
        });
      }
      await batch.commit(noResult: true);
    }
}
