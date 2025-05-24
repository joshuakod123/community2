// lib/widgets/focused_element_guide.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FocusedElementGuide {
  /// Shows the focused guide if it hasn't been shown before
  static Future<void> showIfNeeded(
      BuildContext context, {
        required Offset targetPosition,
        required Size targetSize,
        required String title,
        required String description,
        required String prefsKey,
        VoidCallback? onTryNow,
        VoidCallback? onSkip,
        bool isCircular = false, // Add this parameter
      }) async {
    // Check if the guide has been shown before
    final prefs = await SharedPreferences.getInstance();
    final bool alreadyShown = prefs.getBool(prefsKey) ?? false;

    // If already shown, don't show again
    if (alreadyShown) return;

    // Mark as shown even if user dismisses it by tapping outside
    await prefs.setBool(prefsKey, true);

    if (context.mounted) {
      // Show the overlay
      showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.7),
        builder: (BuildContext context) {
          return _FocusedGuideOverlay(
            targetPosition: targetPosition,
            targetSize: targetSize,
            title: title,
            description: description,
            onTryNow: onTryNow,
            onSkip: onSkip,
          );
        },
      );
    }
  }
}

class _FocusedGuideOverlay extends StatelessWidget {
  final Offset targetPosition;
  final Size targetSize;
  final String title;
  final String description;
  final VoidCallback? onTryNow;
  final VoidCallback? onSkip;

  const _FocusedGuideOverlay({
    required this.targetPosition,
    required this.targetSize,
    required this.title,
    required this.description,
    this.onTryNow,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTopHalf = targetPosition.dy < screenSize.height / 2;

    // Calculate the content position
    final contentPositionTop = isTopHalf
        ? targetPosition.dy + targetSize.height + 20 // Below the target
        : null;
    final contentPositionBottom = !isTopHalf
        ? screenSize.height - targetPosition.dy + 20 // Above the target
        : null;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Hole for the target element
          CustomPaint(
            size: screenSize,
            painter: _HighlightPainter(
              targetPosition: targetPosition,
              targetSize: targetSize,
            ),
          ),

          // Content panel
          Positioned(
            left: 20,
            right: 20,
            top: contentPositionTop,
            bottom: contentPositionBottom,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF536878), // Payne's Grey from your app
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (onSkip != null)
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onSkip!();
                          },
                          child: const Text(
                            'Skip',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      const SizedBox(width: 16),
                      if (onTryNow != null)
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onTryNow!();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF536878), // Payne's Grey
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Got it!'),
                        )
                      else
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF536878), // Payne's Grey
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Got it!'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightPainter extends CustomPainter {
  final Offset targetPosition;
  final Size targetSize;

  _HighlightPainter({
    required this.targetPosition,
    required this.targetSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // Draw a full-screen rectangle
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Calculate cutout area with rounded corners
    final targetRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        targetPosition.dx,
        targetPosition.dy,
        targetSize.width,
        targetSize.height,
      ),
      const Radius.circular(8), // Match the corner radius of your target element
    );

    // Cut out the target area
    canvas.drawRRect(
      targetRect,
      Paint()..blendMode = BlendMode.clear,
    );

    // Add a subtle glow around the target
    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          targetPosition.dx - 2,
          targetPosition.dy - 2,
          targetSize.width + 4,
          targetSize.height + 4,
        ),
        const Radius.circular(10),
      ),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}