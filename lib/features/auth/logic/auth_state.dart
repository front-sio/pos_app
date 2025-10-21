// features/auth/logic/auth_state.dart
import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final String token;
  final int userId;
  final String email;
  final String firstName;
  final String lastName;
  final String username;

  final List<String> roles;
  final List<String> permissions;
  final bool isSuperuser;

  const AuthAuthenticated({
    required this.token,
    required this.userId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.username,
    this.roles = const [],
    this.permissions = const [],
    this.isSuperuser = false,
  });

  bool hasPermission(String p) =>
      isSuperuser || permissions.map((e) => e.toLowerCase()).contains(p.toLowerCase());

  bool hasAnyPermission(Iterable<String> required) {
    if (isSuperuser) return true;
    final set = permissions.map((e) => e.toLowerCase()).toSet();
    for (final r in required) {
      if (set.contains(r.toLowerCase())) return true;
    }
    return false;
  }

  bool hasRole(String r) => roles.map((e) => e.toLowerCase()).contains(r.toLowerCase());

  @override
  List<Object?> get props => [token, userId, email, firstName, lastName, username, roles, permissions, isSuperuser];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthFailure extends AuthState {
  final String error;
  const AuthFailure(this.error);

  @override
  List<Object?> get props => [error];
}
