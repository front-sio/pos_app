import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'dart:html' as html show window;

// Events
abstract class ConnectivityEvent extends Equatable {
  const ConnectivityEvent();

  @override
  List<Object> get props => [];
}

class ConnectivityChanged extends ConnectivityEvent {
  final bool isOnline;

  const ConnectivityChanged(this.isOnline);

  @override
  List<Object> get props => [isOnline];
}

class CheckConnectivity extends ConnectivityEvent {
  const CheckConnectivity();
}

// States
abstract class ConnectivityState extends Equatable {
  const ConnectivityState();

  @override
  List<Object> get props => [];
}

class ConnectivityInitial extends ConnectivityState {}

class ConnectivityOnline extends ConnectivityState {}

class ConnectivityOffline extends ConnectivityState {}

// Bloc
class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _debounceTimer;

  ConnectivityBloc() : super(ConnectivityInitial()) {
    on<ConnectivityChanged>(_onConnectivityChanged);
    on<CheckConnectivity>(_onCheckConnectivity);

    if (kIsWeb) {
      _listenToWebEvents();
    } else {
      // Listen to connectivity changes for mobile
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (result) {
          final isOnline = result.isNotEmpty && 
                          !result.contains(ConnectivityResult.none);
          add(ConnectivityChanged(isOnline));
        },
      );
    }

    // Check initial connectivity
    add(const CheckConnectivity());
  }

  void _listenToWebEvents() {
    // Listen to browser's online/offline events
    html.window.addEventListener('online', (event) {
      _handleConnectionChange(true);
    });
    
    html.window.addEventListener('offline', (event) {
      _handleConnectionChange(false);
    });
  }

  void _handleConnectionChange(bool isOnline) {
    // Debounce to avoid rapid state changes
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      add(ConnectivityChanged(isOnline));
    });
  }

  void _onConnectivityChanged(
    ConnectivityChanged event,
    Emitter<ConnectivityState> emit,
  ) {
    if (event.isOnline) {
      emit(ConnectivityOnline());
    } else {
      emit(ConnectivityOffline());
    }
  }

  Future<void> _onCheckConnectivity(
    CheckConnectivity event,
    Emitter<ConnectivityState> emit,
  ) async {
    if (kIsWeb) {
      final isOnline = html.window.navigator.onLine ?? true;
      emit(isOnline ? ConnectivityOnline() : ConnectivityOffline());
    } else {
      final result = await _connectivity.checkConnectivity();
      if (result.contains(ConnectivityResult.none)) {
        emit(ConnectivityOffline());
      } else {
        emit(ConnectivityOnline());
      }
    }
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    _debounceTimer?.cancel();
    return super.close();
  }
}
