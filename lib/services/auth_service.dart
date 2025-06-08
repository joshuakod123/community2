import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class AuthService {
  static final _supabase = Supabase.instance.client;

  // Check if user is using temporary password
  static Future<bool> isUsingTemporaryPassword() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserEmail = prefs.getString('current_user_email');

      if (currentUserEmail == null) return false;

      final tempPasswordEmails = prefs.getStringList('temp_password_emails') ?? <String>[];
      return tempPasswordEmails.contains(currentUserEmail);
    } catch (e) {
      print("Error checking temporary password status: $e");
      return false;
    }
  }

  // Get current user info from local storage
  static Future<Map<String, String?>> getCurrentUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return <String, String?>{
        'userId': prefs.getString('current_user_id'),
        'email': prefs.getString('current_user_email'),
        'name': prefs.getString('user_name'),
      };
    } catch (e) {
      print("Error getting current user info: $e");
      return <String, String?>{
        'userId': null,
        'email': null,
        'name': null,
      };
    }
  }

  // Clean up temporary password data
  static Future<void> cleanupTemporaryPasswordData(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Remove from temporary password list
      final tempPasswordEmails = prefs.getStringList('temp_password_emails') ?? <String>[];
      if (tempPasswordEmails.contains(email)) {
        tempPasswordEmails.remove(email);
        await prefs.setStringList('temp_password_emails', tempPasswordEmails);
      }

      // Remove stored temporary password data
      await prefs.remove('temp_password_$email');
      await prefs.remove('temp_user_id_$email');

      print("Cleaned up temporary password data for: $email");
    } catch (e) {
      print("Error cleaning up temporary password data: $e");
    }
  }

  // Clear all temporary passwords (useful for cleanup)
  static Future<void> clearAllTemporaryPasswords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tempPasswordEmails = prefs.getStringList('temp_password_emails') ?? <String>[];

      for (String email in tempPasswordEmails) {
        await prefs.remove('temp_password_$email');
        await prefs.remove('temp_user_id_$email');
      }

      await prefs.remove('temp_password_emails');
      print("Cleared all temporary password data");
    } catch (e) {
      print("Error clearing temporary passwords: $e");
    }
  }

  // Generate secure random password
  static String generateSecurePassword({int length = 12}) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final random = Random.secure();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
  }

  // Validate email format
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Validate password strength
  static Map<String, dynamic> validatePasswordStrength(String password) {
    final issues = <String>[];
    double score = 0.0;

    if (password.length < 8) {
      issues.add('Password must be at least 8 characters long');
    } else {
      score += 0.2;
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      issues.add('Password must contain at least one uppercase letter');
    } else {
      score += 0.2;
    }

    if (!password.contains(RegExp(r'[a-z]'))) {
      issues.add('Password must contain at least one lowercase letter');
    } else {
      score += 0.2;
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      issues.add('Password must contain at least one number');
    } else {
      score += 0.2;
    }

    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      score += 0.2;
    }

    return <String, dynamic>{
      'isValid': issues.isEmpty,
      'score': score,
      'issues': issues,
    };
  }

  // Create or update user in database
  static Future<bool> createOrUpdateUser({
    required String userId,
    required String email,
    String? firstName,
    String? lastName,
    String? tempPassword,
    bool? passwordResetRequired,
  }) async {
    try {
      final userData = <String, dynamic>{
        'id': userId,
        'email': email.toLowerCase(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (firstName != null) userData['first_name'] = firstName;
      if (lastName != null) userData['last_name'] = lastName;
      if (tempPassword != null) {
        userData['temp_password'] = tempPassword;
        userData['temp_password_created_at'] = DateTime.now().toIso8601String();
      }
      if (passwordResetRequired != null) {
        userData['password_reset_required'] = passwordResetRequired;
      }

      await _supabase.from('users').upsert(userData);

      print("Successfully created/updated user: $email");
      return true;
    } catch (e) {
      print("Error creating/updating user: $e");
      return false;
    }
  }

  // Get user data from database
  static Future<Map<String, dynamic>?> getUserData(String identifier, {bool byEmail = false}) async {
    try {
      final query = _supabase
          .from('users')
          .select('*');

      final result = byEmail
          ? await query.eq('email', identifier.toLowerCase()).maybeSingle()
          : await query.eq('id', identifier).maybeSingle();

      return result;
    } catch (e) {
      print("Error getting user data: $e");
      return null;
    }
  }

  // Sign out user
  static Future<bool> signOut() async {
    try {
      // Sign out from Supabase Auth
      await _supabase.auth.signOut();

      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user_id');
      await prefs.remove('current_user_email');
      await prefs.remove('user_name');

      // Note: We don't clear temporary password data here in case user wants to log back in

      print("Successfully signed out user");
      return true;
    } catch (e) {
      print("Error signing out: $e");
      return false;
    }
  }

  // Check if user session is valid
  static Future<bool> isSessionValid() async {
    try {
      final session = _supabase.auth.currentSession;

      if (session?.user != null) {
        // Check if session is not expired
        final expiresAt = session!.expiresAt;
        if (expiresAt != null && DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000).isAfter(DateTime.now())) {
          return true;
        }
      }

      // Check if user is logged in with temporary password
      final userInfo = await getCurrentUserInfo();
      if (userInfo['userId'] != null && userInfo['email'] != null) {
        final isTemp = await isUsingTemporaryPassword();
        if (isTemp) {
          return true; // Temporary password users are considered valid until they set a new password
        }
      }

      return false;
    } catch (e) {
      print("Error checking session validity: $e");
      return false;
    }
  }

  // Reset password via email
  static Future<bool> resetPasswordViaEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email.toLowerCase());
      print("Password reset email sent to: $email");
      return true;
    } catch (e) {
      print("Error sending password reset email: $e");
      return false;
    }
  }

  // Update user password
  static Future<bool> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      print("Password updated successfully");
      return true;
    } catch (e) {
      print("Error updating password: $e");
      return false;
    }
  }

  // Clean up expired temporary passwords from database
  static Future<void> cleanupExpiredTemporaryPasswords() async {
    try {
      // Get current timestamp
      final now = DateTime.now();
      final oneDayAgo = now.subtract(const Duration(days: 1));

      // Find users with temporary passwords older than 1 day
      final expiredUsers = await _supabase
          .from('users')
          .select('id, email, temp_password_created_at')
          .not('temp_password', 'is', null)
          .lt('temp_password_created_at', oneDayAgo.toIso8601String());

      // Clear expired temporary passwords
      for (final user in expiredUsers) {
        await _supabase
            .from('users')
            .update({
          'temp_password': null,
          'password_reset_required': null,
          'temp_password_created_at': null,
        })
            .eq('id', user['id']);

        // Also clean up local storage if it's the current user
        final currentUserInfo = await getCurrentUserInfo();
        if (currentUserInfo['email'] == user['email']) {
          await cleanupTemporaryPasswordData(user['email'] as String);
        }
      }

      if (expiredUsers.isNotEmpty) {
        print("Cleaned up ${expiredUsers.length} expired temporary passwords");
      }
    } catch (e) {
      print("Error cleaning up expired temporary passwords: $e");
    }
  }

  // Initialize auth service (call this on app startup)
  static Future<void> initialize() async {
    try {
      // Clean up expired temporary passwords
      await cleanupExpiredTemporaryPasswords();

      // Check current session
      final isValid = await isSessionValid();
      print("Auth service initialized. Session valid: $isValid");

      // If session is invalid, clear local storage
      if (!isValid) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('current_user_id');
        await prefs.remove('current_user_email');
        await prefs.remove('user_name');
      }
    } catch (e) {
      print("Error initializing auth service: $e");
    }
  }

  // Get user's display name
  static Future<String> getUserDisplayName() async {
    try {
      final userInfo = await getCurrentUserInfo();

      if (userInfo['name'] != null && userInfo['name']!.isNotEmpty) {
        return userInfo['name']!;
      }

      if (userInfo['email'] != null) {
        // Get user data from database
        final userData = await getUserData(userInfo['email']!, byEmail: true);
        if (userData != null) {
          final firstName = userData['first_name'] as String? ?? '';
          final lastName = userData['last_name'] as String? ?? '';
          final fullName = "$firstName $lastName".trim();

          if (fullName.isNotEmpty) {
            // Cache the name locally
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_name', fullName);
            return fullName;
          }
        }

        // Return email if no name is available
        return userInfo['email']!.split('@')[0];
      }

      return 'User';
    } catch (e) {
      print("Error getting user display name: $e");
      return 'User';
    }
  }

  // Check if email exists in system
  static Future<bool> emailExists(String email) async {
    try {
      final userData = await getUserData(email.toLowerCase(), byEmail: true);
      return userData != null;
    } catch (e) {
      print("Error checking if email exists: $e");
      return false;
    }
  }

  // Create temporary password for user
  static Future<Map<String, dynamic>> createTemporaryPassword(String email) async {
    try {
      // Check if user exists
      final userData = await getUserData(email.toLowerCase(), byEmail: true);

      if (userData == null) {
        return <String, dynamic>{
          'success': false,
          'error': 'User not found',
        };
      }

      // Generate temporary password
      final tempPassword = generateSecurePassword(length: 10);

      // Update user record
      await _supabase
          .from('users')
          .update({
        'temp_password': tempPassword,
        'password_reset_required': true,
        'temp_password_created_at': DateTime.now().toIso8601String(),
      })
          .eq('email', email.toLowerCase());

      // Store in local preferences
      final prefs = await SharedPreferences.getInstance();
      final tempPasswordEmails = prefs.getStringList('temp_password_emails') ?? <String>[];

      if (!tempPasswordEmails.contains(email.toLowerCase())) {
        tempPasswordEmails.add(email.toLowerCase());
        await prefs.setStringList('temp_password_emails', tempPasswordEmails);
      }

      await prefs.setString('temp_password_$email', tempPassword);
      await prefs.setString('temp_user_id_$email', userData['id'] as String);

      return <String, dynamic>{
        'success': true,
        'tempPassword': tempPassword,
        'userId': userData['id'],
      };
    } catch (e) {
      print("Error creating temporary password: $e");
      return <String, dynamic>{
        'success': false,
        'error': 'Failed to create temporary password',
      };
    }
  }

  // Verify temporary password
  static Future<bool> verifyTemporaryPassword(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedTempPassword = prefs.getString('temp_password_$email');

      if (storedTempPassword == null || storedTempPassword != password) {
        return false;
      }

      // Also verify against database
      final userData = await getUserData(email.toLowerCase(), byEmail: true);
      return userData?['temp_password'] == password;
    } catch (e) {
      print("Error verifying temporary password: $e");
      return false;
    }
  }

  // Get password strength score (0.0 to 1.0)
  static double getPasswordStrengthScore(String password) {
    final validation = validatePasswordStrength(password);
    return validation['score'] as double;
  }

  // Get password strength description
  static String getPasswordStrengthDescription(String password) {
    final score = getPasswordStrengthScore(password);

    if (score <= 0.4) return "Weak";
    if (score <= 0.6) return "Fair";
    if (score <= 0.8) return "Good";
    return "Strong";
  }
}