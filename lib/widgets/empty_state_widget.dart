import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/sizes.dart';
import '../theme/theme_manager.dart';
import 'modern_button.dart';
import 'micro_interactions.dart';
import 'universal_placeholder.dart';

enum EmptyStateType {
  general,
  sales,
  customers,
  products,
  reports,
  dashboard,
  settings,
  notifications,
}

class EmptyStateWidget extends StatefulWidget {
  final EmptyStateType type;
  final String? title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final bool showIllustration;
  final Widget? customIllustration;
  final double? maxHeight;
  final bool isCompact;

  const EmptyStateWidget({
    Key? key,
    required this.type,
    this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.showIllustration = true,
    this.customIllustration,
    this.maxHeight,
    this.isCompact = false,
  }) : super(key: key);

  // Predefined constructors for specific use cases
  const EmptyStateWidget.sales({
    Key? key,
    VoidCallback? onCreateSale,
    VoidCallback? onImport,
  }) : this(
         key: key,
         type: EmptyStateType.sales,
         actionLabel: 'Create Sale',
         onAction: onCreateSale,
         secondaryActionLabel: 'Import Sales',
         onSecondaryAction: onImport,
       );

  const EmptyStateWidget.customers({
    Key? key,
    VoidCallback? onAddCustomer,
    VoidCallback? onImport,
  }) : this(
         key: key,
         type: EmptyStateType.customers,
         actionLabel: 'Add Customer',
         onAction: onAddCustomer,
         secondaryActionLabel: 'Import Customers',
         onSecondaryAction: onImport,
       );

  const EmptyStateWidget.products({
    Key? key,
    VoidCallback? onAddProduct,
    VoidCallback? onImport,
  }) : this(
         key: key,
         type: EmptyStateType.products,
         actionLabel: 'Add Product',
         onAction: onAddProduct,
         secondaryActionLabel: 'Import Products',
         onSecondaryAction: onImport,
       );

  const EmptyStateWidget.reports({
    Key? key,
    VoidCallback? onGenerateReport,
  }) : this(
         key: key,
         type: EmptyStateType.reports,
         actionLabel: 'Generate Report',
         onAction: onGenerateReport,
       );

  const EmptyStateWidget.dashboard({
    Key? key,
    VoidCallback? onRefresh,
  }) : this(
         key: key,
         type: EmptyStateType.dashboard,
         actionLabel: 'Refresh Dashboard',
         onAction: onRefresh,
       );

  const EmptyStateWidget.compact({
    Key? key,
    required EmptyStateType type,
    String? title,
    String? message,
    VoidCallback? onAction,
  }) : this(
         key: key,
         type: type,
         title: title,
         message: message,
         onAction: onAction,
         isCompact: true,
         showIllustration: false,
       );

  @override
  State<EmptyStateWidget> createState() => _EmptyStateWidgetState();
}

class _EmptyStateWidgetState extends State<EmptyStateWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimation();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: widget.isCompact 
          ? AppSizes.shortAnimation 
          : AppSizes.longAnimation,
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
      begin: widget.isCompact ? 0.95 : 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: widget.isCompact 
          ? const Interval(0.0, 1.0, curve: Curves.easeOut)
          : const Interval(0.2, 0.8, curve: AppSizes.bounceCurve),
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
    if (widget.isCompact) {
      return _buildCompactState();
    }

    return UniversalPlaceholder(
      type: PlaceholderType.empty,
      title: widget.title ?? _getTypeTitle(),
      message: widget.message ?? _getTypeMessage(),
      icon: _getTypeIcon(),
      illustration: widget.customIllustration,
      actionLabel: widget.actionLabel,
      onAction: widget.onAction,
      secondaryActionLabel: widget.secondaryActionLabel,
      onSecondaryAction: widget.onSecondaryAction,
      accentColor: _getTypeColor(),
    );
  }

  Widget _buildCompactState() {
    final businessColors = ThemeManager().currentBusinessColors;
    final effectiveColor = _getTypeColor() ?? businessColors.primary;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          constraints: BoxConstraints(maxHeight: widget.maxHeight ?? 200),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: effectiveColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: effectiveColor.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getTypeIcon(),
                size: 32,
                color: effectiveColor.withOpacity(0.7),
              ),
              const SizedBox(height: 12),
              Text(
                widget.title ?? _getTypeTitle(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: effectiveColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.message ?? _getTypeMessage(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.onAction != null) ...[
                const SizedBox(height: 16),
                ModernButton(
                  text: widget.actionLabel ?? 'Get Started',
                  type: ModernButtonType.outline,
                  backgroundColor: effectiveColor,
                  size: ModernButtonSize.small,
                  onPressed: () {
                    HapticManager.trigger(HapticType.light);
                    widget.onAction?.call();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getTypeTitle() {
    switch (widget.type) {
      case EmptyStateType.general:
        return 'Nothing here yet';
      case EmptyStateType.sales:
        return 'No sales recorded';
      case EmptyStateType.customers:
        return 'No customers added';
      case EmptyStateType.products:
        return 'No products in inventory';
      case EmptyStateType.reports:
        return 'No reports available';
      case EmptyStateType.dashboard:
        return 'Dashboard is empty';
      case EmptyStateType.settings:
        return 'No settings configured';
      case EmptyStateType.notifications:
        return 'No notifications';
    }
  }

  String _getTypeMessage() {
    switch (widget.type) {
      case EmptyStateType.general:
        return 'Get started by creating your first item.';
      case EmptyStateType.sales:
        return 'Start recording your sales to track your business performance.';
      case EmptyStateType.customers:
        return 'Add your first customer to begin managing your client relationships.';
      case EmptyStateType.products:
        return 'Add products to your inventory to start selling.';
      case EmptyStateType.reports:
        return 'Generate reports to gain insights into your business.';
      case EmptyStateType.dashboard:
        return 'Your activity will appear here once you start using the app.';
      case EmptyStateType.settings:
        return 'Configure your preferences to personalize your experience.';
      case EmptyStateType.notifications:
        return 'You\'ll see important updates and alerts here.';
    }
  }

  IconData _getTypeIcon() {
    switch (widget.type) {
      case EmptyStateType.general:
        return Icons.inbox_outlined;
      case EmptyStateType.sales:
        return Icons.receipt_long_outlined;
      case EmptyStateType.customers:
        return Icons.people_outline;
      case EmptyStateType.products:
        return Icons.inventory_2_outlined;
      case EmptyStateType.reports:
        return Icons.analytics_outlined;
      case EmptyStateType.dashboard:
        return Icons.dashboard_outlined;
      case EmptyStateType.settings:
        return Icons.settings_outlined;
      case EmptyStateType.notifications:
        return Icons.notifications_none_outlined;
    }
  }

  Color? _getTypeColor() {
    switch (widget.type) {
      case EmptyStateType.general:
        return AppColors.kInfo;
      case EmptyStateType.sales:
        return Colors.green;
      case EmptyStateType.customers:
        return Colors.blue;
      case EmptyStateType.products:
        return Colors.orange;
      case EmptyStateType.reports:
        return Colors.purple;
      case EmptyStateType.dashboard:
        return AppColors.kPrimary;
      case EmptyStateType.settings:
        return Colors.grey;
      case EmptyStateType.notifications:
        return Colors.red;
    }
  }
}

/// A reusable empty state wrapper that can be used in any screen
class EmptyStateWrapper extends StatelessWidget {
  final Widget child;
  final bool isEmpty;
  final EmptyStateWidget emptyState;

  const EmptyStateWrapper({
    Key? key,
    required this.child,
    required this.isEmpty,
    required this.emptyState,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isEmpty) {
      return emptyState;
    }
    return child;
  }
}

/// Helper widget to conditionally show empty state based on data
class ConditionalEmptyState<T> extends StatelessWidget {
  final List<T>? data;
  final EmptyStateWidget emptyState;
  final Widget Function(List<T> data) builder;
  final bool isLoading;

  const ConditionalEmptyState({
    Key? key,
    this.data,
    required this.emptyState,
    required this.builder,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (data == null || data!.isEmpty) {
      return emptyState;
    }

    return builder(data!);
  }
}
