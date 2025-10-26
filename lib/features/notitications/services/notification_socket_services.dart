import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:sales_app/config/config.dart';
import 'package:sales_app/features/notitications/data/notification_model.dart';

class NotificationSocketService {
  IO.Socket? _socket;

  final _notifController = StreamController<AppNotification>.broadcast();
  final _snapshotController = StreamController<NotificationSnapshot>.broadcast();

  Stream<AppNotification> get notifications => _notifController.stream;
  Stream<NotificationSnapshot> get snapshot => _snapshotController.stream;

  bool get connected => _socket?.connected == true;

  /// Connects to the notifications Socket.IO endpoint.
  /// This implementation mirrors the RealtimeProducts style:
  /// - Builds origin from AppConfig.baseUrl
  /// - Uses a dedicated Socket.IO path: /socket.io-notifications
  /// - Sends token via auth payload and extraHeaders
  /// - Enables reconnection with backoff
  Future<void> connect({String? token}) async {
    disconnect();

    // Derive origin from base API URL (no separate socket url dependency)
    final base = AppConfig.baseUrl;
    final uri = Uri.parse(base);
    final origin = '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';

    // Prefer provided token, fallback to secure storage
    final secureToken = token ?? await const FlutterSecureStorage().read(key: 'token');

    if (kDebugMode) {
      debugPrint('[NotificationSocket] connecting to $origin via /socket.io-notifications');
    }

    final options = <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'path': '/socket.io-notifications',
      'autoConnect': true,
      'reconnection': true,
      'reconnectionAttempts': 999999,
      'reconnectionDelay': 700,
      // Browsers: handshake auth
      'auth': (secureToken != null && secureToken.isNotEmpty) ? {'token': secureToken} : {},
      // Native: attach Authorization header (ignored by web)
      if (secureToken != null && secureToken.isNotEmpty)
        'extraHeaders': {'Authorization': 'Bearer $secureToken'},
    };

    _socket = IO.io(origin, options);

    _socket!.onConnect((_) {
      if (kDebugMode) debugPrint('[NotificationSocket] connected');
      // Request a snapshot (unreadCount + optional backlog)
      _socket!.emit('snapshot_request');
    });

    _socket!.onConnectError((err) {
      if (kDebugMode) debugPrint('[NotificationSocket] connect_error: $err');
    });

    _socket!.onError((err) {
      if (kDebugMode) debugPrint('[NotificationSocket] error: $err');
    });

    _socket!.onDisconnect((reason) {
      if (kDebugMode) debugPrint('[NotificationSocket] disconnected: $reason');
    });

    // Snapshot payload: { unreadCount: number, items: [] }
    _socket!.on('snapshot', (payload) {
      try {
        final unread = int.tryParse('${payload?['unreadCount'] ?? 0}') ?? 0;
        final items = <AppNotification>[];
        final raw = payload?['items'];
        if (raw is List) {
          for (final it in raw) {
            items.add(AppNotification.fromSocket(it));
          }
        }
        if (!_snapshotController.isClosed) {
          _snapshotController.add(NotificationSnapshot(unreadCount: unread, items: items));
        }
        if (kDebugMode) debugPrint('[NotificationSocket] snapshot: unread=$unread, items=${items.length}');
      } catch (e) {
        if (kDebugMode) debugPrint('[NotificationSocket] snapshot parse error: $e');
      }
    });

    // Realtime single notification
    _socket!.on('notify', (payload) {
      try {
        final n = AppNotification.fromSocket(payload);
        if (!_notifController.isClosed) {
          _notifController.add(n);
        }
        if (kDebugMode) debugPrint('[NotificationSocket] notify: ${n.title}');
      } catch (e) {
        if (kDebugMode) debugPrint('[NotificationSocket] notify parse error: $e');
      }
    });

    _socket!.connect();
  }

  void markAllRead() {
    _socket?.emit('read_all');
  }

  void disconnect() {
    try {
      _socket?.off('snapshot');
      _socket?.off('notify');
      _socket?.dispose();
    } catch (_) {}
    _socket = null;
  }

  void dispose() {
    disconnect();
    _notifController.close();
    _snapshotController.close();
  }
}

class NotificationSnapshot {
  final int unreadCount;
  final List<AppNotification> items;
  NotificationSnapshot({required this.unreadCount, required this.items});
}