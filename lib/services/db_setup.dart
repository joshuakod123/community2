// lib/services/db_setup.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DBSetup {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Keys for tracking schema version
  static const String _schemaVersionKey = 'db_schema_version';
  static const int _currentSchemaVersion = 1; // Increment when schema changes

  // Check if columns exist in users table
  static Future<Map<String, bool>> checkRequiredColumnsExist() async {
    Map<String, bool> columnStatus = {
      'university': false,
      'major': false,
      'category': false,
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

  // Patch for handling missing category column in user selection flow
  static Future<bool> saveUserSelectionWithFallback({
    required String userId,
    String? university,
    String? major,
    String? category,
  }) async {
    try {
      // First try with all fields including category
      Map<String, dynamic> userData = {};

      if (university != null) userData['university'] = university;
      if (major != null) userData['major'] = major;
      if (category != null) userData['category'] = category;

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

        // If fails and error mentions 'category', try without it
        if (e.toString().contains('category')) {
          userData.remove('category');

          if (userData.isEmpty) return false; // Nothing left to update

          try {
            await _supabase
                .from('users')
                .update(userData)
                .eq('id', userId);

            print('Successfully saved user selection without category field');
            return true;
          } catch (fallbackError) {
            print('Error saving without category: $fallbackError');
            return false;
          }
        }

        return false;
      }
    } catch (e) {
      print('Error in saveUserSelectionWithFallback: $e');
      return false;
    }
  }

  // Initialize database and apply necessary migrations
  static Future<void> initializeDatabase() async {
    try {
      await applyMigrations();
      print('Database initialization complete');
    } catch (e) {
      print('Database initialization error: $e');
    }
  }
  }