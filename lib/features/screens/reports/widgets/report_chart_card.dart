import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sales_app/constants/sizes.dart';

enum ChartType { line, bar, pie }

class ReportChartCard extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> chartData;
  final ChartType chartType;

  const ReportChartCard({
    Key? key,
    required this.title,
    required this.chartData,
    required this.chartType,
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
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSizes.padding),
            SizedBox(
              height: 300,
              child: _buildChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    switch (chartType) {
      case ChartType.line:
        return LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) => Text(chartData.isNotEmpty ? chartData[value.toInt()]['label'] ?? '' : '', style: const TextStyle(fontSize: 10)),
                ),
              ),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 20000)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: true, border: Border.all(color: const Color(0xff37434d), width: 1)),
            lineBarsData: [
              LineChartBarData(
                spots: chartData.asMap().entries.map((entry) {
                  final double yValue = (entry.value['value'] as num?)?.toDouble() ?? 0.0;
                  return FlSpot(entry.key.toDouble(), yValue);
                }).toList(),
                isCurved: true,
                barWidth: 2,
                color: Colors.blue,
                dotData: const FlDotData(show: false),
              ),
            ],
          ),
        );
      case ChartType.bar:
        return BarChart(
          BarChartData(
            barGroups: chartData.asMap().entries.map((entry) {
              final double yValue = (entry.value['value'] as num?)?.toDouble() ?? 0.0;
              return BarChartGroupData(
                x: entry.key,
                barRods: [BarChartRodData(toY: yValue, color: Colors.blue)],
              );
            }).toList(),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) => Text(chartData.isNotEmpty ? chartData[value.toInt()]['label'] ?? '' : '', style: const TextStyle(fontSize: 10)),
                ),
              ),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
          ),
        );
      case ChartType.pie:
        return PieChart(
          PieChartData(
            sections: chartData.asMap().entries.map((entry) {
              final double pieValue = (entry.value['value'] as num?)?.toDouble() ?? 0.0;
              return PieChartSectionData(
                color: entry.value['color'],
                value: pieValue,
                title: entry.value['label'],
                radius: 100,
                titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              );
            }).toList(),
            borderData: FlBorderData(show: false),
            sectionsSpace: 0,
            centerSpaceRadius: 40,
          ),
        );
      }
  }
}
