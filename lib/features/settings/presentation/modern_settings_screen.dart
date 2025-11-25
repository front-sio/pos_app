import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../constants/colors.dart';
import '../../../constants/sizes.dart';
import '../../../widgets/modern_card.dart';
import '../../../widgets/modern_button.dart';
import '../../../widgets/modern_list_item.dart';
import '../../../widgets/staggered_list_view.dart';
import '../../../widgets/micro_interactions.dart';
import '../../../widgets/theme_switcher.dart';
import '../../../theme/theme_manager.dart';

class ModernSettingsScreen extends StatefulWidget {
  const ModernSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ModernSettingsScreen> createState() => _ModernSettingsScreenState();
}

class _ModernSettingsScreenState extends State<ModernSettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late Animation<double> _headerAnimation;
  
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  bool _autoBackup = true;
  
  @override
  void initState() {
    super.initState();
    
    _headerController = AnimationController(
      duration: AppSizes.longAnimation,
      vsync: this,
    );
    
    _headerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: AppSizes.bounceCurve,
    ));
    
    _headerController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAnimatedAppBar(),
          _buildSettingsContent(),
        ],
      ),
    );
  }

  SliverAppBar _buildAnimatedAppBar() {
    final businessColors = ThemeManager().currentBusinessColors;
    
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: businessColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: businessColors.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AnimatedBuilder(
                animation: _headerAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, (1 - _headerAnimation.value) * 30),
                    child: Opacity(
                      opacity: _headerAnimation.value,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'Customize Your Experience',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Personalize themes, preferences, and more',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const ThemeSwitcher(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsContent() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // Theme Section
          _buildSectionCard(
            title: 'Appearance',
            icon: Icons.palette,
            children: [
              const BusinessThemeSelector(),
              const SizedBox(height: 16),
              _buildSettingsTile(
                title: 'Dark Mode',
                subtitle: 'Toggle between light and dark themes',
                leading: Icon(
                  ThemeManager().isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: ThemeManager().currentBusinessColors.primary,
                ),
                trailing: const ThemeSwitcher(),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Notifications Section
          _buildSectionCard(
            title: 'Notifications',
            icon: Icons.notifications,
            children: [
              _buildAnimatedSwitchTile(
                title: 'Push Notifications',
                subtitle: 'Receive notifications about sales and orders',
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                  HapticManager.trigger(value ? HapticType.success : HapticType.light);
                },
              ),
              _buildSettingsTile(
                title: 'Notification Sound',
                subtitle: 'Choose notification sound',
                leading: Icon(
                  Icons.volume_up,
                  color: ThemeManager().currentBusinessColors.primary,
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showNotificationSoundPicker,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Security Section
          _buildSectionCard(
            title: 'Security',
            icon: Icons.security,
            children: [
              _buildAnimatedSwitchTile(
                title: 'Biometric Authentication',
                subtitle: 'Use fingerprint or face unlock',
                value: _biometricEnabled,
                onChanged: (value) {
                  setState(() => _biometricEnabled = value);
                  HapticManager.trigger(value ? HapticType.success : HapticType.light);
                },
              ),
              _buildSettingsTile(
                title: 'Change Password',
                subtitle: 'Update your account password',
                leading: Icon(
                  Icons.lock_outline,
                  color: ThemeManager().currentBusinessColors.primary,
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showChangePasswordDialog,
              ),
              _buildSettingsTile(
                title: 'Two-Factor Authentication',
                subtitle: 'Add extra security to your account',
                leading: Icon(
                  Icons.verified_user,
                  color: ThemeManager().currentBusinessColors.success,
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _setup2FA,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Data & Storage Section
          _buildSectionCard(
            title: 'Data & Storage',
            icon: Icons.storage,
            children: [
              _buildAnimatedSwitchTile(
                title: 'Auto Backup',
                subtitle: 'Automatically backup data to cloud',
                value: _autoBackup,
                onChanged: (value) {
                  setState(() => _autoBackup = value);
                  HapticManager.trigger(value ? HapticType.success : HapticType.light);
                },
              ),
              _buildSettingsTile(
                title: 'Export Data',
                subtitle: 'Download your data as CSV/PDF',
                leading: Icon(
                  Icons.file_download,
                  color: ThemeManager().currentBusinessColors.primary,
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _exportData,
              ),
              _buildSettingsTile(
                title: 'Storage Usage',
                subtitle: '2.3 GB of 5 GB used',
                leading: Icon(
                  Icons.pie_chart,
                  color: ThemeManager().currentBusinessColors.warning,
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showStorageDetails,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // About Section
          _buildSectionCard(
            title: 'About',
            icon: Icons.info,
            children: [
              _buildSettingsTile(
                title: 'App Version',
                subtitle: '2.1.0 (Build 42)',
                leading: Icon(
                  Icons.app_settings_alt,
                  color: ThemeManager().currentBusinessColors.primary,
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ThemeManager().currentBusinessColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ThemeManager().currentBusinessColors.success.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    'Latest',
                    style: TextStyle(
                      color: ThemeManager().currentBusinessColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              _buildSettingsTile(
                title: 'Privacy Policy',
                subtitle: 'Read our privacy policy',
                leading: Icon(
                  Icons.privacy_tip,
                  color: ThemeManager().currentBusinessColors.primary,
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showPrivacyPolicy,
              ),
              _buildSettingsTile(
                title: 'Terms of Service',
                subtitle: 'View terms and conditions',
                leading: Icon(
                  Icons.article,
                  color: ThemeManager().currentBusinessColors.primary,
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showTermsOfService,
              ),
              _buildSettingsTile(
                title: 'Debug Auth',
                subtitle: 'Check authentication status',
                leading: Icon(
                  Icons.bug_report,
                  color: Colors.orange,
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.of(context).pushNamed('/debug');
                },
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Logout Button
          ModernButton(
            text: 'Sign Out',
            icon: Icons.logout,
            type: ModernButtonType.outline,
            onPressed: _showLogoutConfirmation,
          ),
          
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return ModernCard(
      type: ModernCardType.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ThemeManager().currentBusinessColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: ThemeManager().currentBusinessColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required String subtitle,
    required Widget leading,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ModernListItem(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
      showBorder: false,
    );
  }

  Widget _buildAnimatedSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ModernListItem(
      leading: AnimatedContainer(
        duration: AppSizes.shortAnimation,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: value 
              ? ThemeManager().currentBusinessColors.success.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          value ? Icons.check_circle : Icons.radio_button_unchecked,
          color: value 
              ? ThemeManager().currentBusinessColors.success 
              : Colors.grey,
          size: 20,
        ),
      ),
      title: title,
      subtitle: subtitle,
      trailing: AnimatedContainer(
        duration: AppSizes.shortAnimation,
        width: 50,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: value 
              ? ThemeManager().currentBusinessColors.success 
              : Colors.grey.shade300,
        ),
        child: AnimatedAlign(
          duration: AppSizes.shortAnimation,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
      onTap: () => onChanged(!value),
      showBorder: false,
    );
  }

  void _showNotificationSoundPicker() {
    HapticManager.trigger(HapticType.selection);
    // Show notification sound picker
  }

  void _showChangePasswordDialog() {
    HapticManager.trigger(HapticType.selection);
    // Show change password dialog
  }

  void _setup2FA() {
    HapticManager.trigger(HapticType.selection);
    // Navigate to 2FA setup
  }

  void _exportData() {
    HapticManager.trigger(HapticType.medium);
    // Show export options
  }

  void _showStorageDetails() {
    HapticManager.trigger(HapticType.selection);
    // Show storage usage details
  }

  void _showPrivacyPolicy() {
    HapticManager.trigger(HapticType.light);
    // Show privacy policy
  }

  void _showTermsOfService() {
    HapticManager.trigger(HapticType.light);
    // Show terms of service
  }

  void _showLogoutConfirmation() {
    HapticManager.trigger(HapticType.medium);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        ),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ModernButton(
            text: 'Sign Out',
            type: ModernButtonType.primary,
            size: ModernButtonSize.small,
            backgroundColor: AppColors.kError,
            onPressed: () {
              Navigator.of(context).pop();
              _performLogout();
            },
          ),
        ],
      ),
    );
  }

  void _performLogout() {
    HapticManager.trigger(HapticType.success);
    // Perform logout
  }
}