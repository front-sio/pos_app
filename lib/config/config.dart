
class AppConfig {
  // Base HTTP API URL (already used by your services)
  static const String baseUrl = String.fromEnvironment(
    'APP_BASE_URL',
    defaultValue: 'https://api.stebofarm.co.tz',
    // defaultValue: 'http://10.0.2.2:8080',
    // defaultValue: 'http://localhost:8080',
  );

  // static const String baseUrl = "https://api.stebofarm.co.tz";
  // static const String baseUrl = "http://10.0.2.2:8080";
  // static const String baseUrl = "http://localhost:8080";

  // Optional dedicated Socket.IO URL; if empty, derive from baseUrl
  static const String socketUrl = String.fromEnvironment(
    'APP_SOCKET_URL',
    defaultValue: '',
  );

  static String deriveSocketUrl() {
    if (socketUrl.trim().isNotEmpty) return socketUrl.trim();
    final uri = Uri.parse(baseUrl);
    final scheme = (uri.scheme == 'https') ? 'https' : 'http';
    // Socket.IO can use same origin; adjust if you proxy differently
    final port = (uri.hasPort) ? ':${uri.port}' : '';
    return '$scheme://${uri.host}$port';
  }
}
