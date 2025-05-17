// lib/services/error_handling_service.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ErrorHandlingService {
  // Singleton pattern
  static final ErrorHandlingService _instance = ErrorHandlingService._internal();
  factory ErrorHandlingService() => _instance;
  ErrorHandlingService._internal();

  // Handle Supabase database errors with better context
  String handleDatabaseError(dynamic error) {
    if (error is PostgrestException) {
      // Check for common PostgrestExceptions
      switch (error.code) {
        case '42703': // Column does not exist
          return 'Database error: There seems to be a missing field in our database. We\'re working on fixing this.';
        case 'PGRST204': // Column not in cache - specifically for the category issue
          return 'Database error: The category field is missing. Your selection will be saved without it.';
        case '42P01': // Table does not exist
          return 'Database error: A required table is missing. Our team has been notified.';
        case '23505': // Unique violation
          return 'This record already exists. Please try with different information.';
        case '22P02': // Invalid input syntax
          final message = error.message ?? '';
          if (message.contains('json')) {
            return 'Invalid data format. Please check your inputs.';
          }
          return 'Invalid input format. Please try again.';
        case '23503': // Foreign key violation
          return 'The referenced information doesn\'t exist. Please select a different option.';
        case '42501': // Insufficient privilege
          return 'You don\'t have permission to perform this operation.';
        default:
          if (error.message != null) {
            return 'Database error: ${error.message}';
          }
          return 'An unexpected database error occurred: ${error.code}';
      }
    } else if (error is AuthException) {
      return 'Authentication error: ${error.message}';
    } else {
      // For other errors
      return error.toString();
    }
  }

  // Show error dialog with proper context
  Future<void> showErrorDialog(BuildContext context, dynamic error, {String? title, String? actionText}) async {
    final errorMessage = handleDatabaseError(error);

    await showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title ?? 'Error Occurred'),
        content: SingleChildScrollView(
          child: Text(errorMessage),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(actionText ?? 'OK'),
          ),
        ],
      ),
    );
  }

  // Show error snackbar with proper context
  void showErrorSnackBar(BuildContext context, dynamic error) {
    final errorMessage = handleDatabaseError(error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'DISMISS',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
          textColor: Colors.white,
        ),
      ),
    );
  }

  // Log error to console with better context
  void logError(dynamic error, {String? context}) {
    final String contextStr = context != null ? '[$context]' : '';

    if (error is PostgrestException) {
      print('$contextStr Database error: ${error.code} - ${error.message}');
      if (error.details != null) {
        print('$contextStr Details: ${error.details}');
      }
      if (error.hint != null) {
        print('$contextStr Hint: ${error.hint}');
      }
    } else {
      print('$contextStr Error: ${error.toString()}');
    }
  }

  // Safe execution wrapper for database operations
  Future<T?> safeExecute<T>(
      Future<T> Function() operation, {
        Function(dynamic)? onError,
        T? defaultValue,
        String? context,
      }) async {
    try {
      return await operation();
    } catch (error) {
      logError(error, context: context);
      if (onError != null) {
        onError(error);
      }
      return defaultValue;
    }
  }
}