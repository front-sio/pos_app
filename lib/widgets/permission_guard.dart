import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sales_app/features/auth/logic/auth_bloc.dart';
import 'package:sales_app/features/auth/logic/auth_state.dart';

class PermissionGuard extends StatelessWidget {
  final String? permission; // require a single permission
  final List<String>? anyOf; // or any in this list
  final String? role; // or a specific role
  final Widget child;
  final Widget? fallback;

  const PermissionGuard({
    super.key,
    this.permission,
    this.anyOf,
    this.role,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AuthBloc>().state;
    if (st is! AuthAuthenticated) {
      return fallback ?? const SizedBox.shrink();
    }

    if (st.isSuperuser) return child;

    bool ok = false;

    if (permission != null) {
      ok = st.hasPermission(permission!);
    }
    if (!ok && anyOf != null && anyOf!.isNotEmpty) {
      ok = st.hasAnyPermission(anyOf!);
    }
    if (!ok && role != null) {
      ok = st.hasRole(role!);
    }

    return ok ? child : (fallback ?? const SizedBox.shrink());
  }
}