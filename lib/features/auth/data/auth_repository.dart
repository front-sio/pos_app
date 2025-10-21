import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_api_service.dart';

class AuthRepository {
  final AuthApiService apiService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthRepository(this.apiService);

  Future<Map<String, dynamic>> login(String identifier, String password) async {
    final userData = await apiService.login(identifier, password);

    final token = userData['token'] as String?;
    final user = (userData['user'] ?? {}) as Map<String, dynamic>;

    if (token != null) {
      // Basic profile
      await _storage.write(key: 'token', value: token);
      await _storage.write(key: 'userId', value: (user['id'] ?? '').toString());
      await _storage.write(key: 'firstName', value: user['first_name']?.toString() ?? '');
      await _storage.write(key: 'lastName', value: user['last_name']?.toString() ?? '');
      await _storage.write(key: 'username', value: user['username']?.toString() ?? '');
      await _storage.write(key: 'email', value: user['email']?.toString() ?? '');
      await _storage.write(key: 'gender', value: user['gender']?.toString() ?? '');

      // RBAC fields
      final roles = (user['roles'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
      final permissions = (user['permissions'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
      final isSuperuser = (user['is_superuser'] is bool)
          ? user['is_superuser'] as bool
          : user['is_superuser']?.toString().toLowerCase() == 'true';

      await _storage.write(key: 'roles', value: jsonEncode(roles));
      await _storage.write(key: 'permissions', value: jsonEncode(permissions));
      await _storage.write(key: 'isSuperuser', value: isSuperuser ? 'true' : 'false');
    }
    return userData;
  }

  // Note: Your backend register endpoint does NOT return a token/user.
  // We keep the function for compatibility, but we won't try to persist roles/permissions here.
  Future<Map<String, dynamic>> register(
    String username,
    String email,
    String firstName,
    String lastName,
    String password,
    String gender,
  ) async {
    final resp = await apiService.register(username, email, firstName, lastName, password, gender);
    return resp;
  }

  Future<void> saveUsername(String username) async {
    await _storage.write(key: 'username', value: username);
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  // Getters
  Future<String?> getToken() => _storage.read(key: 'token');
  Future<String?> getFirstName() => _storage.read(key: 'firstName');
  Future<String?> getLastName() => _storage.read(key: 'lastName');
  Future<String?> getUserId() => _storage.read(key: 'userId');
  Future<String?> getUsername() => _storage.read(key: 'username');
  Future<String?> getEmail() => _storage.read(key: 'email');
  Future<String?> getGender() => _storage.read(key: 'gender');

  Future<List<String>> getRoles() async {
    final raw = await _storage.read(key: 'roles');
    if (raw == null || raw.isEmpty) return <String>[];
    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((e) => e.toString()).toList();
    } catch (_) {
      return <String>[];
    }
  }

  Future<List<String>> getPermissions() async {
    final raw = await _storage.read(key: 'permissions');
    if (raw == null || raw.isEmpty) return <String>[];
    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((e) => e.toString()).toList();
    } catch (_) {
      return <String>[];
    }
  }

  Future<bool> getIsSuperuser() async {
    final raw = await _storage.read(key: 'isSuperuser');
    return raw == 'true';
  }
}