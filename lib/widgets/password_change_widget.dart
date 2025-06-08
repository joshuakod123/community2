import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:experiment3/services/notification_display_service.dart';

// Define the app colors as constants
const Color kPaynesGrey = Color(0xFF536878);
const Color kPearl = Color(0xFFEAE0C8);

class PasswordChangeWidget extends StatefulWidget {
  final bool isTemporaryPassword;
  final VoidCallback? onPasswordChanged;

  const PasswordChangeWidget({
    Key? key,
    this.isTemporaryPassword = false,
    this.onPasswordChanged,
  }) : super(key: key);

  @override
  _PasswordChangeWidgetState createState() => _PasswordChangeWidgetState();
}

class _PasswordChangeWidgetState extends State<PasswordChangeWidget> {
  final _supabase = Supabase.instance.client;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Validate password strength
  String? _validatePassword(String password) {
    if (password.length < 8) {
      return "Password must be at least 8 characters long";
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return "Password must contain at least one uppercase letter";
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return "Password must contain at least one lowercase letter";
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return "Password must contain at least one number";
    }
    return null;
  }

  // Get password strength indicator
  double _getPasswordStrength(String password) {
    double strength = 0.0;

    if (password.length >= 8) strength += 0.2;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.2;
    if (password.contains(RegExp(r'[a-z]'))) strength += 0.2;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.2;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.2;

    return strength;
  }

  // Get password strength color
  Color _getPasswordStrengthColor(double strength) {
    if (strength <= 0.4) return Colors.red;
    if (strength <= 0.6) return Colors.orange;
    if (strength <= 0.8) return Colors.yellow.shade700;
    return Colors.green;
  }

  // Get password strength text
  String _getPasswordStrengthText(double strength) {
    if (strength <= 0.4) return "Weak";
    if (strength <= 0.6) return "Fair";
    if (strength <= 0.8) return "Good";
    return "Strong";
  }

  // Change password function
  Future<void> _changePassword() async {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validate inputs
    if (!widget.isTemporaryPassword && currentPassword.isEmpty) {
      _showErrorMessage("Please enter your current password");
      return;
    }

    if (newPassword.isEmpty) {
      _showErrorMessage("Please enter a new password");
      return;
    }

    if (confirmPassword.isEmpty) {
      _showErrorMessage("Please confirm your new password");
      return;
    }

    if (newPassword != confirmPassword) {
      _showErrorMessage("New passwords do not match");
      return;
    }

    final passwordError = _validatePassword(newPassword);
    if (passwordError != null) {
      _showErrorMessage(passwordError);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.isTemporaryPassword) {
        // For temporary password users, we need to set up their Supabase Auth account
        await _setupAuthAccountWithNewPassword(newPassword);
      } else {
        // For regular users, update their existing password
        await _supabase.auth.updateUser(
          UserAttributes(password: newPassword),
        );
      }

      // Clear the form
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      setState(() {
        _isLoading = false;
      });

      // Show success message
      NotificationDisplayService.showPopupNotification(
        context,
        title: "Password Updated",
        message: "Your password has been successfully updated!",
        isSuccess: true,
        duration: const Duration(seconds: 3),
      );

      // Call the callback if provided
      if (widget.onPasswordChanged != null) {
        widget.onPasswordChanged!();
      }

    } catch (error) {
      setState(() {
        _isLoading = false;
      });

      String errorMessage = "Failed to update password";
      if (error.toString().contains('Invalid login credentials')) {
        errorMessage = "Current password is incorrect";
      } else if (error.toString().contains('Password should be at least')) {
        errorMessage = "Password does not meet security requirements";
      }

      _showErrorMessage(errorMessage);
    }
  }

  // Setup Supabase Auth account for temporary password users
  Future<void> _setupAuthAccountWithNewPassword(String newPassword) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('current_user_email');

      if (userEmail == null) {
        throw Exception("User email not found");
      }

      // Try to create a new auth user or update existing one
      try {
        // First try to sign up (in case user doesn't exist in auth)
        await _supabase.auth.signUp(
          email: userEmail,
          password: newPassword,
        );
      } catch (signUpError) {
        // If sign up fails (user might already exist), try to reset password
        await _supabase.auth.resetPasswordForEmail(userEmail);
        // Note: In a real app, you'd want to handle this through email confirmation
        // For now, we'll assume the password reset works
      }

      // Sign in with the new password
      final response = await _supabase.auth.signInWithPassword(
        email: userEmail,
        password: newPassword,
      );

      if (response.user != null) {
        // Update the users table with the auth user ID
        await _supabase.from('users').update({
          'id': response.user!.id,
        }).eq('email', userEmail);

        // Update local storage
        await prefs.setString('current_user_id', response.user!.id);
      }

    } catch (error) {
      print("Error setting up auth account: $error");
      throw error;
    }
  }

  // Show error message
  void _showErrorMessage(String message) {
    NotificationDisplayService.showPopupNotification(
      context,
      title: message,
      isError: true,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final newPasswordStrength = _getPasswordStrength(_newPasswordController.text);

    return Card(
      elevation: 4,
      color: kPearl,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                Icon(
                  widget.isTemporaryPassword ? Icons.warning : Icons.lock,
                  color: widget.isTemporaryPassword ? Colors.orange : kPaynesGrey,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  widget.isTemporaryPassword
                      ? "Set New Password"
                      : "Change Password",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kPaynesGrey,
                  ),
                ),
              ],
            ),

            if (widget.isTemporaryPassword) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Please set a new password for security",
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Current Password Field (only for non-temporary password users)
            if (!widget.isTemporaryPassword) ...[
              Text(
                "Current Password",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kPaynesGrey,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrentPassword,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText: "Enter current password",
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrentPassword ? Icons.visibility_off : Icons.visibility,
                      color: kPaynesGrey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureCurrentPassword = !_obscureCurrentPassword;
                      });
                    },
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // New Password Field
            Text(
              "New Password",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kPaynesGrey,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _newPasswordController,
              obscureText: _obscureNewPassword,
              enabled: !_isLoading,
              onChanged: (value) {
                setState(() {}); // Trigger rebuild for password strength indicator
              },
              decoration: InputDecoration(
                hintText: "Enter new password",
                filled: true,
                fillColor: Colors.white.withOpacity(0.8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                    color: kPaynesGrey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
            ),

            // Password Strength Indicator
            if (_newPasswordController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: newPasswordStrength,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getPasswordStrengthColor(newPasswordStrength),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _getPasswordStrengthText(newPasswordStrength),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getPasswordStrengthColor(newPasswordStrength),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Confirm Password Field
            Text(
              "Confirm New Password",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kPaynesGrey,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              enabled: !_isLoading,
              decoration: InputDecoration(
                hintText: "Confirm new password",
                filled: true,
                fillColor: Colors.white.withOpacity(0.8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                    color: kPaynesGrey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
            ),

            const SizedBox(height: 24),

            // Password Requirements
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Password Requirements:",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kPaynesGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "• At least 8 characters\n• One uppercase letter\n• One lowercase letter\n• One number",
                    style: TextStyle(
                      fontSize: 11,
                      color: kPaynesGrey.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Update Password Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: !_isLoading ? _changePassword : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPaynesGrey,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Text(
                  "Update Password",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}