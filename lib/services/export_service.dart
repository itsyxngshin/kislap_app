import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:excel/excel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/inventory_provider.dart';

class ExportService {
  static Future<void> exportScheduleToExcel({
    required List<Appliance> inventory,
    required double tariffRate,
    required double targetBudget,
  }) async {
    // 1. Fetch Account Role and Name dynamically
    String userName = 'Guest User';
    String roleName = 'User';

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('full_name, role_id')
            .eq('id', user.id)
            .maybeSingle();

        if (profile != null) {
          userName = profile['full_name'] ?? 'User';
          roleName = profile['role_id'] == 2 ? 'Admin' : 'User';
        }
      }
    } catch (_) {}

    // 2. Initialize Excel and Sheets
    var excel = Excel.createExcel();
    String dataSheetName = 'Data Tables';
    String graphSheetName = 'Visual Analysis';

    Sheet dataSheet = excel[dataSheetName];
    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // --- SHEET 1: DATA TABLES ---
    dataSheet.appendRow([TextCellValue('System Name'), TextCellValue('Kislap Energy Optimization System')]);
    dataSheet.appendRow([TextCellValue('Account Name'), TextCellValue('$userName ($roleName)')]);
    dataSheet.appendRow([TextCellValue('Export Date & Time'), TextCellValue(DateTime.now().toString().split('.')[0])]);
    dataSheet.appendRow([TextCellValue('')]);

    dataSheet.appendRow([TextCellValue('FINANCIAL BASELINE')]);
    dataSheet.appendRow([TextCellValue('Target Budget'), DoubleCellValue(targetBudget)]);
    dataSheet.appendRow([TextCellValue('Utility Rate (PHP/kWh)'), DoubleCellValue(tariffRate)]);
    dataSheet.appendRow([TextCellValue('')]);

    dataSheet.appendRow([
      TextCellValue('Appliance Name'),
      TextCellValue('Qty'),
      TextCellValue('Wattage (W)'),
      TextCellValue('Orig. Hours'),
      TextCellValue('Opt. Hours'),
      TextCellValue('Daily kWh'),
      TextCellValue('Weekly kWh'),
      TextCellValue('Monthly kWh'),
      TextCellValue('Est. Monthly Cost (PHP)'),
    ]);

    double totalDailyKwh = 0;

    for (var item in inventory) {
      double dailyKwh = ((item.presetWattage * item.quantity) / 1000) * item.adjustedHours;
      totalDailyKwh += dailyKwh;

      dataSheet.appendRow([
        TextCellValue(item.customName),
        IntCellValue(item.quantity),
        DoubleCellValue(item.presetWattage),
        DoubleCellValue(item.userAssignedHours),
        DoubleCellValue(item.adjustedHours),
        DoubleCellValue(double.parse(dailyKwh.toStringAsFixed(2))),
        DoubleCellValue(double.parse((dailyKwh * 7).toStringAsFixed(2))),
        DoubleCellValue(double.parse((dailyKwh * 30).toStringAsFixed(2))),
        DoubleCellValue(double.parse((dailyKwh * 30 * tariffRate).toStringAsFixed(2))),
      ]);
    }

    // --- SHEET 2: VISUAL ANALYSIS (For Graphing) ---
    Sheet graphSheet = excel[graphSheetName];
    graphSheet.appendRow([TextCellValue('VISUAL ANALYSIS & GRAPH DATA')]);
    graphSheet.appendRow([TextCellValue('Note: Highlight the tables below and click "Insert > Chart" in Excel to generate your visual graphs.')]);
    graphSheet.appendRow([TextCellValue('')]);

    graphSheet.appendRow([TextCellValue('7-DAY CONSUMPTION TREND')]);
    graphSheet.appendRow([TextCellValue('Day'), TextCellValue('Multiplier Basis'), TextCellValue('Projected kWh')]);

    final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final List<double> factors = [1.0, 0.95, 0.95, 0.95, 1.05, 1.10, 1.0];

    for (int i = 0; i < 7; i++) {
      graphSheet.appendRow([
        TextCellValue(days[i]),
        DoubleCellValue(factors[i]),
        DoubleCellValue(double.parse((totalDailyKwh * factors[i]).toStringAsFixed(2)))
      ]);
    }

    graphSheet.appendRow([TextCellValue('')]);

    graphSheet.appendRow([TextCellValue('APPLIANCE COST BREAKDOWN')]);
    graphSheet.appendRow([TextCellValue('Appliance'), TextCellValue('Monthly Cost (PHP)')]);
    for (var item in inventory) {
       double cost = (((item.presetWattage * item.quantity) / 1000) * item.adjustedHours) * 30 * tariffRate;
       graphSheet.appendRow([TextCellValue('${item.customName} (x${item.quantity})'), DoubleCellValue(double.parse(cost.toStringAsFixed(2)))]);
    }

    // --- CROSS-PLATFORM SAVE & EXPORT ---
    String fileName = 'Kislap_Optimization_Report.xlsx';

    // This triggers the standard browser download on Web
    var fileBytes = excel.save(fileName: fileName);

    if (fileBytes != null && !kIsWeb) {
      try {
        // Write to the temporary mobile app sandbox
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(fileBytes);

        // Trigger native iOS/Android Share Sheet
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Here is your Kislap Energy Optimization Report!'
        );
      } catch (e) {
        debugPrint('Export Error: $e');
      }
    }
  }
}
