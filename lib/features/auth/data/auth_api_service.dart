import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class AuthApiService {
  final String baseUrl;

  AuthApiService({required this.baseUrl});

  Future<Map<String, dynamic>> login(String identifier, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({"identifier": identifier, "password": password}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return _safeDecode(response.body);
      }

      final Map<String, dynamic> body = _safeDecode(response.body);
      final serverMessage = _extractMessage(body);

      switch (response.statusCode) {
        case 400:
        case 422:
          throw ApiException(
            serverMessage ?? 'Please check your input and try again.',
            statusCode: response.statusCode,
          );
        case 401:
          throw ApiException(
            serverMessage ?? 'Invalid email/username or password.',
            statusCode: response.statusCode,
          );
        case 403:
          throw ApiException(
            serverMessage ?? 'You do not have permission to access this app.',
            statusCode: response.statusCode,
          );
        case 404:
          throw ApiException(
            serverMessage ?? 'Service temporarily unavailable. Please try again later.',
            statusCode: response.statusCode,
          );
        default:
          throw ApiException(
            serverMessage ?? 'Server error. Please try again later.',
            statusCode: response.statusCode,
          );
      }
    } on SocketException {
      throw const ApiException('Cannot connect to server. Check your internet connection.');
    } on TimeoutException {
      throw const ApiException('Request timed out. Please try again.');
    } on FormatException {
      throw const ApiException('Received an unexpected response from the server.');
    }
  }

  Future<Map<String, dynamic>> register(
    String username,
    String email,
    String firstName,
    String lastName,
    String password,
    String gender,
  ) async {
    try {
      final response = await http
          .post(
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
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return _safeDecode(response.body);
      }

      final Map<String, dynamic> body = _safeDecode(response.body);
      final serverMessage = _extractMessage(body);

      switch (response.statusCode) {
        case 400:
        case 409:
        case 422:
          throw ApiException(
            serverMessage ?? 'Please check your input and try again.',
            statusCode: response.statusCode,
          );
        default:
          throw ApiException(
            serverMessage ?? 'Could not complete registration. Please try again later.',
            statusCode: response.statusCode,
          );
      }
    } on SocketException {
      throw const ApiException('Cannot connect to server. Check your internet connection.');
    } on TimeoutException {
      throw const ApiException('Request timed out. Please try again.');
    } on FormatException {
      throw const ApiException('Received an unexpected response from the server.');
    }
  }

  Map<String, dynamic> _safeDecode(String body) {
    if (body.isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  String? _extractMessage(Map<String, dynamic> body) {
    // Try common keys used by APIs
    final candidates = [
      body['message'],
      body['error'],
      body['detail'],
      body['description'],
      if (body['errors'] is List) (body['errors'] as List).join(', '),
      if (body['errors'] is Map)
        (body['errors'] as Map)
            .values
            .whereType<List>()
            .expand((e) => e)
            .whereType<String>()
            .join(', '),
    ];
    for (final c in candidates) {
      if (c is String && c.trim().isNotEmpty) return c.trim();
    }
    return null;
  }
}