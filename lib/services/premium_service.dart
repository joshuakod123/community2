import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PremiumService {
  // Singleton pattern
  static final PremiumService _instance = PremiumService._internal();
  factory PremiumService() => _instance;
  PremiumService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Keys for local storage
  static const String _isPremiumKey = 'is_premium_user';
  static const String _premiumExpiryKey = 'premium_expiry_date';

  // Check if user is premium
  Future<bool> isPremiumUser() async {
    try {
      // First check local cache
      final prefs = await SharedPreferences.getInstance();
      final localIsPremium = prefs.getBool(_isPremiumKey);
      final expiryDateStr = prefs.getString(_premiumExpiryKey);

      // If we have cached premium status and it hasn't expired, use it
      if (localIsPremium == true && expiryDateStr != null) {
        final expiryDate = DateTime.parse(expiryDateStr);
        if (expiryDate.isAfter(DateTime.now())) {
          return true;
        }
      }

      // Otherwise check with Supabase
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      try {
        // Try to get premium status from database using is_premium only
        // Avoid using premium_until which causes errors
        final response = await _supabase
            .from('users')
            .select('is_premium')
            .eq('id', user.id)
            .maybeSingle();

        if (response != null) {
          final isPremium = response['is_premium'] ?? false;

          // Store results in cache
          await prefs.setBool(_isPremiumKey, isPremium);
          return isPremium;
        }
      } catch (e) {
        print('Error checking premium status: $e');
        // If error occurs, use cached value
        return localIsPremium ?? false;
      }

      return false;
    } catch (e) {
      print('Error checking premium status: $e');
      return false;
    }
  }

  // Set user as premium after successful payment
  Future<bool> setUserAsPremium({required int months}) async {
    // TODO: This function is currently disabled to prevent a bug where users become premium just by visiting the placeholder page.
    // TODO: When you implement real payment logic, you can uncomment this code.

    /*
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Calculate expiry date (today + months)
      final now = DateTime.now();
      final expiryDate = DateTime(now.year, now.month + months, now.day, now.hour, now.minute, now.second);

      try {
        // Only update is_premium field, avoid premium_until which is missing
        await _supabase
            .from('users')
            .update({
          'is_premium': true,
        })
            .eq('id', user.id);
      } catch (e) {
        print('Error updating premium status in database: $e');
        // Continue execution to at least update local cache
      }

      // Update local cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isPremiumKey, true);
      await prefs.setString(_premiumExpiryKey, expiryDate.toIso8601String());

      return true;
    } catch (e) {
      print('Error setting user as premium: $e');
      return false;
    }
    */

    print("WARNING: setUserAsPremium is currently disabled to prevent accidental premium status grants.");
    return false; // Return false because the action is disabled.
  }

  // Get premium expiry date
  Future<DateTime?> getPremiumExpiryDate() async {
    try {
      // For now, only use the local cache for expiry date
      final prefs = await SharedPreferences.getInstance();
      final expiryDateStr = prefs.getString(_premiumExpiryKey);

      if (expiryDateStr != null) {
        return DateTime.parse(expiryDateStr);
      }

      // If premium but no expiry date, set default to 1 year from now
      final isPremium = prefs.getBool(_isPremiumKey) ?? false;
      if (isPremium) {
        final defaultExpiry = DateTime.now().add(const Duration(days: 365));
        await prefs.setString(_premiumExpiryKey, defaultExpiry.toIso8601String());
        return defaultExpiry;
      }

      return null;
    } catch (e) {
      print('Error getting premium expiry date: $e');
      return null;
    }
  }

  // Clear premium status (for logout or testing)
  Future<void> clearPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isPremiumKey);
    await prefs.remove(_premiumExpiryKey);
  }

  // Save payment transaction record
  Future<bool> savePaymentRecord({
    required String transactionId,
    required double amount,
    required String currency,
    required String paymentMethod,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      try {
        // Try to save to payment_transactions table
        await _supabase.from('payment_transactions').insert({
          'user_id': user.id,
          'transaction_id': transactionId,
          'amount': amount,
          'currency': currency,
          'payment_method': paymentMethod,
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        // If payment_transactions table doesn't exist, log and continue
        print('Error saving payment record: $e');
        // We still consider this a success since setting premium status is the main goal
      }

      return true;
    } catch (e) {
      print('Error in payment record function: $e');
      return false;
    }
  }
}