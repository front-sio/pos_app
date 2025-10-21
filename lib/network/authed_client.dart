import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthedClient extends http.BaseClient {
  AuthedClient({
    http.Client? inner,
    FlutterSecureStorage? storage,
  })  : _inner = inner ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  final http.Client _inner;
  final FlutterSecureStorage _storage;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final token = await _storage.read(key: 'token');

    request.headers.putIfAbsent('Accept', () => 'application/json');

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}