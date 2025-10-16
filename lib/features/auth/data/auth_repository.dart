import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_api_service.dart';

class AuthRepository {
  final AuthApiService apiService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthRepository(this.apiService);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final userData = await apiService.login(email, password);
    if (userData['token'] != null) {
      await _storage.write(key: 'token', value: userData['token']);
      await _storage.write(key: 'userId', value: userData['user']['id'].toString());
      await _storage.write(key: 'firstName', value: userData['user']['first_name']);
      await _storage.write(key: 'lastName', value: userData['user']['last_name']);
      await _storage.write(key: 'username', value: userData['user']['username']);
      await _storage.write(key: 'email', value: userData['user']['email']);
    }
    return userData;
  }

  Future<Map<String, dynamic>> register(
    String username, 
    String email, 
    String firstName, 
    String lastName, 
    String password, 
    String gender 
  ) async {
    final userData = await apiService.register(username, email, firstName, lastName, password, gender);
    if (userData['token'] != null) {
      await _storage.write(key: 'token', value: userData['token']);
      await _storage.write(key: 'userId', value: userData['user']['id'].toString());
      await _storage.write(key: 'email', value: userData['user']['email']);
      await _storage.write(key: 'firstName', value: userData['user']['first_name']);
      await _storage.write(key: 'lastName', value: userData['user']['last_name']);
      await _storage.write(key: 'username', value: userData['user']['username']);
    }
    return userData;
  }
  
  Future<void> saveUsername(String username) async {
    await _storage.write(key: 'username', value: username);
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<String?> getFirstName() async {
    return await _storage.read(key: 'firstName');
  }
  
  Future<String?> getLastName() async {
    return await _storage.read(key: 'lastName');
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: 'userId');
  }

  Future<String?> getUsername() async {
    return await _storage.read(key: 'username');
  }

  Future<String?> getEmail() async {
    return await _storage.read(key: 'email');
  }
}
