import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../constants/sizes.dart';
import '../theme/theme_manager.dart';
import 'modern_card.dart';
import 'modern_button.dart';

class ThemeSwitcher extends StatefulWidget {
  const ThemeSwitcher({Key? key}) : super(key: key);

  @override
  State<ThemeSwitcher> createState() => _ThemeSwitcherState();
}

class _ThemeSwitcherState extends State<ThemeSwitcher>
    with TickerProviderStateMixin {
  late AnimationController _toggleController;
  late AnimationController _rippleController;
  late Animation<double> _toggleAnimation;
  late Animation<double> _rippleAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _toggleController = AnimationController(
      duration: AppSizes.mediumAnimation,
      vsync: this,
    );
    
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _toggleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _toggleController,
      curve: Curves.easeInOutCubic,
    ));
    
    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOutCubic,
    ));
    
    // Set initial state based on current theme
    if (ThemeManager().isDarkMode) {
      _toggleController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _toggleController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _toggleTheme() {
    HapticFeedback.mediumImpact();
    
    _rippleController.forward().then((_) {
      _rippleController.reset();
    });
    
    if (ThemeManager().isDarkMode) {
      _toggleController.reverse();
      ThemeManager().setThemeMode(AppThemeMode.light);
    } else {
      _toggleController.forward();
      ThemeManager().setThemeMode(AppThemeMode.dark);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: _toggleTheme,
      child: AnimatedBuilder(
        animation: Listenable.merge([_toggleAnimation, _rippleAnimation]),
        builder: (context, child) {
          return Container(
            width: 56,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E1E1E), const Color(0xFF374151)]
                    : [const Color(0xFFE2E8F0), const Color(0xFFF1F5F9)],
              ),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Ripple effect
                if (_rippleAnimation.value > 0)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedBuilder(
                        animation: _rippleAnimation,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: RipplePainter(
                              animation: _rippleAnimation,
                              color: Colors.white.withOpacity(0.3),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                
                // Sliding thumb
                AnimatedBuilder(
                  animation: _toggleAnimation,
                  builder: (context, child) {
                    return Positioned(
                      left: 2 + (_toggleAnimation.value * 22),
                      top: 2,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: _toggleAnimation.value > 0.5
                                ? [const Color(0xFF1E293B), const Color(0xFF475569)]
                                : [const Color(0xFFFBBF24), const Color(0xFFF59E0B)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          _toggleAnimation.value > 0.5
                              ? Icons.dark_mode
                              : Icons.light_mode,
                          size: 16,
                          color: _toggleAnimation.value > 0.5
                              ? Colors.white
                              : Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class BusinessThemeSelector extends StatefulWidget {
  const BusinessThemeSelector({Key? key}) : super(key: key);

  @override
  State<BusinessThemeSelector> createState() => _BusinessThemeSelectorState();
}

class _BusinessThemeSelectorState extends State<BusinessThemeSelector>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: AppSizes.longAnimation,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: ModernCard(
        type: ModernCardType.elevated,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Text(
                  'Business Theme',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: BusinessTheme.values.map((theme) {
                return _buildThemeOption(theme);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(BusinessTheme theme) {
    final themeColors = _getThemeColors(theme);
    final isSelected = ThemeManager().businessTheme == theme;
    
    return AnimatedContainer(
      duration: AppSizes.shortAnimation,
      curve: Curves.easeInOut,
      child: ModernCard(
        type: isSelected ? ModernCardType.filled : ModernCardType.outlined,
        gradientColors: isSelected ? themeColors.gradient : null,
        backgroundColor: isSelected ? null : Colors.transparent,
        enableHoverEffect: true,
        onTap: () {
          HapticFeedback.selectionClick();
          ThemeManager().setBusinessTheme(theme);
          setState(() {});
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: themeColors.gradient,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: themeColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                themeColors.icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              themeColors.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : null,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  BusinessThemeColors _getThemeColors(BusinessTheme theme) {
    switch (theme) {
      case BusinessTheme.retail:
        return BusinessThemeColors.retail;
      case BusinessTheme.restaurant:
        return BusinessThemeColors.restaurant;
      case BusinessTheme.pharmacy:
        return BusinessThemeColors.pharmacy;
      case BusinessTheme.electronics:
        return BusinessThemeColors.electronics;
      case BusinessTheme.fashion:
        return BusinessThemeColors.fashion;
      case BusinessTheme.automotive:
        return BusinessThemeColors.automotive;
    }
  }
}

class RipplePainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  RipplePainter({
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(1.0 - animation.value)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = animation.value * (size.width / 2);
    
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(RipplePainter oldDelegate) {
    return oldDelegate.animation.value != animation.value;
  }
}