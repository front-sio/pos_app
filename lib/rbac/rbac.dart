import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/features/auth/logic/auth_bloc.dart';
import 'package:sales_app/features/auth/logic/auth_state.dart';

class Rbac {
  static const Map<String, String> menuPermissions = {
    "Dashboard": "dashboard:view",
    "Profile": "profile:view",
    "Users": "users:view",
    "Sales": "sales:view",
    "Stock": "stock:view",
    "Customers": "customers:view",
    "Suppliers": "suppliers:view",
    "Products": "products:view",
    "Purchases": "purchases:view",
    "Invoices": "invoices:view",
    "Profit Tracker": "profits:view",
    "Reports": "reports:view",
    "Settings": "settings:view",
    "Returns": "returns:view",
  };

  static bool can(BuildContext context, String permission) {
    if (permission.isEmpty) return true;
    final st = context.read<AuthBloc>().state;
    if (st is! AuthAuthenticated) return false;
    if (st.isSuperuser) return true;
    final permsLower = st.permissions.map((p) => p.toLowerCase()).toSet();
    return permsLower.contains(permission.toLowerCase());
  }

  static bool canMenu(BuildContext context, String menuLabel) {
    final perm = menuPermissions[menuLabel] ?? '';
    return can(context, perm);
  }
}
