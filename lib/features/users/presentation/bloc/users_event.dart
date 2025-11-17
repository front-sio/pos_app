import 'package:equatable/equatable.dart';

abstract class UsersEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadUsers extends UsersEvent {}

class LoadRolesAndPermissions extends UsersEvent {}

class CreateRoleRequested extends UsersEvent {
  final String name;
  final String description;
  CreateRoleRequested(this.name, {this.description = ''});
  @override
  List<Object?> get props => [name, description];
}

class CreatePermissionRequested extends UsersEvent {
  final String name;
  final String description;
  CreatePermissionRequested(this.name, {this.description = ''});
  @override
  List<Object?> get props => [name, description];
}

class CreateUserWithRoleRequested extends UsersEvent {
  final Map<String, dynamic> payload;
  CreateUserWithRoleRequested(this.payload);
  @override
  List<Object?> get props => [payload];
}

class AssignRoleRequested extends UsersEvent {
  final int userId;
  final int roleId;
  AssignRoleRequested(this.userId, this.roleId);
  @override
  List<Object?> get props => [userId, roleId];
}

class ResendResetRequested extends UsersEvent {
  final int userId;
  ResendResetRequested(this.userId);
  @override
  List<Object?> get props => [userId];
}

class DeleteUserRequested extends UsersEvent {
  final int userId;
  DeleteUserRequested(this.userId);
  @override
  List<Object?> get props => [userId];
}

class UpdateUserRequested extends UsersEvent {
  final int userId;
  final Map<String, dynamic> payload;
  UpdateUserRequested(this.userId, this.payload);
  @override
  List<Object?> get props => [userId, payload];
}

class AssignPermissionToRoleRequested extends UsersEvent {
  final int roleId;
  final int permissionId;
  AssignPermissionToRoleRequested(this.roleId, this.permissionId);
  @override
  List<Object?> get props => [roleId, permissionId];
}

class RevokePermissionFromRoleRequested extends UsersEvent {
  final int roleId;
  final int permissionId;
  RevokePermissionFromRoleRequested(this.roleId, this.permissionId);
  @override
  List<Object?> get props => [roleId, permissionId];
}

class LoadRolePermissions extends UsersEvent {
  final int roleId;
  LoadRolePermissions(this.roleId);
  @override
  List<Object?> get props => [roleId];
}