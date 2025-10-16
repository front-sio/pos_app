import 'package:flutter/material.dart';
import 'package:sales_app/widgets/responsive_grid.dart';
import 'package:sales_app/widgets/stats_card.dart';

class ReportCardGrid extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final int responsiveGrid;

  const ReportCardGrid({
    Key? key,
    required this.data,
    this.responsiveGrid = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveGrid(
      minChildWidth: 250, // Added to ensure better wrapping
      children: data.map((item) {
        return StatCard(
          title: item['title'],
          value: item['value'],
          subtitle: item['subtitle'],
          icon: item['icon'],
          color: item['color'],
        );
      }).toList(),
    );
  }
}
