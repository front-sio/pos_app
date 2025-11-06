import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart' as xls;
import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ExportService {
  static const PdfColor _brandPrimary = PdfColor(0.00, 0.30, 0.60);
  static const PdfColor _brandAccent = PdfColor(0.13, 0.59, 0.95);
  static const PdfColor _successGreen = PdfColor(0.15, 0.68, 0.38);
  static const PdfColor _warningOrange = PdfColor(0.96, 0.49, 0.00);

  static Future<void> exportToCsv(
    List<Map<String, dynamic>> rows, {
    String fileName = 'report.csv',
    String? title,
    String? subtitle,
  }) async {
    if (rows.isEmpty) {
      await _saveBytes(fileName, Uint8List.fromList(utf8.encode('')));
      return;
    }

    final headers = _headersFromRows(rows);
    final buffer = StringBuffer();

    if (title != null) {
      buffer.writeln(_escapeCsv(title));
      if (subtitle != null) buffer.writeln(_escapeCsv(subtitle));
      buffer.writeln();
    }

    buffer.writeln(headers.map(_escapeCsv).join(','));
    for (final row in rows) {
      buffer.writeln(headers.map((h) => _escapeCsv(row[h])).join(','));
    }

    final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));
    await _saveBytes(fileName, bytes, extOverride: 'csv', mime: MimeType.csv);
  }

  static Future<void> exportToExcel(
    List<Map<String, dynamic>> rows, {
    String fileName = 'report.xlsx',
    String sheetName = 'Report',
    String? title,
    String? subtitle,
  }) async {
    final book = xls.Excel.createExcel();
    final sheet = book[sheetName];

    int currentRow = 0;

    if (title != null) {
      final titleCell = sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow));
      titleCell.value = xls.TextCellValue(title);
      titleCell.cellStyle = xls.CellStyle(
        bold: true,
        fontSize: 16,
        fontColorHex: xls.ExcelColor.fromHexString('#004D99'),
      );
      currentRow++;

      if (subtitle != null) {
        final subtitleCell = sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow));
        subtitleCell.value = xls.TextCellValue(subtitle);
        subtitleCell.cellStyle = xls.CellStyle(
          fontSize: 10,
          fontColorHex: xls.ExcelColor.fromHexString('#666666'),
          italic: true,
        );
        currentRow++;
      }
      currentRow++;
    }

    if (rows.isEmpty) {
      sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value = xls.TextCellValue('No data');
    } else {
      final headers = _headersFromRows(rows);

      for (int i = 0; i < headers.length; i++) {
        final headerCell = sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow));
        headerCell.value = xls.TextCellValue(headers[i]);
        headerCell.cellStyle = xls.CellStyle(
          bold: true,
          backgroundColorHex: xls.ExcelColor.fromHexString('#004D99'),
          fontColorHex: xls.ExcelColor.white,
          horizontalAlign: xls.HorizontalAlign.Center,
          verticalAlign: xls.VerticalAlign.Center,
        );
      }
      currentRow++;

      for (int rowIdx = 0; rowIdx < rows.length; rowIdx++) {
        final row = rows[rowIdx];
        final isEven = rowIdx % 2 == 0;

        for (int colIdx = 0; colIdx < headers.length; colIdx++) {
          final cell = sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: colIdx, rowIndex: currentRow + rowIdx));
          final v = row[headers[colIdx]];
          final bgColor = isEven ? xls.ExcelColor.fromHexString('#F5F5F5') : xls.ExcelColor.white;

          if (v == null) {
            cell.value = xls.TextCellValue('');
            cell.cellStyle = xls.CellStyle(backgroundColorHex: bgColor);
          } else if (v is num) {
            cell.value = xls.DoubleCellValue(v.toDouble());
            cell.cellStyle = xls.CellStyle(backgroundColorHex: bgColor);
            if (_isInteger(v)) {
              cell.cellStyle?.numberFormat = xls.NumFormat.standard_0;
            } else {
              cell.cellStyle?.numberFormat = xls.NumFormat.standard_2;
            }
          } else if (v is DateTime) {
            cell.value = xls.TextCellValue(v.toIso8601String().split('T').first);
            cell.cellStyle = xls.CellStyle(backgroundColorHex: bgColor);
          } else {
            cell.value = xls.TextCellValue(v.toString());
            cell.cellStyle = xls.CellStyle(backgroundColorHex: bgColor);
          }
        }
      }
    }

    final bytes = Uint8List.fromList(book.encode()!);
    await _saveBytes(fileName, bytes, extOverride: 'xlsx', mime: MimeType.microsoftExcel);
  }

  static Future<void> exportToPdf({
    required String title,
    required List<String> headers,
    required List<List<dynamic>> rows,
    String fileName = 'report.pdf',
    String? subtitle,
    List<pw.Widget> extraTopWidgets = const [],
  }) async {
    final doc = pw.Document();
    final theme = pw.ThemeData.withFont(base: pw.Font.helvetica(), bold: pw.Font.helveticaBold());

    final normalized = _normalizeRows(headers, rows);
    final display = normalized.map((r) => r.map((c) => _cellToString(c)).toList()).toList();

    doc.addPage(
      pw.MultiPage(
        theme: theme,
        margin: const pw.EdgeInsets.fromLTRB(30, 40, 30, 35),
        pageFormat: PdfPageFormat.a4,
        header: (ctx) => _buildModernHeader(title: title, subtitle: subtitle),
        footer: _buildModernFooter,
        build: (ctx) => [
          if (extraTopWidgets.isNotEmpty) ...extraTopWidgets,
          if (display.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Center(
                child: pw.Text(
                  'No data available for the selected period',
                  style: pw.TextStyle(color: PdfColors.grey700, fontSize: 12),
                ),
              ),
            )
          else
            _buildModernTable(headers: headers, rows: display),
        ],
      ),
    );

    final bytes = await doc.save();
    await _saveBytes(fileName, Uint8List.fromList(bytes), extOverride: 'pdf', mime: MimeType.pdf);
  }

  static Future<void> exportSalesTableReportPdf({
    required String title,
    required List<String> headers,
    required List<List<dynamic>> rows,
    String fileName = 'sales-report.pdf',
    String? subtitle,
    String Function(num)? currencyFmt,
  }) async {
    final fmt = currencyFmt ?? ((num n) => n.toStringAsFixed(2));
    final normalized = _normalizeRows(headers, rows);

    final idxRevenue = _findColumnIndex(headers, const ['revenue', 'sales value', 'amount', 'total']);
    final idxCost = _findColumnIndex(headers, const ['cost', 'purchase cost']);
    final idxProfit = _findColumnIndex(headers, const ['profit', 'gross profit', 'net profit']);
    final idxQty = _findColumnIndex(headers, const ['qty', 'quantity', 'orders', 'sold qty']);

    final display = <List<String>>[];
    for (final r in normalized) {
      final row = <String>[];
      for (int i = 0; i < headers.length; i++) {
        final v = r[i];
        if (i == idxRevenue || i == idxCost || i == idxProfit) {
          row.add(fmt(_toNum(v)));
        } else if (i == idxQty) {
          final n = _toNum(v);
          row.add((n % 1 == 0) ? n.toInt().toString() : n.toStringAsFixed(2));
        } else {
          row.add(_cellToString(v));
        }
      }
      display.add(row);
    }

    num totalValue = 0, totalProfit = 0, totalQty = 0;
    if (idxRevenue != -1) {
      for (final r in normalized) {
        totalValue += _toNum(r[idxRevenue]);
      }
    } else {
      final lastIdx = _lastNumericColumnIndex(normalized);
      if (lastIdx != -1) {
        for (final r in normalized) {
          totalValue += _toNum(r[lastIdx]);
        }
      }
    }
    if (idxProfit != -1) {
      for (final r in normalized) {
        totalProfit += _toNum(r[idxProfit]);
      }
    }
    if (idxQty != -1) {
      for (final r in normalized) {
        totalQty += _toNum(r[idxQty]);
      }
    }

    final totalRows = normalized.length;

    final doc = pw.Document();
    final theme = pw.ThemeData.withFont(base: pw.Font.helvetica(), bold: pw.Font.helveticaBold());

    doc.addPage(
      pw.MultiPage(
        theme: theme,
        margin: const pw.EdgeInsets.fromLTRB(30, 40, 30, 35),
        pageFormat: PdfPageFormat.a4,
        header: (ctx) => _buildModernHeader(title: title, subtitle: subtitle),
        footer: _buildModernFooter,
        build: (ctx) => [
          if (display.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Center(
                child: pw.Text('No data for the selected period', style: pw.TextStyle(color: PdfColors.grey700)),
              ),
            )
          else ...[
            _buildSalesTableWithTotals(
              headers: headers,
              rows: display,
              idxQty: idxQty,
              idxRevenue: idxRevenue,
              idxProfit: idxProfit,
              totals: _SalesTotals(
                totalsLabel: 'Totals',
                qty: idxQty != -1 ? ((totalQty % 1 == 0) ? totalQty.toInt().toString() : totalQty.toStringAsFixed(2)) : null,
                revenue: (idxRevenue != -1 || totalValue != 0) ? fmt(totalValue) : null,
                profit: idxProfit != -1 ? fmt(totalProfit) : null,
                rowsCount: totalRows,
              ),
            ),
            pw.SizedBox(height: 12),
            _buildSummaryCards(
              totalRows: totalRows,
              totalQty: totalQty,
              totalValue: totalValue,
              totalProfit: totalProfit,
              fmt: fmt,
              idxQty: idxQty,
            ),
          ],
        ],
      ),
    );

    final bytes = await doc.save();
    await _saveBytes(fileName, Uint8List.fromList(bytes), extOverride: 'pdf', mime: MimeType.pdf);
  }

  static Future<void> exportSummaryReportPdf({
    required String title,
    required List<MapEntry<String, String>> entries,
    String fileName = 'summary-report.pdf',
    String? subtitle,
  }) async {
    final doc = pw.Document();
    final theme = pw.ThemeData.withFont(base: pw.Font.helvetica(), bold: pw.Font.helveticaBold());

    doc.addPage(
      pw.MultiPage(
        theme: theme,
        margin: const pw.EdgeInsets.fromLTRB(30, 40, 30, 35),
        pageFormat: PdfPageFormat.a4,
        header: (ctx) => _buildModernHeader(title: title, subtitle: subtitle),
        footer: _buildModernFooter,
        build: (ctx) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.grey300, width: 1),
              boxShadow: [
                pw.BoxShadow(color: PdfColors.grey300, blurRadius: 4, offset: const PdfPoint(0, 2)),
              ],
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < entries.length; i++) ...[
                  if (i > 0) pw.Divider(color: PdfColors.grey200, height: 12),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        entries[i].key,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.grey800, fontSize: 11),
                      ),
                      pw.Text(
                        entries[i].value,
                        style: const pw.TextStyle(color: PdfColors.black, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    await _saveBytes(fileName, Uint8List.fromList(bytes), extOverride: 'pdf', mime: MimeType.pdf);
  }

  static pw.Widget _buildModernHeader({required String title, String? subtitle}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          height: 5,
          decoration: pw.BoxDecoration(
            gradient: const pw.LinearGradient(
              colors: [_brandPrimary, _brandAccent],
            ),
            borderRadius: pw.BorderRadius.circular(2),
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    title,
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _brandPrimary),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 3),
                      child: pw.Text(subtitle, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    ),
                ],
              ),
            ),
            pw.Text(
              'Generated: ${DateTime.now().toIso8601String().split('T').first}',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(color: PdfColors.grey300, height: 1),
        pw.SizedBox(height: 12),
      ],
    );
  }

  static pw.Widget _buildModernFooter(pw.Context ctx) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300, height: 1),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Confidential Report',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
            pw.Text(
              'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildModernTable({required List<String> headers, required List<List<String>> rows}) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        for (int i = 0; i < headers.length; i++) i: i == 0 ? const pw.FlexColumnWidth(2.5) : const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _brandPrimary),
          children: [
            for (final h in headers)
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  h,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                ),
              ),
          ],
        ),
        for (int i = 0; i < rows.length; i++)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: i % 2 == 0 ? PdfColors.grey50 : PdfColors.white,
            ),
            children: [
              for (final cell in rows[i])
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(cell, style: const pw.TextStyle(fontSize: 9, color: PdfColors.black)),
                ),
            ],
          ),
      ],
    );
  }

  static pw.Widget _buildSalesTableWithTotals({
    required List<String> headers,
    required List<List<String>> rows,
    required int idxQty,
    required int idxRevenue,
    required int idxProfit,
    required _SalesTotals totals,
  }) {
    final widths = <int, pw.TableColumnWidth>{};
    for (int i = 0; i < headers.length; i++) {
      widths[i] = i == 0 ? const pw.FlexColumnWidth(2.5) : const pw.FlexColumnWidth(1);
    }

    pw.Widget cell(String text, {bool bold = false, pw.Alignment align = pw.Alignment.centerLeft, PdfColor? color}) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        alignment: align,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color ?? PdfColors.black,
          ),
        ),
      );
    }

    final allRows = <pw.TableRow>[];

    allRows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _brandPrimary),
        children: [for (final h in headers) cell(h, bold: true, color: PdfColors.white)],
      ),
    );

    for (int i = 0; i < rows.length; i++) {
      final r = rows[i];
      final children = <pw.Widget>[];
      for (int j = 0; j < headers.length; j++) {
        final alignRight = (j == idxQty || j == idxRevenue || j == idxProfit);
        children.add(cell(r[j], align: alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft));
      }
      allRows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(color: i % 2 == 0 ? PdfColors.grey50 : PdfColors.white),
          children: children,
        ),
      );
    }

    if (rows.isNotEmpty) {
      final totalsRow = List<String>.filled(headers.length, '');
      if (headers.isNotEmpty) totalsRow[0] = totals.totalsLabel;
      if (idxQty != -1 && totals.qty != null) totalsRow[idxQty] = totals.qty!;
      if (idxRevenue != -1 && totals.revenue != null) totalsRow[idxRevenue] = totals.revenue!;
      if (idxProfit != -1 && totals.profit != null) totalsRow[idxProfit] = totals.profit!;

      allRows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey200, border: pw.Border.all(color: _brandPrimary, width: 1.5)),
          children: [
            for (int i = 0; i < headers.length; i++)
              cell(
                totalsRow[i],
                bold: i == 0 || i == idxQty || i == idxRevenue || i == idxProfit,
                align: (i == idxQty || i == idxRevenue || i == idxProfit) ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
              ),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: widths,
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: allRows,
    );
  }

  static pw.Widget _buildSummaryCards({
    required int totalRows,
    required num totalQty,
    required num totalValue,
    required num totalProfit,
    required String Function(num) fmt,
    required int idxQty,
  }) {
    pw.Widget card(String label, String value, PdfColor color) {
      return pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: color, width: 2),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              pw.SizedBox(height: 4),
              pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: color)),
            ],
          ),
        ),
      );
    }

    return pw.Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        card('Total Rows', totalRows.toString(), _brandPrimary),
        if (idxQty != -1) card('Total Qty/Orders', (totalQty % 1 == 0) ? totalQty.toInt().toString() : totalQty.toStringAsFixed(2), _brandAccent),
        if (totalValue != 0) card('Total Sales Value', fmt(totalValue), _successGreen),
        if (totalProfit != 0) card('Total Profit', fmt(totalProfit), _warningOrange),
      ],
    );
  }

  static List<String> _headersFromRows(List<Map<String, dynamic>> rows) {
    final seen = <String>{};
    final ordered = <String>[];
    for (final r in rows) {
      for (final k in r.keys) {
        if (!seen.contains(k)) {
          seen.add(k);
          ordered.add(k);
        }
      }
    }
    return ordered;
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

  static List<List<dynamic>> _normalizeRows(List<String> headers, List<List<dynamic>> rows) {
    if (headers.isEmpty) return <List<dynamic>>[];
    if (rows.isEmpty) return <List<dynamic>>[];
    return rows.map((r) {
      final out = List<dynamic>.from(r);
      if (out.length < headers.length) {
        out.addAll(List.filled(headers.length - out.length, ''));
      } else if (out.length > headers.length) {
        out.removeRange(headers.length, out.length);
      }
      return out;
    }).toList();
  }

  static int _findColumnIndex(List<String> headers, List<String> candidates) {
    for (var i = 0; i < headers.length; i++) {
      final h = headers[i].trim().toLowerCase();
      if (candidates.any((c) => h == c || h.contains(c))) return i;
    }
    return -1;
  }

  static int _lastNumericColumnIndex(List<List<dynamic>> rows) {
    if (rows.isEmpty) return -1;
    final width = rows.first.length;
    for (int col = width - 1; col >= 0; col--) {
      bool anyNum = false;
      for (final r in rows) {
        final v = r[col];
        if (v is num) {
          anyNum = true;
          break;
        }
        if (v is String && num.tryParse(v.replaceAll(RegExp(r'[^0-9\.\-]'), '')) != null) {
          anyNum = true;
          break;
        }
      }
      if (anyNum) return col;
    }
    return -1;
  }

  static num _toNum(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v;
    final s = v.toString().replaceAll(RegExp(r'[^0-9\.\-]'), '');
    return num.tryParse(s) ?? 0;
  }

  static String _cellToString(dynamic v) {
    if (v == null) return '';
    if (v is DateTime) return v.toIso8601String().split('T').first;
    return v.toString();
  }

  static bool _isInteger(num v) => v is int || v == v.roundToDouble();
}

class _SalesTotals {
  final String totalsLabel;
  final String? qty;
  final String? revenue;
  final String? profit;
  final int rowsCount;

  const _SalesTotals({
    required this.totalsLabel,
    required this.rowsCount,
    this.qty,
    this.revenue,
    this.profit,
  });
}