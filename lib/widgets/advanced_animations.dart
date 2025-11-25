import 'package:flutter/material.dart';
import '../constants/sizes.dart';
import 'micro_interactions.dart';

enum AnimationType {
  slideUp,
  slideDown,
  slideLeft,
  slideRight,
  fade,
  scale,
  rotate,
  elastic,
  bounce,
  wave,
  flip,
  reveal,
}

class AdvancedStaggeredList extends StatefulWidget {
  final List<Widget> children;
  final AnimationType animationType;
  final Duration delay;
  final Duration staggerDelay;
  final Duration duration;
  final Curve curve;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final Axis scrollDirection;
  final bool enablePullToRefresh;
  final Future<void> Function()? onRefresh;
  final bool enableInfiniteScroll;
  final VoidCallback? onLoadMore;
  final bool isLoading;
  final Widget? loadingWidget;

  const AdvancedStaggeredList({
    Key? key,
    required this.children,
    this.animationType = AnimationType.slideUp,
    this.delay = const Duration(milliseconds: 100),
    this.staggerDelay = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeOutCubic,
    this.controller,
    this.physics,
    this.padding,
    this.shrinkWrap = false,
    this.scrollDirection = Axis.vertical,
    this.enablePullToRefresh = false,
    this.onRefresh,
    this.enableInfiniteScroll = false,
    this.onLoadMore,
    this.isLoading = false,
    this.loadingWidget,
  }) : super(key: key);

  @override
  State<AdvancedStaggeredList> createState() => _AdvancedStaggeredListState();
}

class _AdvancedStaggeredListState extends State<AdvancedStaggeredList>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _initializeAnimations();
    _startStaggeredAnimation();
    
    if (widget.enableInfiniteScroll) {
      _scrollController.addListener(_onScroll);
    }
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      widget.children.length,
      (index) => AnimationController(duration: widget.duration, vsync: this),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: widget.curve),
      );
    }).toList();
  }

  void _startStaggeredAnimation() {
    Future.delayed(widget.delay, () {
      for (int i = 0; i < _controllers.length; i++) {
        Future.delayed(
          Duration(milliseconds: i * widget.staggerDelay.inMilliseconds),
          () {
            if (mounted) {
              _controllers[i].forward();
            }
          },
        );
      }
    });
  }

  void _onScroll() {
    if (widget.onLoadMore != null &&
        !widget.isLoading &&
        _scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      widget.onLoadMore?.call();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget listView = ListView.builder(
      controller: _scrollController,
      physics: widget.physics,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      scrollDirection: widget.scrollDirection,
      itemCount: widget.children.length + (widget.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= widget.children.length) {
          return widget.loadingWidget ?? 
                 const Center(child: CircularProgressIndicator());
        }
        
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return _buildAnimatedChild(index, widget.children[index]);
          },
        );
      },
    );

    if (widget.enablePullToRefresh && widget.onRefresh != null) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh!,
        child: listView,
      );
    }

    return listView;
  }

  Widget _buildAnimatedChild(int index, Widget child) {
    final animation = _animations[index];
    
    switch (widget.animationType) {
      case AnimationType.slideUp:
        return Transform.translate(
          offset: Offset(0, (1 - animation.value) * 50),
          child: Opacity(opacity: animation.value, child: child),
        );
        
      case AnimationType.slideDown:
        return Transform.translate(
          offset: Offset(0, (animation.value - 1) * 50),
          child: Opacity(opacity: animation.value, child: child),
        );
        
      case AnimationType.slideLeft:
        return Transform.translate(
          offset: Offset((1 - animation.value) * 100, 0),
          child: Opacity(opacity: animation.value, child: child),
        );
        
      case AnimationType.slideRight:
        return Transform.translate(
          offset: Offset((animation.value - 1) * 100, 0),
          child: Opacity(opacity: animation.value, child: child),
        );
        
      case AnimationType.fade:
        return Opacity(opacity: animation.value, child: child);
        
      case AnimationType.scale:
        return Transform.scale(
          scale: animation.value,
          child: Opacity(opacity: animation.value, child: child),
        );
        
      case AnimationType.rotate:
        return Transform.rotate(
          angle: (1 - animation.value) * 0.5,
          child: Opacity(opacity: animation.value, child: child),
        );
        
      case AnimationType.elastic:
        return Transform.scale(
          scale: Curves.elasticOut.transform(animation.value),
          child: child,
        );
        
      case AnimationType.bounce:
        return Transform.translate(
          offset: Offset(0, (1 - Curves.bounceOut.transform(animation.value)) * 30),
          child: child,
        );
        
      case AnimationType.wave:
        return Transform.translate(
          offset: Offset(0, (1 - animation.value) * 20 * (index % 2 == 0 ? 1 : -1)),
          child: Opacity(opacity: animation.value, child: child),
        );
        
      case AnimationType.flip:
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY((1 - animation.value) * 1.5708),
          child: child,
        );
        
      case AnimationType.reveal:
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: animation.value,
            child: child,
          ),
        );
    }
  }
}

class AdvancedStaggeredGrid extends StatefulWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final AnimationType animationType;
  final Duration delay;
  final Duration staggerDelay;
  final Duration duration;
  final Curve curve;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final bool enablePullToRefresh;
  final Future<void> Function()? onRefresh;

  const AdvancedStaggeredGrid({
    Key? key,
    required this.children,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = 8.0,
    this.crossAxisSpacing = 8.0,
    this.childAspectRatio = 1.0,
    this.animationType = AnimationType.scale,
    this.delay = const Duration(milliseconds: 100),
    this.staggerDelay = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeOutBack,
    this.controller,
    this.physics,
    this.padding,
    this.shrinkWrap = false,
    this.enablePullToRefresh = false,
    this.onRefresh,
  }) : super(key: key);

  @override
  State<AdvancedStaggeredGrid> createState() => _AdvancedStaggeredGridState();
}

class _AdvancedStaggeredGridState extends State<AdvancedStaggeredGrid>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startStaggeredAnimation();
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      widget.children.length,
      (index) => AnimationController(duration: widget.duration, vsync: this),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: widget.curve),
      );
    }).toList();
  }

  void _startStaggeredAnimation() {
    Future.delayed(widget.delay, () {
      for (int i = 0; i < _controllers.length; i++) {
        // Calculate stagger delay based on grid position
        final row = i ~/ widget.crossAxisCount;
        final col = i % widget.crossAxisCount;
        final delay = (row + col) * widget.staggerDelay.inMilliseconds;
        
        Future.delayed(
          Duration(milliseconds: delay),
          () {
            if (mounted) {
              _controllers[i].forward();
            }
          },
        );
      }
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget gridView = GridView.builder(
      controller: widget.controller,
      physics: widget.physics,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        mainAxisSpacing: widget.mainAxisSpacing,
        crossAxisSpacing: widget.crossAxisSpacing,
        childAspectRatio: widget.childAspectRatio,
      ),
      itemCount: widget.children.length,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return _buildAnimatedChild(index, widget.children[index]);
          },
        );
      },
    );

    if (widget.enablePullToRefresh && widget.onRefresh != null) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh!,
        child: gridView,
      );
    }

    return gridView;
  }

  Widget _buildAnimatedChild(int index, Widget child) {
    final animation = _animations[index];
    
    switch (widget.animationType) {
      case AnimationType.scale:
        return Transform.scale(
          scale: animation.value,
          child: child,
        );
        
      case AnimationType.fade:
        return Opacity(opacity: animation.value, child: child);
        
      case AnimationType.slideUp:
        return Transform.translate(
          offset: Offset(0, (1 - animation.value) * 30),
          child: Opacity(opacity: animation.value, child: child),
        );
        
      case AnimationType.elastic:
        return Transform.scale(
          scale: Curves.elasticOut.transform(animation.value),
          child: child,
        );
        
      case AnimationType.bounce:
        return Transform.scale(
          scale: Curves.bounceOut.transform(animation.value),
          child: child,
        );
        
      case AnimationType.rotate:
        return Transform.rotate(
          angle: (1 - animation.value) * 6.28,
          child: Transform.scale(scale: animation.value, child: child),
        );
        
      default:
        return Transform.scale(
          scale: animation.value,
          child: child,
        );
    }
  }
}

class AnimatedPageTransition extends StatefulWidget {
  final Widget child;
  final AnimationType animationType;
  final Duration duration;
  final Curve curve;
  final bool autoStart;

  const AnimatedPageTransition({
    Key? key,
    required this.child,
    this.animationType = AnimationType.slideUp,
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeOutCubic,
    this.autoStart = true,
  }) : super(key: key);

  @override
  State<AnimatedPageTransition> createState() => _AnimatedPageTransitionState();
}

class _AnimatedPageTransitionState extends State<AnimatedPageTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
    
    if (widget.autoStart) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void start() => _controller.forward();
  void reverse() => _controller.reverse();
  void reset() => _controller.reset();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        switch (widget.animationType) {
          case AnimationType.slideUp:
            return Transform.translate(
              offset: Offset(0, (1 - _animation.value) * 100),
              child: Opacity(opacity: _animation.value, child: widget.child),
            );
            
          case AnimationType.slideDown:
            return Transform.translate(
              offset: Offset(0, (_animation.value - 1) * 100),
              child: Opacity(opacity: _animation.value, child: widget.child),
            );
            
          case AnimationType.slideLeft:
            return Transform.translate(
              offset: Offset((1 - _animation.value) * 300, 0),
              child: widget.child,
            );
            
          case AnimationType.slideRight:
            return Transform.translate(
              offset: Offset((_animation.value - 1) * 300, 0),
              child: widget.child,
            );
            
          case AnimationType.fade:
            return Opacity(opacity: _animation.value, child: widget.child);
            
          case AnimationType.scale:
            return Transform.scale(
              scale: _animation.value,
              child: widget.child,
            );
            
          case AnimationType.elastic:
            return Transform.scale(
              scale: Curves.elasticOut.transform(_animation.value),
              child: widget.child,
            );
            
          default:
            return widget.child;
        }
      },
    );
  }
}

class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;
  final bool autoStart;

  const PulseAnimation({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 1000),
    this.minScale = 0.95,
    this.maxScale = 1.05,
    this.autoStart = true,
  }) : super(key: key);

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    if (widget.autoStart) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}