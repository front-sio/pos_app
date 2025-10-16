import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/features/auth/logic/auth_bloc.dart';
import 'package:sales_app/features/auth/logic/auth_event.dart';
import 'package:sales_app/features/auth/logic/auth_state.dart';
import '../constants/sizes.dart';

// Sidebar menu constants
final List<Map<String, dynamic>> sidebarMenu = [
  {
    "label": "Dashboard",
    "icon": Icons.dashboard_outlined,
    "route": "/dashboard",
  },
  {
    "label": "Products",
    "icon": Icons.add_box_outlined,
    "route": "/products",
  },
  {
    "label": "Stock",
    "icon": Icons.inventory_2_outlined,
    "route": "/stock",
  },
  {
    "label": "Purchases",
    "icon": Icons.shopping_cart_checkout_outlined,
    "route": "/purchases",
  },
  {
    "label": "Sales",
    "icon": Icons.point_of_sale_outlined,
    "route": "/sales",
  },
  
  {
    "label": "Returns",
    "icon": Icons.keyboard_return_outlined,
    "route": "/returns",
  },
  {
    "label": "Invoices",
    "icon": Icons.receipt_long_outlined,
    "route": "/invoices",
  },
  {
    "label": "Reports",
    "icon": Icons.bar_chart_outlined,
    "route": "/reports",
  },
  {
    "label": "Suppliers",
    "icon": Icons.people_outline,
    "route": "/suppliers",
  },
  {
    "label": "Customers",
    "icon": Icons.people_outline,
    "route": "/customers",
  },
  {
    "label": "Users",
    "icon": Icons.people_outline,
    "route": "/users",
  },
  {
    "label": "Settings",
    "icon": Icons.settings_outlined,
    "route": "/settings",
  },
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

  Widget _buildItem(IconData icon, String title, String route) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isActive = widget.activeMenu == title;
    final isHovered = _hovered == title;

    final bool highlighted = isActive || isHovered;
    final Color itemTextColor = highlighted ? cs.onPrimary : cs.onSurface.withOpacity(0.65);
    final Color itemIconColor = itemTextColor;

    final BoxDecoration decoration = highlighted
        ? BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cs.primary.withOpacity(0.95),
                cs.primaryContainer.withOpacity(0.85),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
          )
        : BoxDecoration(
            color: isHovered ? cs.primary.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
          );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = title),
      onExit: (_) => setState(() => _hovered = ""),
      child: AnimatedContainer(
        duration: AppSizes.shortAnimation,
        curve: Curves.easeInOut,
        decoration: decoration,
        margin: const EdgeInsets.symmetric(
          horizontal: AppSizes.smallPadding,
          vertical: AppSizes.smallPadding / 2,
        ),
        child: ListTile(
          leading: Icon(icon, color: itemIconColor, size: AppSizes.normalIcon),
          title: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: itemTextColor,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          onTap: () => widget.onMenuSelected(title),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSizes.padding,
            vertical: AppSizes.smallPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border(
          right: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.padding),
              children: sidebarMenu
                  .map((menu) =>
                      _buildItem(menu['icon'], menu['label'], menu['route']))
                  .toList(),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSizes.padding),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white10 : Colors.black12,
                  width: 1,
                ),
              ),
            ),
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is AuthAuthenticated) {
                  return Row(
                    children: [
                      CircleAvatar(
                        radius: AppSizes.avatarSize / 2,
                        backgroundColor: cs.primary,
                        child: Icon(
                          Icons.person_outline,
                          color: cs.onPrimary,
                          size: AppSizes.normalIcon,
                        ),
                      ),
                      const SizedBox(width: AppSizes.padding),
                      Expanded(
                        child: Text(
                          "${state.firstName} ${state.lastName}",
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Logout',
                        icon: Icon(
                          Icons.logout_outlined,
                          color: cs.onSurface.withOpacity(0.7),
                          size: AppSizes.normalIcon,
                        ),
                        onPressed: () {
                          context.read<AuthBloc>().add(LogoutRequested());
                        },
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}