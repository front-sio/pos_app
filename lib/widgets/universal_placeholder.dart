import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/sizes.dart';
import '../theme/theme_manager.dart';
import 'modern_card.dart';
import 'modern_button.dart';
import 'micro_interactions.dart';

enum PlaceholderType {
  error,
  empty,
  noResults,
  noInternet,
  loading,
  maintenance,
  permissionDenied,
  notFound,
}

class UniversalPlaceholder extends StatefulWidget {
  final PlaceholderType type;
  final String? title;
  final String? message;
  final IconData? icon;
  final Widget? illustration;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final bool showActions;
  final Color? accentColor;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;

  const UniversalPlaceholder({
    Key? key,
    required this.type,
    this.title,
    this.message,
    this.icon,
    this.illustration,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.showActions = true,
    this.accentColor,
    this.maxWidth = 400,
    this.padding,
  }) : super(key: key);

  // Predefined constructors for common scenarios
  const UniversalPlaceholder.error({
    Key? key,
    String? title,
    String? message,
    VoidCallback? onRetry,
    VoidCallback? onGoBack,
  }) : this(
         key: key,
         type: PlaceholderType.error,
         title: title ?? 'Something went wrong',
         message: message ?? 'We encountered an unexpected error. Please try again.',
         icon: Icons.error_outline,
         actionLabel: 'Retry',
         onAction: onRetry,
         secondaryActionLabel: 'Go Back',
         onSecondaryAction: onGoBack,
         accentColor: AppColors.kError,
       );

  const UniversalPlaceholder.empty({
    Key? key,
    required String feature,
    String? message,
    VoidCallback? onCreate,
  }) : this(
         key: key,
         type: PlaceholderType.empty,
         title: 'No $feature found',
         message: message ?? 'Get started by creating your first $feature.',
         icon: Icons.inbox_outlined,
         actionLabel: 'Create $feature',
         onAction: onCreate,
         accentColor: AppColors.kInfo,
       );

  const UniversalPlaceholder.noResults({
    Key? key,
    String? searchTerm,
    VoidCallback? onClearSearch,
  }) : this(
         key: key,
         type: PlaceholderType.noResults,
         title: 'No results found',
         message: searchTerm != null 
             ? 'No results for "$searchTerm". Try adjusting your search.'
             : 'No results match your current filters.',
         icon: Icons.search_off,
         actionLabel: 'Clear Search',
         onAction: onClearSearch,
         accentColor: AppColors.kWarning,
       );

  const UniversalPlaceholder.noInternet({
    Key? key,
    VoidCallback? onRetry,
  }) : this(
         key: key,
         type: PlaceholderType.noInternet,
         title: 'No Internet Connection',
         message: 'Please check your internet connection and try again.',
         icon: Icons.wifi_off,
         actionLabel: 'Retry',
         onAction: onRetry,
         accentColor: AppColors.kWarning,
       );

  const UniversalPlaceholder.permissionDenied({
    Key? key,
    String? feature,
    VoidCallback? onContactAdmin,
  }) : this(
         key: key,
         type: PlaceholderType.permissionDenied,
         title: 'Access Denied',
         message: feature != null
             ? 'You don\'t have permission to access $feature.'
             : 'You don\'t have permission to access this feature.',
         icon: Icons.lock_outline,
         actionLabel: 'Contact Admin',
         onAction: onContactAdmin,
         accentColor: AppColors.kError,
       );

  @override
  State<UniversalPlaceholder> createState() => _UniversalPlaceholderState();
}

class _UniversalPlaceholderState extends State<UniversalPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimation();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: AppSizes.longAnimation,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: AppSizes.bounceCurve),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.4, 1.0, curve: AppSizes.defaultCurve),
    ));
  }

  void _startAnimation() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: widget.maxWidth ?? 400),
              child: ModernCard(
                type: ModernCardType.elevated,
                padding: widget.padding ?? const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildIllustration(),
                    const SizedBox(height: 24),
                    _buildTitle(),
                    const SizedBox(height: 12),
                    _buildMessage(),
                    if (widget.showActions && _hasActions()) ...[
                      const SizedBox(height: 32),
                      _buildActions(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    if (widget.illustration != null) {
      return widget.illustration!;
    }

    final businessColors = ThemeManager().currentBusinessColors;
    final effectiveColor = widget.accentColor ?? _getTypeColor() ?? businessColors.primary;
    final iconData = widget.icon ?? _getTypeIcon();

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: effectiveColor.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: effectiveColor.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Icon(
        iconData,
        size: 40,
        color: effectiveColor,
      ),
    );
  }

  Widget _buildTitle() {
    final title = widget.title ?? _getTypeTitle();
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: widget.accentColor ?? _getTypeColor(),
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMessage() {
    final message = widget.message ?? _getTypeMessage();
    return Text(
      message,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: Colors.grey.shade600,
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildActions() {
    final actions = <Widget>[];

    if (widget.onAction != null) {
      actions.add(
        ModernButton(
          text: widget.actionLabel ?? _getDefaultActionLabel(),
          type: ModernButtonType.primary,
          backgroundColor: widget.accentColor ?? _getTypeColor(),
          onPressed: () {
            HapticManager.trigger(HapticType.medium);
            widget.onAction?.call();
          },
        ),
      );
    }

    if (widget.onSecondaryAction != null) {
      actions.add(
        ModernButton(
          text: widget.secondaryActionLabel ?? 'Cancel',
          type: ModernButtonType.outline,
          onPressed: () {
            HapticManager.trigger(HapticType.light);
            widget.onSecondaryAction?.call();
          },
        ),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    if (actions.length == 1) {
      return actions.first;
    }

    return Column(
      children: [
        actions.first,
        const SizedBox(height: 12),
        actions.last,
      ],
    );
  }

  bool _hasActions() {
    return widget.onAction != null || widget.onSecondaryAction != null;
  }

  IconData _getTypeIcon() {
    switch (widget.type) {
      case PlaceholderType.error:
        return Icons.error_outline;
      case PlaceholderType.empty:
        return Icons.inbox_outlined;
      case PlaceholderType.noResults:
        return Icons.search_off;
      case PlaceholderType.noInternet:
        return Icons.wifi_off;
      case PlaceholderType.loading:
        return Icons.hourglass_empty;
      case PlaceholderType.maintenance:
        return Icons.build_outlined;
      case PlaceholderType.permissionDenied:
        return Icons.lock_outline;
      case PlaceholderType.notFound:
        return Icons.not_interested;
    }
  }

  Color? _getTypeColor() {
    switch (widget.type) {
      case PlaceholderType.error:
        return AppColors.kError;
      case PlaceholderType.empty:
        return AppColors.kInfo;
      case PlaceholderType.noResults:
        return AppColors.kWarning;
      case PlaceholderType.noInternet:
        return AppColors.kWarning;
      case PlaceholderType.loading:
        return AppColors.kInfo;
      case PlaceholderType.maintenance:
        return AppColors.kWarning;
      case PlaceholderType.permissionDenied:
        return AppColors.kError;
      case PlaceholderType.notFound:
        return AppColors.kError;
    }
  }

  String _getTypeTitle() {
    switch (widget.type) {
      case PlaceholderType.error:
        return 'Something went wrong';
      case PlaceholderType.empty:
        return 'Nothing here yet';
      case PlaceholderType.noResults:
        return 'No results found';
      case PlaceholderType.noInternet:
        return 'No Internet Connection';
      case PlaceholderType.loading:
        return 'Loading...';
      case PlaceholderType.maintenance:
        return 'Under Maintenance';
      case PlaceholderType.permissionDenied:
        return 'Access Denied';
      case PlaceholderType.notFound:
        return 'Not Found';
    }
  }

  String _getTypeMessage() {
    switch (widget.type) {
      case PlaceholderType.error:
        return 'We encountered an unexpected error. Please try again.';
      case PlaceholderType.empty:
        return 'Get started by creating your first item.';
      case PlaceholderType.noResults:
        return 'Try adjusting your search or filters.';
      case PlaceholderType.noInternet:
        return 'Please check your internet connection and try again.';
      case PlaceholderType.loading:
        return 'Please wait while we load your content.';
      case PlaceholderType.maintenance:
        return 'We\'re currently performing maintenance. Please try again later.';
      case PlaceholderType.permissionDenied:
        return 'You don\'t have permission to access this feature.';
      case PlaceholderType.notFound:
        return 'The content you\'re looking for could not be found.';
    }
  }

  String _getDefaultActionLabel() {
    switch (widget.type) {
      case PlaceholderType.error:
        return 'Retry';
      case PlaceholderType.empty:
        return 'Get Started';
      case PlaceholderType.noResults:
        return 'Clear Search';
      case PlaceholderType.noInternet:
        return 'Retry';
      case PlaceholderType.loading:
        return 'Refresh';
      case PlaceholderType.maintenance:
        return 'Check Status';
      case PlaceholderType.permissionDenied:
        return 'Contact Admin';
      case PlaceholderType.notFound:
        return 'Go Back';
    }
  }
}