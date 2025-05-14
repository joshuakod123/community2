// lib/widgets/journey_section_guide.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JourneySectionGuide {
  static const String _journeyGuideKey = 'journey_section_guide_shown';

  /// Shows the user's journey section guide if it hasn't been shown before
  static Future<void> showIfNeeded(BuildContext context, GlobalKey journeySectionKey) async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyShown = prefs.getBool(_journeyGuideKey) ?? false;

    if (alreadyShown) return;

    // Mark as shown for next time
    await prefs.setBool(_journeyGuideKey, true);

    // Get the position of the journey section widget
    if (!context.mounted || journeySectionKey.currentContext == null) return;

    final RenderBox renderBox = journeySectionKey.currentContext!.findRenderObject() as RenderBox;
    final Size size = renderBox.size;
    final Offset position = renderBox.localToGlobal(Offset.zero);

    if (context.mounted) {
      // Show the guide overlay
      showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.7),
        builder: (BuildContext context) {
          return _JourneySectionGuideOverlay(
            sectionPosition: position,
            sectionSize: size,
          );
        },
      );
    }
  }
}

class _JourneySectionGuideOverlay extends StatelessWidget {
  final Offset sectionPosition;
  final Size sectionSize;

  const _JourneySectionGuideOverlay({
    required this.sectionPosition,
    required this.sectionSize,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // Calculate tooltip position - always below the journey section
    final tooltipTop = sectionPosition.dy + sectionSize.height + 20;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Highlight the journey section
          CustomPaint(
            size: screenSize,
            painter: _SectionHighlightPainter(
              sectionPosition: sectionPosition,
              sectionSize: sectionSize,
            ),
          ),

          // Tooltip for explaining the Journey section
          Positioned(
            left: 20,
            right: 20,
            top: tooltipTop,
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
                  const Text(
                    'Your Academic Journey',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF536878), // Payne's Grey
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'This purple section shows your target university and major. The percentage circle shows your estimated chance of acceptance based on your academic profile.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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

          // Animated pulse around the percentage
          Positioned(
            right: 20,
            top: sectionPosition.dy + 20,
            child: const _PulsingCircle(),
          ),
        ],
      ),
    );
  }
}

class _PulsingCircle extends StatefulWidget {
  const _PulsingCircle();

  @override
  _PulsingCircleState createState() => _PulsingCircleState();
}

class _PulsingCircleState extends State<_PulsingCircle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
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
        return CustomPaint(
          painter: _PulseCirclePainter(
            progress: _animation.value,
          ),
          child: Container(
            width: 100,
            height: 100,
          ),
        );
      },
    );
  }
}

class _PulseCirclePainter extends CustomPainter {
  final double progress;

  _PulseCirclePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white.withOpacity(1.0 - progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) * (0.8 + (0.2 * progress));

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _SectionHighlightPainter extends CustomPainter {
  final Offset sectionPosition;
  final Size sectionSize;

  _SectionHighlightPainter({
    required this.sectionPosition,
    required this.sectionSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // Draw a full-screen rectangle
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Draw rounded rectangle for the section
    final RRect sectionRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        sectionPosition.dx,
        sectionPosition.dy,
        sectionSize.width,
        sectionSize.height,
      ),
      const Radius.circular(16), // Match the corner radius of your section
    );

    // Cut out the section area
    canvas.drawRRect(
      sectionRect,
      Paint()..blendMode = BlendMode.clear,
    );

    // Add a subtle glow around the section
    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          sectionPosition.dx - 2,
          sectionPosition.dy - 2,
          sectionSize.width + 4,
          sectionSize.height + 4,
        ),
        const Radius.circular(18),
      ),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}