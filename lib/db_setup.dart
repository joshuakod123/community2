// lib/services/db_setup.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class DBSetup {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Setup premium-related database structure
  static Future<void> setupPremiumTables() async {
    try {
      // Attempt to add premium columns to users table
      try {
        // Check if premium_until column exists
        await _supabase.rpc('check_column_exists', params: {
          'table_name': 'users',
          'column_name': 'premium_until'
        });
      } catch (e) {
        // Column doesn't exist, add it
        if (e.toString().contains('does not exist') ||
            e.toString().contains('function') ||
            e.toString().contains('not found')) {
          print('Setting up premium_until column...');
          try {
            // Use RPC call if available
            await _supabase.rpc('add_column_if_not_exists', params: {
              'table_name': 'users',
              'column_name': 'premium_until',
              'column_type': 'timestamptz'
            });
          } catch (e2) {
            print('Error creating premium_until column: $e2');
            // RPC function might not exist, that's ok
          }
        }
      }

      // Add is_premium column if needed
      try {
        await _supabase.rpc('check_column_exists', params: {
          'table_name': 'users',
          'column_name': 'is_premium'
        });
      } catch (e) {
        if (e.toString().contains('does not exist') ||
            e.toString().contains('function') ||
            e.toString().contains('not found')) {
          print('Setting up is_premium column...');
          try {
            await _supabase.rpc('add_column_if_not_exists', params: {
              'table_name': 'users',
              'column_name': 'is_premium',
              'column_type': 'boolean'
            });
          } catch (e2) {
            print('Error creating is_premium column: $e2');
            // RPC function might not exist, that's ok
          }
        }
      }

      // Verify payment_transactions table exists
      try {
        await _supabase.from('payment_transactions').select('count').limit(1);
      } catch (e) {
        print('Payment transactions table not found or error: $e');
        // Table doesn't exist, we can't create it from client side
        // This would need to be done manually in the Supabase dashboard
      }

    } catch (e) {
      print('Error running database setup: $e');
    }
  }

  // You can call this function from your app initialization
  static Future<void> initializeDatabase() async {
    await setupPremiumTables();
  }
}