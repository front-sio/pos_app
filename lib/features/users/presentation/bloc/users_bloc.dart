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
      emit(UsersActionSuccess(res['message'] ?? 'User created'));
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
      await repository.resendReset(event.userId);
      emit(UsersActionSuccess('Reset link resent'));
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
}