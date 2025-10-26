// lib/features/products/services/realtime_product.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:sales_app/config/config.dart';

class RealtimeProducts {
  final Duration debounce;
  IO.Socket? _socket;
  final _controller = StreamController<String>.broadcast();
  Timer? _debouncer;

  Stream<String> get events => _controller.stream;

  RealtimeProducts({this.debounce = const Duration(milliseconds: 400)});

  Future<void> connect() async {
    disconnect();

    final base = AppConfig.baseUrl;
    final uri = Uri.parse(base);
    final origin = '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';

    final token = await const FlutterSecureStorage().read(key: 'token');

    if (kDebugMode) {
      debugPrint('[RealtimeProducts] connecting to $origin/socket.io-products');
    }

    final options = <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'path': '/socket.io-products',
      'autoConnect': true,
      'reconnection': true,
      'reconnectionAttempts': 999999,
      'reconnectionDelay': 700,
      // Web: use auth payload; Server should read socket.handshake.auth.token
      'auth': token != null && token.isNotEmpty ? {'token': token} : {},
      // Non-web (native) can also send headers; browsers ignore extraHeaders
      if (token != null && token.isNotEmpty)
        'extraHeaders': {'Authorization': 'Bearer $token'},
    };

    _socket = IO.io(origin, options);

    _socket!.onConnect((_) {
      if (kDebugMode) debugPrint('[RealtimeProducts] connected');
    });
    _socket!.onConnectError((err) {
      if (kDebugMode) debugPrint('[RealtimeProducts] connect_error: $err');
    });
    _socket!.onError((err) {
      if (kDebugMode) debugPrint('[RealtimeProducts] error: $err');
    });
    _socket!.onDisconnect((reason) {
      if (kDebugMode) debugPrint('[RealtimeProducts] disconnected: $reason');
    });

    _socket!.on('products_changed', (data) {
      final type = _extractType(data);
      if (kDebugMode) debugPrint('[RealtimeProducts] products_changed: $type');

      _debouncer?.cancel();
      _debouncer = Timer(debounce, () {
        if (!_controller.isClosed) _controller.add(type);
      });
    });

    _socket!.connect();
  }

  String _extractType(dynamic data) {
    try {
      final t = (data?['type']?.toString() ?? '').toLowerCase();
      if (t.isNotEmpty) return t;
    } catch (_) {}
    return 'products_changed';
  }

  void disconnect() {
    _debouncer?.cancel();
    _debouncer = null;
    try {
      _socket?.off('products_changed');
      _socket?.dispose();
    } catch (_) {}
    _socket = null;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}