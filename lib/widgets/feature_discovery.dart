// lib/widgets/feature_discovery.dart (continued)
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A feature discovery widget that highlights a specific UI element
/// and shows a tooltip explaining its function
class FeatureDiscovery extends StatefulWidget {
  final Widget child;
  final String featureId;
  final String title;
  final String description;
  final IconData? icon;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onComplete;
  final bool isCircular;
  final AlignmentGeometry contentAlignment;

  const FeatureDiscovery({
    Key? key,
    required this.child,
    required this.featureId,
    required this.title,
    required this.description,
    this.icon,
    this.backgroundColor = const Color(0xFF6DEEC7), // Aquamarine
    this.textColor = Colors.black87,
    this.onComplete,
    this.isCircular = false,
    this.contentAlignment = Alignment.bottomCenter,
  }) : super(key: key);

  /// Show the feature discovery if it hasn't been shown before
  static Future<bool> showIfNeeded({
    required BuildContext context,
    required String featureId,
    required OverlayState overlay,
    required GlobalKey targetKey,
    required String title,
    required String description,
    IconData? icon,
    Color backgroundColor = const Color(0xFF6DEEC7),
    Color textColor = Colors.black87,
    VoidCallback? onComplete,
    bool isCircular = false,
    AlignmentGeometry contentAlignment = Alignment.bottomCenter,
  }) async {
    // Check if feature has been shown before
    final prefs = await SharedPreferences.getInstance();
    final alreadyShown = prefs.getBool('feature_$featureId') ?? false;

    if (alreadyShown) return false;

    // Mark as shown for next time
    await prefs.setBool('feature_$featureId', true);

    if (!context.mounted) return false;

    // Get position and size of target widget
    final RenderBox? renderBox = targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return false;

    final targetPosition = renderBox.localToGlobal(Offset.zero);
    final targetSize = renderBox.size;

    // Show overlay
    final OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => _FeatureDiscoveryOverlay(
        targetPosition: targetPosition,
        targetSize: targetSize,
        title: title,
        description: description,
        icon: icon,
        backgroundColor: backgroundColor,
        textColor: textColor,
        onTap: () {
          // Remove overlay
          overlayEntry.remove();
          if (onComplete != null) {
            onComplete();
          }
        },
        isCircular: isCircular,
        contentAlignment: contentAlignment,
      ),
    );

    overlay.insert(overlayEntry);
    return true;
  }

  @override
  _FeatureDiscoveryState createState() => _FeatureDiscoveryState();
}

class _FeatureDiscoveryState extends State<FeatureDiscovery> {
  GlobalKey targetKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Check if needs to be shown after first build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _checkAndShow();
    });
  }

  Future<void> _checkAndShow() async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final alreadyShown = prefs.getBool('feature_${widget.featureId}') ?? false;

    if (alreadyShown) return;

    // Mark as shown for next time
    await prefs.setBool('feature_${widget.featureId}', true);

    if (!mounted) return;

    final overlay = Overlay.of(context);
    if (overlay == null) return;

    FeatureDiscovery.showIfNeeded(
      context: context,
      featureId: widget.featureId,
      overlay: overlay,
      targetKey: targetKey,
      title: widget.title,
      description: widget.description,
      icon: widget.icon,
      backgroundColor: widget.backgroundColor,
      textColor: widget.textColor,
      onComplete: widget.onComplete,
      isCircular: widget.isCircular,
      contentAlignment: widget.contentAlignment,
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: targetKey,
      child: widget.child,
    );
  }
}

class _FeatureDiscoveryOverlay extends StatefulWidget {
  final Offset targetPosition;
  final Size targetSize;
  final String title;
  final String description;
  final IconData? icon;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;
  final bool isCircular;
  final AlignmentGeometry contentAlignment;

  const _FeatureDiscoveryOverlay({
    required this.targetPosition,
    required this.targetSize,
    required this.title,
    required this.description,
    this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
    required this.isCircular,
    required this.contentAlignment,
  });

  @override
  _FeatureDiscoveryOverlayState createState() => _FeatureDiscoveryOverlayState();
}

class _FeatureDiscoveryOverlayState extends State<_FeatureDiscoveryOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Start animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // Calculate tooltip position based on contentAlignment
    double tooltipTop;
    double tooltipLeft;
    double tooltipWidth = 280;

    // Position the tooltip based on alignment
    if (widget.contentAlignment == Alignment.bottomCenter) {
      tooltipTop = widget.targetPosition.dy + widget.targetSize.height + 20;
      tooltipLeft = (screenSize.width - tooltipWidth) / 2;
    } else if (widget.contentAlignment == Alignment.topCenter) {
      tooltipTop = widget.targetPosition.dy - 150;
      tooltipLeft = (screenSize.width - tooltipWidth) / 2;
    } else if (widget.contentAlignment == Alignment.centerLeft) {
      tooltipTop = widget.targetPosition.dy + (widget.targetSize.height / 2) - 75;
      tooltipLeft = widget.targetPosition.dx - tooltipWidth - 20;
    } else if (widget.contentAlignment == Alignment.centerRight) {
      tooltipTop = widget.targetPosition.dy + (widget.targetSize.height / 2) - 75;
      tooltipLeft = widget.targetPosition.dx + widget.targetSize.width + 20;
    } else {
      tooltipTop = widget.targetPosition.dy + widget.targetSize.height + 20;
      tooltipLeft = (screenSize.width - tooltipWidth) / 2;
    }

    // Ensure tooltip is within screen bounds
    if (tooltipLeft < 20) tooltipLeft = 20;
    if (tooltipLeft + tooltipWidth > screenSize.width - 20) {
      tooltipLeft = screenSize.width - tooltipWidth - 20;
    }

    if (tooltipTop < 100) tooltipTop = 100;
    if (tooltipTop > screenSize.height - 200) tooltipTop = screenSize.height - 200;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: screenSize.width,
        height: screenSize.height,
        color: Colors.black.withOpacity(0.7),
        child: Stack(
          children: [
            // Target widget highlight
            CustomPaint(
              size: screenSize,
              painter: _HighlightPainter(
                targetPosition: widget.targetPosition,
                targetSize: widget.targetSize,
                isCircular: widget.isCircular,
                animation: _scaleAnimation,
              ),
            ),

            // Tooltip
            AnimatedBuilder(
              animation: _opacityAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: child,
                );
              },
              child: Positioned(
                top: tooltipTop,
                left: tooltipLeft,
                width: tooltipWidth,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: widget.backgroundColor,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (widget.icon != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Icon(
                                  widget.icon,
                                  color: widget.textColor,
                                  size: 24,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                widget.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: widget.textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: widget.textColor.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            "Tap anywhere to dismiss",
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: widget.textColor.withOpacity(0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightPainter extends CustomPainter {
  final Offset targetPosition;
  final Size targetSize;
  final bool isCircular;
  final Animation<double> animation;

  _HighlightPainter({
    required this.targetPosition,
    required this.targetSize,
    required this.isCircular,
    required this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint cutoutPaint = Paint()..blendMode = BlendMode.clear;

    // Draw a target highlighting shape
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.2 * animation.value)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    if (isCircular) {
      // For circular targets
      final center = Offset(
        targetPosition.dx + targetSize.width / 2,
        targetPosition.dy + targetSize.height / 2,
      );
      final radius = Math.max(targetSize.width, targetSize.height) / 2;

      // Cut out the target
      canvas.drawCircle(center, radius, cutoutPaint);

      // Draw highlight ring(s)
      canvas.drawCircle(center, radius * (1 + 0.2 * animation.value), highlightPaint);
      canvas.drawCircle(center, radius * (1 + 0.4 * animation.value), highlightPaint..color = Colors.white.withOpacity(0.1 * animation.value));
    } else {
      // For rectangular targets
      final rect = Rect.fromLTWH(
        targetPosition.dx,
        targetPosition.dy,
        targetSize.width,
        targetSize.height,
      );
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

      // Cut out the target
      canvas.drawRRect(rrect, cutoutPaint);

      // Draw highlight
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.inflate(4 * animation.value),
          const Radius.circular(12),
        ),
        highlightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HighlightPainter oldDelegate) {
    return oldDelegate.animation.value != animation.value;
  }
}