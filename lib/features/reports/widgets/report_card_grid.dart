import 'package:flutter/material.dart';
import 'package:sales_app/constants/sizes.dart';

/// Responsive grid of small report cards.
///
/// Expects `data` to be a list of maps with keys:
/// - title (String)
/// - value (String)
/// - color (Color) optional
/// - icon (IconData) optional
///
/// The widget is defensive: missing icon/color/value are handled with sensible defaults.
class ReportCardGrid extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final int responsiveGrid;
  final double spacing;
  final double runSpacing;
  const ReportCardGrid({
    Key? key,
    required this.data,
    this.responsiveGrid = 2,
    this.spacing = AppSizes.padding,
    this.runSpacing = AppSizes.padding,
  }) : super(key: key);

  IconData _iconFromDynamic(dynamic icon) {
    if (icon == null) return Icons.insert_chart_outlined;
    if (icon is IconData) return icon;
    // optionally allow string names in future; fallback to default
    return Icons.insert_chart_outlined;
  }

  Color _colorFromDynamic(dynamic c, BuildContext context) {
    if (c == null) {
      return Theme.of(context).colorScheme.primary;
    }
    if (c is Color) return c;
    // allow hex int or string like '#FF00FF'
    if (c is int) return Color(c);
    if (c is String) {
      try {
        final cleaned = c.replaceAll('#', '');
        final value = int.parse(cleaned, radix: 16);
        if (cleaned.length == 6) {
          return Color(0xFF000000 | value);
        }
        return Color(value);
      } catch (_) {
        return Theme.of(context).colorScheme.primary;
      }
    }
    return Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final cards = data.map((item) {
      final title = (item['title'] ?? '') as String;
      final value = (item['value'] ?? '') as String;
      final icon = _iconFromDynamic(item['icon']);
      final color = _colorFromDynamic(item['color'], context);

      return _ReportCard(
        title: title,
        value: value,
        icon: icon,
        color: color,
      );
    }).toList(growable: false);

    return LayoutBuilder(builder: (context, constraints) {
      final cols = responsiveGrid.clamp(1, 6);
      return GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        crossAxisCount: cols,
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing,
        childAspectRatio: 3.4,
        children: cards,
      );
    });
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _ReportCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle = Theme.of(context).textTheme.bodySmall!.copyWith(color: Theme.of(context).textTheme.bodySmall!.color?.withOpacity(0.8));
    final TextStyle valueStyle = Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold);
    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppSizes.padding),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: titleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(value, style: valueStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}