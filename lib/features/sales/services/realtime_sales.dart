import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:sales_app/config/config.dart';

/// Socket.IO realtime sales listener with auto-reconnect and debounce.
/// Emits normalized event types: sale_created, sale_updated, sale_deleted, sales_changed.
class RealtimeSales {
  final Duration debounce;
  IO.Socket? _socket;
  final _controller = StreamController<String>.broadcast();
  Timer? _debouncer;

  /// Stream of event types emitted by the socket
  Stream<String> get events => _controller.stream;

  RealtimeSales({this.debounce = const Duration(milliseconds: 400)});

  /// Connect to the Socket.IO server
  void connect() {
    disconnect();

    final base = AppConfig.baseUrl;
    final uri = Uri.parse(base);
    final origin = '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
    if (kDebugMode) debugPrint('[RealtimeSales] connecting to $origin via /socket.io');

    // Allow polling fallback to avoid failures behind some proxies
    _socket = IO.io(origin, <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'path': '/socket.io',
      'autoConnect': true,
      'reconnection': true,
      'reconnectionAttempts': 999999,
      'reconnectionDelay': 700,
      // Note: extraHeaders are ignored on web; rely on CORS on server
    });

    _socket!.onConnect((_) {
      if (kDebugMode) debugPrint('[RealtimeSales] connected');
    });

    _socket!.onConnectError((err) {
      if (kDebugMode) debugPrint('[RealtimeSales] connect_error: $err');
    });

    _socket!.onError((err) {
      if (kDebugMode) debugPrint('[RealtimeSales] error: $err');
    });

    _socket!.onDisconnect((reason) {
      if (kDebugMode) debugPrint('[RealtimeSales] disconnected: $reason');
    });

    // Unified sales event from backend
    _socket!.on('sales_changed', (data) {
      final type = _extractType(data);
      if (kDebugMode) debugPrint('[RealtimeSales] sales_changed: $type');

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
    return 'sales_changed';
  }

  void disconnect() {
    _debouncer?.cancel();
    _debouncer = null;
    try {
      _socket?.off('sales_changed');
      _socket?.dispose();
    } catch (_) {}
    _socket = null;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}