import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/features/auth/logic/auth_bloc.dart';
import 'package:sales_app/features/auth/logic/auth_state.dart';

/// RBAC (Role-Based Access Control) helper for Flutter UI.
///
/// This ensures menus, buttons, and pages are only visible or accessible
/// if the authenticated user has the required permission.
class Rbac {
  /// Mapping between app menu labels and their required backend permissions.
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

  /// Checks if the current user has a specific permission.
  ///
  /// If `isSuperuser` is true, all permissions are automatically granted.
  static bool can(BuildContext context, String permission) {
    if (permission.isEmpty) return true;

    final state = context.read<AuthBloc>().state;

    if (state is! AuthAuthenticated) return false;

    // Superusers bypass all permission checks
    if (state.isSuperuser) return true;

    // Normalize permissions to lowercase for case-insensitive checks
    final perms = state.permissions.map((p) => p.toLowerCase()).toSet();
    return perms.contains(permission.toLowerCase());
  }

  /// Shortcut for checking if a menu item should be shown.
  ///
  /// Example:
  /// ```dart
  /// if (Rbac.canMenu(context, "Sales")) { ... }
  /// ```
  static bool canMenu(BuildContext context, String menuLabel) {
    final perm = menuPermissions[menuLabel] ?? '';
    return can(context, perm);
  }

  /// Optional helper: checks if user has **any** of several permissions.
  ///
  /// Example:
  /// ```dart
  /// if (Rbac.canAny(context, ["sales:view", "sales:create"])) { ... }
  /// ```
  static bool canAny(BuildContext context, List<String> permissions) {
    if (permissions.isEmpty) return true;
    final state = context.read<AuthBloc>().state;

    if (state is! AuthAuthenticated) return false;
    if (state.isSuperuser) return true;

    final perms = state.permissions.map((p) => p.toLowerCase()).toSet();
    return permissions.any((p) => perms.contains(p.toLowerCase()));
  }

  /// Optional helper: checks if user has **all** of several permissions.
  static bool canAll(BuildContext context, List<String> permissions) {
    if (permissions.isEmpty) return true;
    final state = context.read<AuthBloc>().state;

    if (state is! AuthAuthenticated) return false;
    if (state.isSuperuser) return true;

    final perms = state.permissions.map((p) => p.toLowerCase()).toSet();
    return permissions.every((p) => perms.contains(p.toLowerCase()));
  }
}
