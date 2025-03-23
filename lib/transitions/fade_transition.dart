import 'package:flutter/material.dart';
import './route_manager.dart';

// Custom fade transition function - enhanced version
PageRouteBuilder fadeTransition(Widget page, {Duration duration = const Duration(milliseconds: 300)}) {
  return RouteManager.createFadeRoute(page: page, duration: duration);
}

// Custom slide transition function
PageRouteBuilder slideTransition(Widget page, {
  Duration duration = const Duration(milliseconds: 300),
  SlideDirection direction = SlideDirection.rightToLeft,
}) {
  return RouteManager.createSlideRoute(
    page: page,
    duration: duration,
    direction: direction,
  );
}

// Custom scale transition function
PageRouteBuilder scaleTransition(Widget page, {Duration duration = const Duration(milliseconds: 300)}) {
  return RouteManager.createScaleRoute(page: page, duration: duration);
}