import 'package:flutter/material.dart';
import 'package:sales_app/constants/colors.dart';
import 'package:sales_app/constants/sizes.dart';

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

  @override
  Widget build(BuildContext context) {
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(AppColors.kPrimary.withOpacity(0.05)),
                columns: headers.map((header) => DataColumn(label: Text(header, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                rows: data.map((row) {
                  return DataRow(
                    cells: headers.map((header) {
                      return DataCell(Text(row[header] != null ? row[header].toString() : 'N/A'));
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
