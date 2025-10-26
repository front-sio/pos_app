import 'package:equatable/equatable.dart';
import 'package:sales_app/features/notitications/data/notification_model.dart';


abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object?> get props => [];
}

class StartNotifications extends NotificationEvent {
  final String? token;
  const StartNotifications({this.token});
}

class StopNotifications extends NotificationEvent {
  const StopNotifications();
}

class SnapshotReceived extends NotificationEvent {
  final int unreadCount;
  final List<AppNotification> items;
  const SnapshotReceived(this.unreadCount, this.items);

  @override
  List<Object?> get props => [unreadCount, items];
}

class NotificationReceived extends NotificationEvent {
  final AppNotification notification;
  const NotificationReceived(this.notification);

  @override
  List<Object?> get props => [notification];
}

class MarkAllRead extends NotificationEvent {
  const MarkAllRead();
}