import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../users/services/users_api_service.dart';
import '../../widgets/modern_card.dart';
import '../../constants/colors.dart';

class AuthDebugScreen extends StatefulWidget {
  const AuthDebugScreen({Key? key}) : super(key: key);

  @override
  State<AuthDebugScreen> createState() => _AuthDebugScreenState();
}

class _AuthDebugScreenState extends State<AuthDebugScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Map<String, String?> _storedData = {};
  String? _testResult = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadStoredData();
  }

  Future<void> _loadStoredData() async {
    setState(() => _loading = true);
    
    try {
      final data = <String, String?>{};
      
      // Load all stored auth data
      data['token'] = await _storage.read(key: 'token');
      data['userId'] = await _storage.read(key: 'userId');
      data['username'] = await _storage.read(key: 'username');
      data['email'] = await _storage.read(key: 'email');
      data['firstName'] = await _storage.read(key: 'firstName');
      data['lastName'] = await _storage.read(key: 'lastName');
      data['roles'] = await _storage.read(key: 'roles');
      data['permissions'] = await _storage.read(key: 'permissions');
      data['isSuperuser'] = await _storage.read(key: 'isSuperuser');
      
      setState(() {
        _storedData = data;
      });
    } catch (e) {
      setState(() {
        _testResult = 'Error loading data: $e';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _testUsersAPI() async {
    setState(() {
      _loading = true;
      _testResult = 'Testing users API...';
    });
    
    try {
      final token = _storedData['token'];
      if (token == null || token.isEmpty) {
        setState(() => _testResult = '❌ No token found in storage');
        return;
      }
      
      final usersService = UsersApiService();
      
      // Test fetching users
      final users = await usersService.fetchUsers(token);
      setState(() => _testResult = '✅ Users API works! Found ${users.length} users');
      
    } catch (e) {
      setState(() => _testResult = '❌ Users API failed: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _testRolesAPI() async {
    setState(() {
      _loading = true;
      _testResult = 'Testing roles API...';
    });
    
    try {
      final token = _storedData['token'];
      if (token == null || token.isEmpty) {
        setState(() => _testResult = '❌ No token found in storage');
        return;
      }
      
      final usersService = UsersApiService();
      
      // Test fetching roles
      final roles = await usersService.fetchRoles(token);
      setState(() => _testResult = '✅ Roles API works! Found ${roles.length} roles');
      
    } catch (e) {
      setState(() => _testResult = '❌ Roles API failed: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _clearStorage() async {
    await _storage.deleteAll();
    setState(() {
      _storedData = {};
      _testResult = '🗑️ Storage cleared';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth Debug'),
        backgroundColor: AppColors.kPrimary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Storage Data
            ModernCard(
              type: ModernCardType.elevated,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.storage, color: AppColors.kPrimary),
                      const SizedBox(width: 8),
                      const Text(
                        'Stored Data',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _loadStoredData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ..._storedData.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                entry.key,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                entry.value?.isEmpty == true 
                                    ? '(empty)' 
                                    : entry.value ?? '(null)',
                                style: TextStyle(
                                  color: (entry.value?.isEmpty ?? true)
                                      ? Colors.red
                                      : Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test Results
            ModernCard(
              type: ModernCardType.outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bug_report, color: AppColors.kWarning),
                      SizedBox(width: 8),
                      Text(
                        'API Tests',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_testResult?.isNotEmpty == true)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _testResult!.startsWith('✅')
                            ? Colors.green.withOpacity(0.1)
                            : _testResult!.startsWith('❌')
                                ? Colors.red.withOpacity(0.1)
                                : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _testResult!.startsWith('✅')
                              ? Colors.green
                              : _testResult!.startsWith('❌')
                                  ? Colors.red
                                  : Colors.blue,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _testResult!,
                        style: TextStyle(
                          color: _testResult!.startsWith('✅')
                              ? Colors.green.shade700
                              : _testResult!.startsWith('❌')
                                  ? Colors.red.shade700
                                  : Colors.blue.shade700,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _loading ? null : _testUsersAPI,
                        icon: const Icon(Icons.people),
                        label: const Text('Test Users API'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _loading ? null : _testRolesAPI,
                        icon: const Icon(Icons.admin_panel_settings),
                        label: const Text('Test Roles API'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _clearStorage,
                        icon: const Icon(Icons.delete),
                        label: const Text('Clear Storage'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Instructions
            ModernCard(
              type: ModernCardType.filled,
              backgroundColor: AppColors.kInfo.withOpacity(0.1),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: AppColors.kInfo),
                      SizedBox(width: 8),
                      Text(
                        'Debug Instructions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    '1. Login to the app first\n'
                    '2. Check if token and user data are stored\n'
                    '3. Test the APIs to see if they work\n'
                    '4. If APIs fail, check permissions in stored data\n'
                    '5. Clear storage if needed to reset',
                    style: TextStyle(height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}