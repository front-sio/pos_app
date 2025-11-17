import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_event.dart';
import 'auth_state.dart';
import '../data/auth_repository.dart';
import 'package:sales_app/utils/api_error_handler.dart';

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

      final roles = await repository.getRoles();
      final permissions = (await repository.getPermissions()).map((p) => p.toLowerCase()).toList();
      final isSuperuser = await repository.getIsSuperuser();

      // Debug logging for restored session
      print('[AuthBloc] Session restored for user: $username');
      print('[AuthBloc] Is superuser: $isSuperuser');
      print('[AuthBloc] Roles (${roles.length}): ${roles.join(", ")}');
      print('[AuthBloc] Permissions (${permissions.length}): ${permissions.take(5).join(", ")}...');

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

      final token = userData['token'] as String? ?? '';
      final user = (userData['user'] ?? {}) as Map<String, dynamic>;

      final userId = (user['id'] ?? 0) as int;
      final firstName = user['first_name']?.toString() ?? '';
      final lastName = user['last_name']?.toString() ?? '';
      final username = user['username']?.toString() ?? '';
      final email = user['email']?.toString() ?? '';

      final roles = (user['roles'] as List?)
              ?.map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList() ?? <String>[];

      final permissions = (user['permissions'] as List?)
              ?.map((e) => e.toString().trim().toLowerCase())
              .where((e) => e.isNotEmpty)
              .toList() ?? <String>[];

      final isSuperuserRaw = user['is_superuser'];
      final isSuperuser = isSuperuserRaw == true ||
          (isSuperuserRaw is String && isSuperuserRaw.toLowerCase() == 'true') ||
          (isSuperuserRaw is num && isSuperuserRaw != 0);

      // Debug logging for permissions
      print('[AuthBloc] Login successful for user: $username');
      print('[AuthBloc] Is superuser: $isSuperuser');
      print('[AuthBloc] Roles (${roles.length}): ${roles.join(", ")}');
      print('[AuthBloc] Permissions (${permissions.length}): ${permissions.take(5).join(", ")}...');

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
    } on ApiException catch (e) {
      // Friendly message from API handler
      emit(AuthFailure(e.message));
    } catch (_) {
      // Fallback friendly message
      emit(const AuthFailure('Something went wrong. Please check your connection and try again.'));
    }
  }

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
    } on ApiException catch (e) {
      emit(AuthFailure(e.message));
    } catch (_) {
      emit(const AuthFailure('Could not complete registration. Please try again.'));
    }
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    await repository.logout();
    emit(const AuthUnauthenticated());
  }
}