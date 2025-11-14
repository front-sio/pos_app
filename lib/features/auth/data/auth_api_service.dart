import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:sales_app/utils/api_error_handler.dart';

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
            serverMessage ?? 'Taarifa ulizotuma si sahihi. Tafadhali angalia na jaribu tena.',
            statusCode: response.statusCode,
            type: ApiErrorType.validation,
          );
        case 401:
          throw ApiException(
            serverMessage ?? 'Jina la mtumiaji au nywila si sahihi.',
            statusCode: response.statusCode,
            type: ApiErrorType.http,
          );
        case 403:
          throw ApiException(
            serverMessage ?? 'Huna ruhusa ya kutumia programu hii.',
            statusCode: response.statusCode,
            type: ApiErrorType.http,
          );
        case 404:
          throw ApiException(
            serverMessage ?? 'Huduma haipatikani kwa sasa. Tafadhali jaribu tena baadaye.',
            statusCode: response.statusCode,
            type: ApiErrorType.http,
          );
        case 502:
        case 503:
        case 504:
          throw ApiException(
            'Huduma haipatikani kwa sasa. Tafadhali angalia kama server inafanya kazi.',
            statusCode: response.statusCode,
            type: ApiErrorType.http,
          );
        default:
          throw ApiException(
            serverMessage ?? 'Tatizo la server. Tafadhali jaribu tena baadaye.',
            statusCode: response.statusCode,
            type: ApiErrorType.http,
          );
      }
    } on SocketException {
      throw ApiException(
        'Imeshindwa kuunganisha na server. Angalia muunganisho wako wa mtandao.',
        type: ApiErrorType.network,
      );
    } on TimeoutException {
      throw ApiException(
        'Muda umeisha. Tafadhali jaribu tena.',
        type: ApiErrorType.timeout,
      );
    } on FormatException {
      throw ApiException(
        'Tatizo la kusoma jibu kutoka server.',
        type: ApiErrorType.parsing,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Tatizo limetokea. Tafadhali jaribu tena.',
        type: ApiErrorType.unknown,
        originalError: e,
      );
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
            serverMessage ?? 'Taarifa ulizotuma si sahihi. Tafadhali angalia na jaribu tena.',
            statusCode: response.statusCode,
            type: ApiErrorType.validation,
          );
        default:
          throw ApiException(
            serverMessage ?? 'Imeshindwa kukamilisha usajili. Tafadhali jaribu tena baadaye.',
            statusCode: response.statusCode,
            type: ApiErrorType.http,
          );
      }
    } on SocketException {
      throw ApiException(
        'Imeshindwa kuunganisha na server. Angalia muunganisho wako wa mtandao.',
        type: ApiErrorType.network,
      );
    } on TimeoutException {
      throw ApiException(
        'Muda umeisha. Tafadhali jaribu tena.',
        type: ApiErrorType.timeout,
      );
    } on FormatException {
      throw ApiException(
        'Tatizo la kusoma jibu kutoka server.',
        type: ApiErrorType.parsing,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Tatizo limetokea. Tafadhali jaribu tena.',
        type: ApiErrorType.unknown,
        originalError: e,
      );
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