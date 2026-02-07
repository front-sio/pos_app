
class AppConfig {
  // Base HTTP API URL (already used by your services)
  static const String baseUrl = String.fromEnvironment(
    'APP_BASE_URL',
    defaultValue: 'http://pos-posapi-ef0xxp-f6dd3b-138-68-41-254.traefik.me',
  );
}


// defaultValue: 'http://localhost:8080',
// defaultValue: 'https://api.stebofarm.co.tz',
// defaultValue: 'https://magasin-api.iperfee.com',
// defaultValue: 'http://74.50.97.22:8080',
// defaultValue: 'https://app.stebofarm.co.tz',
