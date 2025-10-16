import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthApiService {
  final String baseUrl;

  AuthApiService({required this.baseUrl});

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"email": email, "password": password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"] ?? "Login failed");
    }
  }


  Future<Map<String, dynamic>> register(
    String username, 
    String email, 
    String firstName, 
    String lastName, 
    String password, 
    String gender 
    ) async{
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

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)["message"] ?? "Registration failed");
    }
  }
}
