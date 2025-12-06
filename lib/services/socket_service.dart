import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/config.dart';
import '../features/auth/logic/auth_bloc.dart';
import '../features/auth/logic/auth_state.dart';
import '../utils/dependency_injection.dart';

enum SocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

enum UserActivity {
  online,
  offline,
  typing,
  recording,
  viewing,
  editing,
  creating,
  idle,
}

class UserActivityData {
  final int userId;
  final String username;
  final String? fullName;
  final UserActivity activity;
  final String? details;
  final String? page;
  final DateTime timestamp;

  UserActivityData({
    required this.userId,
    required this.username,
    this.fullName,
    required this.activity,
    this.details,
    this.page,
    required this.timestamp,
  });

  factory UserActivityData.fromJson(Map<String, dynamic> json) {
    return UserActivityData(
      userId: json['userId'] ?? 0,
      username: json['username'] ?? '',
      fullName: json['fullName'],
      activity: UserActivity.values.firstWhere(
        (e) => e.toString() == 'UserActivity.${json['activity']}',
        orElse: () => UserActivity.online,
      ),
      details: json['details'],
      page: json['page'],
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'fullName': fullName,
      'activity': activity.toString().split('.').last,
      'details': details,
      'page': page,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  String get activityDisplayText {
    switch (activity) {
      case UserActivity.online:
        return 'is online';
      case UserActivity.offline:
        return 'is offline';
      case UserActivity.typing:
        return 'is typing...';
      case UserActivity.recording:
        return 'is recording...';
      case UserActivity.viewing:
        return details != null ? 'is viewing $details' : 'is viewing';
      case UserActivity.editing:
        return details != null ? 'is editing $details' : 'is editing';
      case UserActivity.creating:
        return details != null ? 'is creating $details' : 'is creating';
      case UserActivity.idle:
        return 'is idle';
    }
  }
}

class SocketService {
  static SocketService? _instance;
  static SocketService get instance {
    _instance ??= SocketService._internal();
    return _instance!;
  }

  SocketService._internal();

  IO.Socket? _socket;
  SocketConnectionState _connectionState = SocketConnectionState.disconnected;
  Timer? _heartbeatTimer;
  Timer? _idleTimer;
  UserActivity _currentActivity = UserActivity.offline;
  String? _currentPage;
  String? _currentDetails;
  
  // Event streams
  final _connectionStateController = StreamController<SocketConnectionState>.broadcast();
  final _userActivityController = StreamController<UserActivityData>.broadcast();
  final _onlineUsersController = StreamController<List<UserActivityData>>.broadcast();
  final _roleUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  final _authUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  
  // Public streams
  Stream<SocketConnectionState> get connectionState => _connectionStateController.stream;
  Stream<UserActivityData> get userActivity => _userActivityController.stream;
  Stream<List<UserActivityData>> get onlineUsers => _onlineUsersController.stream;
  Stream<Map<String, dynamic>> get roleUpdate => _roleUpdateController.stream;
  Stream<Map<String, dynamic>> get authUpdate => _authUpdateController.stream;

  SocketConnectionState get currentState => _connectionState;
  bool get isConnected => _connectionState == SocketConnectionState.connected;
  UserActivity get currentActivity => _currentActivity;

  Future<void> connect() async {
    if (_connectionState == SocketConnectionState.connected || 
        _connectionState == SocketConnectionState.connecting) {
      return;
    }

    try {
      _setConnectionState(SocketConnectionState.connecting);

      // Get auth token from AuthBloc
      final authBloc = locator<AuthBloc>();
      final authState = authBloc.state;
      
      if (authState is! AuthAuthenticated) {
        debugPrint('[SocketService] Cannot connect: User not authenticated');
        _setConnectionState(SocketConnectionState.error);
        return;
      }

      final token = authState.token;
      final userId = authState.userId;

      _socket = IO.io(
        AppConfig.socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .setAuth({
              'token': token,
              'userId': userId,
            })
            .build(),
      );

      _setupEventListeners();
      
    } catch (e) {
      debugPrint('[SocketService] Connection error: $e');
      _setConnectionState(SocketConnectionState.error);
    }
  }

  void _setupEventListeners() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      debugPrint('[SocketService] Connected to server');
      _setConnectionState(SocketConnectionState.connected);
      _startHeartbeat();
      _setActivity(UserActivity.online);
    });

    _socket!.onDisconnect((_) {
      debugPrint('[SocketService] Disconnected from server');
      _setConnectionState(SocketConnectionState.disconnected);
      _stopHeartbeat();
      _setActivity(UserActivity.offline);
    });

    _socket!.onConnectError((error) {
      debugPrint('[SocketService] Connection error: $error');
      _setConnectionState(SocketConnectionState.error);
    });

    _socket!.onReconnect((_) {
      debugPrint('[SocketService] Reconnecting...');
      _setConnectionState(SocketConnectionState.reconnecting);
    });

    _socket!.onReconnectAttempt((attempt) {
      debugPrint('[SocketService] Reconnect attempt: $attempt');
    });

    // User activity events
    _socket!.on('user:activity', (data) {
      try {
        final activityData = UserActivityData.fromJson(data);
        _userActivityController.add(activityData);
        debugPrint('[SocketService] User activity: ${activityData.username} ${activityData.activityDisplayText}');
      } catch (e) {
        debugPrint('[SocketService] Error parsing user activity: $e');
      }
    });

    _socket!.on('users:online', (data) {
      try {
        final List<dynamic> usersList = data['users'] ?? [];
        final users = usersList
            .map((user) => UserActivityData.fromJson(user))
            .toList();
        _onlineUsersController.add(users);
        debugPrint('[SocketService] Online users count: ${users.length}');
      } catch (e) {
        debugPrint('[SocketService] Error parsing online users: $e');
      }
    });

    // Role and auth update events
    _socket!.on('user:role:updated', (data) {
      try {
        _roleUpdateController.add(data);
        debugPrint('[SocketService] Role updated: $data');
      } catch (e) {
        debugPrint('[SocketService] Error parsing role update: $e');
      }
    });

    _socket!.on('user:auth:updated', (data) {
      try {
        _authUpdateController.add(data);
        debugPrint('[SocketService] Auth updated: $data');
      } catch (e) {
        debugPrint('[SocketService] Error parsing auth update: $e');
      }
    });

    // Error events
    _socket!.on('error', (data) {
      debugPrint('[SocketService] Server error: $data');
    });

    _socket!.on('unauthorized', (data) {
      debugPrint('[SocketService] Unauthorized: $data');
      _setConnectionState(SocketConnectionState.error);
    });
  }

  void _setConnectionState(SocketConnectionState state) {
    if (_connectionState != state) {
      _connectionState = state;
      _connectionStateController.add(state);
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_socket != null && isConnected) {
        _socket!.emit('heartbeat');
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _startIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_currentActivity != UserActivity.idle && _currentActivity != UserActivity.offline) {
        _setActivity(UserActivity.idle);
      }
    });
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    _startIdleTimer();
  }

  void setActivity(UserActivity activity, {String? page, String? details}) {
    if (!isConnected) return;

    _currentActivity = activity;
    _currentPage = page;
    _currentDetails = details;
    _resetIdleTimer();

    final authBloc = locator<AuthBloc>();
    final authState = authBloc.state;
    
    if (authState is AuthAuthenticated) {
      final activityData = {
        'userId': authState.userId,
        'username': authState.username,
        'fullName': '${authState.firstName} ${authState.lastName}',
        'activity': activity.toString().split('.').last,
        'details': details,
        'page': page,
        'timestamp': DateTime.now().toIso8601String(),
      };

      _socket!.emit('user:activity:update', activityData);
      debugPrint('[SocketService] Activity updated: ${authState.username} ${activity.toString().split('.').last}');
    }
  }

  void _setActivity(UserActivity activity) {
    setActivity(activity);
  }

  void emitUserTyping({String? details}) {
    setActivity(UserActivity.typing, details: details);
  }

  void emitUserRecording({String? details}) {
    setActivity(UserActivity.recording, details: details);
  }

  void emitUserViewing(String page, {String? details}) {
    setActivity(UserActivity.viewing, page: page, details: details);
  }

  void emitUserEditing(String item, {String? details}) {
    setActivity(UserActivity.editing, details: item);
  }

  void emitUserCreating(String item, {String? details}) {
    setActivity(UserActivity.creating, details: item);
  }

  void requestOnlineUsers() {
    if (!isConnected) return;
    _socket!.emit('users:online:request');
  }

  void joinRoom(String room) {
    if (!isConnected) return;
    _socket!.emit('room:join', {'room': room});
    debugPrint('[SocketService] Joined room: $room');
  }

  void leaveRoom(String room) {
    if (!isConnected) return;
    _socket!.emit('room:leave', {'room': room});
    debugPrint('[SocketService] Left room: $room');
  }

  void emitToRoom(String room, String event, dynamic data) {
    if (!isConnected) return;
    _socket!.emit('room:message', {
      'room': room,
      'event': event,
      'data': data,
    });
    debugPrint('[SocketService] Emitted to room $room: $event');
  }

  void subscribeToRoomEvents(String room, Function(dynamic) callback) {
    if (!isConnected) return;
    _socket!.on('room:$room', callback);
  }

  void unsubscribeFromRoomEvents(String room) {
    if (!isConnected) return;
    _socket!.off('room:$room');
  }

  Future<void> disconnect() async {
    _heartbeatTimer?.cancel();
    _idleTimer?.cancel();
    
    if (_socket != null) {
      _setActivity(UserActivity.offline);
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    
    _setConnectionState(SocketConnectionState.disconnected);
  }

  void dispose() {
    disconnect();
    _connectionStateController.close();
    _userActivityController.close();
    _onlineUsersController.close();
    _roleUpdateController.close();
    _authUpdateController.close();
  }
}

// Extension for easy activity tracking in widgets
extension ActivityTracker on Widget {
  void trackActivity(String page, {String? details}) {
    SocketService.instance.emitUserViewing(page, details: details);
  }
}

// Mixin for easy activity tracking in screens
mixin ActivityTrackerMixin<T extends StatefulWidget> on State<T> {
  String get activityPage;
  String? get activityDetails => null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SocketService.instance.emitUserViewing(activityPage, details: activityDetails);
    });
  }

  @override
  void dispose() {
    SocketService.instance.setActivity(UserActivity.online);
    super.dispose();
  }

  void trackEditing(String item) {
    SocketService.instance.emitUserEditing(item);
  }

  void trackCreating(String item) {
    SocketService.instance.emitUserCreating(item);
  }

  void trackTyping({String? details}) {
    SocketService.instance.emitUserTyping(details: details);
  }

  void trackRecording({String? details}) {
    SocketService.instance.emitUserRecording(details: details);
  }
}
