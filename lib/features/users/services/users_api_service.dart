import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sales_app/config/config.dart';

class UsersApiService {
  final String baseUrl;
  final http.Client _http;

  UsersApiService({String? baseUrl, http.Client? httpClient})
      : baseUrl = baseUrl ?? AppConfig.baseUrl,
        _http = httpClient ?? http.Client();

  Uri _uri(String path, [Map<String, String>? qp]) {
    final uri = Uri.parse(baseUrl + path);
    if (qp != null) return uri.replace(queryParameters: qp);
    return uri;
  }

  Future<List<dynamic>> fetchUsers(String token) async {
    final res = await _http.get(_uri('/auth/users'),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'});
    if (res.statusCode != 200) throw Exception('Failed to fetch users: ${res.body}');
    final body = jsonDecode(res.body);
    if (body is List) return body;
    // some backends return { users: [...] } - handle defensively
    if (body is Map && body['users'] is List) return body['users'] as List<dynamic>;
    throw Exception('Unexpected users payload');
  }

  Future<Map<String, dynamic>> fetchCurrentUser(String token) async {
    final res = await _http.get(_uri('/auth/me'),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'});
    if (res.statusCode != 200) throw Exception('Failed to fetch current user: ${res.body}');
    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Unexpected current user payload');
  }

  Future<List<dynamic>> fetchRoles(String token) async {
    final res = await _http.get(_uri('/auth/roles'),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'});
    if (res.statusCode != 200) throw Exception('Failed to fetch roles: ${res.body}');
    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic> && decoded['roles'] is List) {
      return decoded['roles'] as List<dynamic>;
    }
    // If API returns a plain list
    if (decoded is List) return decoded;
    throw Exception('Unexpected roles payload');
  }

  Future<List<dynamic>> fetchPermissions(String token) async {
    final res = await _http.get(_uri('/auth/permissions'),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'});
    if (res.statusCode != 200) throw Exception('Failed to fetch permissions: ${res.body}');
    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic> && decoded['permissions'] is List) {
      return decoded['permissions'] as List<dynamic>;
    }
    if (decoded is List) return decoded;
    throw Exception('Unexpected permissions payload');
  }

  Future<Map<String, dynamic>> createRole(String token, String name, {String description = ''}) async {
    final res = await _http.post(_uri('/auth/roles'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'name': name, 'description': description}));
    if (res.statusCode != 201) throw Exception('Failed to create role: ${res.body}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createPermission(String token, String name, {String description = ''}) async {
    final res = await _http.post(_uri('/auth/permissions'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'name': name, 'description': description}));
    if (res.statusCode != 201) throw Exception('Failed to create permission: ${res.body}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createUserWithRole(String token, Map<String, dynamic> payload) async {
    final res = await _http.post(_uri('/auth/users'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode(payload));
    if (res.statusCode != 201) throw Exception('Failed to create user: ${res.body}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> assignRole(String token, int userId, int roleId) async {
    final res = await _http.post(_uri('/auth/users/$userId/assign-role'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'role_id': roleId}));
    if (res.statusCode != 200) throw Exception('Failed to assign role: ${res.body}');
  }

  Future<void> resendReset(String token, int userId) async {
    final res = await _http.post(_uri('/auth/users/$userId/resend-reset'),
        headers: {'Authorization': 'Bearer $token'});
    if (res.statusCode != 200) throw Exception('Failed to resend reset: ${res.body}');
  }

  Future<void> deleteUser(String token, int userId) async {
    final res = await _http.delete(_uri('/auth/users/$userId'),
        headers: {'Authorization': 'Bearer $token'});
    if (res.statusCode != 200 && res.statusCode != 204) throw Exception('Failed to delete user: ${res.body}');
  }

  Future<Map<String, dynamic>> updateUser(String token, int userId, Map<String, dynamic> payload) async {
    final res = await _http.put(_uri('/auth/users/$userId'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode(payload));
    if (res.statusCode != 200) throw Exception('Failed to update user: ${res.body}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  void dispose() {
    _http.close();
  }
}