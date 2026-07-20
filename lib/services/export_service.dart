import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/appliance_item.dart';

class ExportService {
  static Future<void> exportScheduleToExcel({
    required List<ApplianceItem> inventory,
    required double tariffRate,
    required double targetBudget,
  }) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Optimized Schedule'];
    excel.setDefaultSheet('Optimized Schedule');

    // REMOVED 'const' FROM ALL TextCellValue CALLS BELOW
    sheetObject.appendRow([
      TextCellValue('Appliance Name'),
      TextCellValue('Category'),
      TextCellValue('Status'),
      TextCellValue('Power (Watts)'),
      TextCellValue('Baseline Hours'),
      TextCellValue('Optimized Hours'),
      TextCellValue('Daily kWh'),
      TextCellValue('Est. Monthly Cost (PHP)'),
    ]);

    double totalMonthlyCost = 0.0;
    double totalDailyKwh = 0.0;

    for (var item in inventory) {
      final double dailyKwh = (item.presetWattage / 1000) * item.adjustedHours;
      final double monthlyCost = dailyKwh * 30 * tariffRate;

      totalDailyKwh += dailyKwh;
      totalMonthlyCost += monthlyCost;

      sheetObject.appendRow([
        TextCellValue(item.customName),
        TextCellValue(item.category),
        TextCellValue(item.isLocked ? 'Locked (Essential)' : 'Flexible'),
        DoubleCellValue(item.presetWattage),
        DoubleCellValue(item.userAssignedHours),
        DoubleCellValue(item.adjustedHours),
        DoubleCellValue(double.parse(dailyKwh.toStringAsFixed(2))),
        DoubleCellValue(double.parse(monthlyCost.toStringAsFixed(2))),
      ]);
    }

    sheetObject.appendRow([TextCellValue('')]); 
    sheetObject.appendRow([TextCellValue('--- SUMMARY ---')]);
    
    sheetObject.appendRow([
      TextCellValue('Target Budget:'),
      DoubleCellValue(targetBudget),
    ]);
    
    sheetObject.appendRow([
      TextCellValue('Estimated Total:'),
      DoubleCellValue(double.parse(totalMonthlyCost.toStringAsFixed(2))),
    ]);

    sheetObject.appendRow([
      TextCellValue('Status:'),
      TextCellValue(totalMonthlyCost <= targetBudget ? 'On Track' : 'Budget Breached'),
    ]);

    var fileBytes = excel.save();
    final directory = await getTemporaryDirectory();
    final String filePath = '${directory.path}/Kislap_Optimization_Plan.xlsx';
    
    File(filePath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(fileBytes!);

    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'Here is my optimized Kislap electricity plan!',
    );
  }
}