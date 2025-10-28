import 'package:flutter/material.dart';
import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/constants/sizes.dart';
import 'package:sales_app/utils/currency.dart';

class ReportDataTable extends StatelessWidget {
  final String title;
  final List<String> headers;
  final List<Map<String, dynamic>> data;

  const ReportDataTable({
    Key? key,
    required this.title,
    required this.headers,
    required this.data,
  }) : super(key: key);

  bool _headerHintsCurrency(String header) {
    final h = header.toLowerCase();
    return h.contains('revenue') ||
        h.contains('cost') ||
        h.contains('profit') ||
        h.contains('avg') ||
        h.contains('value') ||
        h.contains('amount') ||
        h.contains('expense') ||
        h.contains('net') ||
        h.contains('stockvalue') ||
        h.contains('spend');
  }

  String _formatCell(BuildContext context, String header, dynamic value) {
    if (value == null) return 'N/A';
    if (value is num && _headerHintsCurrency(header)) {
      return CurrencyFmt.format(context, value);
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final isMobile = constraints.maxWidth < 600;

      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.cardRadius)),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSizes.padding),
              Scrollbar(
                thumbVisibility: false,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      columnSpacing: isMobile ? 12 : 24,
                      headingRowHeight: isMobile ? 36 : 48,
                      dataRowMinHeight: isMobile ? 36 : 48,
                      dataRowMaxHeight: isMobile ? 48 : 56,
                      headingRowColor: MaterialStateProperty.all(AppColors.kPrimary.withOpacity(0.05)),
                      columns: headers
                          .map(
                            (header) => DataColumn(
                              label: Text(
                                header,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 12 : 14,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      rows: data.map((row) {
                        return DataRow(
                          cells: headers
                              .map(
                                (header) => DataCell(
                                  ConstrainedBox(
                                    constraints: BoxConstraints(maxWidth: isMobile ? 140 : 260),
                                    child: Text(
                                      _formatCell(context, header, row[header]),
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: isMobile ? 12 : 14),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}