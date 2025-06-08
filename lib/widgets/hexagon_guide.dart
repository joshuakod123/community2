// lib/widgets/hexagon_guide.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HexagonGuide {
  static const String _hexagonGuideKey = 'hexagon_guide_shown';

  /// Shows the hexagon usage guide if it hasn't been shown before
  static Future<void> showIfNeeded(BuildContext context, GlobalKey hexagonKey) async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyShown = prefs.getBool(_hexagonGuideKey) ?? false;

    if (alreadyShown) return;

    // Mark as shown for next time
    await prefs.setBool(_hexagonGuideKey, true);

    // Get the position of the hexagon widget
    if (!context.mounted || hexagonKey.currentContext == null) return;

    final RenderBox renderBox = hexagonKey.currentContext!.findRenderObject() as RenderBox;
    final Size size = renderBox.size;
    final Offset position = renderBox.localToGlobal(Offset.zero);

    if (context.mounted) {
      // Show the guide overlay
      showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.7),
        builder: (BuildContext context) {
          return _HexagonGuideOverlay(
            hexagonPosition: position,
            hexagonSize: size,
          );
        },
      );
    }
  }
}

class _HexagonGuideOverlay extends StatelessWidget {
  final Offset hexagonPosition;
  final Size hexagonSize;

  const _HexagonGuideOverlay({
    required this.hexagonPosition,
    required this.hexagonSize,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isInUpperHalf = hexagonPosition.dy < screenSize.height / 2;

    // Calculate tooltip position
    final tooltipTop = isInUpperHalf
        ? hexagonPosition.dy + hexagonSize.height + 10
        : null;
    final tooltipBottom = !isInUpperHalf
        ? screenSize.height - hexagonPosition.dy + 10
        : null;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Highlight the hexagon
          CustomPaint(
            size: screenSize,
            painter: _HexagonHighlightPainter(
              hexagonPosition: hexagonPosition,
              hexagonSize: hexagonSize,
            ),
          ),

          // Tooltip for explaining hexagon
          Positioned(
            left: 20,
            right: 20,
            top: tooltipTop,
            bottom: tooltipBottom,
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
                    'Interactive Hexagons',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF536878), // Payne's Grey
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tap on hexagons to navigate to different sections of the app. Each hexagon represents a different step in your academic journey.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
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
            ),
          ),

          // Animated arrow pointing to the hexagon
          Positioned(
            left: hexagonPosition.dx + hexagonSize.width / 2 - 15,
            top: isInUpperHalf
                ? hexagonPosition.dy + hexagonSize.height
                : hexagonPosition.dy - 30,
            child: _AnimatedArrow(pointUp: !isInUpperHalf),
          ),
        ],
      ),
    );
  }
}

class _AnimatedArrow extends StatefulWidget {
  final bool pointUp;

  const _AnimatedArrow({required this.pointUp});

  @override
  _AnimatedArrowState createState() => _AnimatedArrowState();
}

class _AnimatedArrowState extends State<_AnimatedArrow> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 10).animate(
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
        return Transform.translate(
          offset: Offset(0, widget.pointUp ? -_animation.value : _animation.value),
          child: Icon(
            widget.pointUp ? Icons.arrow_upward : Icons.arrow_downward,
            color: Colors.white,
            size: 30,
          ),
        );
      },
    );
  }
}

class _HexagonHighlightPainter extends CustomPainter {
  final Offset hexagonPosition;
  final Size hexagonSize;

  _HexagonHighlightPainter({
    required this.hexagonPosition,
    required this.hexagonSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // Draw a full-screen rectangle
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Draw a hexagon path
    final Path hexagonPath = _getHexagonPath(
      hexagonPosition.dx,
      hexagonPosition.dy,
      hexagonSize.width,
      hexagonSize.height,
    );

    // Cut out the hexagon area
    canvas.drawPath(
      hexagonPath,
      Paint()..blendMode = BlendMode.clear,
    );

    // Add a glow around the hexagon
    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(hexagonPath, glowPaint);
  }

  Path _getHexagonPath(double x, double y, double width, double height) {
    final double a = width / 2;
    final double b = height / 4;

    return Path()
      ..moveTo(x + a, y)
      ..lineTo(x + width, y + b)
      ..lineTo(x + width, y + height - b)
      ..lineTo(x + a, y + height)
      ..lineTo(x, y + height - b)
      ..lineTo(x, y + b)
      ..close();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}