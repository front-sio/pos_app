import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

// Platform-specific imports
import 'connectivity_service_web.dart' if (dart.library.io) 'connectivity_service_mobile.dart' as platform;

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();
  
  Stream<bool> get connectionStatus => _connectionStatusController.stream;
  bool _isConnected = true;
  StreamSubscription? _connectivitySubscription;
  Timer? _debounceTimer;

  ConnectivityService() {
    _initConnectivity();
    
    if (kIsWeb) {
      _listenToBrowserEvents();
    } else {
      _listenToConnectivity();
    }
  }
  
  Future<void> _initConnectivity() async {
    try {
      if (kIsWeb) {
        _isConnected = platform.isOnline();
        _connectionStatusController.add(_isConnected);
      } else {
        final result = await _connectivity.checkConnectivity();
        _updateConnectionStatus(result);
      }
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      _isConnected = true;
      _connectionStatusController.add(true);
    }
  }
  
  void _listenToConnectivity() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      _updateConnectionStatus(results);
    });
  }
  
  void _listenToBrowserEvents() {
    // Listen to browser's online/offline events via platform-specific implementation
    platform.addOnlineListener(() {
      _handleConnectionChange(true);
    });
    
    platform.addOfflineListener(() {
      _handleConnectionChange(false);
    });
  }
  
  void _handleConnectionChange(bool isOnline) {
    // Debounce to avoid rapid state changes
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (_isConnected != isOnline) {
        debugPrint('Network status changed: ${isOnline ? "Online" : "Offline"}');
        _isConnected = isOnline;
        _connectionStatusController.add(isOnline);
      }
    });
  }
  
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final isConnected = results.isNotEmpty && 
                       results.any((result) => result != ConnectivityResult.none);
    
    if (_isConnected != isConnected) {
      _isConnected = isConnected;
      _connectionStatusController.add(isConnected);
      debugPrint('Network status changed: ${isConnected ? "Online" : "Offline"}');
    }
  }
  
  bool get isConnected => _isConnected;
  
  Future<bool> checkConnection() async {
    try {
      if (kIsWeb) {
        return platform.isOnline();
      } else {
        final result = await _connectivity.checkConnectivity();
        return result.isNotEmpty && result.any((r) => r != ConnectivityResult.none);
      }
    } catch (e) {
      debugPrint('Error checking connection: $e');
      return false;
    }
  }
  
  void dispose() {
    _connectivitySubscription?.cancel();
    _debounceTimer?.cancel();
    _connectionStatusController.close();
  }
}
