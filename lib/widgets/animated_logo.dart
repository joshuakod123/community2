// lib/widgets/animated_logo.dart
import 'package:flutter/material.dart';

class AnimatedLogo extends StatefulWidget {
  final double size;
  final Duration duration;
  final String logoPath;

  const AnimatedLogo({
    Key? key,
    this.size = 100.0,
    this.duration = const Duration(milliseconds: 2000),
    required this.logoPath,
  }) : super(key: key);

  @override
  _AnimatedLogoState createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo> with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _loopController;
  late Animation<double> _entryAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    // Initial entry animation controller
    _entryController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Continuous subtle animation controller
    _loopController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Entry animation with bounce effect
    _entryAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.elasticOut,
    );

    // Continuous floating effect
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50.0,
      ),
    ]).animate(_loopController);

    // Opacity pulsing for subtle glow effect
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.85)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.85, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50.0,
      ),
    ]).animate(_loopController);

    // Start initial animation
    _entryController.forward();

    // Start continuous loop animation after entry is complete
    _entryController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _loopController.repeat();
      }
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _loopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_entryController, _loopController]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 4 * _bounceAnimation.value),
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: 0.4 + (0.6 * _entryAnimation.value),
              child: child,
            ),
          ),
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3 * _opacityAnimation.value),
              blurRadius: 20 * _opacityAnimation.value,
              spreadRadius: 2 * _opacityAnimation.value,
            ),
          ],
        ),
        child: Image.asset(
          widget.logoPath,
          width: widget.size,
          height: widget.size,
        ),
      ),
    );
  }
}