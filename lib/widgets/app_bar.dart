import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_app/features/auth/logic/auth_bloc.dart';
import 'package:sales_app/features/auth/logic/auth_event.dart';
import 'package:sales_app/features/auth/logic/auth_state.dart';
import 'package:sales_app/utils/keyboard_shortcuts.dart';
import '../constants/colors.dart';
import '../utils/responsive.dart';

class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AdminAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: kToolbarHeight,
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : 16,
          ),
          child: Row(
            children: [
              // Menu Icon for Mobile/Tablet
              if (!isDesktop) ...[
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    // This uses the context from a parent Scaffold
                    Scaffold.of(context).openDrawer();
                  },
                ),
                const SizedBox(width: 8),
              ],
              
              // Logo and App Name
              _buildBranding(context),
              
              if (isDesktop || isTablet) ...[
                const SizedBox(width: 40),
                // Search Bar - Only show on desktop/tablet
                Expanded(
                  flex: isDesktop ? 2 : 3,
                  child: _buildSearchBar(context),
                ),
              ],
              
              const Spacer(),
              
              // Right side actions
              _buildActions(context, isDesktop),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBranding(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.kPrimary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.shopping_bag_outlined,
            color: Colors.white,
            size: isDesktop ? 24 : 20,
          ),
        ),
        const SizedBox(width: 12),
        if (isDesktop) ...[
          Text(
            'Sales Business',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.kTextPrimary,
                ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.kSuccess.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'PRO',
              style: TextStyle(
                color: AppColors.kSuccess,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActions(BuildContext context, bool isDesktop) {
    return Row(
      children: [
        // Notifications
        _buildNotificationButton(context),
        const SizedBox(width: 8),
        
        // Help
        if (isDesktop) ...[
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {},
            tooltip: 'Help',
          ),
          const SizedBox(width: 8),
        ],
        
        // Settings
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () {},
          tooltip: 'Settings',
        ),
        const SizedBox(width: 16),
        
        // Profile and Logout
        _buildProfileButton(context, isDesktop),
      ],
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {},
          tooltip: 'Notifications',
        ),
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.kError,
              shape: BoxShape.circle,
            ),
            child: Text(
              '3',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildProfileButton(BuildContext context, bool isDesktop) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String displayName = 'Guest';
        String displayUsername = 'Not logged in';

        if (state is AuthAuthenticated) {
          displayName = '${state.firstName} ${state.lastName}';
          displayUsername = state.username;
        }

        return InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            if (state is AuthAuthenticated) {
              _showProfileMenu(context);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.withOpacity(0.2),
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.kPrimary.withOpacity(0.1),
                  child: Icon(
                    Icons.person_outline,
                    size: 20,
                    color: AppColors.kPrimary,
                  ),
                ),
                if (isDesktop) ...[
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        displayUsername,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }



  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext bc) {
        final authBloc = BlocProvider.of<AuthBloc>(context);
        return BlocProvider.value(
          value: authBloc,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    String displayName = 'Guest';
                    String displayUsername = 'Not logged in';

                    if (state is AuthAuthenticated) {
                      displayName = '${state.firstName} ${state.lastName}';
                      displayUsername = state.username;
                    }
                    return ListTile(
                      title: Text(
                        displayName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        displayUsername,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.kTextSecondary,
                        ),
                      ),
                      leading:  CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.kPrimary,
                        child: Icon(
                          Icons.person_outline,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Profile'),
                  onTap: () {
                    Navigator.pop(bc);
                    // TODO: Implement navigation to profile screen
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.kError),
                  title: const Text('Logout', style: TextStyle(color: AppColors.kError)),
                  onTap: () {
                    BlocProvider.of<AuthBloc>(bc).add(LogoutRequested());
                    Navigator.pop(bc);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }



 Widget _buildSearchBar(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    
    // Wrap with InkWell to make it tappable
    return InkWell(
      onTap: () {
        // Explicitly invoke the action when the search bar is tapped
        Actions.invoke(context, const OpenSearchIntent());
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(
              Icons.search,
              size: 20,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isDesktop ? 'Search products, orders, customers...' : 'Search...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
            if (isDesktop)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[700]
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '⌘K',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }


  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
