import 'package:flutter_bloc/flutter_bloc.dart';
import 'users_event.dart';
import 'users_state.dart';
import 'package:sales_app/features/users/repository/users_repository.dart';


class UsersBloc extends Bloc<UsersEvent, UsersState> {
  final UsersRepository repository;

  UsersBloc({required this.repository}) : super(UsersInitial()) {
    on<LoadUsers>(_onLoadUsers);
    on<LoadRolesAndPermissions>(_onLoadRolesAndPermissions);
    on<CreateRoleRequested>(_onCreateRole);
    on<CreatePermissionRequested>(_onCreatePermission);
    on<CreateUserWithRoleRequested>(_onCreateUserWithRole);
    on<AssignRoleRequested>(_onAssignRole);
    on<ResendResetRequested>(_onResendReset);
    on<DeleteUserRequested>(_onDeleteUser);
    on<UpdateUserRequested>(_onUpdateUser);
    on<AssignPermissionToRoleRequested>(_onAssignPermissionToRole);
    on<RevokePermissionFromRoleRequested>(_onRevokePermissionFromRole);
    on<LoadRolePermissions>(_onLoadRolePermissions);
  }

  Future<void> _onLoadUsers(LoadUsers _event, Emitter<UsersState> emit) async {
    try {
      emit(UsersLoading());
      final users = await repository.getUsers();
      emit(UsersLoaded(users));
    } catch (e) {
      emit(UsersFailure(e.toString()));
    }
  }

  Future<void> _onLoadRolesAndPermissions(LoadRolesAndPermissions _event, Emitter<UsersState> emit) async {
    try {
      emit(UsersLoading());
      final roles = await repository.getRoles();
      final permissions = await repository.getPermissions();
      emit(RolesPermissionsLoaded(roles, permissions));
    } catch (e) {
      emit(UsersFailure(e.toString()));
    }
  }

  Future<void> _onCreateRole(CreateRoleRequested event, Emitter<UsersState> emit) async {
    try {
      emit(UsersLoading());
      final res = await repository.createRole(event.name, description: event.description);
      emit(UsersActionSuccess(res['message'] ?? 'Role created'));
      add(LoadRolesAndPermissions());
    } catch (e) {
      emit(UsersFailure(e.toString()));
    }
  }

  Future<void> _onCreatePermission(CreatePermissionRequested event, Emitter<UsersState> emit) async {
    try {
      emit(UsersLoading());
      final res = await repository.createPermission(event.name, description: event.description);
      emit(UsersActionSuccess(res['message'] ?? 'Permission created'));
      add(LoadRolesAndPermissions());
    } catch (e) {
      emit(UsersFailure(e.toString()));
    }
  }

  Future<void> _onCreateUserWithRole(CreateUserWithRoleRequested event, Emitter<UsersState> emit) async {
    try {
      emit(UsersLoading());
      final res = await repository.createUserWithRole(event.payload);
      
      // Build detailed success message
      final username = res['username'] ?? event.payload['username'];
      final email = res['email'] ?? event.payload['email'];
      final emailSent = res['credentials_sent'] == true;
      
      String message = '✅ User "$username" created successfully!\n';
      if (emailSent) {
        message += '📧 Welcome email sent to $email';
      } else {
        message += '⚠️ Email not configured - credentials logged to console';
      }
      
      emit(UsersActionSuccess(message));
      add(LoadUsers());
    } catch (e) {
      emit(UsersFailure(e.toString()));
    }
  }

  Future<void> _onAssignRole(AssignRoleRequested event, Emitter<UsersState> emit) async {
    try {
      emit(UsersLoading());
      await repository.assignRole(event.userId, event.roleId);
      emit(UsersActionSuccess('Role assigned'));
      add(LoadUsers());
    } catch (e) {
      emit(UsersFailure(e.toString()));
    }
  }

  Future<void> _onResendReset(ResendResetRequested event, Emitter<UsersState> emit) async {
    try {
      emit(UsersLoading());
      final res = await repository.resendReset(event.userId);
      
      final emailSent = res['reset_email_sent'] == true;
      String message = '✅ Password reset link resent';
      if (emailSent) {
        message += '\n📧 Check email for reset instructions';
      } else {
        message += '\n⚠️ Email not configured - check console for reset token';
      }
      
      emit(UsersActionSuccess(message));
    } catch (e) {
      emit(UsersFailure(e.toString()));
    }
  }

  Future<void> _onDeleteUser(DeleteUserRequested event, Emitter<UsersState> emit) async {
    try {
      emit(UsersLoading());
      await repository.deleteUser(event.userId);
      emit(UsersActionSuccess('User deleted'));
      add(LoadUsers());
    } catch (e) {
      emit(UsersFailure(e.toString()));
    }
  }

  Future<void> _onUpdateUser(UpdateUserRequested event, Emitter<UsersState> emit) async {
    try {
      emit(UsersLoading());
      final res = await repository.updateUser(event.userId, event.payload);
      emit(UsersActionSuccess(res['message'] ?? 'User updated'));
      add(LoadUsers());
    } catch (e) {
      emit(UsersFailure(e.toString()));
    }
  }

  Future<void> _onAssignPermissionToRole(AssignPermissionToRoleRequested event, Emitter<UsersState> emit) async {
    try {
      emit(UsersLoading());
      final res = await repository.assignPermissionToRole(event.roleId, event.permissionId);
      emit(UsersActionSuccess(res['message'] ?? 'Permission assigned to role'));
      add(LoadRolesAndPermissions());
    } catch (e) {
      emit(UsersFailure(e.toString()));
    }
  }

  Future<void> _onRevokePermissionFromRole(RevokePermissionFromRoleRequested event, Emitter<UsersState> emit) async {
    try {
      emit(UsersLoading());
      final res = await repository.revokePermissionFromRole(event.roleId, event.permissionId);
      emit(UsersActionSuccess(res['message'] ?? 'Permission revoked from role'));
      add(LoadRolesAndPermissions());
    } catch (e) {
      emit(UsersFailure(e.toString()));
    }
  }

  Future<void> _onLoadRolePermissions(LoadRolePermissions event, Emitter<UsersState> emit) async {
    try {
      emit(UsersLoading());
      final permissions = await repository.getRolePermissions(event.roleId);
      emit(RolePermissionsLoaded(event.roleId, permissions));
    } catch (e) {
      emit(UsersFailure(e.toString()));
    }
  }
}