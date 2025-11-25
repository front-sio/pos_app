import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../constants/sizes.dart';
import '../theme/theme_manager.dart';
import 'micro_interactions.dart';

enum FeatureCardType {
  primary,
  secondary,
  compact,
  detailed,
  grid,
  list,
}

enum FeatureCardAction {
  view,
  edit,
  delete,
  archive,
  restore,
  duplicate,
}

class AdvancedFeatureCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? description;
  final Widget? leading;
  final Widget? trailing;
  final List<FeatureCardAction> actions;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Function(FeatureCardAction)? onActionTap;
  final FeatureCardType type;
  final Color? accentColor;
  final List<Widget>? badges;
  final Map<String, String>? metadata;
  final bool isSelected;
  final bool isLoading;
  final int animationDelay;
  final Widget? hero;
  final String? heroTag;

  const AdvancedFeatureCard({
    Key? key,
    required this.title,
    this.subtitle,
    this.description,
    this.leading,
    this.trailing,
    this.actions = const [],
    this.onTap,
    this.onLongPress,
    this.onActionTap,
    this.type = FeatureCardType.primary,
    this.accentColor,
    this.badges,
    this.metadata,
    this.isSelected = false,
    this.isLoading = false,
    this.animationDelay = 0,
    this.hero,
    this.heroTag,
  }) : super(key: key);

  @override
  State<AdvancedFeatureCard> createState() => _AdvancedFeatureCardState();
}

class _AdvancedFeatureCardState extends State<AdvancedFeatureCard>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _hoverController;
  late AnimationController _selectionController;
  late AnimationController _actionController;
  
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  late Animation<double> _selectionAnimation;
  late Animation<double> _actionRevealAnimation;
  
  bool _isHovered = false;
  bool _actionsRevealed = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startEntranceAnimation();
  }

  void _initializeAnimations() {
    _entranceController = AnimationController(
      duration: AppSizes.mediumAnimation,
      vsync: this,
    );
    
    _hoverController = AnimationController(
      duration: AppSizes.shortAnimation,
      vsync: this,
    );
    
    _selectionController = AnimationController(
      duration: AppSizes.shortAnimation,
      vsync: this,
    );
    
    _actionController = AnimationController(
      duration: AppSizes.mediumAnimation,
      vsync: this,
    );

    // Entrance animations
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: AppSizes.defaultCurve,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));

    // Hover animations
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));
    
    _elevationAnimation = Tween<double>(
      begin: _getBaseElevation(),
      end: _getBaseElevation() + 8,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));

    // Selection animation
    _selectionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _selectionController,
      curve: AppSizes.bounceCurve,
    ));

    // Action reveal animation
    _actionRevealAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _actionController,
      curve: AppSizes.defaultCurve,
    ));
  }

  void _startEntranceAnimation() {
    Future.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (mounted) {
        _entranceController.forward();
      }
    });
  }

  void _onHoverEnter() {
    if (!widget.isLoading) {
      setState(() => _isHovered = true);
      _hoverController.forward();
    }
  }

  void _onHoverExit() {
    setState(() => _isHovered = false);
    _hoverController.reverse();
  }

  void _onTap() {
    HapticManager.trigger(HapticType.light);
    if (!widget.isSelected) {
      _selectionController.forward().then((_) {
        _selectionController.reverse();
      });
    }
    widget.onTap?.call();
  }

  void _onLongPress() {
    HapticManager.trigger(HapticType.medium);
    if (widget.actions.isNotEmpty) {
      setState(() => _actionsRevealed = !_actionsRevealed);
      if (_actionsRevealed) {
        _actionController.forward();
      } else {
        _actionController.reverse();
      }
    }
    widget.onLongPress?.call();
  }

  void _onActionTap(FeatureCardAction action) {
    HapticManager.trigger(HapticType.selection);
    setState(() => _actionsRevealed = false);
    _actionController.reverse();
    widget.onActionTap?.call(action);
  }

  @override
  void didUpdateWidget(AdvancedFeatureCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _selectionController.forward();
      } else {
        _selectionController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _hoverController.dispose();
    _selectionController.dispose();
    _actionController.dispose();
    super.dispose();
  }

  double _getBaseElevation() {
    switch (widget.type) {
      case FeatureCardType.primary:
        return 4;
      case FeatureCardType.secondary:
        return 2;
      case FeatureCardType.compact:
        return 1;
      case FeatureCardType.detailed:
        return 6;
      case FeatureCardType.grid:
        return 2;
      case FeatureCardType.list:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessColors = ThemeManager().currentBusinessColors;
    final effectiveAccentColor = widget.accentColor ?? businessColors.primary;
    
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _scaleAnimation,
            _elevationAnimation,
            _selectionAnimation,
          ]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: MouseRegion(
                onEnter: (_) => _onHoverEnter(),
                onExit: (_) => _onHoverExit(),
                child: Stack(
                  children: [
                    // Main card
                    _buildMainCard(context, effectiveAccentColor),
                    
                    // Selection indicator
                    if (widget.isSelected || _selectionAnimation.value > 0)
                      _buildSelectionIndicator(effectiveAccentColor),
                    
                    // Action buttons
                    if (_actionsRevealed || _actionRevealAnimation.value > 0)
                      _buildActionButtons(context, effectiveAccentColor),
                    
                    // Loading overlay
                    if (widget.isLoading)
                      _buildLoadingOverlay(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainCard(BuildContext context, Color accentColor) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(_getCardRadius()),
        border: Border.all(
          color: widget.isSelected 
              ? accentColor.withOpacity(0.5)
              : Colors.grey.withOpacity(0.1),
          width: widget.isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: _elevationAnimation.value,
            offset: Offset(0, _elevationAnimation.value / 2),
            spreadRadius: widget.isSelected ? 2 : 0,
          ),
          if (widget.isSelected)
            BoxShadow(
              color: accentColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 0),
              spreadRadius: 1,
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _onTap,
          onLongPress: _onLongPress,
          borderRadius: BorderRadius.circular(_getCardRadius()),
          child: _buildCardContent(context, accentColor),
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context, Color accentColor) {
    switch (widget.type) {
      case FeatureCardType.primary:
        return _buildPrimaryContent(context, accentColor);
      case FeatureCardType.secondary:
        return _buildSecondaryContent(context, accentColor);
      case FeatureCardType.compact:
        return _buildCompactContent(context, accentColor);
      case FeatureCardType.detailed:
        return _buildDetailedContent(context, accentColor);
      case FeatureCardType.grid:
        return _buildGridContent(context, accentColor);
      case FeatureCardType.list:
        return _buildListContent(context, accentColor);
    }
  }

  Widget _buildPrimaryContent(BuildContext context, Color accentColor) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.hero != null && widget.heroTag != null)
            Hero(
              tag: widget.heroTag!,
              child: widget.hero!,
            ),
          
          Row(
            children: [
              if (widget.leading != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: widget.leading!,
                ),
                const SizedBox(width: 12),
              ],
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: widget.isSelected ? accentColor : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              
              if (widget.trailing != null) ...[
                const SizedBox(width: 12),
                widget.trailing!,
              ],
            ],
          ),
          
          if (widget.description != null) ...[
            const SizedBox(height: 12),
            Text(
              widget.description!,
              style: theme.textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          
          if (widget.badges?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.badges!,
            ),
          ],
          
          if (widget.metadata?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            _buildMetadata(context),
          ],
        ],
      ),
    );
  }

  Widget _buildSecondaryContent(BuildContext context, Color accentColor) {
    return _buildListContent(context, accentColor);
  }

  Widget _buildCompactContent(BuildContext context, Color accentColor) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          if (widget.leading != null) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: widget.leading!,
            ),
            const SizedBox(width: 8),
          ],
          
          Expanded(
            child: Text(
              widget.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          if (widget.trailing != null) ...[
            const SizedBox(width: 8),
            widget.trailing!,
          ],
        ],
      ),
    );
  }

  Widget _buildDetailedContent(BuildContext context, Color accentColor) {
    return _buildPrimaryContent(context, accentColor);
  }

  Widget _buildGridContent(BuildContext context, Color accentColor) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          if (widget.leading != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: widget.leading!,
            ),
            const SizedBox(height: 12),
          ],
          
          Text(
            widget.title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          if (widget.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          
          const Spacer(),
          
          if (widget.trailing != null)
            widget.trailing!,
        ],
      ),
    );
  }

  Widget _buildListContent(BuildContext context, Color accentColor) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (widget.leading != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: widget.leading!,
            ),
            const SizedBox(width: 12),
          ],
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          
          if (widget.trailing != null) ...[
            const SizedBox(width: 12),
            widget.trailing!,
          ],
        ],
      ),
    );
  }

  Widget _buildMetadata(BuildContext context) {
    return Column(
      children: widget.metadata!.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Text(
                entry.key,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.value,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSelectionIndicator(Color accentColor) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _selectionAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_getCardRadius()),
              border: Border.all(
                color: accentColor.withOpacity(_selectionAnimation.value * 0.8),
                width: 3 * _selectionAnimation.value,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Color accentColor) {
    return Positioned(
      top: 8,
      right: 8,
      child: AnimatedBuilder(
        animation: _actionRevealAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _actionRevealAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: widget.actions.map((action) {
                  return _buildActionButton(action, accentColor);
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton(FeatureCardAction action, Color accentColor) {
    final icon = _getActionIcon(action);
    final color = _getActionColor(action, accentColor);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onActionTap(action),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            size: 16,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(_getCardRadius()),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  double _getCardRadius() {
    switch (widget.type) {
      case FeatureCardType.compact:
        return 8;
      case FeatureCardType.grid:
        return 12;
      default:
        return AppSizes.cardBorderRadius;
    }
  }

  IconData _getActionIcon(FeatureCardAction action) {
    switch (action) {
      case FeatureCardAction.view:
        return Icons.visibility;
      case FeatureCardAction.edit:
        return Icons.edit;
      case FeatureCardAction.delete:
        return Icons.delete;
      case FeatureCardAction.archive:
        return Icons.archive;
      case FeatureCardAction.restore:
        return Icons.restore;
      case FeatureCardAction.duplicate:
        return Icons.copy;
    }
  }

  Color _getActionColor(FeatureCardAction action, Color defaultColor) {
    switch (action) {
      case FeatureCardAction.delete:
        return AppColors.kError;
      case FeatureCardAction.edit:
        return AppColors.kWarning;
      case FeatureCardAction.view:
        return AppColors.kInfo;
      default:
        return defaultColor;
    }
  }
}