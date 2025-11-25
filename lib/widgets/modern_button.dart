import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../constants/sizes.dart';

enum ModernButtonType {
  primary,
  secondary,
  outline,
  text,
  floating,
  glass,
}

enum ModernButtonSize {
  small,
  medium,
  large,
}

class ModernButton extends StatefulWidget {
  final String? text;
  final Widget? child;
  final IconData? icon;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final ModernButtonType type;
  final ModernButtonSize size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final List<Color>? gradientColors;
  final bool isLoading;
  final bool isEnabled;
  final double? width;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool enableHapticFeedback;
  final bool enableRippleEffect;

  const ModernButton({
    Key? key,
    this.text,
    this.child,
    this.icon,
    this.onPressed,
    this.onLongPress,
    this.type = ModernButtonType.primary,
    this.size = ModernButtonSize.medium,
    this.backgroundColor,
    this.foregroundColor,
    this.gradientColors,
    this.isLoading = false,
    this.isEnabled = true,
    this.width,
    this.borderRadius,
    this.padding,
    this.enableHapticFeedback = true,
    this.enableRippleEffect = true,
  }) : assert(text != null || child != null),
       super(key: key);

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late AnimationController _rippleController;
  late AnimationController _loadingController;
  late AnimationController _glowController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _glowAnimation;
  
  bool _isPressed = false;
  bool _isHovered = false;
  Offset? _ripplePosition;

  @override
  void initState() {
    super.initState();
    
    _pressController = AnimationController(
      duration: AppSizes.shortAnimation,
      vsync: this,
    );
    
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeInOut,
    ));
    
    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _loadingController,
      curve: Curves.linear,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.isLoading) {
      _loadingController.repeat();
    }
    
    if (widget.type == ModernButtonType.primary) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ModernButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isLoading && !oldWidget.isLoading) {
      _loadingController.repeat();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _loadingController.stop();
      _loadingController.reset();
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    _rippleController.dispose();
    _loadingController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  double _getButtonHeight() {
    switch (widget.size) {
      case ModernButtonSize.small:
        return 36.0;
      case ModernButtonSize.medium:
        return AppSizes.buttonHeight;
      case ModernButtonSize.large:
        return 56.0;
    }
  }

  EdgeInsetsGeometry _getButtonPadding() {
    switch (widget.size) {
      case ModernButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case ModernButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      case ModernButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    }
  }

  double _getButtonBorderRadius() {
    return widget.borderRadius ?? AppSizes.buttonRadius;
  }

  Color _getBackgroundColor() {
    if (!widget.isEnabled) {
      return AppColors.kTextSecondary.withOpacity(0.3);
    }
    
    switch (widget.type) {
      case ModernButtonType.primary:
        return widget.backgroundColor ?? AppColors.kPrimary;
      case ModernButtonType.secondary:
        return widget.backgroundColor ?? AppColors.kSecondary;
      case ModernButtonType.outline:
      case ModernButtonType.text:
        return Colors.transparent;
      case ModernButtonType.floating:
        return widget.backgroundColor ?? AppColors.kPrimary;
      case ModernButtonType.glass:
        return AppColors.kGlassBackground;
    }
  }

  Color _getForegroundColor() {
    if (!widget.isEnabled) {
      return AppColors.kTextSecondary;
    }
    
    switch (widget.type) {
      case ModernButtonType.primary:
      case ModernButtonType.secondary:
      case ModernButtonType.floating:
        return widget.foregroundColor ?? AppColors.kTextOnPrimary;
      case ModernButtonType.outline:
      case ModernButtonType.text:
      case ModernButtonType.glass:
        return widget.foregroundColor ?? AppColors.kPrimary;
    }
  }

  BorderSide? _getBorder() {
    switch (widget.type) {
      case ModernButtonType.outline:
        return BorderSide(
          color: widget.isEnabled
              ? (widget.backgroundColor ?? AppColors.kPrimary)
              : AppColors.kTextSecondary.withOpacity(0.3),
          width: 1.5,
        );
      case ModernButtonType.glass:
        return BorderSide(
          color: AppColors.kGlassBorder,
          width: 1,
        );
      default:
        return null;
    }
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.isEnabled || widget.isLoading) return;
    
    setState(() {
      _isPressed = true;
      _ripplePosition = details.localPosition;
    });
    
    _pressController.forward();
    
    if (widget.enableRippleEffect) {
      _rippleController.forward().then((_) {
        _rippleController.reset();
      });
    }
    
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
  }

  void _onTapUp() {
    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  void _onHoverEnter() {
    setState(() => _isHovered = true);
  }

  void _onHoverExit() {
    setState(() => _isHovered = false);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHoverEnter(),
      onExit: (_) => _onHoverExit(),
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _scaleAnimation,
          _glowAnimation,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width,
              height: _getButtonHeight(),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_getButtonBorderRadius()),
                boxShadow: [
                  if (widget.type == ModernButtonType.primary && _isHovered)
                    BoxShadow(
                      color: AppColors.kPrimary.withOpacity(0.4 * _glowAnimation.value),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  if (widget.type == ModernButtonType.floating)
                    BoxShadow(
                      color: AppColors.kShadowColor,
                      blurRadius: _isHovered ? 12 : 8,
                      offset: Offset(0, _isHovered ? 6 : 4),
                    ),
                ],
              ),
              child: Stack(
                children: [
                  // Gradient background
                  if (widget.gradientColors != null)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: widget.gradientColors!,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(_getButtonBorderRadius()),
                        ),
                      ),
                    ),
                  
                  // Ripple effect
                  if (widget.enableRippleEffect && _ripplePosition != null)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(_getButtonBorderRadius()),
                        child: AnimatedBuilder(
                          animation: _rippleAnimation,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: RipplePainter(
                                animation: _rippleAnimation,
                                center: _ripplePosition!,
                                color: Colors.white.withOpacity(0.3),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  
                  // Main button
                  Positioned.fill(
                    child: ElevatedButton(
                      onPressed: widget.isEnabled && !widget.isLoading 
                          ? widget.onPressed 
                          : null,
                      onLongPress: widget.onLongPress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.gradientColors == null 
                            ? _getBackgroundColor() 
                            : Colors.transparent,
                        foregroundColor: _getForegroundColor(),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        side: _getBorder(),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_getButtonBorderRadius()),
                        ),
                        padding: widget.padding ?? _getButtonPadding(),
                      ),
                      child: _buildButtonContent(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildButtonContent() {
    if (widget.isLoading) {
      return AnimatedBuilder(
        animation: _rotationAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationAnimation.value * 3.14159,
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(_getForegroundColor()),
              ),
            ),
          );
        },
      );
    }

    if (widget.child != null) {
      return widget.child!;
    }

    final List<Widget> children = [];
    
    if (widget.icon != null) {
      children.add(
        Icon(
          widget.icon,
          size: widget.size == ModernButtonSize.small ? 16 : 20,
        ),
      );
      
      if (widget.text != null) {
        children.add(const SizedBox(width: 8));
      }
    }
    
    if (widget.text != null) {
      children.add(
        Text(
          widget.text!,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: widget.size == ModernButtonSize.small ? 14 : 16,
          ),
        ),
      );
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }
}

class RipplePainter extends CustomPainter {
  final Animation<double> animation;
  final Offset center;
  final Color color;

  RipplePainter({
    required this.animation,
    required this.center,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(1.0 - animation.value)
      ..style = PaintingStyle.fill;

    final radius = animation.value * size.width;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(RipplePainter oldDelegate) {
    return oldDelegate.animation.value != animation.value;
  }
}