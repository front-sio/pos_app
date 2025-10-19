import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:sales_app/config/config.dart';

/// Socket.IO realtime products listener with auto-reconnect and debounce.
/// Emits normalized types: product_created, product_updated, product_deleted,
/// stock_changed, purchase_created, purchase_payment_updated, products_changed.
class RealtimeProducts {
  final Duration debounce;
  IO.Socket? _socket;
  final _controller = StreamController<String>.broadcast();
  Timer? _debouncer;

  Stream<String> get events => _controller.stream;

  RealtimeProducts({this.debounce = const Duration(milliseconds: 400)});

  void connect() {
    disconnect();

    final base = AppConfig.baseUrl; // e.g., http://localhost:8080 (gateway)
    final uri = Uri.parse(base);
    final origin = '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
    if (kDebugMode) debugPrint('[RealtimeProducts] connecting to $origin/socket.io-products');

    _socket = IO.io(origin, <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'path': '/socket.io-products',
      'autoConnect': true,
      'reconnection': true,
      'reconnectionAttempts': 999999,
      'reconnectionDelay': 700,
    });

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