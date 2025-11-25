import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/sizes.dart';

class ModernListItem extends StatefulWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? backgroundColor;
  final bool isSelected;
  final bool showBorder;
  final EdgeInsetsGeometry? padding;
  final int animationDelay;

  const ModernListItem({
    Key? key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.backgroundColor,
    this.isSelected = false,
    this.showBorder = true,
    this.padding,
    this.animationDelay = 0,
  }) : super(key: key);

  @override
  State<ModernListItem> createState() => _ModernListItemState();
}

class _ModernListItemState extends State<ModernListItem>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _shimmerController;
  
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shimmerAnimation;
  
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    
    // Slide in animation
    _slideController = AnimationController(
      duration: AppSizes.mediumAnimation,
      vsync: this,
    );
    
    // Scale animation for press effect
    _scaleController = AnimationController(
      duration: AppSizes.shortAnimation,
      vsync: this,
    );
    
    // Shimmer animation for highlighting
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: AppSizes.defaultCurve,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
    
    _shimmerAnimation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
    
    // Start entrance animation with delay
    Future.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (mounted) {
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _onTapDown() {
    setState(() => _isPressed = true);
    _scaleController.forward();
  }

  void _onTapUp() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _triggerShimmer() {
    _shimmerController.forward().then((_) {
      _shimmerController.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: AppSizes.shortAnimation,
          curve: AppSizes.defaultCurve,
          margin: const EdgeInsets.symmetric(
            horizontal: AppSizes.smallPadding,
            vertical: AppSizes.smallPadding / 2,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.kPrimary.withOpacity(0.1)
                : widget.backgroundColor ?? AppColors.kCardBackground,
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
            border: widget.showBorder
                ? Border.all(
                    color: widget.isSelected
                        ? AppColors.kPrimary.withOpacity(0.3)
                        : AppColors.kDivider.withOpacity(0.3),
                    width: 1,
                  )
                : null,
            boxShadow: [
              if (_isHovered || widget.isSelected)
                BoxShadow(
                  color: AppColors.kShadowColor,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _triggerShimmer();
                  widget.onTap?.call();
                },
                onLongPress: widget.onLongPress,
                onTapDown: (_) => _onTapDown(),
                onTapUp: (_) => _onTapUp(),
                onTapCancel: _onTapCancel,
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                child: Stack(
                  children: [
                    // Shimmer effect
                    AnimatedBuilder(
                      animation: _shimmerAnimation,
                      builder: (context, child) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                stops: [
                                  (_shimmerAnimation.value - 1).clamp(0.0, 1.0),
                                  _shimmerAnimation.value.clamp(0.0, 1.0),
                                  (_shimmerAnimation.value + 1).clamp(0.0, 1.0),
                                ],
                                colors: [
                                  Colors.transparent,
                                  Colors.white.withOpacity(0.1),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    // Content
                    Padding(
                      padding: widget.padding ??
                          const EdgeInsets.all(AppSizes.padding),
                      child: Row(
                        children: [
                          // Leading widget
                          AnimatedContainer(
                            duration: AppSizes.shortAnimation,
                            transform: Matrix4.identity()
                              ..scale(_isPressed ? 0.9 : 1.0),
                            child: widget.leading,
                          ),
                          const SizedBox(width: AppSizes.padding),
                          
                          // Title and subtitle
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedDefaultTextStyle(
                                  duration: AppSizes.shortAnimation,
                                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                    color: widget.isSelected
                                        ? AppColors.kPrimary
                                        : AppColors.kText,
                                    fontWeight: widget.isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                                  child: Text(
                                    widget.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (widget.subtitle != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.subtitle!,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.kTextSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          
                          // Trailing widget
                          if (widget.trailing != null) ...[
                            const SizedBox(width: AppSizes.smallPadding),
                            AnimatedContainer(
                              duration: AppSizes.shortAnimation,
                              transform: Matrix4.identity()
                                ..scale(_isPressed ? 0.9 : 1.0),
                              child: widget.trailing!,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}