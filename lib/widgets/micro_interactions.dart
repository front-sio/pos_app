import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../constants/sizes.dart';

enum HapticType {
  light,
  medium,
  heavy,
  selection,
  error,
  success,
}

class HapticManager {
  static void trigger(HapticType type) {
    switch (type) {
      case HapticType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticType.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticType.heavy:
        HapticFeedback.heavyImpact();
        break;
      case HapticType.selection:
        HapticFeedback.selectionClick();
        break;
      case HapticType.error:
        HapticFeedback.vibrate();
        break;
      case HapticType.success:
        HapticFeedback.lightImpact();
        Future.delayed(const Duration(milliseconds: 50), () {
          HapticFeedback.lightImpact();
        });
        break;
    }
  }
}

class SwipeToActionCard extends StatefulWidget {
  final Widget child;
  final Widget? leftAction;
  final Widget? rightAction;
  final VoidCallback? onLeftSwipe;
  final VoidCallback? onRightSwipe;
  final Color? leftActionColor;
  final Color? rightActionColor;
  final double actionWidth;
  final bool enableHapticFeedback;

  const SwipeToActionCard({
    Key? key,
    required this.child,
    this.leftAction,
    this.rightAction,
    this.onLeftSwipe,
    this.onRightSwipe,
    this.leftActionColor,
    this.rightActionColor,
    this.actionWidth = 80.0,
    this.enableHapticFeedback = true,
  }) : super(key: key);

  @override
  State<SwipeToActionCard> createState() => _SwipeToActionCardState();
}

class _SwipeToActionCardState extends State<SwipeToActionCard>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  
  double _dragExtent = 0.0;
  bool _hapticTriggered = false;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: AppSizes.shortAnimation,
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _handleDragStart() {
    _scaleController.forward();
    _hapticTriggered = false;
  }

  void _handleDragUpdate(double delta) {
    setState(() {
      _dragExtent = (_dragExtent + delta).clamp(-widget.actionWidth, widget.actionWidth);
    });
    
    // Trigger haptic feedback when reaching action threshold
    if (widget.enableHapticFeedback && !_hapticTriggered) {
      if (_dragExtent.abs() > widget.actionWidth * 0.7) {
        HapticManager.trigger(HapticType.medium);
        _hapticTriggered = true;
      }
    }
  }

  void _handleDragEnd() {
    _scaleController.reverse();
    
    if (_dragExtent.abs() > widget.actionWidth * 0.7) {
      if (_dragExtent > 0 && widget.onRightSwipe != null) {
        widget.onRightSwipe!();
        if (widget.enableHapticFeedback) {
          HapticManager.trigger(HapticType.success);
        }
      } else if (_dragExtent < 0 && widget.onLeftSwipe != null) {
        widget.onLeftSwipe!();
        if (widget.enableHapticFeedback) {
          HapticManager.trigger(HapticType.success);
        }
      }
    }
    
    setState(() {
      _dragExtent = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: (_) => _handleDragStart(),
      onHorizontalDragUpdate: (details) => _handleDragUpdate(details.delta.dx),
      onHorizontalDragEnd: (_) => _handleDragEnd(),
      child: Stack(
        children: [
          // Background actions
          if (widget.leftAction != null || widget.rightAction != null)
            Positioned.fill(
              child: Row(
                children: [
                  if (widget.leftAction != null)
                    Container(
                      width: widget.actionWidth,
                      decoration: BoxDecoration(
                        color: widget.leftActionColor ?? AppColors.kError,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppSizes.borderRadius),
                          bottomLeft: Radius.circular(AppSizes.borderRadius),
                        ),
                      ),
                      child: widget.leftAction!,
                    ),
                  const Spacer(),
                  if (widget.rightAction != null)
                    Container(
                      width: widget.actionWidth,
                      decoration: BoxDecoration(
                        color: widget.rightActionColor ?? AppColors.kSuccess,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(AppSizes.borderRadius),
                          bottomRight: Radius.circular(AppSizes.borderRadius),
                        ),
                      ),
                      child: widget.rightAction!,
                    ),
                ],
              ),
            ),
          
          // Main content
          ScaleTransition(
            scale: _scaleAnimation,
            child: Transform.translate(
              offset: Offset(_dragExtent, 0),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}

class PullToRefreshIndicator extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final double triggerOffset;
  final Color? color;

  const PullToRefreshIndicator({
    Key? key,
    required this.child,
    required this.onRefresh,
    this.triggerOffset = 80.0,
    this.color,
  }) : super(key: key);

  @override
  State<PullToRefreshIndicator> createState() => _PullToRefreshIndicatorState();
}

class _PullToRefreshIndicatorState extends State<PullToRefreshIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  
  double _pullExtent = 0.0;
  bool _isRefreshing = false;
  bool _hapticTriggered = false;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePull(double extent) {
    setState(() {
      _pullExtent = extent.clamp(0.0, widget.triggerOffset * 1.5);
    });
    
    final progress = (_pullExtent / widget.triggerOffset).clamp(0.0, 1.0);
    _controller.value = progress;
    
    if (!_hapticTriggered && progress >= 1.0) {
      HapticManager.trigger(HapticType.medium);
      _hapticTriggered = true;
    }
  }

  void _handleRefresh() async {
    if (_pullExtent >= widget.triggerOffset && !_isRefreshing) {
      setState(() {
        _isRefreshing = true;
      });
      
      _controller.repeat();
      HapticManager.trigger(HapticType.success);
      
      try {
        await widget.onRefresh();
      } finally {
        setState(() {
          _isRefreshing = false;
          _pullExtent = 0.0;
          _hapticTriggered = false;
        });
        _controller.reset();
      }
    } else {
      setState(() {
        _pullExtent = 0.0;
        _hapticTriggered = false;
      });
      _controller.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification &&
            notification.metrics.pixels < 0) {
          _handlePull(-notification.metrics.pixels);
        } else if (notification is ScrollEndNotification) {
          _handleRefresh();
        }
        return false;
      },
      child: Stack(
        children: [
          widget.child,
          if (_pullExtent > 0)
            Positioned(
              top: _pullExtent - 40,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_scaleAnimation, _rotationAnimation]),
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Transform.rotate(
                        angle: _isRefreshing ? _rotationAnimation.value * 3.14159 : 0,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: widget.color ?? AppColors.kPrimary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isRefreshing ? Icons.refresh : Icons.arrow_downward,
                            color: Colors.white,
                            size: 20,
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
    );
  }
}

class AnimatedCounter extends StatefulWidget {
  final int value;
  final Duration duration;
  final TextStyle? textStyle;
  final String? prefix;
  final String? suffix;

  const AnimatedCounter({
    Key? key,
    required this.value,
    this.duration = const Duration(milliseconds: 1000),
    this.textStyle,
    this.prefix,
    this.suffix,
  }) : super(key: key);

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _countAnimation;
  
  int _previousValue = 0;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _updateAnimation();
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
      _updateAnimation();
      _controller.forward(from: 0);
    }
  }

  void _updateAnimation() {
    _countAnimation = IntTween(
      begin: _previousValue,
      end: widget.value,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _countAnimation,
      builder: (context, child) {
        return Text(
          '${widget.prefix ?? ''}${_countAnimation.value}${widget.suffix ?? ''}',
          style: widget.textStyle,
        );
      },
    );
  }
}

class FloatingActionBubble extends StatefulWidget {
  final List<FloatingActionItem> items;
  final Widget? child;
  final Color? backgroundColor;
  final Duration animationDuration;

  const FloatingActionBubble({
    Key? key,
    required this.items,
    this.child,
    this.backgroundColor,
    this.animationDuration = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  State<FloatingActionBubble> createState() => _FloatingActionBubbleState();
}

class _FloatingActionBubbleState extends State<FloatingActionBubble>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<Offset>> _itemAnimations;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.125,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _itemAnimations = List.generate(widget.items.length, (index) {
      return Tween<Offset>(
        begin: Offset.zero,
        end: Offset(0, -(index + 1) * 70.0 / 100),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Interval(
          index * 0.1,
          1.0,
          curve: Curves.elasticOut,
        ),
      ));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    HapticManager.trigger(HapticType.medium);
    
    setState(() {
      _isExpanded = !_isExpanded;
    });
    
    if (_isExpanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Backdrop
        if (_isExpanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleExpanded,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Container(
                    color: Colors.black.withOpacity(0.3 * _controller.value),
                  );
                },
              ),
            ),
          ),
        
        // Action items
        ...widget.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          
          return AnimatedBuilder(
            animation: _itemAnimations[index],
            builder: (context, child) {
              return Transform.translate(
                offset: _itemAnimations[index].value * 100,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: FloatingActionButton.small(
                    heroTag: 'fab_${index}',
                    onPressed: () {
                      item.onTap();
                      _toggleExpanded();
                      HapticManager.trigger(HapticType.selection);
                    },
                    backgroundColor: item.backgroundColor,
                    child: Icon(item.icon, color: item.iconColor),
                  ),
                ),
              );
            },
          );
        }).toList(),
        
        // Main FAB
        AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationAnimation.value * 2 * 3.14159,
              child: FloatingActionButton(
                onPressed: _toggleExpanded,
                backgroundColor: widget.backgroundColor ?? AppColors.kPrimary,
                child: widget.child ??
                    Icon(
                      _isExpanded ? Icons.close : Icons.add,
                      color: Colors.white,
                    ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class FloatingActionItem {
  final IconData icon;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? iconColor;
  final String? tooltip;

  const FloatingActionItem({
    required this.icon,
    required this.onTap,
    this.backgroundColor,
    this.iconColor,
    this.tooltip,
  });
}