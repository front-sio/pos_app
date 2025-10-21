import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_event.dart';
import 'auth_state.dart';
import '../data/auth_repository.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;

  AuthBloc({required this.repository}) : super(const AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    final token = await repository.getToken();
    final userIdString = await repository.getUserId();
    final userId = userIdString != null ? int.tryParse(userIdString) : null;

    if (token != null && userId != null) {
      final firstName = await repository.getFirstName() ?? '';
      final lastName = await repository.getLastName() ?? '';
      final username = await repository.getUsername() ?? '';
      final email = await repository.getEmail() ?? '';

      // RBAC restore
      final roles = await repository.getRoles();
      final permissions = await repository.getPermissions();
      final isSuperuser = await repository.getIsSuperuser();

      emit(AuthAuthenticated(
        token: token,
        userId: userId,
        email: email,
        firstName: firstName,
        lastName: lastName,
        username: username,
        roles: roles,
        permissions: permissions,
        isSuperuser: isSuperuser,
      ));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final userData = await repository.login(event.identifier, event.password);

      final token = userData['token'] as String;
      final user = (userData['user'] ?? {}) as Map<String, dynamic>;

      final userId = (user['id'] ?? 0) as int;
      final firstName = user['first_name']?.toString() ?? '';
      final lastName = user['last_name']?.toString() ?? '';
      final username = user['username']?.toString() ?? '';
      final email = user['email']?.toString() ?? '';

      final roles = (user['roles'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
      final permissions = (user['permissions'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
      final isSuperuser = (user['is_superuser'] is bool)
          ? user['is_superuser'] as bool
          : user['is_superuser']?.toString().toLowerCase() == 'true';

      emit(AuthAuthenticated(
        token: token,
        userId: userId,
        email: email,
        firstName: firstName,
        lastName: lastName,
        username: username,
        roles: roles,
        permissions: permissions,
        isSuperuser: isSuperuser,
      ));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  // Backend /auth/register returns message/id (no token). Keep user unauthenticated.
  Future<void> _onRegisterRequested(RegisterRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      await repository.register(
        event.username,
        event.email,
        event.firstName,
        event.lastName,
        event.password,
        event.gender,
      );
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    await repository.logout();
    emit(const AuthUnauthenticated());
  }
}