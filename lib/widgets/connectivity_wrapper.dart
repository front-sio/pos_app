import 'package:flutter/material.dart';
import '../core/network/connectivity_service.dart';
import 'offline_screen.dart';

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;
  
  const ConnectivityWrapper({
    super.key,
    required this.child,
  });

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _isOnline = true;
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();
    _checkInitialConnection();
    _connectivityService.connectionStatus.listen((isConnected) {
      setState(() {
        if (!isConnected && _isOnline) {
          _wasOffline = true;
        }
        
        if (isConnected && _wasOffline) {
          _showReconnectedSnackBar();
          _wasOffline = false;
        }
        
        _isOnline = isConnected;
      });
    });
  }

  Future<void> _checkInitialConnection() async {
    final isConnected = await _connectivityService.checkConnection();
    if (mounted) {
      setState(() {
        _isOnline = isConnected;
      });
    }
  }

  void _showReconnectedSnackBar() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.wifi, color: Colors.white),
              SizedBox(width: 12),
              Text('Back online! 🎉'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handleRetry() async {
    final isConnected = await _connectivityService.checkConnection();
    if (mounted) {
      setState(() {
        _isOnline = isConnected;
      });
      
      if (!isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Still no internet connection'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _connectivityService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOnline) {
      return OfflineScreen(onRetry: _handleRetry);
    }
    
    return widget.child;
  }
}
