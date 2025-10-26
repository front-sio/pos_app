import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:sales_app/config/config.dart';

class RealtimeInvoices {
  final Duration debounce;
  IO.Socket? _socket;
  final _controller = StreamController<String>.broadcast();
  Timer? _debouncer;

  Stream<String> get events => _controller.stream;

  RealtimeInvoices({this.debounce = const Duration(milliseconds: 400)});

  void connect() {
    disconnect();

    final base = AppConfig.baseUrl;
    final uri = Uri.parse(base);
    final origin = '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
    if (kDebugMode) debugPrint('[RealtimeInvoices] connecting to $origin via /socket.io-invoices');

    _socket = IO.io(origin, <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'path': '/socket.io-invoices',
      'autoConnect': true,
      'reconnection': true,
      'reconnectionAttempts': 999999,
      'reconnectionDelay': 700,
    });

    _socket!.onConnect((_) {
      if (kDebugMode) debugPrint('[RealtimeInvoices] connected');
    });

    _socket!.onConnectError((err) {
      if (kDebugMode) debugPrint('[RealtimeInvoices] connect_error: $err');
    });

    _socket!.onError((err) {
      if (kDebugMode) debugPrint('[RealtimeInvoices] error: $err');
    });

    _socket!.onDisconnect((reason) {
      if (kDebugMode) debugPrint('[RealtimeInvoices] disconnected: $reason');
    });

    _socket!.on('invoices_changed', (data) {
      final type = _extractType(data);
      if (kDebugMode) debugPrint('[RealtimeInvoices] invoices_changed: $type');

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
    return 'invoices_changed';
  }

  void disconnect() {
    _debouncer?.cancel();
    _debouncer = null;
    try {
      _socket?.off('invoices_changed');
      _socket?.dispose();
    } catch (_) {}
    _socket = null;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}