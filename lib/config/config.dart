
class AppConfig {
  static const String _baseUrlRaw = String.fromEnvironment(
    'APP_BASE_URL',
    defaultValue: 'https://pos-posapi-ef0xxp-f6dd3b-138-68-41-254.traefik.me',
  );

  static const String _socketUrlRaw = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'wss://pos-posapi-ef0xxp-f6dd3b-138-68-41-254.traefik.me', // Change this to your Socket.IO server
  );

  // Prevent mixed-content calls when the app is served over HTTPS.
  static final String baseUrl = _normalizeForSecureContext(_baseUrlRaw);
  static final String socketUrl = _normalizeForSecureContext(_socketUrlRaw, isSocket: true);

  static String _normalizeForSecureContext(String value, {bool isSocket = false}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme) return trimmed;
    if (Uri.base.scheme != 'https') return trimmed;

    if (!isSocket && uri.scheme == 'http') {
      return uri.replace(scheme: 'https').toString();
    }
    if (isSocket && uri.scheme == 'ws') {
      return uri.replace(scheme: 'wss').toString();
    }
    return trimmed;
  }
}


// defaultValue: 'http://localhost:8080',
// defaultValue: 'https://api.stebofarm.co.tz',
// defaultValue: 'https://magasin-api.iperfee.com',
// defaultValue: 'http://74.50.97.22:8080',
// defaultValue: 'https://app.stebofarm.co.tz',
