import 'package:flutter/material.dart';
import 'app_guide_manager.dart';

/// Guide that highlights specific UI elements with a spotlight effect
class FocusedElementGuide {
  /// Shows the guide if it hasn't been shown to this user before
  static Future<void> show(
      BuildContext context, {
        required Offset targetPosition,
        required Size targetSize,
        required String title,
        required String description,
        required String featureKey,
        bool isCircular = false,
      }) async {
    if (!context.mounted) return;

    // Show the guide
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _FocusedElementGuideContent(
        targetPosition: targetPosition,
        targetSize: targetSize,
        title: title,
        description: description,
        isCircular: isCircular,
        onDismiss: () {
          // No additional actions on dismiss
        },
        onTryNow: () {
          // Navigate or perform action based on featureKey
          _navigateToFeature(context, featureKey);
        },
      ),
    );

    // Mark as completed
    await AppGuideManager.markGuideCompleted('feature_guide_completed_$featureKey');
  }

  // Handle navigation based on the feature
  static void _navigateToFeature(BuildContext context, String featureKey) {
    // Implement navigation based on featureKey
    // For example:
    switch (featureKey) {
      case 'community_board':
      // Navigate to community board
      // Navigator.of(context).pushNamed('/community');
        break;
      case 'calendar':
      // Navigate to calendar
      // Navigator.of(context).pushNamed('/calendar');
        break;
      case 'scores':
      // Navigate to scores
      // Navigator.of(context).pushNamed('/scores');
        break;
      default:
      // No specific navigation
        break;
    }
  }
}

class _FocusedElementGuideContent extends StatefulWidget {
  final Offset targetPosition;
  final Size targetSize;
  final String title;
  final String description;
  final bool isCircular;
  final VoidCallback? onDismiss;
  final VoidCallback? onTryNow;

  const _FocusedElementGuideContent({
    required this.targetPosition,
    required this.targetSize,
    required this.title,
    required this.description,
    this.isCircular = false,
    this.onDismiss,
    this.onTryNow,
  });

  @override
  _FocusedElementGuideContentState createState() => _FocusedElementGuideContentState();
}

class _FocusedElementGuideContentState extends State<_FocusedElementGuideContent> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button from dismissing
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Stack(
            children: [
              // Semi-transparent background
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {}, // Prevent touches passing through
                  child: Container(
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),
              ),

              // Highlighted target element with pulse animation
              Positioned(
                left: widget.targetPosition.dx - 5,
                top: widget.targetPosition.dy - 5,
                child: Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: widget.targetSize.width + 10,
                    height: widget.targetSize.height + 10,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withOpacity(_fadeAnimation.value),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(
                        widget.isCircular ? 100 : 8,
                      ),
                      color: Colors.transparent,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(_fadeAnimation.value * 0.5),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Tooltip/instruction dialog
              Positioned(
                bottom: 100,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.description,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              if (widget.onDismiss != null) {
                                widget.onDismiss!();
                              }
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[600],
                            ),
                            child: const Text(
                              'Got it',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              if (widget.onTryNow != null) {
                                widget.onTryNow!();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF536878), // kPaynesGrey
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            child: const Text(
                              'Try it now',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}