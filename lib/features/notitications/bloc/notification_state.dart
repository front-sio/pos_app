import 'package:equatable/equatable.dart';
import 'package:sales_app/features/notitications/data/notification_model.dart';

class NotificationState extends Equatable {
  final bool connected;
  final int unreadCount;
  final List<AppNotification> items;

  const NotificationState({
    required this.connected,
    required this.unreadCount,
    required this.items,
  });

  factory NotificationState.initial() => const NotificationState(
        connected: false,
        unreadCount: 0,
        items: <AppNotification>[],
      );

  NotificationState copyWith({
    bool? connected,
    int? unreadCount,
    List<AppNotification>? items,
  }) {
    return NotificationState(
      connected: connected ?? this.connected,
      unreadCount: unreadCount ?? this.unreadCount,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [connected, unreadCount, items];
}