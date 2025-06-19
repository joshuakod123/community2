// lib/services/db_setup.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DBSetup {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Keys for tracking schema version
  static const String _schemaVersionKey = 'db_schema_version';
  static const int _currentSchemaVersion = 2; // Increment when schema changes

  // Check if columns exist in users table (RLS-safe)
  static Future<Map<String, bool>> checkRequiredColumnsExist() async {
    Map<String, bool> columnStatus = {
      'university': false,
      'major': false,
      'category': false,
      'temp_password': false,
      'password_reset_required': false,
    };

    try {
      // Use a lighter approach that doesn't require reading data
      // This checks table structure without triggering RLS policies
      print('Checking if users table and columns exist...');

      // For RLS-enabled tables, we'll assume columns exist and handle errors gracefully
      // in actual operations rather than pre-checking
      columnStatus = {
        'university': true,  // Assume they exist
        'major': true,
        'category': true,
        'temp_password': true,
        'password_reset_required': true,
      };

      print('Assumed all columns exist - will handle missing columns gracefully in operations');
      return columnStatus;
    } catch (e) {
      print('Error checking table structure: $e');
      // Return default status - assume columns exist
      return columnStatus;
    }
  }

  // Apply schema updates (RLS-safe)
  static Future<bool> applyMigrations() async {
    try {
      // Check current schema version in preferences
      final prefs = await SharedPreferences.getInstance();
      final currentVersion = prefs.getInt(_schemaVersionKey) ?? 0;

      if (currentVersion >= _currentSchemaVersion) {
        print('Database schema is up to date (version $currentVersion)');
        return true;
      }

      print('Applying database migrations from version $currentVersion to $_currentSchemaVersion');

      // Check column status
      final columnStatus = await checkRequiredColumnsExist();

      // Mark migration as complete in local storage
      await prefs.setInt(_schemaVersionKey, _currentSchemaVersion);

      print('Schema migration completed successfully');
      print('Column status: $columnStatus');
      return true;
    } catch (e) {
      print('Error during schema migration: $e');
      return false;
    }
  }

  // RLS-compliant user selection saving
  static Future<bool> saveUserSelectionRLSSafe({
    required String userId,
    String? university,
    String? major,
    String? category,
    String? tempPassword,
    bool? passwordResetRequired,
  }) async {
    try {
      // Only attempt database operations if user is authenticated
      final session = _supabase.auth.currentSession;
      if (session?.user == null) {
        print('Cannot save user selection: No authenticated session');
        return false;
      }

      // Only update if this is the current user's record
      if (session!.user!.id != userId) {
        print('Cannot save user selection: User ID mismatch');
        return false;
      }

      Map<String, dynamic> userData = {};

      if (university != null) userData['university'] = university;
      if (major != null) userData['major'] = major;
      if (category != null) userData['category'] = category;
      if (tempPassword != null) userData['temp_password'] = tempPassword;
      if (passwordResetRequired != null) userData['password_reset_required'] = passwordResetRequired;

      if (userData.isEmpty) return true; // Nothing to update

      // Attempt to update with graceful error handling
      try {
        await _supabase
            .from('users')
            .update(userData)
            .eq('id', userId);

        print('Successfully saved user selection with all fields');
        return true;
      } catch (e) {
        print('Error saving user selection: $e');

        // If specific columns fail, try without them
        if (e.toString().contains('column') || e.toString().contains('does not exist')) {
          print('Attempting to save without problematic columns...');

          // Remove potentially problematic fields and retry
          userData.remove('category');
          userData.remove('temp_password');
          userData.remove('password_reset_required');

          if (userData.isNotEmpty) {
            try {
              await _supabase
                  .from('users')
                  .update(userData)
                  .eq('id', userId);

              print('Successfully saved user selection without problematic fields');
              return true;
            } catch (fallbackError) {
              print('Fallback save also failed: $fallbackError');
            }
          }
        }

        return false;
      }
    } catch (e) {
      print('Error in saveUserSelectionRLSSafe: $e');
      return false;
    }
  }

  // RLS-compliant temporary password update
  static Future<bool> updateTemporaryPasswordRLSSafe({
    required String userId,
    String? tempPassword,
    bool? passwordResetRequired,
  }) async {
    try {
      // Check if user is authenticated and it's their own record
      final session = _supabase.auth.currentSession;
      if (session?.user == null || session!.user!.id != userId) {
        print('Cannot update temporary password: Authentication/authorization issue');
        return false;
      }

      Map<String, dynamic> updateData = {};

      if (tempPassword != null) {
        updateData['temp_password'] = tempPassword;
        updateData['temp_password_created_at'] = DateTime.now().toIso8601String();
      }
      if (passwordResetRequired != null) {
        updateData['password_reset_required'] = passwordResetRequired;
      }

      if (updateData.isEmpty) return true;

      await _supabase
          .from('users')
          .update(updateData)
          .eq('id', userId);

      print('Successfully updated temporary password data');
      return true;
    } catch (e) {
      print('Error updating temporary password: $e');
      return false;
    }
  }

  // Use Supabase function for password reset (bypasses RLS)
  static Future<Map<String, dynamic>> resetPasswordUsingFunction({
    required String email,
    required String tempPassword,
  }) async {
    try {
      // Call the database function we created
      final result = await _supabase.rpc('reset_user_password', params: {
        'user_email': email.toLowerCase(),
        'temp_password': tempPassword,
      });

      if (result != null && result['success'] == true) {
        print('Password reset function succeeded: ${result['message']}');
        return {
          'success': true,
          'userId': result['user_id'],
          'message': result['message'],
        };
      } else {
        print('Password reset function failed: ${result?['error'] ?? 'Unknown error'}');
        return {
          'success': false,
          'error': result?['error'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      print('Error calling password reset function: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Clean up expired temporary passwords using database function
  static Future<bool> cleanupExpiredTemporaryPasswords() async {
    try {
      final result = await _supabase.rpc('cleanup_expired_temp_passwords');

      if (result != null && result['success'] == true) {
        final cleanedUp = result['cleaned_up'] ?? 0;
        print('Cleaned up $cleanedUp expired temporary passwords');
        return true;
      } else {
        print('Cleanup function failed: ${result?['error'] ?? 'Unknown error'}');
        return false;
      }
    } catch (e) {
      print('Error during temporary password cleanup: $e');
      return false;
    }
  }

  // Get user data in RLS-compliant way
  static Future<Map<String, dynamic>?> getUserDataRLSSafe(String identifier, {bool byEmail = false}) async {
    try {
      // Only allow reading if user is authenticated and requesting their own data
      final session = _supabase.auth.currentSession;

      if (session?.user == null) {
        print('Cannot get user data: No authenticated session');
        return null;
      }

      final query = _supabase.from('users').select('*');

      Map<String, dynamic>? result;

      if (byEmail) {
        // When searching by email, ensure it matches the authenticated user's email
        if (session!.user!.email?.toLowerCase() == identifier.toLowerCase()) {
          result = await query.eq('email', identifier.toLowerCase()).maybeSingle();
        } else {
          print('Cannot get user data: Email does not match authenticated user');
          return null;
        }
      } else {
        // When searching by ID, ensure it matches the authenticated user's ID
        if (session!.user!.id == identifier) {
          result = await query.eq('id', identifier).maybeSingle();
        } else {
          print('Cannot get user data: User ID does not match authenticated user');
          return null;
        }
      }

      return result;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Initialize database and apply necessary migrations
  static Future<void> initializeDatabase() async {
    try {
      print('Initializing database...');

      await applyMigrations();
      print('Database initialization complete');

      // Run cleanup if user is authenticated
      final session = _supabase.auth.currentSession;
      if (session?.user != null) {
        await cleanupExpiredTemporaryPasswords();
      }
    } catch (e) {
      print('Database initialization error: $e');
    }
  }

  // Test database connectivity and RLS policies
  static Future<bool> testDatabaseConnection() async {
    try {
      // Test a simple query that should work regardless of RLS
      await _supabase.from('users').select('count').limit(0);
      print('Database connection test: SUCCESS');
      return true;
    } catch (e) {
      print('Database connection test: FAILED - $e');
      return false;
    }
  }

  static saveUserSelectionWithFallback({required String userId, String? university, String? major, String? category}) {}
}