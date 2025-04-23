import 'package:supabase_flutter/supabase_flutter.dart';

class DBSetup {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Check if premium columns exist in users table
  static Future<bool> checkPremiumColumnsExist() async {
    try {
      // Try to query using the premium columns
      await _supabase
          .from('users')
          .select('is_premium, premium_until')
          .limit(1);

      // If no error, columns exist
      print('Premium columns exist in users table');
      return true;
    } catch (e) {
      print('Premium columns may not exist: $e');
      return false;
    }
  }

  // Check if payment_transactions table exists
  static Future<bool> checkPaymentTableExists() async {
    try {
      // Try to query the table
      await _supabase
          .from('payment_transactions')
          .select('count')
          .limit(1);

      // If no error, table exists
      print('Payment transactions table exists');
      return true;
    } catch (e) {
      print('Payment transactions table may not exist: $e');
      return false;
    }
  }

  // Initialize database - only checks, doesn't create
  static Future<void> initializeDatabase() async {
    await checkPremiumColumnsExist();
    await checkPaymentTableExists();

    print('Database check complete. Please ensure required tables and columns exist.');
  }
}