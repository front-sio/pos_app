class AppConfig {
  // Base HTTP API URL
  static const String baseUrl = String.fromEnvironment(
    'APP_BASE_URL',
    defaultValue: 'https://api.stebofarm.co.tz',
  );

  // Optional dedicated Socket.IO URL
  static const String socketUrl = String.fromEnvironment(
    'APP_SOCKET_URL',
    defaultValue: '',
  );

  // Derive Socket.IO URL (with correct WSS scheme)
  static String deriveSocketUrl() {
    if (socketUrl.trim().isNotEmpty) return socketUrl.trim();
    final uri = Uri.parse(baseUrl);
    // Use wss if HTTPS, ws if HTTP
    final scheme = (uri.scheme == 'https') ? 'wss' : 'ws';
    final port = (uri.hasPort) ? ':${uri.port}' : '';
    return '$scheme://${uri.host}$port/socket.io-products'; // ⚡ include correct Socket.IO path
  }
}
