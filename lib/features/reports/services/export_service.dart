import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart' as xls;
import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ExportService {
  // CSV -----------------------------------------------------------------------
  static Future<void> exportToCsv(
    List<Map<String, dynamic>> rows, {
    String fileName = 'report.csv',
  }) async {
    if (rows.isEmpty) {
      await _saveBytes(fileName, Uint8List.fromList(utf8.encode('')));
      return;
    }

    final headers = _headersFromRows(rows);
    final buffer = StringBuffer();
    buffer.writeln(headers.map(_escapeCsv).join(','));

    for (final row in rows) {
      buffer.writeln(headers.map((h) => _escapeCsv(row[h])).join(','));
    }

    final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));
    await _saveBytes(fileName, bytes, extOverride: 'csv', mime: MimeType.csv);
  }

  // Excel ---------------------------------------------------------------------
  static Future<void> exportToExcel(
    List<Map<String, dynamic>> rows, {
    String fileName = 'report.xlsx',
    String sheetName = 'Report',
  }) async {
    final book = xls.Excel.createExcel();
    final sheet = book[sheetName];

    if (rows.isEmpty) {
      sheet.appendRow(<xls.CellValue?>[xls.TextCellValue('No data')]);
    } else {
      final headers = _headersFromRows(rows);
      sheet.appendRow(headers.map<xls.CellValue?>((h) => xls.TextCellValue(h)).toList());

      for (final row in rows) {
        sheet.appendRow(
          headers.map<xls.CellValue?>((h) {
            final v = row[h];
            if (v == null) return xls.TextCellValue('');
            if (v is num) return xls.DoubleCellValue(v.toDouble());
            return xls.TextCellValue(v.toString());
          }).toList(),
        );
      }
    }

    final encoded = book.encode();
    final bytes = Uint8List.fromList(encoded!);
    await _saveBytes(fileName, bytes, extOverride: 'xlsx', mime: MimeType.microsoftExcel);
  }

  // PDF -----------------------------------------------------------------------
  static Future<void> exportToPdf({
    required String title,
    required List<String> headers,
    required List<List<dynamic>> rows,
    String fileName = 'report.pdf',
    String? subtitle,
    List<pw.Widget> extraTopWidgets = const [],
  }) async {
    final doc = pw.Document();

    // Use MultiPage with theme OR pageTheme, not both.
    // We pass theme + margin here and DO NOT pass pageTheme to avoid assertion.
    final theme = pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
    );

    doc.addPage(
      pw.MultiPage(
        theme: theme,
        margin: const pw.EdgeInsets.fromLTRB(24, 48, 24, 36),
        pageFormat: PdfPageFormat.a4,
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            if (subtitle != null && subtitle.isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 2),
                child: pw.Text(subtitle, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ),
            pw.SizedBox(height: 10),
          ],
        ),
        build: (ctx) => [
          if (extraTopWidgets.isNotEmpty) ...extraTopWidgets,
          pw.TableHelper.fromTextArray(
            context: ctx,
            headers: headers,
            data: rows
                .map((r) => r.map((cell) => cell is num ? cell.toString() : (cell?.toString() ?? '')).toList())
                .toList(),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerAlignment: pw.Alignment.centerLeft,
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    await _saveBytes(fileName, Uint8List.fromList(bytes), extOverride: 'pdf', mime: MimeType.pdf);
  }

  // Helpers -------------------------------------------------------------------
  static List<String> _headersFromRows(List<Map<String, dynamic>> rows) {
    final set = <String>{};
    for (final r in rows) {
      set.addAll(r.keys);
    }
    return set.toList();
  }

  static String _escapeCsv(dynamic v) {
    final s = v?.toString() ?? '';
    final needsQuotes = s.contains(',') || s.contains('"') || s.contains('\n') || s.contains('\r');
    final t = s.replaceAll('"', '""');
    return needsQuotes ? '"$t"' : t;
  }

  static Future<void> _saveBytes(String name, Uint8List bytes, {String? extOverride, MimeType? mime}) async {
    final ext = (extOverride ?? name.split('.').last).toLowerCase();
    await FileSaver.instance.saveFile(
      name: name.endsWith('.$ext') ? name : '$name.$ext',
      bytes: bytes,
      ext: ext,
      mimeType: mime ?? _guessMime(ext),
    );
  }

  static MimeType _guessMime(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return MimeType.pdf;
      case 'xlsx':
        return MimeType.microsoftExcel;
      case 'csv':
        return MimeType.csv;
      default:
        return MimeType.other;
    }
  }
}