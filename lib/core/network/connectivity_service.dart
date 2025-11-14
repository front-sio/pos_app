import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html show window;

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
        _isConnected = html.window.navigator.onLine ?? true;
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
    // Listen to browser's online event
    html.window.addEventListener('online', (event) {
      _handleConnectionChange(true);
    });
    
    // Listen to browser's offline event  
    html.window.addEventListener('offline', (event) {
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
        return html.window.navigator.onLine ?? true;
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
