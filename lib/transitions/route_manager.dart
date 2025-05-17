import 'package:flutter/material.dart';

// Define an enum for slide directions
enum SlideDirection {
  rightToLeft,
  leftToRight,
  topToBottom,
  bottomToTop,
}

class RouteManager {
  // Default transition duration
  static const Duration defaultDuration = Duration(milliseconds: 300);

  // Fade transition
  static PageRouteBuilder createFadeRoute({
    required Widget page,
    Duration duration = defaultDuration,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var curve = Curves.easeInOut;
        var curveTween = CurveTween(curve: curve);
        var fadeTween = Tween<double>(begin: 0.0, end: 1.0);
        var fadeAnimation = fadeTween.animate(curveTween.animate(animation));
        return FadeTransition(
          opacity: fadeAnimation,
          child: child,
        );
      },
    );
  }

  // Slide transition (right to left by default)
  static PageRouteBuilder createSlideRoute({
    required Widget page,
    Duration duration = defaultDuration,
    SlideDirection direction = SlideDirection.rightToLeft,
  }) {
    Offset beginOffset;

    switch (direction) {
      case SlideDirection.rightToLeft:
        beginOffset = const Offset(1.0, 0.0);
        break;
      case SlideDirection.leftToRight:
        beginOffset = const Offset(-1.0, 0.0);
        break;
      case SlideDirection.topToBottom:
        beginOffset = const Offset(0.0, -1.0);
        break;
      case SlideDirection.bottomToTop:
        beginOffset = const Offset(0.0, 1.0);
        break;
    }

    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var curve = Curves.easeInOut;
        var curveTween = CurveTween(curve: curve);
        var slideTween = Tween<Offset>(begin: beginOffset, end: Offset.zero);
        var slideAnimation = slideTween.animate(curveTween.animate(animation));

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  // Scale transition
  static PageRouteBuilder createScaleRoute({
    required Widget page,
    Duration duration = defaultDuration,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var curve = Curves.easeInOut;
        var curveTween = CurveTween(curve: curve);
        var scaleTween = Tween<double>(begin: 0.8, end: 1.0);
        var scaleAnimation = scaleTween.animate(curveTween.animate(animation));

        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
    );
  }
}