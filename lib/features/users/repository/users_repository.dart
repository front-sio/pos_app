import 'package:sales_app/features/users/models/user_model.dart';
import 'package:sales_app/features/users/services/users_api_service.dart';
import 'package:sales_app/features/users/models/role_permission.dart';
import 'package:sales_app/features/auth/data/auth_repository.dart';

class UsersRepository {
  final UsersApiService api;
  final AuthRepository auth;

  UsersRepository({required this.api, required this.auth});

  Future<List<UserModel>> getUsers() async {
    final token = await auth.getToken();
    if (token == null) throw Exception('Not authenticated');
    final list = await api.fetchUsers(token);
    return list.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<UserModel> getCurrentUser() async {
    final token = await auth.getToken();
    if (token == null) throw Exception('Not authenticated');
    final json = await api.fetchCurrentUser(token);
    // backend returns { user: {...} } or user object; handle both
    final map = json['user'] != null ? json['user'] as Map<String, dynamic> : json as Map<String, dynamic>;
    return UserModel.fromJson(map);
  }

  Future<List<RoleModel>> getRoles() async {
    final token = await auth.getToken();
    if (token == null) throw Exception('Not authenticated');
    final list = await api.fetchRoles(token);
    return list.map((e) => RoleModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<PermissionModel>> getPermissions() async {
    final token = await auth.getToken();
    if (token == null) throw Exception('Not authenticated');
    final list = await api.fetchPermissions(token);
    return list.map((e) => PermissionModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> createRole(String name, {String description = ''}) async {
    final token = await auth.getToken();
    if (token == null) throw Exception('Not authenticated');
    return await api.createRole(token, name, description: description);
  }

  Future<Map<String, dynamic>> createPermission(String name, {String description = ''}) async {
    final token = await auth.getToken();
    if (token == null) throw Exception('Not authenticated');
    return await api.createPermission(token, name, description: description);
  }

  Future<Map<String, dynamic>> createUserWithRole(Map<String, dynamic> payload) async {
    final token = await auth.getToken();
    if (token == null) throw Exception('Not authenticated');
    return await api.createUserWithRole(token, payload);
  }

  Future<void> assignRole(int userId, int roleId) async {
    final token = await auth.getToken();
    if (token == null) throw Exception('Not authenticated');
    await api.assignRole(token, userId, roleId);
  }

  Future<Map<String, dynamic>> resendReset(int userId) async {
    final token = await auth.getToken();
    if (token == null) throw Exception('Not authenticated');
    return await api.resendReset(token, userId);
  }

  Future<void> deleteUser(int userId) async {
    final token = await auth.getToken();
    if (token == null) throw Exception('Not authenticated');
    await api.deleteUser(token, userId);
  }

  Future<Map<String, dynamic>> updateUser(int userId, Map<String, dynamic> payload) async {
    final token = await auth.getToken();
    if (token == null) throw Exception('Not authenticated');
    return await api.updateUser(token, userId, payload);
  }

  Future<Map<String, dynamic>> assignPermissionToRole(int roleId, int permissionId) async {
    final token = await auth.getToken();
    if (token == null) throw Exception('Not authenticated');
    return await api.assignPermissionToRole(token, roleId, permissionId);
  }

  Future<Map<String, dynamic>> revokePermissionFromRole(int roleId, int permissionId) async {
    final token = await auth.getToken();
    if (token == null) throw Exception('Not authenticated');
    return await api.revokePermissionFromRole(token, roleId, permissionId);
  }

  Future<List<PermissionModel>> getRolePermissions(int roleId) async {
    final token = await auth.getToken();
    if (token == null) throw Exception('Not authenticated');
    final list = await api.getRolePermissions(token, roleId);
    return list.map((e) => PermissionModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}