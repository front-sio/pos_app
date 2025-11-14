import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sales_app/utils/api_error_handler.dart';

typedef CurrencyProvider = String? Function();
typedef OnUnauthorized = void Function();

class AuthHttpClient extends http.BaseClient {
  final http.Client _inner;
  final FlutterSecureStorage _storage;
  final CurrencyProvider? _currencyProvider;
  OnUnauthorized? onUnauthorized;

  AuthHttpClient({
    http.Client? inner,
    FlutterSecureStorage? storage,
    CurrencyProvider? currencyProvider,
    this.onUnauthorized,
  })  : _inner = inner ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage(),
        _currencyProvider = currencyProvider;

  Future<Map<String, String>> _defaultHeaders({bool json = true}) async {
    final token = await _storage.read(key: 'token');
    final headers = <String, String>{
      if (json) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final code = _currencyProvider?.call();
    if (code != null && code.isNotEmpty) {
      headers['X-Currency'] = code;
    }
    return headers;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    try {
      final wantsJson = (request is http.Request)
          ? (request.headers['Content-Type'] == 'application/json')
          : false;

      final defaults = await _defaultHeaders(json: wantsJson);
      defaults.forEach((k, v) {
        request.headers.putIfAbsent(k, () => v);
      });

      final response = await _inner.send(request).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw ApiException(
            'Muda umeisha! Server inachukua muda mrefu kujibu. Tafadhali jaribu tena.',
            type: ApiErrorType.timeout,
          );
        },
      );

      // Check for 401 Unauthorized
      if (response.statusCode == 401) {
        // Token expired or invalid
        await _storage.deleteAll();
        onUnauthorized?.call();
      }

      // Check for other error status codes
      if (response.statusCode >= 400) {
        throw ApiException(
          ApiErrorHandler.getHttpErrorMessage(response.statusCode),
          type: ApiErrorType.http,
          statusCode: response.statusCode,
        );
      }

      return response;
    } on SocketException {
      throw ApiException(
        'Huduma haipatikani. Tafadhali angalia kama server inafanya kazi na muunganisho wa mtandao.',
        type: ApiErrorType.network,
      );
    } on TimeoutException {
      throw ApiException(
        'Muda umeisha! Server inachukua muda mrefu. Tafadhali jaribu tena.',
        type: ApiErrorType.timeout,
      );
    } on http.ClientException {
      throw ApiException(
        'Imeshindwa kuunganisha na server. Angalia muunganisho wako.',
        type: ApiErrorType.network,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Tatizo limetokea. Tafadhali jaribu tena baadaye.',
        type: ApiErrorType.unknown,
        originalError: e,
      );
    }
  }
}