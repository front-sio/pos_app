import 'package:equatable/equatable.dart';
import 'package:sales_app/features/users/models/role_permission.dart';
import 'package:sales_app/features/users/models/user_model.dart';

abstract class UsersState extends Equatable {
  @override
  List<Object?> get props => [];
}

class UsersInitial extends UsersState {}

class UsersLoading extends UsersState {}

class UsersLoaded extends UsersState {
  final List<UserModel> users;
  UsersLoaded(this.users);
  @override
  List<Object?> get props => [users];
}

class RolesPermissionsLoaded extends UsersState {
  final List<RoleModel> roles;
  final List<PermissionModel> permissions;
  RolesPermissionsLoaded(this.roles, this.permissions);
  @override
  List<Object?> get props => [roles, permissions];
}

class UsersActionSuccess extends UsersState {
  final String message;
  UsersActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class UsersFailure extends UsersState {
  final String error;
  UsersFailure(this.error);
  @override
  List<Object?> get props => [error];
}

class RolePermissionsLoaded extends UsersState {
  final int roleId;
  final List<PermissionModel> permissions;
  RolePermissionsLoaded(this.roleId, this.permissions);
  @override
  List<Object?> get props => [roleId, permissions];
}