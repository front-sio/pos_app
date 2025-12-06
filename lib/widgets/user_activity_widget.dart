import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/sizes.dart';
import '../services/socket_service.dart';
import '../theme/theme_manager.dart';

class UserActivityWidget extends StatefulWidget {
  final bool showHeader;
  final bool showOnlineCount;
  final int maxVisibleUsers;
  final Widget Function(UserActivityData activity)? customUserTile;
  final VoidCallback? onUserTap;

  const UserActivityWidget({
    Key? key,
    this.showHeader = true,
    this.showOnlineCount = true,
    this.maxVisibleUsers = 5,
    this.customUserTile,
    this.onUserTap,
  }) : super(key: key);

  @override
  State<UserActivityWidget> createState() => _UserActivityWidgetState();
}

class _UserActivityWidgetState extends State<UserActivityWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  List<UserActivityData> _onlineUsers = [];
  UserActivityData? _lastActivity;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupSocketListeners();
    _requestOnlineUsers();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: AppSizes.mediumAnimation,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: AppSizes.defaultCurve,
    ));

    _fadeController = AnimationController(
      duration: AppSizes.shortAnimation,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
  }

  void _setupSocketListeners() {
    SocketService.instance.onlineUsers.listen((users) {
      if (mounted) {
        setState(() {
          _onlineUsers = users;
        });
        _slideController.forward();
      }
    });

    SocketService.instance.userActivity.listen((activity) {
      if (mounted) {
        setState(() {
          _lastActivity = activity;
        });
        _fadeController.forward().then((_) {
          _fadeController.reverse();
        });
      }
    });
  }

  void _requestOnlineUsers() {
    if (SocketService.instance.isConnected) {
      SocketService.instance.requestOnlineUsers();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_onlineUsers.isEmpty && _lastActivity == null) {
      return const SizedBox.shrink();
    }

    final businessColors = ThemeManager().currentBusinessColors;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showHeader) _buildHeader(businessColors),
          if (_lastActivity != null) _buildLastActivity(businessColors),
          if (_onlineUsers.isNotEmpty) _buildOnlineUsersList(businessColors),
        ],
      ),
    );
  }

  Widget _buildHeader(BusinessThemeColors businessColors) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.people_outline,
            color: businessColors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Team Activity',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: businessColors.primary,
            ),
          ),
          const Spacer(),
          if (widget.showOnlineCount)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: businessColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_onlineUsers.length} online',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: businessColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLastActivity(BusinessThemeColors businessColors) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: businessColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: businessColors.primary.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            _buildActivityIcon(_lastActivity!.activity, businessColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _lastActivity!.fullName ?? _lastActivity!.username,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _lastActivity!.activityDisplayText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _formatTimestamp(_lastActivity!.timestamp),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineUsersList(BusinessThemeColors businessColors) {
    final visibleUsers = _onlineUsers.take(widget.maxVisibleUsers).toList();

    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        children: [
          ...visibleUsers.map((user) => _buildUserTile(user, businessColors.primary)),
          if (_onlineUsers.length > widget.maxVisibleUsers)
            _buildSeeMoreButton(),
        ],
      ),
    );
  }

  Widget _buildUserTile(UserActivityData user, Color businessColor) {
    if (widget.customUserTile != null) {
      return widget.customUserTile!(user);
    }

    return InkWell(
      onTap: () => widget.onUserTap?.call(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            _buildUserAvatar(user),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName ?? user.username,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (user.activity != UserActivity.online)
                    Text(
                      user.activityDisplayText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
            _buildActivityIndicator(user.activity, businessColor),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar(UserActivityData user) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: _getUserColor(user.userId),
          child: Text(
            _getInitials(user.fullName ?? user.username),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _getActivityColor(user.activity),
              border: Border.all(color: Colors.white, width: 2),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityIcon(UserActivity activity, Color businessColor) {
    IconData icon;
    Color color;

    switch (activity) {
      case UserActivity.typing:
        icon = Icons.keyboard;
        color = Colors.blue;
        break;
      case UserActivity.recording:
        icon = Icons.mic;
        color = Colors.red;
        break;
      case UserActivity.editing:
        icon = Icons.edit;
        color = Colors.orange;
        break;
      case UserActivity.creating:
        icon = Icons.add_circle;
        color = Colors.green;
        break;
      case UserActivity.viewing:
        icon = Icons.visibility;
        color = Colors.purple;
        break;
      case UserActivity.idle:
        icon = Icons.bedtime;
        color = Colors.grey;
        break;
      case UserActivity.online:
        icon = Icons.online_prediction;
        color = businessColor;
        break;
      case UserActivity.offline:
        icon = Icons.offline_bolt;
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: color,
        size: 20,
      ),
    );
  }

  Widget _buildActivityIndicator(UserActivity activity, Color businessColor) {
    if (activity == UserActivity.typing) {
      return _buildTypingIndicator();
    }

    if (activity == UserActivity.recording) {
      return _buildRecordingIndicator();
    }

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: _getActivityColor(activity),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _fadeController,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.5 + (0.5 * _fadeAnimation.value),
              child: Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(right: 2),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildRecordingIndicator() {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.3 + (0.7 * _fadeAnimation.value)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildSeeMoreButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextButton(
        onPressed: () => widget.onUserTap?.call(),
        child: Text(
          'See ${_onlineUsers.length - widget.maxVisibleUsers} more',
          style: TextStyle(
            color: ThemeManager().currentBusinessColors.primary,
          ),
        ),
      ),
    );
  }

  Color _getUserColor(int userId) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[userId % colors.length];
  }

  Color _getActivityColor(UserActivity activity) {
    switch (activity) {
      case UserActivity.online:
        return Colors.green;
      case UserActivity.offline:
        return Colors.grey;
      case UserActivity.typing:
        return Colors.blue;
      case UserActivity.recording:
        return Colors.red;
      case UserActivity.viewing:
        return Colors.purple;
      case UserActivity.editing:
        return Colors.orange;
      case UserActivity.creating:
        return Colors.green;
      case UserActivity.idle:
        return Colors.grey;
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

/// Compact version of the activity widget for smaller spaces
class CompactUserActivityWidget extends StatelessWidget {
  final List<UserActivityData> users;
  final int maxVisibleUsers;

  const CompactUserActivityWidget({
    Key? key,
    required this.users,
    this.maxVisibleUsers = 3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) return const SizedBox.shrink();

    final visibleUsers = users.take(maxVisibleUsers).toList();
    final remainingCount = users.length - maxVisibleUsers;

    return Row(
      children: [
        ...visibleUsers.map((user) => _buildCompactUserAvatar(user)),
        if (remainingCount > 0) _buildRemainingCount(remainingCount),
      ],
    );
  }

  Widget _buildCompactUserAvatar(UserActivityData user) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: _getUserColor(user.userId),
            child: Text(
              _getInitials(user.fullName ?? user.username),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _getActivityColor(user.activity),
                border: Border.all(color: Colors.white, width: 1),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemainingCount(int count) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.grey.shade300,
      child: Text(
        '+$count',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getUserColor(int userId) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[userId % colors.length];
  }

  Color _getActivityColor(UserActivity activity) {
    switch (activity) {
      case UserActivity.online:
        return Colors.green;
      case UserActivity.offline:
        return Colors.grey;
      case UserActivity.typing:
        return Colors.blue;
      case UserActivity.recording:
        return Colors.red;
      case UserActivity.viewing:
        return Colors.purple;
      case UserActivity.editing:
        return Colors.orange;
      case UserActivity.creating:
        return Colors.green;
      case UserActivity.idle:
        return Colors.grey;
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
