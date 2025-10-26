import 'package:flutter/material.dart';
import 'package:sales_app/rbac/rbac.dart';

final List<Map<String, dynamic>> sidebarMenu = [
  {"label": "Dashboard", "icon": Icons.dashboard_outlined},
  {"label": "Products", "icon": Icons.add_box_outlined},
  {"label": "Categories", "icon": Icons.category_outlined},
  {"label": "Units", "icon": Icons.straighten},
  {"label": "Stock", "icon": Icons.inventory_2_outlined},
  {"label": "Purchases", "icon": Icons.shopping_cart_checkout_outlined},
  {"label": "Sales", "icon": Icons.point_of_sale_outlined},
  {"label": "Returns", "icon": Icons.keyboard_return_outlined},
  {"label": "Invoices", "icon": Icons.receipt_long_outlined},
  {"label": "Expenses", "icon": Icons.account_balance_wallet_outlined}, // Always visible
  {"label": "Reports", "icon": Icons.bar_chart_outlined},
  {"label": "Suppliers", "icon": Icons.people_outline},
  {"label": "Customers", "icon": Icons.people_outline},
  {"label": "Users", "icon": Icons.people_outline},
  {"label": "Settings", "icon": Icons.settings_outlined},
];

const Map<String, String> _menuPermissions = {
  "Dashboard": "dashboard:view",
  "Products": "products:view",
  "Categories": "categories:view",
  "Units": "units:view",
  "Stock": "stock:view",
  "Purchases": "purchases:view",
  "Sales": "sales:view",
  "Returns": "returns:view",
  "Invoices": "invoices:view",
  "Expenses": "expenses:view",
  "Reports": "reports:view",
  "Suppliers": "suppliers:view",
  "Customers": "customers:view",
  "Users": "users:view",
  "Settings": "settings:view",
};

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
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: highlighted ? cs.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          dense: true,
          leading: Icon(icon, color: highlighted ? cs.primary : cs.onSurface),
          title: Text(
            title,
            style: TextStyle(
              color: highlighted ? cs.primary : cs.onSurface,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          onTap: () => widget.onMenuSelected(title),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredMenu = sidebarMenu.where((menu) {
      final label = (menu['label'] as String?) ?? '';

      // Always show Dashboard and Expenses to all users
      if (label == "Dashboard" || label == "Expenses") return true;

      final perm = _menuPermissions[label];
      final allowedByExplicitPerm = perm == null ? true : Rbac.can(context, perm);
      final allowedByMenuHelper = Rbac.canMenu(context, label);
      return allowedByExplicitPerm && allowedByMenuHelper;
    }).toList();

    return Container(
      width: 250,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Main Menu",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: filteredMenu
                  .map((menu) => _buildItem(menu['icon'] as IconData, menu['label'] as String))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}