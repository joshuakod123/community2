// lib/login/forgot_password.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this for Clipboard
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/loading_widget.dart';
import '../login/login_page.dart';
import 'package:experiment3/services/notification_display_service.dart';

// Define the app colors as constants
const Color kPaynesGrey = Color(0xFF536878);
const Color kPearl = Color(0xFFEAE0C8);

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _supabase = Supabase.instance.client;
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _passwordReset = false;
  String _generatedPassword = '';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Function to generate a random password
  String _generateRandomPassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final random = Random.secure();
    return List.generate(12, (index) => chars[random.nextInt(chars.length)]).join();
  }

  // Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Show error message
  void _showErrorMessage(String message) {
    if (context.mounted) {
      NotificationDisplayService.showPopupNotification(
        context,
        title: "Error",
        message: message,
        isSuccess: false,
      );
    }
  }

  // Hide loading and show error
  void _hideLoadingAndShowError(String message) {
    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    setState(() {
      _isLoading = false;
    });
    _showErrorMessage(message);
  }

  // Reset password function with improved error handling
  Future<void> _resetPassword() async {
    final email = _emailController.text.trim().toLowerCase();

    // Validate email
    if (email.isEmpty) {
      _showErrorMessage("Please enter your email address");
      return;
    }

    if (!_isValidEmail(email)) {
      _showErrorMessage("Please enter a valid email address");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Show loading dialog
      LoadingWidget.show(context, message: "Checking account...");

      // Generate a random password
      final newPassword = _generateRandomPassword();

      // Check if user exists in users table
      final userResponse = await _supabase
          .from('users')
          .select('id, email, first_name, last_name')
          .eq('email', email)
          .maybeSingle();

      if (userResponse == null) {
        // User doesn't exist in users table
        _hideLoadingAndShowError("No account found with this email address. Please check your email or create a new account.");
        return;
      }

      // Set temporary password for existing user
      await _setTemporaryPassword(email, newPassword, userResponse['id']);

    } catch (error) {
      print("❌ General error in password reset: $error");
      _hideLoadingAndShowError("An unexpected error occurred. Please try again.");
    }
  }

  // Set temporary password for existing user
  Future<void> _setTemporaryPassword(String email, String newPassword, String userId) async {
    try {
      // Update user record with temporary password
      await _supabase
          .from('users')
          .update({
        'temp_password': newPassword,
        'password_reset_required': true,
        'temp_password_created_at': DateTime.now().toIso8601String(),
      })
          .eq('id', userId);

      // Store temporary password info in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      List<String> tempPasswordEmails = prefs.getStringList('temp_password_emails') ?? [];

      if (!tempPasswordEmails.contains(email)) {
        tempPasswordEmails.add(email);
        await prefs.setStringList('temp_password_emails', tempPasswordEmails);
      }

      await prefs.setString('temp_password_$email', newPassword);
      await prefs.setString('temp_user_id_$email', userId);

      _generatedPassword = newPassword;

      // Hide loading dialog
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      setState(() {
        _isLoading = false;
        _passwordReset = true;
      });

      print("✅ Successfully generated temporary password for: $email");

    } catch (dbError) {
      print("❌ Database error: $dbError");
      _hideLoadingAndShowError("Failed to reset password. Please try again or contact support.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPearl,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: _passwordReset
                  ? _buildSuccessContent()
                  : _buildResetPasswordContent(),
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const LoadingWidget(
                backgroundColor: Colors.transparent,
                textColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  // Reset password form content
  Widget _buildResetPasswordContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),

        // Reset Password Icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: kPaynesGrey.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.lock_reset,
            size: 50,
            color: kPaynesGrey,
          ),
        ),

        const SizedBox(height: 24),

        // Reset Your Password Text
        Text(
          "Reset Your Password",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: kPaynesGrey,
          ),
        ),

        const SizedBox(height: 12),

        // Instruction Text
        Text(
          "Enter the email address associated with your account and we'll generate a temporary password for you.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: kPaynesGrey.withOpacity(0.7),
          ),
        ),

        const SizedBox(height: 40),

        // Email Field
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          enabled: !_isLoading,
          decoration: InputDecoration(
            hintText: "Email Address",
            filled: true,
            fillColor: Colors.white.withOpacity(0.8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(
              Icons.email_outlined,
              color: kPaynesGrey,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),

        const SizedBox(height: 32),

        // Reset Password Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: !_isLoading ? _resetPassword : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPaynesGrey,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Reset Password",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Back to Login
        TextButton(
          onPressed: !_isLoading
              ? () => Navigator.pop(context)
              : null,
          style: TextButton.styleFrom(
            foregroundColor: kPaynesGrey,
          ),
          child: const Text(
            "Back to Login",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // Success content with generated password
  Widget _buildSuccessContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),

        // Success icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            size: 60,
            color: Colors.green,
          ),
        ),

        const SizedBox(height: 24),

        // Success title
        Text(
          "Password Reset Successful!",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: kPaynesGrey,
          ),
        ),

        const SizedBox(height: 16),

        // Success message
        Text(
          "Your temporary password has been generated. Use this password to log in and then set a new password.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: kPaynesGrey.withOpacity(0.7),
          ),
        ),

        const SizedBox(height: 32),

        // Temporary password display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kPaynesGrey.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text(
                "Temporary Password:",
                style: TextStyle(
                  fontSize: 14,
                  color: kPaynesGrey.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                _generatedPassword,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: kPaynesGrey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Copy button
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _generatedPassword));
                  _showErrorMessage("Password copied to clipboard!");
                },
                icon: Icon(Icons.copy, size: 18),
                label: Text("Copy Password"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPaynesGrey,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Important note
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning,
                color: Colors.orange.shade700,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Please copy this password and change it immediately after logging in for security.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Go to Login Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPaynesGrey,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Go to Login",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}