import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart' as xls;
import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Lightweight data model for invoice export
class InvoiceLineData {
  final String product;
  final double soldQty;
  final double returnedQty;
  final double unitPrice;

  const InvoiceLineData({
    required this.product,
    required this.soldQty,
    required this.returnedQty,
    required this.unitPrice,
  });
}

class InvoiceSaleSection {
  final int saleId;
  final DateTime soldAt;
  final List<InvoiceLineData> lines;

  const InvoiceSaleSection({
    required this.saleId,
    required this.soldAt,
    required this.lines,
  });
}

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

  // PDF (generic table) -------------------------------------------------------
  static Future<void> exportToPdf({
    required String title,
    required List<String> headers,
    required List<List<dynamic>> rows,
    String fileName = 'report.pdf',
    String? subtitle,
    List<pw.Widget> extraTopWidgets = const [],
  }) async {
    final doc = pw.Document();

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
                child: pw.Text(subtitle, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
              ),
            pw.SizedBox(height: 10),
          ],
        ),
        footer: (ctx) => _footer(ctx),
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
            headerDecoration: pw.BoxDecoration(color: PdfColors.blue),
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

  // PDF (Invoice layout) ------------------------------------------------------
  static Future<void> exportInvoicePdf({
    required String fileName,
    required int invoiceId,
    required String customerName,
    required DateTime createdAt,
    required String statusText, // Paid | Credited | Unpaid
    required List<InvoiceSaleSection> sections,
    required num amountPaid,
    required num amountDue,
    required String Function(num) fmtCurrency,
  }) async {
    final doc = pw.Document();
    final theme = pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
    );

    // Totals
    num originalTotal = 0;
    num returnedValue = 0;
    for (final s in sections) {
      for (final l in s.lines) {
        final lineOriginal = l.unitPrice * l.soldQty;
        final lineReturned = l.unitPrice * l.returnedQty;
        originalTotal += lineOriginal;
        returnedValue += lineReturned;
      }
    }
    final adjustedTotal = originalTotal - returnedValue;

    // Status palette
    final palette = _statusPalette(statusText);

    pw.Widget statusBadge(String label) => pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: pw.BoxDecoration(
            color: palette.bg,
            borderRadius: pw.BorderRadius.circular(999),
            border: pw.Border.all(color: palette.border, width: 0.8),
          ),
          child: pw.Text(
            label.toUpperCase(),
            style: pw.TextStyle(color: palette.fg, fontWeight: pw.FontWeight.bold),
          ),
        );

    pw.Widget masthead() => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Invoice #$invoiceId', style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('Customer: $customerName', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey800)),
                  pw.SizedBox(height: 2),
                  pw.Text('Status: $statusText', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey800)),
                  pw.SizedBox(height: 2),
                  pw.Text('Invoice Created At: ${_fmtDateTime(createdAt)}', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey800)),
                ],
              ),
              statusBadge(statusText),
            ],
          ),
        );

    pw.Widget saleTable(InvoiceSaleSection sec) {
      final rows = <List<String>>[];
      num subtotalNet = 0;

      for (final l in sec.lines) {
        final netQty = (l.soldQty - l.returnedQty).clamp(0, double.infinity);
        final original = l.unitPrice * l.soldQty;
        final returned = l.unitPrice * l.returnedQty;
        final netTotal = original - returned;
        subtotalNet += netTotal;

        rows.add([
          l.product,
          l.soldQty.toStringAsFixed(2),
          l.returnedQty.toStringAsFixed(2),
          netQty.toStringAsFixed(2),
          fmtCurrency(l.unitPrice),
          fmtCurrency(original),
          fmtCurrency(returned),
          fmtCurrency(netTotal),
        ]);
      }

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            'Sale ID: ${sec.saleId} | Date: ${_fmtDateTime(sec.soldAt)}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Product',
              'Sold Qty',
              'Returned',
              'Net',
              'Unit Price',
              'Original Total',
              'Returned Value',
              'Net Total',
            ],
            data: rows,
            border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.6),
            headerDecoration: pw.BoxDecoration(color: PdfColors.grey800),
            headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellAlignment: pw.Alignment.centerLeft,
            headerAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Subtotal (after returns): ${fmtCurrency(subtotalNet)}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ],
      );
    }

    pw.Widget thickDivider() => pw.Container(height: 2, color: PdfColors.black);

    pw.Widget invoiceSummary() => pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Invoice Summary', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              _kv('Original Total Amount:', fmtCurrency(originalTotal)),
              _kv('Returned Value:', fmtCurrency(returnedValue)),
              _kv('Adjusted Total:', fmtCurrency(adjustedTotal)),
              _kv('Amount Paid:', fmtCurrency(amountPaid)),
              _kv('Amount Due:', fmtCurrency(amountDue)),
              _kv('Status:', statusText),
            ],
          ),
        );

    doc.addPage(
      pw.MultiPage(
        theme: theme,
        margin: const pw.EdgeInsets.fromLTRB(24, 36, 24, 32),
        pageFormat: PdfPageFormat.a4,
        header: (ctx) => pw.Column(children: [
          pw.Container(height: 3, color: PdfColors.black),
          pw.SizedBox(height: 8),
        ]),
        footer: (ctx) => _footer(ctx),
        build: (ctx) => [
          masthead(),
          pw.SizedBox(height: 14),
          pw.Text('Sales Details', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          ..._intersperse<pw.Widget>(
            sections.map((s) => saleTable(s)).toList(),
            pw.Column(children: [
              pw.SizedBox(height: 10),
              pw.Divider(color: PdfColors.grey),
              pw.SizedBox(height: 10),
            ]),
          ),
          pw.SizedBox(height: 12),
          thickDivider(),
          pw.SizedBox(height: 14),
          invoiceSummary(),
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

  static String _fmtDateTime(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  static pw.Widget _kv(String k, String v) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(text: '$k ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.TextSpan(text: v),
            ],
          ),
        ),
      );

  static List<T> _intersperse<T>(List<T> list, T separator) {
    if (list.isEmpty) return list;
    final result = <T>[];
    for (var i = 0; i < list.length; i++) {
      result.add(list[i]);
      if (i != list.length - 1) result.add(separator);
    }
    return result;
  }

  static _StatusColors _statusPalette(String statusText) {
    final s = statusText.toLowerCase();
    if (s.contains('paid')) {
      return _StatusColors(
        bg: PdfColor(0.90, 0.98, 0.92), // light green
        fg: PdfColors.green,
        border: PdfColors.green,
      );
    }
    if (s.contains('credit')) {
      return _StatusColors(
        bg: PdfColor(1.00, 0.96, 0.90), // light orange
        fg: PdfColors.orange,
        border: PdfColors.orange,
      );
    }
    return _StatusColors(
      bg: PdfColor(1.00, 0.92, 0.92), // light red
      fg: PdfColors.red,
      border: PdfColors.red,
    );
    }

  static pw.Widget _footer(pw.Context ctx) => pw.Container(
        padding: const pw.EdgeInsets.only(top: 8),
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
      );
}

class _StatusColors {
  final PdfColor bg;
  final PdfColor fg;
  final PdfColor border;
  const _StatusColors({required this.bg, required this.fg, required this.border});
}