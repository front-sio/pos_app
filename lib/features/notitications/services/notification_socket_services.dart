// lib/features/notitications/services/notification_socket_services.dart
import 'dart:async';
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

  void connect({String? token}) {
    if (connected) return;

    final base = AppConfig.socketUrl.trim().isNotEmpty
        ? AppConfig.socketUrl.trim()
        : AppConfig.baseUrl;
    final uri = Uri.parse(base);
    final scheme = uri.scheme.isEmpty ? 'http' : uri.scheme;
    final port = uri.hasPort ? ':${uri.port}' : '';
    final origin = '$scheme://${uri.host}$port';

    _socket = IO.io(
      '$origin/notifications',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableForceNew()
          .setQuery({'auth': token ?? ''})
          .build(),
    );

    _socket!.onConnect((_) {
      // Ask server for a current unread count + optional backlog
      _socket!.emit('snapshot_request');
    });

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
        _snapshotController.add(NotificationSnapshot(unreadCount: unread, items: items));
      } catch (_) {
        // swallow parse errors to keep stream healthy
      }
    });

    _socket!.on('notify', (payload) {
      try {
        _notifController.add(AppNotification.fromSocket(payload));
      } catch (_) {
        // ignore malformed messages
      }
    });

    _socket!.onDisconnect((_) {});
    _socket!.onError((_) {});
    _socket!.connect();
  }

  void markAllRead() {
    _socket?.emit('read_all');
  }

  void disconnect() {
    _socket?.dispose();
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