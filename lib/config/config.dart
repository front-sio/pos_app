
class AppConfig {
  // Base HTTP API URL (already used by your services)
  static const String baseUrl = String.fromEnvironment(
    'APP_BASE_URL',
    defaultValue: 'https://magasin-api.iperfee.com',
  );
}


// defaultValue: 'http://localhost:8080',
// defaultValue: 'https://api.stebofarm.co.tz',
// defaultValue: 'https://magasin-api.iperfee.com',
