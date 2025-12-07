
class AppConfig {
  // Base HTTP API URL (already used by your services)
  static const String baseUrl = String.fromEnvironment(
    'APP_BASE_URL',
    defaultValue: 'https://api.stebofarm.co.tz',
  );

  // Socket.IO URL for real-time features
  static const String socketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'ws://api.stebofarm.co.tz', // Change this to your Socket.IO server
  );
}


// defaultValue: 'http://localhost:8080',
// defaultValue: 'https://api.stebofarm.co.tz',
// defaultValue: 'https://magasin-api.iperfee.com',
// defaultValue: 'http://74.50.97.22:8080',
// defaultValue: 'https://app.stebofarm.co.tz',
