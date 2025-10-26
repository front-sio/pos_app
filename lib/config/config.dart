
class AppConfig {
  // Base HTTP API URL (already used by your services)
  static const String baseUrl = String.fromEnvironment(
    'APP_BASE_URL',
    defaultValue: 'https://api.stebofarm.co.tz',
    // defaultValue: 'http://10.0.2.2:8080',
    // defaultValue: 'http://localhost:8080',
  );
}
