import 'package:flutter/material.dart';

class PageTransition extends StatefulWidget {
  final Widget child;
  final PageTransitionType type;
  final Curve curve;
  final Alignment alignment;
  final Duration duration;

  const PageTransition({
    Key? key,
    required this.child,
    this.type = PageTransitionType.fade,
    this.curve = Curves.easeInOut,
    this.alignment = Alignment.center,
    this.duration = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  _PageTransitionState createState() => _PageTransitionState();
}

enum PageTransitionType {
  fade,
  scale,
  slide,
}

class _PageTransitionState extends State<PageTransition> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.type) {
      case PageTransitionType.fade:
        return FadeTransition(opacity: _animation, child: widget.child);
      case PageTransitionType.scale:
        return ScaleTransition(
          scale: _animation,
          alignment: widget.alignment,
          child: widget.child,
        );
      case PageTransitionType.slide:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(_animation),
          child: widget.child,
        );
      default:
        return FadeTransition(opacity: _animation, child: widget.child);
    }
  }
}