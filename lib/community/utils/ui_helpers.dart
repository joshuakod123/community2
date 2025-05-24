// lib/community/utils/ui_helpers.dart
import 'package:flutter/material.dart';
import 'package:experiment3/services/notification_display_service.dart';

class UIHelpers {
  // Display a snackbar with a message
  static void showSnackBar(BuildContext context, String message, {
    bool isError = false,
    bool isSuccess = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    final Color backgroundColor = isError
        ? Colors.red
        : isSuccess
        ? Colors.green
        : Colors.grey.shade800;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Display a confirmation dialog
  static Future<bool> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: isDestructive
                ? TextButton.styleFrom(foregroundColor: Colors.red)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // Show a loading dialog
  static void showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hide the loading dialog
  static void hideLoadingDialog(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  // Generate a color from a string (for consistent user avatars)
  static Color getColorFromString(String str) {
    // Simple hash function
    int hash = 0;
    for (var i = 0; i < str.length; i++) {
      hash = str.codeUnitAt(i) + ((hash << 5) - hash);
    }

    // Convert to RGB
    final red = ((hash & 0xFF0000) >> 16);
    final green = ((hash & 0x00FF00) >> 8);
    final blue = (hash & 0x0000FF);

    // Return a more vivid color by ensuring at least one component is strong
    return Color.fromARGB(
      255,
      red.clamp(100, 255),
      green.clamp(100, 255),
      blue.clamp(100, 255),
    );
  }

  // Get a category color based on category name
  static Color getCategoryColor(String? category) {
    if (category == null) return Colors.grey;

    switch (category.toLowerCase()) {
      case 'announcement':
        return Colors.blue;
      case 'question':
        return Colors.orange;
      case 'general':
        return Colors.green;
      case 'suggestion':
        return Colors.purple;
      case 'event':
        return Colors.red;
      default:
        return Colors.teal;
    }
  }

  // Get a category icon based on category name
  static IconData getCategoryIcon(String? category) {
    if (category == null) return Icons.article;

    switch (category.toLowerCase()) {
      case 'announcement':
        return Icons.campaign;
      case 'question':
        return Icons.help;
      case 'general':
        return Icons.chat;
      case 'suggestion':
        return Icons.lightbulb;
      case 'event':
        return Icons.event;
      default:
        return Icons.article;
    }
  }
}