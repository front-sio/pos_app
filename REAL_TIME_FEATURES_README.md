# Real-Time Features Implementation Guide

This guide documents the real-time features implemented in the sales app, including empty states, user activity tracking, and real-time role/auth updates using Socket.IO.

## Features Implemented

### 1. Reusable Empty State Components

#### Files:
- `lib/widgets/empty_state_widget.dart` - Main empty state widget
- `lib/widgets/universal_placeholder.dart` - Existing placeholder widget

#### Usage:

```dart
// Basic empty state
EmptyStateWidget(
  type: EmptyStateType.sales,
  onAction: () => Navigator.push(...),
)

// Predefined constructors
EmptyStateWidget.sales(onCreateSale: () => ...)
EmptyStateWidget.customers(onAddCustomer: () => ...)
EmptyStateWidget.products(onAddProduct: () => ...)
EmptyStateWidget.reports(onGenerateReport: () => ...)

// Compact version
EmptyStateWidget.compact(
  type: EmptyStateType.general,
  title: 'No data found',
  onAction: () => ...,
)

// Conditional wrapper
ConditionalEmptyState<String>(
  data: items,
  emptyState: const EmptyStateWidget.sales(),
  builder: (data) => ListView(...),
)
```

#### Available Types:
- `general` - Generic empty state
- `sales` - Sales-specific with relevant messaging
- `customers` - Customer management
- `products` - Product inventory
- `reports` - Reports and analytics
- `dashboard` - Dashboard overview
- `settings` - Settings pages
- `notifications` - Notification center

### 2. Real-Time User Activity Tracking

#### Files:
- `lib/services/socket_service.dart` - Socket.IO client service
- `lib/widgets/user_activity_widget.dart` - Activity display widget
- `sales-gateway/socket-service/` - Backend Socket.IO server

#### Features:
- Real-time online/offline status
- Activity indicators (typing, recording, editing, viewing)
- User presence management
- Room-based messaging
- Automatic heartbeat and cleanup

#### Flutter Client Usage:

```dart
// Initialize in main.dart or app initialization
void main() {
  setupLocator(); // Setup dependency injection
  SocketService.instance.connect();
  runApp(MyApp());
}

// In a screen, use ActivityTrackerMixin
class MyScreen extends StatefulWidget with ActivityTrackerMixin<MyScreen> {
  @override
  String get activityPage => 'Sales';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: UserActivityWidget(
        maxVisibleUsers: 5,
        showHeader: true,
        showOnlineCount: true,
      ),
    );
  }
}

// Manual activity tracking
SocketService.instance.emitUserViewing('Dashboard');
SocketService.instance.emitUserEditing('Product');
SocketService.instance.emitUserCreating('Sale');
SocketService.instance.emitUserTyping(details: 'Message');
SocketService.instance.emitUserRecording(details: 'Voice Note');
```

#### Activity Widget Usage:

```dart
// Full activity widget
UserActivityWidget(
  showHeader: true,
  showOnlineCount: true,
  maxVisibleUsers: 5,
  onUserTap: () => _showUserList(),
)

// Compact version for tight spaces
CompactUserActivityWidget(
  users: userList,
  maxVisibleUsers: 3,
)
```

### 3. Real-Time Role and Authentication Updates

#### Features:
- Live role updates when permissions change
- Authentication state synchronization
- Admin-triggered role changes
- Automatic UI updates based on permissions

#### Usage:

```dart
// Listen for role updates
SocketService.instance.roleUpdate.listen((data) {
  // Update UI when roles change
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Roles updated: ${data['roles']}')),
  );
});

// Listen for auth updates
SocketService.instance.authUpdate.listen((data) {
  // Handle authentication changes
  if (data['action'] == 'logout') {
    Navigator.pushReplacementNamed(context, '/login');
  }
});
```

### 4. Backend Socket.IO Server

#### Files:
- `sales-gateway/socket-service/index.js` - Main server
- `sales-gateway/socket-service/package.json` - Dependencies

#### Setup:

```bash
cd sales-gateway/socket-service
npm install
npm start
```

#### Environment Variables:

```env
SOCKET_PORT=3001
JWT_SECRET=your-jwt-secret
ALLOWED_ORIGINS=http://localhost:3000,https://app.stebofarm.co.tz
```

#### API Events:

##### Client to Server:
- `authenticate` - User authentication
- `user:activity:update` - Update user activity
- `user:typing` - Typing indicator
- `user:recording` - Recording indicator
- `users:online:request` - Request online users
- `room:join` - Join a room
- `room:leave` - Leave a room
- `room:message` - Send message to room
- `heartbeat` - Keep connection alive
- `admin:role:update` - Admin role update (superuser only)
- `admin:auth:update` - Admin auth update (superuser only)

##### Server to Client:
- `authenticated` - Authentication success
- `unauthorized` - Authentication failed
- `user:activity` - User activity update
- `users:online` - Online users list
- `user:role:updated` - Role update notification
- `user:auth:updated` - Auth update notification
- `room:joined` - Room join confirmation
- `room:left` - Room leave confirmation
- `room:{roomName}` - Room-specific messages
- `error` - Error messages

## Integration Examples

### Example 1: Sales Screen with Activity Tracking

```dart
class SalesScreen extends StatefulWidget with ActivityTrackerMixin<SalesScreen> {
  @override
  String get activityPage => 'Sales';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales'),
        actions: [
          // Show online users compactly
          StreamBuilder<List<UserActivityData>>(
            stream: SocketService.instance.onlineUsers,
            builder: (context, snapshot) {
              return CompactUserActivityWidget(
                users: snapshot.data ?? [],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Activity widget
          const UserActivityWidget(maxVisibleUsers: 3),
          
          // Sales list with empty state
          ConditionalEmptyState<Sale>(
            data: sales,
            emptyState: const EmptyStateWidget.sales(
              onCreateSale: null,
            ),
            builder: (sales) => ListView.builder(...),
          ),
        ],
      ),
    );
  }
  
  void _addSale() {
    trackCreating('Sale');
    // Navigate to sale creation
  }
}
```

### Example 2: Role-Based Content

```dart
Widget _buildRoleBasedContent() {
  return BlocBuilder<AuthBloc, AuthState>(
    builder: (context, state) {
      if (state is! AuthAuthenticated) return const SizedBox.shrink();
      
      return Column(
        children: [
          // Only show if user has permission
          if (Rbac.can(context, 'users:view'))
            ListTile(
              title: const Text('User Management'),
              onTap: () {
                SocketService.instance.emitUserViewing('User Management');
              },
            ),
            
          // Check multiple permissions
          if (Rbac.canAny(context, ['sales:create', 'sales:edit']))
            ListTile(
              title: const Text('Sales Operations'),
              onTap: () {
                SocketService.instance.emitUserViewing('Sales Operations');
              },
            ),
        ],
      );
    },
  );
}
```

### Example 3: Search with Typing Indicator

```dart
Widget _buildSearchField() {
  return TextField(
    decoration: const InputDecoration(
      labelText: 'Search...',
      prefixIcon: Icon(Icons.search),
    ),
    onChanged: (value) {
      if (value.isNotEmpty) {
        // Show typing indicator
        SocketService.instance.emitUserTyping(
          details: 'Searching for "$value"',
        );
      } else {
        // Return to viewing state
        SocketService.instance.emitUserViewing(activityPage);
      }
    },
  );
}
```

## Configuration

### Flutter App Configuration

1. **Socket URL Configuration** (`lib/config/config.dart`):
```dart
static const String socketUrl = String.fromEnvironment(
  'SOCKET_URL',
  defaultValue: 'ws://localhost:3001',
);
```

2. **Dependency Injection** (`lib/utils/dependency_injection.dart`):
```dart
void setupLocator() {
  locator.registerLazySingleton(() => AuthApiService(...));
  locator.registerLazySingleton(() => AuthRepository(...));
  locator.registerLazySingleton(() => AuthBloc(...));
}
```

### Backend Configuration

1. **Environment Setup**:
```env
SOCKET_PORT=3001
JWT_SECRET=your-super-secret-jwt-key
ALLOWED_ORIGINS=http://localhost:3000,https://yourdomain.com
```

2. **Production Considerations**:
- Use Redis for user activity storage in production
- Implement proper SSL/TLS
- Add rate limiting
- Monitor connection health

## Testing

### Demo Screen

A comprehensive demo is available at `lib/examples/activity_demo_screen.dart` showing:
- Connection status management
- Activity controls
- Typing indicators
- Empty state toggles
- Role-based content
- Real-time updates

### Running the Demo

1. Start the Socket.IO server:
```bash
cd sales-gateway/socket-service
npm install
npm start
```

2. Run the Flutter app:
```bash
cd sales-app
flutter run
```

3. Navigate to the demo screen and test the features.

## Best Practices

1. **Activity Tracking**:
   - Use `ActivityTrackerMixin` for automatic page tracking
   - Call specific activity methods for user actions
   - Handle disconnection gracefully

2. **Empty States**:
   - Use predefined constructors for consistency
   - Provide clear action buttons
   - Include contextual messaging

3. **Real-Time Updates**:
   - Always check authentication state
   - Handle connection errors gracefully
   - Provide fallback UI when offline

4. **Performance**:
   - Limit online users display
   - Use efficient data structures
   - Implement proper cleanup

## Troubleshooting

### Common Issues

1. **Socket Connection Fails**:
   - Check server is running on correct port
   - Verify JWT secret matches
   - Check CORS configuration

2. **Activity Not Updating**:
   - Ensure user is authenticated
   - Check network connectivity
   - Verify socket connection state

3. **Empty State Not Showing**:
   - Check data list is actually empty
   - Verify ConditionalEmptyState usage
   - Ensure widget is properly rebuilt

### Debug Logging

Enable debug logging by checking console output:
- Flutter: Use `debugPrint()` in SocketService
- Node.js: Console logs are enabled by default

## Future Enhancements

1. **Offline Support**: Cache activity data for offline viewing
2. **Push Notifications**: Integrate with mobile push services
3. **Advanced Rooms**: Support for nested room structures
4. **Message History**: Store and retrieve recent activity
5. **Analytics Dashboard**: Track usage patterns and statistics
