// lib/services/notification_display_service.dart
import 'package:flutter/material.dart';

class NotificationDisplayService {
  // Show a pop-up notification dialog
  static void showPopupNotification(
      BuildContext context, {
        required String title,
        String message = '',
        bool isSuccess = false,
        bool isError = false,
        Duration duration = const Duration(seconds: 3),
      }) {
    // Create an overlay entry with late keyword
    late OverlayEntry overlayEntry;

    // Determine background color based on notification type
    Color backgroundColor;
    IconData iconData;

    if (isSuccess) {
      backgroundColor = const Color(0xFF6DEEC7); // Aquamarine for success
      iconData = Icons.check_circle;
    } else if (isError) {
      backgroundColor = const Color(0xFFE38C96); // Rose for errors
      iconData = Icons.error_outline;
    } else {
      backgroundColor = const Color(0xFFAF95C6); // African Violet for info
      iconData = Icons.notifications_active;
    }

    // Initialize overlayEntry before using it
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 80.0, // Position from top (below status bar)
        left: 20.0,
        right: 20.0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(iconData, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (message.isNotEmpty)
                        Text(
                          message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
                  onPressed: () {
                    overlayEntry.remove();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Insert the overlay entry
    Overlay.of(context).insert(overlayEntry);

    // Remove after duration
    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}