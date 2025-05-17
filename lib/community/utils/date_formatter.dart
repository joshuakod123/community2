// lib/community/utils/date_formatter.dart
import 'package:intl/intl.dart';

class DateFormatter {
  // Format date to relative time (e.g., "Just now", "2 hours ago", "Yesterday")
  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return DateFormat('MMM d, yyyy').format(dateTime);
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return DateFormat('MMM d').format(dateTime);
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  // Format date for post details (e.g., "March 15, 2023 at 2:30 PM")
  static String getDetailDateTime(DateTime dateTime) {
    return DateFormat('MMMM d, yyyy \'at\' h:mm a').format(dateTime);
  }

  // Format date for expiration (e.g., "Expires in 3 days")
  static String getExpirationText(DateTime expirationDate) {
    final now = DateTime.now();
    final difference = expirationDate.difference(now);

    if (difference.isNegative) {
      return 'Expired';
    } else if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Expires in ${difference.inMinutes} minutes';
      }
      return 'Expires in ${difference.inHours} hours';
    } else if (difference.inDays == 1) {
      return 'Expires tomorrow';
    } else {
      return 'Expires in ${difference.inDays} days';
    }
  }

  // Get color for expiration text (to indicate urgency)
  static int getExpirationColor(DateTime expirationDate) {
    final now = DateTime.now();
    final difference = expirationDate.difference(now);

    if (difference.isNegative) {
      return 0xFF9E9E9E; // Gray for expired
    } else if (difference.inDays == 0) {
      return 0xFFE53935; // Red for same day
    } else if (difference.inDays <= 2) {
      return 0xFFFF9800; // Orange for 1-2 days
    } else {
      return 0xFF4CAF50; // Green for 3+ days
    }
  }
}