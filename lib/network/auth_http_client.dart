import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

typedef CurrencyProvider = String? Function();

class AuthHttpClient extends http.BaseClient {
  final http.Client _inner;
  final FlutterSecureStorage _storage;
  final CurrencyProvider? _currencyProvider;

  AuthHttpClient({
    http.Client? inner,
    FlutterSecureStorage? storage,
    CurrencyProvider? currencyProvider,
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
    final wantsJson = (request is http.Request)
        ? (request.headers['Content-Type'] == 'application/json')
        : false;

    final defaults = await _defaultHeaders(json: wantsJson);
    defaults.forEach((k, v) {
      request.headers.putIfAbsent(k, () => v);
    });

    return _inner.send(request);
  }
}