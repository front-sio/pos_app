// features/sidebar/sidebar.dart
import 'package:flutter/material.dart';
import 'package:sales_app/rbac/rbac.dart';

final List<Map<String, dynamic>> sidebarMenu = [
  {"label": "Dashboard", "icon": Icons.dashboard_outlined},
  {"label": "Products", "icon": Icons.add_box_outlined},
  {"label": "Stock", "icon": Icons.inventory_2_outlined},
  {"label": "Purchases", "icon": Icons.shopping_cart_checkout_outlined},
  {"label": "Sales", "icon": Icons.point_of_sale_outlined},
  {"label": "Returns", "icon": Icons.keyboard_return_outlined},
  {"label": "Invoices", "icon": Icons.receipt_long_outlined},
  {"label": "Reports", "icon": Icons.bar_chart_outlined},
  {"label": "Suppliers", "icon": Icons.people_outline},
  {"label": "Customers", "icon": Icons.people_outline},
  {"label": "Users", "icon": Icons.people_outline},
  {"label": "Settings", "icon": Icons.settings_outlined},
];

class Sidebar extends StatefulWidget {
  final Function(String) onMenuSelected;
  final String activeMenu;

  const Sidebar({
    super.key,
    required this.onMenuSelected,
    required this.activeMenu,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  String _hovered = "";

  Widget _buildItem(IconData icon, String title) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isActive = widget.activeMenu == title;
    final isHovered = _hovered == title;
    final highlighted = isActive || isHovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = title),
      onExit: (_) => setState(() => _hovered = ""),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: highlighted ? cs.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          leading: Icon(icon, color: highlighted ? cs.primary : cs.onSurface),
          title: Text(
            title,
            style: TextStyle(color: highlighted ? cs.primary : cs.onSurface),
          ),
          onTap: () => widget.onMenuSelected(title),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter menus based on RBAC permissions
    final filteredMenu = sidebarMenu.where((m) {
      final label = m['label'] as String;
      return Rbac.canMenu(context, label);
    }).toList();

    return Container(
      width: 250,
      color: Theme.of(context).colorScheme.surface,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: filteredMenu
            .map((m) => _buildItem(m['icon'] as IconData, m['label'] as String))
            .toList(),
      ),
    );
  }
}
