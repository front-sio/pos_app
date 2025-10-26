class AppConfig {
  // Base HTTP API URL
  static const String baseUrl = String.fromEnvironment(
    'APP_BASE_URL',
    defaultValue: 'https://api.stebofarm.co.tz',
  );

}
