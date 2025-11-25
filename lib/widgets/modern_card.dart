import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/sizes.dart';

enum ModernCardType {
  elevated,
  outlined,
  filled,
  glass,
}

class ModernCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final ModernCardType type;
  final Color? backgroundColor;
  final List<Color>? gradientColors;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final bool isSelected;
  final bool enableHoverEffect;
  final bool enableParallax;
  final int animationDelay;
  final Widget? backgroundImage;

  const ModernCard({
    Key? key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.type = ModernCardType.elevated,
    this.backgroundColor,
    this.gradientColors,
    this.padding,
    this.margin,
    this.borderRadius,
    this.isSelected = false,
    this.enableHoverEffect = true,
    this.enableParallax = false,
    this.animationDelay = 0,
    this.backgroundImage,
  }) : super(key: key);

  @override
  State<ModernCard> createState() => _ModernCardState();
}

class _ModernCardState extends State<ModernCard>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _tapController;
  late AnimationController _entranceController;
  late AnimationController _parallaxController;
  
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _parallaxAnimation;
  
  bool _isHovered = false;
  bool _isPressed = false;
  Offset _localPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _hoverController = AnimationController(
      duration: AppSizes.mediumAnimation,
      vsync: this,
    );
    
    _tapController = AnimationController(
      duration: AppSizes.shortAnimation,
      vsync: this,
    );
    
    _entranceController = AnimationController(
      duration: AppSizes.longAnimation,
      vsync: this,
    );
    
    _parallaxController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    
    // Initialize animations
    _elevationAnimation = Tween<double>(
      begin: _getBaseElevation(),
      end: _getBaseElevation() + 8,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: AppSizes.defaultCurve,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _tapController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: AppSizes.bounceCurve,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _parallaxAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _parallaxController,
      curve: Curves.easeOut,
    ));
    
    // Start entrance animation
    Future.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (mounted) {
        _entranceController.forward();
      }
    });
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _tapController.dispose();
    _entranceController.dispose();
    _parallaxController.dispose();
    super.dispose();
  }

  double _getBaseElevation() {
    switch (widget.type) {
      case ModernCardType.elevated:
        return 4;
      case ModernCardType.glass:
        return 0;
      case ModernCardType.outlined:
        return 0;
      case ModernCardType.filled:
        return 2;
    }
  }

  BoxDecoration _getCardDecoration() {
    switch (widget.type) {
      case ModernCardType.elevated:
        return BoxDecoration(
          color: widget.backgroundColor ?? AppColors.kCardBackground,
          borderRadius: BorderRadius.circular(
            widget.borderRadius ?? AppSizes.cardBorderRadius,
          ),
          gradient: widget.gradientColors != null
              ? LinearGradient(
                  colors: widget.gradientColors!,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: AppColors.kShadowColor,
              blurRadius: _elevationAnimation.value,
              offset: Offset(0, _elevationAnimation.value / 2),
              spreadRadius: widget.isSelected ? 2 : 0,
            ),
            if (widget.isSelected)
              BoxShadow(
                color: AppColors.kPrimary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 0),
                spreadRadius: 1,
              ),
          ],
        );
        
      case ModernCardType.glass:
        return BoxDecoration(
          color: AppColors.kGlassBackground,
          borderRadius: BorderRadius.circular(
            widget.borderRadius ?? AppSizes.cardBorderRadius,
          ),
          border: Border.all(
            color: AppColors.kGlassBorder,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        );
        
      case ModernCardType.outlined:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(
            widget.borderRadius ?? AppSizes.cardBorderRadius,
          ),
          border: Border.all(
            color: widget.isSelected 
                ? AppColors.kPrimary 
                : AppColors.kDivider,
            width: widget.isSelected ? 2 : 1,
          ),
        );
        
      case ModernCardType.filled:
        return BoxDecoration(
          color: widget.backgroundColor ?? AppColors.kPrimary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(
            widget.borderRadius ?? AppSizes.cardBorderRadius,
          ),
          gradient: widget.gradientColors != null
              ? LinearGradient(
                  colors: widget.gradientColors!,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        );
    }
  }

  void _onHoverEnter() {
    if (!widget.enableHoverEffect) return;
    setState(() => _isHovered = true);
    _hoverController.forward();
  }

  void _onHoverExit() {
    if (!widget.enableHoverEffect) return;
    setState(() => _isHovered = false);
    _hoverController.reverse();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _tapController.forward();
    
    if (widget.enableParallax) {
      final RenderBox box = context.findRenderObject() as RenderBox;
      _localPosition = box.globalToLocal(details.globalPosition);
      _parallaxController.forward();
    }
  }

  void _onTapUp() {
    setState(() => _isPressed = false);
    _tapController.reverse();
    _parallaxController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _tapController.reverse();
    _parallaxController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _elevationAnimation,
            _scaleAnimation,
            _parallaxAnimation,
          ]),
          builder: (context, child) {
            return Container(
              margin: widget.margin ?? const EdgeInsets.all(AppSizes.smallPadding),
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: MouseRegion(
                  onEnter: (_) => _onHoverEnter(),
                  onExit: (_) => _onHoverExit(),
                  child: GestureDetector(
                    onTapDown: _onTapDown,
                    onTapUp: (_) => _onTapUp(),
                    onTapCancel: _onTapCancel,
                    onTap: widget.onTap,
                    onLongPress: widget.onLongPress,
                    child: Stack(
                      children: [
                        // Background image
                        if (widget.backgroundImage != null)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                widget.borderRadius ?? AppSizes.cardBorderRadius,
                              ),
                              child: widget.backgroundImage!,
                            ),
                          ),
                        
                        // Main card container
                        Container(
                          decoration: _getCardDecoration(),
                          child: widget.type == ModernCardType.glass
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    widget.borderRadius ?? AppSizes.cardBorderRadius,
                                  ),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                    child: _buildCardContent(),
                                  ),
                                )
                              : _buildCardContent(),
                        ),
                        
                        // Parallax overlay
                        if (widget.enableParallax && _isPressed)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                widget.borderRadius ?? AppSizes.cardBorderRadius,
                              ),
                              child: AnimatedBuilder(
                                animation: _parallaxAnimation,
                                builder: (context, child) {
                                  final size = MediaQuery.of(context).size;
                                  final dx = (_localPosition.dx - size.width / 2) * 0.1 * _parallaxAnimation.value;
                                  final dy = (_localPosition.dy - size.height / 2) * 0.1 * _parallaxAnimation.value;
                                  
                                  return Transform.translate(
                                    offset: Offset(dx, dy),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: RadialGradient(
                                          center: Alignment.center,
                                          radius: 1.0,
                                          colors: [
                                            Colors.white.withOpacity(0.1),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardContent() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        borderRadius: BorderRadius.circular(
          widget.borderRadius ?? AppSizes.cardBorderRadius,
        ),
        child: Padding(
          padding: widget.padding ?? const EdgeInsets.all(AppSizes.padding),
          child: widget.child,
        ),
      ),
    );
  }
}