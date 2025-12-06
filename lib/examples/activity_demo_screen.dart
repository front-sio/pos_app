import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/socket_service.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/user_activity_widget.dart';
import '../widgets/modern_button.dart';
import '../widgets/custom_field.dart';
import '../features/auth/logic/auth_bloc.dart';
import '../features/auth/logic/auth_state.dart';
import '../rbac/rbac.dart';

class ActivityDemoScreen extends StatefulWidget {
  const ActivityDemoScreen({Key? key}) : super(key: key);

  @override
  State<ActivityDemoScreen> createState() => _ActivityDemoScreenState();
}

class _ActivityDemoScreenState extends State<ActivityDemoScreen>
    with ActivityTrackerMixin<ActivityDemoScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _showEmptyState = false;
  List<String> _mockData = [];

  @override
  String get activityPage => 'Activity Demo';

  @override
  void initState() {
    super.initState();
    _loadMockData();
    _setupSocketListeners();
  }

  void _loadMockData() {
    // Simulate loading data
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _mockData = ['Item 1', 'Item 2', 'Item 3'];
      });
    });
  }

  void _setupSocketListeners() {
    // Listen for role updates
    SocketService.instance.roleUpdate.listen((data) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Your roles have been updated: ${data['roles']?.join(', ')}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });

    // Listen for auth updates
    SocketService.instance.authUpdate.listen((data) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Your authentication has been updated'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _showEmptyState = !_showEmptyState),
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is! AuthAuthenticated) {
            return const Center(
              child: Text('Please login to access this feature'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Connection status
                _buildConnectionStatus(),
                const SizedBox(height: 20),

                // User activity widget
                const UserActivityWidget(
                  maxVisibleUsers: 3,
                  showHeader: true,
                  showOnlineCount: true,
                ),
                const SizedBox(height: 20),

                // Demo controls
                _buildDemoControls(),
                const SizedBox(height: 20),

                // Search field with typing indicator
                _buildSearchField(),
                const SizedBox(height: 20),

                // Empty state demo
                _buildEmptyStateDemo(),
                const SizedBox(height: 20),

                // Role-based content
                _buildRoleBasedContent(authState),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return StreamBuilder<SocketConnectionState>(
      stream: SocketService.instance.connectionState,
      builder: (context, snapshot) {
        final state = snapshot.data ?? SocketConnectionState.disconnected;
        
        Color statusColor;
        String statusText;
        IconData statusIcon;

        switch (state) {
          case SocketConnectionState.connected:
            statusColor = Colors.green;
            statusText = 'Connected';
            statusIcon = Icons.wifi;
            break;
          case SocketConnectionState.connecting:
            statusColor = Colors.orange;
            statusText = 'Connecting...';
            statusIcon = Icons.wifi_find;
            break;
          case SocketConnectionState.reconnecting:
            statusColor = Colors.orange;
            statusText = 'Reconnecting...';
            statusIcon = Icons.sync;
            break;
          case SocketConnectionState.error:
            statusColor = Colors.red;
            statusText = 'Connection Error';
            statusIcon = Icons.wifi_off;
            break;
          case SocketConnectionState.disconnected:
          default:
            statusColor = Colors.grey;
            statusText = 'Disconnected';
            statusIcon = Icons.wifi_off;
            break;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(statusIcon, color: statusColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Real-time Connection',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      statusText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              ModernButton(
                text: 'Reconnect',
                type: ModernButtonType.outline,
                onPressed: () {
                  if (state == SocketConnectionState.connected) {
                    SocketService.instance.disconnect();
                  } else {
                    SocketService.instance.connect();
                  }
                },
                size: ModernButtonSize.small,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDemoControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity Controls',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ModernButton(
                  text: 'View Dashboard',
                  icon: Icons.dashboard,
                  onPressed: () {
                    SocketService.instance.emitUserViewing('Dashboard');
                    trackEditing('Dashboard Settings');
                  },
                ),
                ModernButton(
                  text: 'Edit Product',
                  icon: Icons.edit,
                  onPressed: () {
                    SocketService.instance.emitUserEditing('Product');
                  },
                ),
                ModernButton(
                  text: 'Create Sale',
                  icon: Icons.add,
                  onPressed: () {
                    SocketService.instance.emitUserCreating('Sale');
                  },
                ),
                ModernButton(
                  text: 'Start Typing',
                  icon: Icons.keyboard,
                  onPressed: () {
                    SocketService.instance.emitUserTyping(details: 'Demo Message');
                  },
                ),
                ModernButton(
                  text: 'Record Audio',
                  icon: Icons.mic,
                  onPressed: () {
                    SocketService.instance.emitUserRecording(details: 'Voice Note');
                  },
                ),
                ModernButton(
                  text: 'Go Online',
                  icon: Icons.online_prediction,
                  onPressed: () {
                    SocketService.instance.setActivity(UserActivity.online);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search with Typing Indicator',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            CustomInput(
              controller: _searchController,
              label: 'Search...',
              prefixIcon: Icons.search,
              onChanged: (value) {
                if (value.isNotEmpty) {
                  SocketService.instance.emitUserTyping(details: 'Searching for "$value"');
                } else {
                  SocketService.instance.setActivity(UserActivity.viewing, page: activityPage);
                }
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'Start typing to see the "is typing..." indicator in the activity widget above.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateDemo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Empty State Demo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _showEmptyState,
                  onChanged: (value) => setState(() => _showEmptyState = value),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ConditionalEmptyState<String>(
                data: _showEmptyState ? [] : _mockData,
                emptyState: const EmptyStateWidget.sales(
                  onCreateSale: null,
                ),
                builder: (data) {
                  return ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.receipt_long)),
                        title: Text(data[index]),
                        subtitle: Text('Sale item ${index + 1}'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBasedContent(AuthAuthenticated authState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Role-Based Content',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // Check if user can view users
            if (Rbac.can(context, 'users:view'))
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('User Management'),
                subtitle: const Text('You have permission to manage users'),
                trailing: ModernButton(
                  text: 'Manage',
                  type: ModernButtonType.outline,
                  onPressed: () {
                    SocketService.instance.emitUserViewing('User Management');
                  },
                  size: ModernButtonSize.small,
                ),
              ),

            // Check if user can create sales
            if (Rbac.can(context, 'sales:create'))
              ListTile(
                leading: const Icon(Icons.add_circle),
                title: const Text('Create Sales'),
                subtitle: const Text('You have permission to create sales'),
                trailing: ModernButton(
                  text: 'Create',
                  type: ModernButtonType.outline,
                  onPressed: () {
                    SocketService.instance.emitUserCreating('Sale');
                  },
                  size: ModernButtonSize.small,
                ),
              ),

            // Check if user can view reports
            if (Rbac.can(context, 'reports:view'))
              ListTile(
                leading: const Icon(Icons.analytics),
                title: const Text('View Reports'),
                subtitle: const Text('You have permission to view reports'),
                trailing: ModernButton(
                  text: 'View',
                  type: ModernButtonType.outline,
                  onPressed: () {
                    SocketService.instance.emitUserViewing('Reports');
                  },
                  size: ModernButtonSize.small,
                ),
              ),

            // Show message if no permissions
            if (!Rbac.canAny(context, ['users:view', 'sales:create', 'reports:view']))
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'You don\'t have permissions for any of the demo features. Contact your administrator.',
                  style: TextStyle(color: Colors.orange),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 16),
            const Text(
              'Your Roles:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: authState.roles.map((role) {
                return Chip(
                  label: Text(role),
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  side: BorderSide(color: Colors.blue),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
