// lib/features/auth/bloc/auth_state.dart

import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final Map<String, dynamic> userData;

  AuthSuccess(this.userData);

  @override
  List<Object?> get props => [userData];
}

class AuthAuthenticated extends AuthState {
  final String token;
  final int userId;
  final String email;
  final String firstName;
  final String lastName;
  final String username;

  AuthAuthenticated({required this.token, required this.userId, required this.email, required this.firstName, required this.lastName, required this.username});

  @override
  List<Object?> get props => [token, userId, email, firstName, lastName, username];
}

class AuthUnauthenticated extends AuthState {}

class AuthFailure extends AuthState {
  final String error;

  AuthFailure(this.error);

  @override
  List<Object?> get props => [error];
}
