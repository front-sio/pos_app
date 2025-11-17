import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart' as xls;
import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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

class PartyInfo {
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final String? taxId;
  final String? website;

  const PartyInfo({
    required this.name,
    this.address,
    this.phone,
    this.email,
    this.taxId,
    this.website,
  });

  bool get isEmpty =>
      name.trim().isEmpty &&
      (address == null || address!.trim().isEmpty) &&
      (phone == null || phone!.trim().isEmpty) &&
      (email == null || email!.trim().isEmpty);
}

class _StatusColors {
  final PdfColor bg;
  final PdfColor fg;
  final PdfColor border;
  const _StatusColors({required this.bg, required this.fg, required this.border});
}

class ExportService {
  static const PdfColor brandPrimary = PdfColor(0.0, 0.65, 0.67);
  static const PdfColor brandAccent = PdfColor(0.13, 0.59, 0.95);
  static const PdfColor headerBg = PdfColor(0.15, 0.15, 0.15);
  static const PdfColor successGreen = PdfColor(0.15, 0.68, 0.38);
  static const PdfColor warningOrange = PdfColor(0.96, 0.49, 0.00);
  static const PdfColor dangerRed = PdfColor(0.95, 0.30, 0.25);
  static const PdfColor lightGrey = PdfColor(0.97, 0.97, 0.97);
  static const PdfColor accentGrey = PdfColor(0.93, 0.93, 0.93);

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
            pw.Text(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: headerBg)),
            if (subtitle != null && subtitle.isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 2),
                child: pw.Text(subtitle, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
              ),
            pw.SizedBox(height: 10),
          ],
        ),
        footer: (ctx) => _buildFooter(ctx),
        build: (ctx) => [
          if (extraTopWidgets.isNotEmpty) ...extraTopWidgets,
          pw.TableHelper.fromTextArray(
            context: ctx,
            headers: headers,
            data: rows
                .map((r) => r.map((cell) => cell is num ? cell.toString() : (cell?.toString() ?? '')).toList())
                .toList(),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 11),
            headerDecoration: const pw.BoxDecoration(color: headerBg),
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerAlignment: pw.Alignment.center,
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    await _saveBytes(fileName, Uint8List.fromList(bytes), extOverride: 'pdf', mime: MimeType.pdf);
  }

  static Future<void> exportInvoicePdf({
    required String fileName,
    required int invoiceId,
    required String customerName,
    required DateTime createdAt,
    required String statusText,
    required List<InvoiceSaleSection> sections,
    required num amountPaid,
    required num amountDue,
    required String Function(num) fmtCurrency,
    PartyInfo? seller,
    PartyInfo? customer,
    Uint8List? companyLogoBytes,
    List<String>? paymentNotes,
    String? termsAndConditions,
    String? invoicePrefix,
  }) async {
    final doc = pw.Document();
    final theme = pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
    );

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
    final palette = _statusPalette(statusText);

    pw.Widget topBanner() {
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 20),
        decoration: pw.BoxDecoration(
          gradient: pw.LinearGradient(
            colors: [brandPrimary, brandAccent],
            begin: pw.Alignment.topLeft,
            end: pw.Alignment.bottomRight,
          ),
          borderRadius: pw.BorderRadius.circular(12),
          boxShadow: [
            pw.BoxShadow(blurRadius: 8, offset: const PdfPoint(0, 2), color: PdfColors.grey500),
          ],
        ),
        padding: const pw.EdgeInsets.fromLTRB(24, 20, 24, 20),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'INVOICE',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 24,
                    letterSpacing: 1.5,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(
                        text: '${invoicePrefix ?? 'INV-'}$invoiceId',
                        style: pw.TextStyle(color: PdfColors.white, fontSize: 14, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.TextSpan(
                        text: '   •   ${_fmtDateTime(createdAt)}',
                        style: pw.TextStyle(color: PdfColors.white, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.Row(
              children: [
                if (companyLogoBytes != null)
                  pw.Container(
                    width: 54,
                    height: 54,
                    margin: const pw.EdgeInsets.only(right: 12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(8),
                      boxShadow: [pw.BoxShadow(blurRadius: 4, offset: const PdfPoint(0, 1))],
                    ),
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Image(pw.MemoryImage(companyLogoBytes), fit: pw.BoxFit.contain),
                    ),
                  ),
                if (seller != null && seller.name.isNotEmpty)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        seller.name.toUpperCase(),
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      if ((seller.address ?? '').isNotEmpty)
                        pw.Text(
                          seller.address ?? '',
                          style: pw.TextStyle(color: PdfColors.white, fontSize: 9),
                        ),
                      if ((seller.website ?? '').isNotEmpty)
                        pw.Text(
                          seller.website ?? '',
                          style: pw.TextStyle(color: PdfColors.white, fontSize: 9, decoration: pw.TextDecoration.underline),
                        ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      );
    }

    pw.Widget headerInfo() {
      final left = _buildInfoCard(
        title: 'BILL TO',
        lines: [
          _kvInline('Name', (customer?.name.isNotEmpty ?? false) ? customer!.name : customerName, bold: true),
          if ((customer?.taxId ?? '').isNotEmpty) _kvInline('Tax ID', customer!.taxId ?? ''),
          if ((customer?.phone ?? '').isNotEmpty) _kvInline('Phone', customer!.phone ?? ''),
          if ((customer?.email ?? '').isNotEmpty) _kvInline('Email', customer!.email ?? ''),
          if ((customer?.address ?? '').isNotEmpty) _kvInline('Address', customer!.address ?? ''),
        ],
      );

      final right = _buildInfoCard(
        title: 'PAYMENT INFO',
        lines: [
          _kvColoredInline('Status', statusText, palette.fg, bold: true),
          if (paymentNotes != null && paymentNotes.isNotEmpty)
            ...paymentNotes.map((e) => pw.Text(e, style: const pw.TextStyle(fontSize: 10))),
          _kvInline('Invoice Date', _fmtDateTime(createdAt)),
        ],
      );

      return pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(child: left),
          pw.SizedBox(width: 20),
          pw.Expanded(child: right),
        ],
      );
    }

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
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [_darkenColor(brandPrimary, 0.1), _darkenColor(brandAccent, 0.1)],
              ),
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(6),
                topRight: pw.Radius.circular(6),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Sale ID: ${sec.saleId}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                    color: PdfColors.white,
                  ),
                ),
                pw.Text(
                  'Date: ${_fmtDateTime(sec.soldAt)}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          ),
          buildModernItemTable(
            headers: const [
              'Product',
              'Sold',
              'Returned',
              'Net Qty',
              'Unit Price',
              'Original',
              'Returned Value',
              'Net Total',
            ],
            rows: rows,
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: pw.BoxDecoration(
              color: accentGrey,
              borderRadius: pw.BorderRadius.only(
                bottomLeft: pw.Radius.circular(6),
                bottomRight: pw.Radius.circular(6),
              ),
            ),
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(
                      text: 'Section Subtotal: ',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                    ),
                    pw.TextSpan(
                      text: fmtCurrency(subtotalNet),
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: brandPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    pw.Widget totalsPanel() {
      return pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          borderRadius: pw.BorderRadius.circular(10),
          border: pw.Border.all(color: accentGrey, width: 2),
          color: lightGrey,
        ),
        child: pw.Column(
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(height: 2),
                      kvLargeModern('Original Total', fmtCurrency(originalTotal), color: headerBg),
                      pw.SizedBox(height: 6),
                      kvLargeModern('Less: Returns', fmtCurrency(returnedValue), color: dangerRed),
                      pw.SizedBox(height: 8),
                      pw.Container(
                        height: 1.5,
                        color: brandPrimary,
                        margin: const pw.EdgeInsets.symmetric(vertical: 6),
                      ),
                      kvLargeModern('Adjusted Total', fmtCurrency(adjustedTotal), bold: true, color: brandPrimary, fontSize: 13),
                    ],
                  ),
                ),
                pw.SizedBox(width: 24),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(height: 2),
                      kvLargeModern('Amount Paid', fmtCurrency(amountPaid), color: successGreen, bold: true),
                      pw.SizedBox(height: 6),
                      kvLargeModern(
                        'Outstanding',
                        fmtCurrency(amountDue),
                        color: amountDue > 0 ? warningOrange : successGreen,
                        bold: true,
                      ),
                      pw.SizedBox(height: 8),
                      pw.Container(
                        height: 1.5,
                        color: palette.fg,
                        margin: const pw.EdgeInsets.symmetric(vertical: 6),
                      ),
                      kvLargeModern('Status', statusText.toUpperCase(), color: palette.fg, bold: true, fontSize: 13),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    pw.Widget thankYouBlock() {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(height: 12),
          pw.Text(
            'THANK YOU FOR YOUR BUSINESS',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: brandPrimary),
          ),
          if ((termsAndConditions ?? '').isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: lightGrey,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: accentGrey),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Terms & Conditions', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.SizedBox(height: 4),
                  pw.Text(termsAndConditions ?? '', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                ],
              ),
            ),
          ],
          if (seller != null && !seller.isEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Divider(color: accentGrey, height: 1.5),
            pw.SizedBox(height: 10),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Company Contact', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: headerBg)),
                      pw.SizedBox(height: 4),
                      if ((seller.phone ?? '').isNotEmpty)
                        pw.Text('Tel: ${seller.phone}', style: const pw.TextStyle(fontSize: 9)),
                      if ((seller.email ?? '').isNotEmpty)
                        pw.Text('Email: ${seller.email}', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if ((seller.address ?? '').isNotEmpty) ...[
                        pw.Text('Address', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: headerBg)),
                        pw.SizedBox(height: 2),
                        pw.Text(seller.address ?? '', style: const pw.TextStyle(fontSize: 9)),
                      ],
                      if ((seller.taxId ?? '').isNotEmpty) ...[
                        pw.SizedBox(height: 6),
                        pw.Text('Tax ID: ${seller.taxId}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    }

    final sectionWidgets = sections.map((s) => saleTable(s)).toList();
    final separatedSections = _intersperse<pw.Widget>(
      sectionWidgets,
      pw.Column(children: [
        pw.SizedBox(height: 14),
        pw.Divider(color: accentGrey, height: 1.5),
        pw.SizedBox(height: 14),
      ]),
    );

    doc.addPage(
      pw.MultiPage(
        theme: theme,
        margin: const pw.EdgeInsets.fromLTRB(28, 20, 28, 28),
        pageFormat: PdfPageFormat.a4,
        header: (ctx) => _buildTopRule(),
        footer: (ctx) => _buildFooterInvoice(ctx),
        build: (ctx) => [
          topBanner(),
          pw.SizedBox(height: 16),
          headerInfo(),
          pw.SizedBox(height: 18),
          pw.Text('SALES DETAILS', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: headerBg)),
          pw.SizedBox(height: 10),
          ...separatedSections,
          pw.SizedBox(height: 18),
          totalsPanel(),
          pw.SizedBox(height: 20),
          thankYouBlock(),
        ],
      ),
    );

    final bytes = await doc.save();
    await _saveBytes(fileName, Uint8List.fromList(bytes), extOverride: 'pdf', mime: MimeType.pdf);
  }

  /// Generate invoice PDF bytes without saving (for email attachment)
  /// Simplified version for fast generation
  static Future<Uint8List> generateInvoicePdfBytes({
    required int invoiceId,
    required String customerName,
    required DateTime createdAt,
    required String statusText,
    required List<InvoiceSaleSection> sections,
    required num amountPaid,
    required num amountDue,
    required String Function(num) fmtCurrency,
    PartyInfo? seller,
    PartyInfo? customer,
    Uint8List? companyLogoBytes,
    List<String>? paymentNotes,
    String? termsAndConditions,
    String? invoicePrefix,
  }) async {
    final doc = pw.Document();

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

    // Build simplified PDF for speed
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              color: PdfColors.green,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'INVOICE',
                    style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  ),
                  pw.Text(
                    '#${invoicePrefix ?? ''}$invoiceId',
                    style: pw.TextStyle(fontSize: 20, color: PdfColors.white),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Customer & Date Info
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Bill To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(customerName, style: const pw.TextStyle(fontSize: 16)),
                    if (customer?.email != null) pw.Text(customer!.email!),
                    if (customer?.phone != null) pw.Text(customer!.phone!),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Date: ${createdAt.toString().split(' ')[0]}'),
                    pw.Text('Status: $statusText', 
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: statusText.toLowerCase() == 'paid' ? PdfColors.green : PdfColors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 30),
            
            // Items Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Product', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                // Items
                ...sections.expand((section) => section.lines.map((line) => pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(line.product)),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(line.soldQty.toStringAsFixed(0))),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(fmtCurrency(line.unitPrice))),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(fmtCurrency(line.unitPrice * line.soldQty))),
                  ],
                ))).toList(),
              ],
            ),
            pw.SizedBox(height: 20),
            
            // Totals
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                width: 250,
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Subtotal:'),
                        pw.Text(fmtCurrency(adjustedTotal)),
                      ],
                    ),
                    pw.Divider(),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                        pw.Text(fmtCurrency(adjustedTotal), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                    if (amountPaid > 0) ...[
                      pw.SizedBox(height: 10),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Paid:'),
                          pw.Text(fmtCurrency(amountPaid), style: const pw.TextStyle(color: PdfColors.green)),
                        ],
                      ),
                    ],
                    if (amountDue > 0) ...[
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Due:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text(fmtCurrency(amountDue), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Footer
            if (termsAndConditions != null) ...[
              pw.SizedBox(height: 40),
              pw.Text('Terms & Conditions:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(termsAndConditions, style: const pw.TextStyle(fontSize: 10)),
            ],
          ],
        ),
      ),
    );

    final bytes = await doc.save();
    return Uint8List.fromList(bytes);
  }

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

  static pw.Widget kvLargeModern(
    String k,
    String v, {
    bool bold = false,
    PdfColor? color,
    double fontSize = 11,
  }) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(
                text: '$k: ',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: fontSize,
                  color: headerBg,
                ),
              ),
              pw.TextSpan(
                text: v,
                style: pw.TextStyle(
                  fontSize: fontSize,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: color ?? headerBg,
                ),
              ),
            ],
          ),
        ),
      );

  static pw.Widget buildModernItemTable({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    final tableRows = <pw.TableRow>[];

    tableRows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: headerBg),
        children: headers
            .asMap()
            .entries
            .map((entry) {
              final isNumeric = entry.key > 3;
              return pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                alignment: isNumeric ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
                child: pw.Text(
                  entry.value,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                    color: PdfColors.white,
                  ),
                ),
              );
            })
            .toList(),
      ),
    );

    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      final isEven = i % 2 == 0;

      tableRows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: isEven ? lightGrey : PdfColors.white,
            border: pw.Border(
              bottom: pw.BorderSide(
                color: PdfColors.grey300,
                width: 0.5,
              ),
            ),
          ),
          children: row
              .asMap()
              .entries
              .map((entry) {
                final isNumeric = entry.key > 3;
                final value = entry.value;

                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                  alignment: isNumeric ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
                  child: pw.Text(
                    value,
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: isNumeric ? brandPrimary : headerBg,
                      fontWeight: isNumeric ? pw.FontWeight.bold : pw.FontWeight.normal,
                    ),
                  ),
                );
              })
              .toList(),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder(
        top: const pw.BorderSide(color: headerBg, width: 0.7),
        bottom: const pw.BorderSide(color: headerBg, width: 0.7),
        left: const pw.BorderSide(color: headerBg, width: 0.7),
        right: const pw.BorderSide(color: headerBg, width: 0.7),
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.2),
        1: const pw.FlexColumnWidth(1.1),
        2: const pw.FlexColumnWidth(1.1),
        3: const pw.FlexColumnWidth(1.1),
        4: const pw.FlexColumnWidth(1.3),
        5: const pw.FlexColumnWidth(1.3),
        6: const pw.FlexColumnWidth(1.4),
        7: const pw.FlexColumnWidth(1.4),
      },
      children: tableRows,
    );
  }

  static pw.Widget _buildInfoCard({required String title, required List<pw.Widget> lines}) => pw.Container(
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: accentGrey, width: 1.2),
          boxShadow: [pw.BoxShadow(blurRadius: 4, offset: const PdfPoint(0, 1), color: PdfColors.grey500)],
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: headerBg)),
            pw.SizedBox(height: 8),
            ...lines,
          ],
        ),
      );

  static pw.Widget _buildTopRule() => pw.Column(children: [
        pw.Container(
          height: 3,
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(colors: [brandPrimary, brandAccent]),
          ),
        ),
        pw.SizedBox(height: 8),
      ]);

  static pw.Widget _buildFooter(pw.Context ctx) => pw.Container(
        padding: const pw.EdgeInsets.only(top: 8),
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
      );

  static pw.Widget _buildFooterInvoice(pw.Context ctx) => pw.Column(
        children: [
          pw.Divider(color: accentGrey, height: 1.5),
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 6),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  '© ${DateTime.now().year} All rights reserved',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
                pw.Text(
                  'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      );

  static pw.Widget _kvInline(String label, String value, {bool bold = false}) => pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: pw.TextStyle(
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                fontSize: 10,
                color: headerBg,
              ),
            ),
            pw.TextSpan(text: value, style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      );

  static pw.Widget _kvColoredInline(String label, String value, PdfColor color, {bool bold = false}) => pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, fontSize: 10, color: headerBg),
            ),
            pw.TextSpan(text: value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: color)),
          ],
        ),
      );

  static _StatusColors _statusPalette(String statusText) {
    final s = statusText.toLowerCase();
    if (s.contains('paid')) {
      return _StatusColors(
        bg: const PdfColor(0.90, 0.98, 0.92),
        fg: successGreen,
        border: successGreen,
      );
    }
    if (s.contains('credit')) {
      return _StatusColors(
        bg: const PdfColor(1.00, 0.96, 0.90),
        fg: warningOrange,
        border: warningOrange,
      );
    }
    return _StatusColors(
      bg: const PdfColor(1.00, 0.92, 0.92),
      fg: dangerRed,
      border: dangerRed,
    );
  }

  static List<T> _intersperse<T>(List<T> items, T separator) {
    if (items.isEmpty) return items;
    final out = <T>[];
    for (var i = 0; i < items.length; i++) {
      out.add(items[i]);
      if (i != items.length - 1) out.add(separator);
    }
    return out;
  }

  static PdfColor _darkenColor(PdfColor color, double factor) {
    final clamped = (double f) => (f * (1 - factor)).clamp(0.0, 1.0).toDouble();
    return PdfColor(clamped(color.red), clamped(color.green), clamped(color.blue));
  }
}