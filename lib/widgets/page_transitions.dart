import 'package:flutter/material.dart';
import '../constants/sizes.dart';

enum PageTransitionType {
  slideFromRight,
  slideFromLeft,
  slideFromBottom,
  slideFromTop,
  fade,
  scale,
  rotation,
  slideAndFade,
  scaleAndRotate,
  elastic,
  parallax,
}

class PageTransitionBuilder {
  static PageRouteBuilder<T> buildTransition<T extends Object?>({
    required Widget page,
    required PageTransitionType type,
    Duration? duration,
    Duration? reverseDuration,
    Curve? curve,
    Curve? reverseCurve,
    bool? maintainState,
    bool? opaque,
    bool? barrierDismissible,
    String? barrierLabel,
    Color? barrierColor,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration ?? AppSizes.pageTransition,
      reverseTransitionDuration: reverseDuration ?? AppSizes.pageTransition,
      maintainState: maintainState ?? true,
      opaque: opaque ?? true,
      barrierDismissible: barrierDismissible ?? false,
      barrierLabel: barrierLabel,
      barrierColor: barrierColor,
      settings: settings,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return _buildTransition(
          type: type,
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: child,
          curve: curve ?? AppSizes.defaultCurve,
          reverseCurve: reverseCurve ?? AppSizes.defaultCurve,
        );
      },
    );
  }

  static Widget _buildTransition({
    required PageTransitionType type,
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
    required Curve curve,
    required Curve reverseCurve,
  }) {
    switch (type) {
      case PageTransitionType.slideFromRight:
        return _slideTransition(
          animation: animation,
          child: child,
          curve: curve,
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        );

      case PageTransitionType.slideFromLeft:
        return _slideTransition(
          animation: animation,
          child: child,
          curve: curve,
          begin: const Offset(-1.0, 0.0),
          end: Offset.zero,
        );

      case PageTransitionType.slideFromBottom:
        return _slideTransition(
          animation: animation,
          child: child,
          curve: curve,
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        );

      case PageTransitionType.slideFromTop:
        return _slideTransition(
          animation: animation,
          child: child,
          curve: curve,
          begin: const Offset(0.0, -1.0),
          end: Offset.zero,
        );

      case PageTransitionType.fade:
        return _fadeTransition(
          animation: animation,
          child: child,
          curve: curve,
        );

      case PageTransitionType.scale:
        return _scaleTransition(
          animation: animation,
          child: child,
          curve: curve,
        );

      case PageTransitionType.rotation:
        return _rotationTransition(
          animation: animation,
          child: child,
          curve: curve,
        );

      case PageTransitionType.slideAndFade:
        return _slideAndFadeTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: child,
          curve: curve,
        );

      case PageTransitionType.scaleAndRotate:
        return _scaleAndRotateTransition(
          animation: animation,
          child: child,
          curve: curve,
        );

      case PageTransitionType.elastic:
        return _elasticTransition(
          animation: animation,
          child: child,
        );

      case PageTransitionType.parallax:
        return _parallaxTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: child,
          curve: curve,
        );
    }
  }

  static Widget _slideTransition({
    required Animation<double> animation,
    required Widget child,
    required Curve curve,
    required Offset begin,
    required Offset end,
  }) {
    final offsetAnimation = Tween<Offset>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: curve,
    ));

    return SlideTransition(
      position: offsetAnimation,
      child: child,
    );
  }

  static Widget _fadeTransition({
    required Animation<double> animation,
    required Widget child,
    required Curve curve,
  }) {
    final opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: curve,
    ));

    return FadeTransition(
      opacity: opacityAnimation,
      child: child,
    );
  }

  static Widget _scaleTransition({
    required Animation<double> animation,
    required Widget child,
    required Curve curve,
  }) {
    final scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: curve,
    ));

    return ScaleTransition(
      scale: scaleAnimation,
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  static Widget _rotationTransition({
    required Animation<double> animation,
    required Widget child,
    required Curve curve,
  }) {
    final rotationAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: curve,
    ));

    return RotationTransition(
      turns: rotationAnimation,
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  static Widget _slideAndFadeTransition({
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
    required Curve curve,
  }) {
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: curve,
    ));

    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));

    // Slide out the previous page
    final secondarySlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.3, 0.0),
    ).animate(CurvedAnimation(
      parent: secondaryAnimation,
      curve: curve,
    ));

    final secondaryFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: secondaryAnimation,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    ));

    return Stack(
      children: [
        SlideTransition(
          position: secondarySlideAnimation,
          child: FadeTransition(
            opacity: secondaryFadeAnimation,
            child: Container(), // Previous page placeholder
          ),
        ),
        SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        ),
      ],
    );
  }

  static Widget _scaleAndRotateTransition({
    required Animation<double> animation,
    required Widget child,
    required Curve curve,
  }) {
    final scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: curve,
    ));

    final rotationAnimation = Tween<double>(
      begin: 0.2,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: curve,
    ));

    return Transform.scale(
      scale: scaleAnimation.value,
      child: Transform.rotate(
        angle: rotationAnimation.value,
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
  }

  static Widget _elasticTransition({
    required Animation<double> animation,
    required Widget child,
  }) {
    final elasticAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.elasticOut,
    ));

    return ScaleTransition(
      scale: elasticAnimation,
      child: child,
    );
  }

  static Widget _parallaxTransition({
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
    required Curve curve,
  }) {
    final slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: curve,
    ));

    final secondarySlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.5, 0.0),
    ).animate(CurvedAnimation(
      parent: secondaryAnimation,
      curve: curve,
    ));

    final scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: secondaryAnimation,
      curve: curve,
    ));

    return Stack(
      children: [
        SlideTransition(
          position: secondarySlideAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: Container(), // Previous page placeholder
          ),
        ),
        SlideTransition(
          position: slideAnimation,
          child: child,
        ),
      ],
    );
  }
}

// Extension for easy navigation with transitions
extension NavigatorTransitions on NavigatorState {
  Future<T?> pushWithTransition<T extends Object?>(
    Widget page, {
    PageTransitionType type = PageTransitionType.slideFromRight,
    Duration? duration,
    Curve? curve,
    RouteSettings? settings,
  }) {
    return push<T>(
      PageTransitionBuilder.buildTransition<T>(
        page: page,
        type: type,
        duration: duration,
        curve: curve,
        settings: settings,
      ),
    );
  }

  Future<T?> pushReplacementWithTransition<T extends Object?, TO extends Object?>(
    Widget page, {
    PageTransitionType type = PageTransitionType.slideFromRight,
    Duration? duration,
    Curve? curve,
    RouteSettings? settings,
    TO? result,
  }) {
    return pushReplacement<T, TO>(
      PageTransitionBuilder.buildTransition<T>(
        page: page,
        type: type,
        duration: duration,
        curve: curve,
        settings: settings,
      ),
      result: result,
    );
  }
}