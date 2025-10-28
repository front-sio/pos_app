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
    return LayoutBuilder(builder: (ctx, constraints) {
      final isMobile = constraints.maxWidth < 600;
      final baseHeight = isMobile ? 220.0 : (constraints.maxWidth < 1000 ? 280.0 : 320.0);

      // For line/bar, make the chart horizontally scrollable when there are many data points.
      final points = chartData.length;
      final widthPerPoint = isMobile ? 56.0 : 46.0;
      final contentWidth = chartType == ChartType.pie
          ? constraints.maxWidth
          : points <= 0
              ? constraints.maxWidth
              : (points * widthPerPoint).clamp(constraints.maxWidth, 2000.0);

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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSizes.padding),
              if (chartData.isEmpty)
                SizedBox(
                  height: baseHeight,
                  child: Center(
                    child: Text('No data', style: Theme.of(context).textTheme.bodyMedium),
                  ),
                )
              else
                SizedBox(
                  height: baseHeight,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: contentWidth > constraints.maxWidth ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
                    child: SizedBox(
                      width: contentWidth,
                      child: _buildChart(context),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildChart(BuildContext context) {
    switch (chartType) {
      case ChartType.line:
        return _buildLineChart(context);
      case ChartType.bar:
        return _buildBarChart(context);
      case ChartType.pie:
        return _buildPieChart(context);
    }
  }

  Widget _buildLineChart(BuildContext context) {
    final spots = <FlSpot>[];
    double maxY = 0;
    for (var i = 0; i < chartData.length; i++) {
      final yValue = (chartData[i]['value'] as num?)?.toDouble() ?? 0.0;
      spots.add(FlSpot(i.toDouble(), yValue));
      if (yValue > maxY) maxY = yValue;
    }
    final interval = _niceInterval(maxY);

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, horizontalInterval: interval, drawVerticalLine: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              reservedSize: 30,
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= chartData.length) return const SizedBox.shrink();
                final label = (chartData[idx]['label'] ?? '').toString();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _shorten(label),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(_compactNumber(value), style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: const Color(0xff37434d), width: 1)),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 2,
            color: Colors.blue,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(BuildContext context) {
    final groups = <BarChartGroupData>[];
    double maxY = 0;
    for (var i = 0; i < chartData.length; i++) {
      final yValue = (chartData[i]['value'] as num?)?.toDouble() ?? 0.0;
      if (yValue > maxY) maxY = yValue;
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [BarChartRodData(toY: yValue, color: Colors.blue)],
        ),
      );
    }
    final interval = _niceInterval(maxY);

    return BarChart(
      BarChartData(
        barGroups: groups,
        maxY: maxY == 0 ? 1 : maxY,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              reservedSize: 30,
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= chartData.length) return const SizedBox.shrink();
                final label = (chartData[idx]['label'] ?? '').toString();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(_shorten(label), style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(_compactNumber(value), style: const TextStyle(fontSize: 10)),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true, horizontalInterval: interval, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildPieChart(BuildContext context) {
    final sections = chartData.asMap().entries.map((entry) {
      final v = (entry.value['value'] as num?)?.toDouble() ?? 0.0;
      final color = entry.value['color'] as Color? ??
          Colors.primaries[entry.key % Colors.primaries.length];
      final label = (entry.value['label'] ?? '').toString();
      return PieChartSectionData(
        color: color,
        value: v,
        title: _shorten(label),
        radius: 100,
        titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        borderData: FlBorderData(show: false),
        sectionsSpace: 0,
        centerSpaceRadius: 40,
      ),
    );
  }

  double _niceInterval(double maxY) {
    if (maxY <= 0) return 1;
    final magnitude = (maxY / 4).clamp(1, double.infinity);
    final pow10 = _pow10((magnitude).toStringAsFixed(0).length - 1);
    double normalized = (magnitude / pow10).ceilToDouble();
    if (normalized > 5) normalized = 10;
    else if (normalized > 2) normalized = 5;
    else if (normalized > 1) normalized = 2;
    else normalized = 1;
    return normalized * pow10;
  }

  double _pow10(int exp) {
    double r = 1;
    for (int i = 0; i < exp; i++) {
      r *= 10;
    }
    return r;
  }

  String _shorten(String s) {
    if (s.length <= 8) return s;
    return '${s.substring(0, 6)}…';
  }

  String _compactNumber(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}