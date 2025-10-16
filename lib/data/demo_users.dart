class DemoUsers {
  // Fake list of users
  static final List<Map<String, String>> users = [
    {
      "email": "admin@demo.com",
      "password": "admin123",
      "role": "Admin",
    },
    {
      "email": "coach@demo.com",
      "password": "coach123",
      "role": "Coach",
    },
    {
      "email": "player@demo.com",
      "password": "player123",
      "role": "Player",
    },
  ];

  static Map<String, String>? login(String email, String password) {
    try {
      return users.firstWhere(
        (user) => user["email"] == email && user["password"] == password,
      );
    } catch (e) {
      return null;
    }
  }
}
