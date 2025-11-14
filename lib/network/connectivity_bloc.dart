import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class ConnectivityEvent extends Equatable {
  const ConnectivityEvent();

  @override
  List<Object> get props => [];
}

class ConnectivityChanged extends ConnectivityEvent {
  final List<ConnectivityResult> result;

  const ConnectivityChanged(this.result);

  @override
  List<Object> get props => [result];
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

  ConnectivityBloc() : super(ConnectivityInitial()) {
    on<ConnectivityChanged>(_onConnectivityChanged);
    on<CheckConnectivity>(_onCheckConnectivity);

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (result) => add(ConnectivityChanged(result)),
    );

    // Check initial connectivity
    add(const CheckConnectivity());
  }

  void _onConnectivityChanged(
    ConnectivityChanged event,
    Emitter<ConnectivityState> emit,
  ) {
    if (event.result.contains(ConnectivityResult.none)) {
      emit(ConnectivityOffline());
    } else {
      emit(ConnectivityOnline());
    }
  }

  Future<void> _onCheckConnectivity(
    CheckConnectivity event,
    Emitter<ConnectivityState> emit,
  ) async {
    final result = await _connectivity.checkConnectivity();
    if (result.contains(ConnectivityResult.none)) {
      emit(ConnectivityOffline());
    } else {
      emit(ConnectivityOnline());
    }
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
