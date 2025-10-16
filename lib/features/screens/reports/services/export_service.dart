import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ExportService {
  static Future<String?> _requestPermissionAndGetPath(String extension) async {
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      // TODO: Handle denied permission (e.g., show a snackbar)
      return null;
    }
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/report_${DateTime.now().millisecondsSinceEpoch}.$extension';
    return path;
  }

  static Future<void> exportToCsv(List<Map<String, dynamic>> data) async {
    final path = await _requestPermissionAndGetPath('csv');
    if (path == null) {
      return;
    }

    final file = File(path);
    if (data.isEmpty) {
      return;
    }

    List<List<dynamic>> rows = [];
    rows.add(data.first.keys.toList());
    
    for (var item in data) {
      rows.add(item.values.toList());
    }

    String csv = const ListToCsvConverter().convert(rows);
    await file.writeAsString(csv);
    // TODO: Show a snackbar or notification
    print('CSV exported to: $path');
  }

  static Future<void> exportToExcel(List<Map<String, dynamic>> data) async {
    final path = await _requestPermissionAndGetPath('xlsx');
    if (path == null) {
      return;
    }

    // Correctly instantiate the File object using the path.
    final file = File(path);
    
    if (data.isEmpty) {
      return;
    }

    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];

    // Add headers
    data.first.keys.toList().asMap().forEach((index, key) {
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: index, rowIndex: 0)).value = TextCellValue(key);
    });

    // Add data rows
    data.asMap().forEach((rowIndex, rowMap) {
      rowMap.values.toList().asMap().forEach((colIndex, value) {
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex + 1)).value = TextCellValue(value.toString());
      });
    });

    try {
      final bytes = await excel.encode();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
        // TODO: Show a snackbar or notification
        print('Excel exported to: $path');
      } else {
        // TODO: Handle the case where encoding fails
        print('Excel encoding failed.');
      }
    } catch (e) {
      // TODO: Handle potential file writing errors
      print('Error writing Excel file: $e');
    }
  }
}
