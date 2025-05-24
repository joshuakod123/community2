// lib/services/db_setup.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DBSetup {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Keys for tracking schema version
  static const String _schemaVersionKey = 'db_schema_version';
  static const int _currentSchemaVersion = 2; // Increment when schema changes

  // Check if columns exist in users table
  static Future<Map<String, bool>> checkRequiredColumnsExist() async {
    Map<String, bool> columnStatus = {
      'university': false,
      'major': false,
      'category': false,
      'temp_password': false,
      'password_reset_required': false,
    };

    try {
      // Try to query all potential columns from users table
      final response = await _supabase
          .from('users')
          .select('id')
          .limit(1);

      // If we got here, the table exists
      print('Users table exists');

      // Now check each column individually with separate try-catch blocks
      try {
        await _supabase
            .from('users')
            .select('university')
            .limit(1);
        columnStatus['university'] = true;
        print('university column exists');
      } catch (e) {
        print('university column does not exist: $e');
      }

      try {
        await _supabase
            .from('users')
            .select('major')
            .limit(1);
        columnStatus['major'] = true;
        print('major column exists');
      } catch (e) {
        print('major column does not exist: $e');
      }

      try {
        await _supabase
            .from('users')
            .select('category')
            .limit(1);
        columnStatus['category'] = true;
        print('category column exists');
      } catch (e) {
        print('category column does not exist: $e');
      }

      try {
        await _supabase
            .from('users')
            .select('temp_password')
            .limit(1);
        columnStatus['temp_password'] = true;
        print('temp_password column exists');
      } catch (e) {
        print('temp_password column does not exist: $e');
      }

      try {
        await _supabase
            .from('users')
            .select('password_reset_required')
            .limit(1);
        columnStatus['password_reset_required'] = true;
        print('password_reset_required column exists');
      } catch (e) {
        print('password_reset_required column does not exist: $e');
      }

      return columnStatus;
    } catch (e) {
      print('Error checking table or columns: $e');
      return columnStatus;
    }
  }

  // Apply schema updates to ensure the client handles missing columns properly
  static Future<bool> applyMigrations() async {
    try {
      // Check current schema version in preferences
      final prefs = await SharedPreferences.getInstance();
      final currentVersion = prefs.getInt(_schemaVersionKey) ?? 0;

      // If already at current version, skip
      if (currentVersion >= _currentSchemaVersion) {
        print('Schema already at latest version: $_currentSchemaVersion');
        return true;
      }

      print('Applying schema migration from version $currentVersion to $_currentSchemaVersion');

      // Check what columns currently exist
      final columnStatus = await checkRequiredColumnsExist();

      // Update the user's schema version regardless of migration success
      // This prevents repeated attempts at migration that might fail due to permissions
      await prefs.setInt(_schemaVersionKey, _currentSchemaVersion);

      print('Schema check complete. Column status: $columnStatus');
      return true;
    } catch (e) {
      print('Error during schema migration: $e');
      return false;
    }
  }

  // Enhanced user selection saving with temp password support
  static Future<bool> saveUserSelectionWithFallback({
    required String userId,
    String? university,
    String? major,
    String? category,
    String? tempPassword,
    bool? passwordResetRequired,
  }) async {
    try {
      // First try with all fields including category and temp password fields
      Map<String, dynamic> userData = {};

      if (university != null) userData['university'] = university;
      if (major != null) userData['major'] = major;
      if (category != null) userData['category'] = category;
      if (tempPassword != null) userData['temp_password'] = tempPassword;
      if (passwordResetRequired != null) userData['password_reset_required'] = passwordResetRequired;

      if (userData.isEmpty) return true; // Nothing to update

      // First attempt with all fields
      try {
        await _supabase
            .from('users')
            .update(userData)
            .eq('id', userId);

        print('Successfully saved user selection with all fields');
        return true;
      } catch (e) {
        print('Error saving with all fields: $e');

        // If fails, try removing problematic fields one by one
        final problematicFields = ['category', 'temp_password', 'password_reset_required'];

        for (String field in problematicFields) {
          if (e.toString().contains(field)) {
            userData.remove(field);
            print('Removed problematic field: $field');
          }
        }

        if (userData.isEmpty) return false; // Nothing left to update

        try {
          await _supabase
              .from('users')
              .update(userData)
              .eq('id', userId);

          print('Successfully saved user selection without problematic fields');
          return true;
        } catch (fallbackError) {
          print('Error saving without problematic fields: $fallbackError');
          return false;
        }
      }
    } catch (e) {
      print('Error in saveUserSelectionWithFallback: $e');
      return false;
    }
  }

  // New method specifically for temporary password operations
  static Future<bool> updateTemporaryPassword({
    required String userId,
    String? tempPassword,
    bool? passwordResetRequired,
  }) async {
    try {
      Map<String, dynamic> updateData = {};

      if (tempPassword != null) {
        updateData['temp_password'] = tempPassword;
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

  // Method to clean up temporary passwords (can be called periodically)
  static Future<bool> cleanupExpiredTemporaryPasswords() async {
    try {
      // This would require a database function or RLS policy to work properly
      // For now, we'll just log that cleanup was attempted
      print('Temporary password cleanup attempted');
      return true;
    } catch (e) {
      print('Error during temporary password cleanup: $e');
      return false;
    }
  }

  // Initialize database and apply necessary migrations
  static Future<void> initializeDatabase() async {
    try {
      await applyMigrations();
      print('Database initialization complete');

      // Optionally run cleanup on app start
      await cleanupExpiredTemporaryPasswords();
    } catch (e) {
      print('Database initialization error: $e');
    }
  }
}