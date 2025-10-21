import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthApiService {
  final String baseUrl;

  AuthApiService({required this.baseUrl});

  /// Login using identifier (username or email) and password.
  Future<Map<String, dynamic>> login(String identifier, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"identifier": identifier, "password": password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      throw Exception(body["message"] ?? "Login failed");
    }
  }

  // Note: Backend register returns a message/id (not token)
  Future<Map<String, dynamic>> register(
    String username,
    String email,
    String firstName,
    String lastName,
    String password,
    String gender,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "username": username,
        "email": email,
        "first_name": firstName,
        "last_name": lastName,
        "gender": gender,
        "password": password
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      throw Exception(body["message"] ?? "Registration failed");
    }
  }
}