import 'package:flutter/material.dart';
import '../constants/sizes.dart';

class StaggeredListView extends StatefulWidget {
  final List<Widget> children;
  final Duration animationDelay;
  final Duration staggerDelay;
  final Curve animationCurve;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final Axis scrollDirection;
  final bool reverse;
  final ScrollController? controller;
  final bool enablePullToRefresh;
  final Future<void> Function()? onRefresh;

  const StaggeredListView({
    Key? key,
    required this.children,
    this.animationDelay = const Duration(milliseconds: 100),
    this.staggerDelay = const Duration(milliseconds: 50),
    this.animationCurve = Curves.easeOutBack,
    this.physics,
    this.padding,
    this.shrinkWrap = false,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.enablePullToRefresh = false,
    this.onRefresh,
  }) : super(key: key);

  @override
  State<StaggeredListView> createState() => _StaggeredListViewState();
}

class _StaggeredListViewState extends State<StaggeredListView>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<double>> _scaleAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startStaggeredAnimations();
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      widget.children.length,
      (index) => AnimationController(
        duration: AppSizes.mediumAnimation,
        vsync: this,
      ),
    );

    _slideAnimations = _controllers.map((controller) {
      return Tween<Offset>(
        begin: const Offset(0.0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: widget.animationCurve,
      ));
    }).toList();

    _fadeAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ));
    }).toList();

    _scaleAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.8,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: widget.animationCurve,
      ));
    }).toList();
  }

  void _startStaggeredAnimations() {
    Future.delayed(widget.animationDelay, () {
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

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget listView = ListView.builder(
      controller: widget.controller,
      physics: widget.physics,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      scrollDirection: widget.scrollDirection,
      reverse: widget.reverse,
      itemCount: widget.children.length,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: Listenable.merge([
            _slideAnimations[index],
            _fadeAnimations[index],
            _scaleAnimations[index],
          ]),
          builder: (context, child) {
            return SlideTransition(
              position: _slideAnimations[index],
              child: FadeTransition(
                opacity: _fadeAnimations[index],
                child: ScaleTransition(
                  scale: _scaleAnimations[index],
                  child: widget.children[index],
                ),
              ),
            );
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
}

class StaggeredGridView extends StatefulWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final Duration animationDelay;
  final Duration staggerDelay;
  final Curve animationCurve;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollController? controller;

  const StaggeredGridView({
    Key? key,
    required this.children,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = 8.0,
    this.crossAxisSpacing = 8.0,
    this.childAspectRatio = 1.0,
    this.animationDelay = const Duration(milliseconds: 100),
    this.staggerDelay = const Duration(milliseconds: 50),
    this.animationCurve = Curves.easeOutBack,
    this.physics,
    this.padding,
    this.shrinkWrap = false,
    this.controller,
  }) : super(key: key);

  @override
  State<StaggeredGridView> createState() => _StaggeredGridViewState();
}

class _StaggeredGridViewState extends State<StaggeredGridView>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<double>> _scaleAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startStaggeredAnimations();
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      widget.children.length,
      (index) => AnimationController(
        duration: AppSizes.mediumAnimation,
        vsync: this,
      ),
    );

    _slideAnimations = _controllers.map((controller) {
      return Tween<Offset>(
        begin: const Offset(0.0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: widget.animationCurve,
      ));
    }).toList();

    _fadeAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ));
    }).toList();

    _scaleAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.7,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: widget.animationCurve,
      ));
    }).toList();
  }

  void _startStaggeredAnimations() {
    Future.delayed(widget.animationDelay, () {
      for (int i = 0; i < _controllers.length; i++) {
        // Calculate row and column for staggered effect
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
    return GridView.builder(
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
          animation: Listenable.merge([
            _slideAnimations[index],
            _fadeAnimations[index],
            _scaleAnimations[index],
          ]),
          builder: (context, child) {
            return SlideTransition(
              position: _slideAnimations[index],
              child: FadeTransition(
                opacity: _fadeAnimations[index],
                child: ScaleTransition(
                  scale: _scaleAnimations[index],
                  child: widget.children[index],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class StaggeredWrap extends StatefulWidget {
  final List<Widget> children;
  final Axis direction;
  final WrapAlignment alignment;
  final double spacing;
  final WrapAlignment runAlignment;
  final double runSpacing;
  final WrapCrossAlignment crossAxisAlignment;
  final TextDirection? textDirection;
  final VerticalDirection verticalDirection;
  final Duration animationDelay;
  final Duration staggerDelay;
  final Curve animationCurve;

  const StaggeredWrap({
    Key? key,
    required this.children,
    this.direction = Axis.horizontal,
    this.alignment = WrapAlignment.start,
    this.spacing = 0.0,
    this.runAlignment = WrapAlignment.start,
    this.runSpacing = 0.0,
    this.crossAxisAlignment = WrapCrossAlignment.start,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    this.animationDelay = const Duration(milliseconds: 100),
    this.staggerDelay = const Duration(milliseconds: 30),
    this.animationCurve = Curves.easeOutBack,
  }) : super(key: key);

  @override
  State<StaggeredWrap> createState() => _StaggeredWrapState();
}

class _StaggeredWrapState extends State<StaggeredWrap>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<double>> _scaleAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startStaggeredAnimations();
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      widget.children.length,
      (index) => AnimationController(
        duration: AppSizes.shortAnimation,
        vsync: this,
      ),
    );

    _fadeAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ));
    }).toList();

    _scaleAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.5,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: widget.animationCurve,
      ));
    }).toList();
  }

  void _startStaggeredAnimations() {
    Future.delayed(widget.animationDelay, () {
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

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      direction: widget.direction,
      alignment: widget.alignment,
      spacing: widget.spacing,
      runAlignment: widget.runAlignment,
      runSpacing: widget.runSpacing,
      crossAxisAlignment: widget.crossAxisAlignment,
      textDirection: widget.textDirection,
      verticalDirection: widget.verticalDirection,
      children: widget.children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        
        return AnimatedBuilder(
          animation: Listenable.merge([
            _fadeAnimations[index],
            _scaleAnimations[index],
          ]),
          builder: (context, _) {
            return FadeTransition(
              opacity: _fadeAnimations[index],
              child: ScaleTransition(
                scale: _scaleAnimations[index],
                child: child,
              ),
            );
          },
        );
      }).toList(),
    );
  }
}