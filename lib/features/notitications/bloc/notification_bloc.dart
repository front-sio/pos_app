import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/features/notitications/bloc/notification_event.dart';
import 'package:sales_app/features/notitications/bloc/notification_state.dart';
import 'package:sales_app/features/notitications/data/notification_model.dart';
import 'package:sales_app/features/notitications/services/notification_socket_services.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationSocketService service;

  StreamSubscription<AppNotification>? _sub;
  StreamSubscription<NotificationSnapshot>? _snapSub;

  NotificationBloc({required this.service}) : super(NotificationState.initial()) {
    on<StartNotifications>(_onStart);
    on<StopNotifications>(_onStop);
    on<SnapshotReceived>(_onSnapshot);
    on<NotificationReceived>(_onNotification);
    on<MarkAllRead>(_onMarkAllRead);
  }

  Future<void> _onStart(StartNotifications event, Emitter<NotificationState> emit) async {
    service.connect(token: event.token);
    await _snapSub?.cancel();
    await _sub?.cancel();

    _snapSub = service.snapshot.listen((snap) {
      add(SnapshotReceived(snap.unreadCount, snap.items));
    });

    _sub = service.notifications.listen((n) {
      add(NotificationReceived(n));
    });

    emit(state.copyWith(connected: true));
  }

  Future<void> _onStop(StopNotifications event, Emitter<NotificationState> emit) async {
    await _sub?.cancel();
    await _snapSub?.cancel();
    service.disconnect();
    emit(state.copyWith(connected: false));
  }

  void _onSnapshot(SnapshotReceived event, Emitter<NotificationState> emit) {
    emit(state.copyWith(
      unreadCount: event.unreadCount,
      items: [...event.items],
    ));
  }

  void _onNotification(NotificationReceived event, Emitter<NotificationState> emit) {
    final updated = [event.notification, ...state.items];
    emit(state.copyWith(
      items: updated,
      unreadCount: state.unreadCount + 1,
    ));
  }

  void _onMarkAllRead(MarkAllRead event, Emitter<NotificationState> emit) {
    final updated = state.items.map((e) => e.copyWith(read: true)).toList();
    emit(state.copyWith(items: updated, unreadCount: 0));
    service.markAllRead();
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    _snapSub?.cancel();
    service.dispose();
    return super.close();
  }
}