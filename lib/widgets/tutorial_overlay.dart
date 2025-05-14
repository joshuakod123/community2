// lib/widgets/tutorial_overlay.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A comprehensive tutorial overlay system that can highlight multiple elements
/// in sequence with step-by-step instructions
class TutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  final String tutorialKey;
  final VoidCallback? onComplete;
  final bool showSkipButton;

  const TutorialOverlay({
    Key? key,
    required this.steps,
    required this.tutorialKey,
    this.onComplete,
    this.showSkipButton = true,
  }) : super(key: key);

  /// Show the tutorial if it hasn't been shown before
  static Future<void> showIfNeeded(
      BuildContext context, {
        required List<TutorialStep> steps,
        required String tutorialKey,
        VoidCallback? onComplete,
        bool showSkipButton = true,
      }) async {
    // Check if tutorial has been shown before
    final prefs = await SharedPreferences.getInstance();
    final alreadyShown = prefs.getBool(tutorialKey) ?? false;

    if (alreadyShown) return;

    // Mark as shown
    await prefs.setBool(tutorialKey, true);

    if (context.mounted) {
      // Show the tutorial overlay
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          barrierDismissible: false,
          pageBuilder: (BuildContext context, _, __) {
            return TutorialOverlay(
              steps: steps,
              tutorialKey: tutorialKey,
              onComplete: onComplete,
              showSkipButton: showSkipButton,
            );
          },
        ),
      );
    }
  }

  @override
  _TutorialOverlayState createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      // Move to next step with animation
      _animationController.reverse().then((_) {
        setState(() {
          _currentStep++;
        });
        _animationController.forward();
      });
    } else {
      // Complete the tutorial
      _completeTutorial();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      // Move to previous step with animation
      _animationController.reverse().then((_) {
        setState(() {
          _currentStep--;
        });
        _animationController.forward();
      });
    }
  }

  void _skipTutorial() {
    _completeTutorial();
  }

  void _completeTutorial() {
    Navigator.of(context).pop();
    if (widget.onComplete != null) {
      widget.onComplete!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_currentStep];
    final screenSize = MediaQuery.of(context).size;

    // Check if the target widget has a valid context and get its position
    RenderBox? renderBox;
    Offset targetPosition = Offset.zero;
    Size targetSize = Size.zero;

    if (step.targetKey.currentContext != null) {
      renderBox = step.targetKey.currentContext!.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        targetPosition = renderBox.localToGlobal(Offset.zero);
        targetSize = renderBox.size;
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Stack(
              children: [
                // Background overlay with hole
                CustomPaint(
                  size: screenSize,
                  painter: _TutorialPainter(
                    targetPosition: targetPosition,
                    targetSize: targetSize,
                    borderRadius: step.targetBorderRadius,
                    isCircular: step.isCircular,
                  ),
                ),

                // Tooltip content
                _buildTooltip(context, step, targetPosition, targetSize),

                // Navigation buttons
                _buildNavigationButtons(context),

                // Skip button
                if (widget.showSkipButton)
                  Positioned(
                    top: 40,
                    right: 20,
                    child: SafeArea(
                      child: ElevatedButton(
                        onPressed: _skipTutorial,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text('Skip Tutorial'),
                      ),
                    ),
                  ),

                // Progress indicator
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.steps.length,
                          (index) => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == _currentStep ? Colors.white : Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTooltip(
      BuildContext context, TutorialStep step, Offset targetPosition, Size targetSize) {
    // Determine tooltip position
    final screenSize = MediaQuery.of(context).size;
    final isInUpperHalf = targetPosition.dy < screenSize.height / 2;
    final tooltipWidth = screenSize.width * 0.8;

    double tooltipTop;
    if (isInUpperHalf) {
      tooltipTop = targetPosition.dy + targetSize.height + 20;
    } else {
      tooltipTop = targetPosition.dy - 150;
      if (tooltipTop < 100) tooltipTop = 100; // Ensure it's not too high
    }

    return Positioned(
      top: tooltipTop,
      left: (screenSize.width - tooltipWidth) / 2,
      width: tooltipWidth,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (step.icon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Icon(step.icon, color: const Color(0xFF536878), size: 24),
                  ),
                Expanded(
                  child: Text(
                    step.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF536878),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              step.description,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context) {
    final isFirstStep = _currentStep == 0;
    final isLastStep = _currentStep == widget.steps.length - 1;

    return Positioned(
      bottom: 50,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Back button (except for first step)
          if (!isFirstStep)
            ElevatedButton(
              onPressed: _previousStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Back'),
            ),

          const SizedBox(width: 20),

          // Next/Finish button
          ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF536878),
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(isLastStep ? 'Finish' : 'Next'),
          ),
        ],
      ),
    );
  }
}

class _TutorialPainter extends CustomPainter {
  final Offset targetPosition;
  final Size targetSize;
  final double borderRadius;
  final bool isCircular;

  _TutorialPainter({
    required this.targetPosition,
    required this.targetSize,
    this.borderRadius = 8.0,
    this.isCircular = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // Draw the full background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // Calculate the target rect
    final Rect targetRect = Rect.fromLTWH(
      targetPosition.dx,
      targetPosition.dy,
      targetSize.width,
      targetSize.height,
    );

    // Create a path to cut out (either rounded rect or circle)
    final Path cutoutPath = Path();
    if (isCircular) {
      // For circular targets (like buttons)
      final center = Offset(
        targetPosition.dx + targetSize.width / 2,
        targetPosition.dy + targetSize.height / 2,
      );
      final radius = Math.max(targetSize.width, targetSize.height) / 2;
      cutoutPath.addOval(Rect.fromCircle(center: center, radius: radius));
    } else {
      // For rectangular targets
      cutoutPath.addRRect(
        RRect.fromRectAndRadius(
          targetRect,
          Radius.circular(borderRadius),
        ),
      );
    }

    // Cut out the target area
    canvas.drawPath(
      cutoutPath,
      Paint()..blendMode = BlendMode.clear,
    );

    // Add a glow effect around the target
    final Paint glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    if (isCircular) {
      final center = Offset(
        targetPosition.dx + targetSize.width / 2,
        targetPosition.dy + targetSize.height / 2,
      );
      final radius = Math.max(targetSize.width, targetSize.height) / 2;
      canvas.drawCircle(center, radius + 2, glowPaint);
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          targetRect.inflate(2),
          Radius.circular(borderRadius + 2),
        ),
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Class representing a single step in the tutorial
class TutorialStep {
  final GlobalKey targetKey;
  final String title;
  final String description;
  final IconData? icon;
  final double targetBorderRadius;
  final bool isCircular;

  TutorialStep({
    required this.targetKey,
    required this.title,
    required this.description,
    this.icon,
    this.targetBorderRadius = 8.0,
    this.isCircular = false,
  });
}