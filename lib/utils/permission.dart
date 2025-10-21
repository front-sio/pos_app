import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sales_app/features/auth/logic/auth_bloc.dart';
import 'package:sales_app/features/auth/logic/auth_state.dart';

extension AuthPermissionX on BuildContext {
  AuthState get authState => read<AuthBloc>().state;

  bool hasPermission(String perm) {
    final st = authState;
    if (st is AuthAuthenticated) {
      return st.hasPermission(perm);
    }
    return false;
  }

  bool hasAnyPermission(Iterable<String> perms) {
    final st = authState;
    if (st is AuthAuthenticated) {
      return st.hasAnyPermission(perms);
    }
    return false;
  }

  bool hasRole(String role) {
    final st = authState;
    if (st is AuthAuthenticated) {
      return st.hasRole(role);
    }
    return false;
  }

  bool get isSuperuser {
    final st = authState;
    return st is AuthAuthenticated && st.isSuperuser;
  }
}