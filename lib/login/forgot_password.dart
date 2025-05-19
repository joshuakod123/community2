import 'package:flutter/material.dart';
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

  // Function to generate a random password
  String _generateRandomPassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(10, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    // Validate email
    if (email.isEmpty) {
      NotificationDisplayService.showPopupNotification(
        context,
        title: "Please enter your email address",
        isError: true,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // Check for valid email format
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      NotificationDisplayService.showPopupNotification(
        context,
        title: "Please enter a valid email address",
        isError: true,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // Show loading state
    setState(() {
      _isLoading = true;
    });

    try {
      // Show loading dialog
      LoadingWidget.show(context, message: "Resetting password...");

      // Generate a random password
      final newPassword = _generateRandomPassword();

      // First check if the user exists in Auth
      bool userExists = false;
      try {
        // This call will succeed if the email exists in Auth
        await _supabase.auth.resetPasswordForEmail(email);
        userExists = true;
      } catch (e) {
        print("Error checking if user exists in Auth: $e");
        // User doesn't exist in Auth, but we'll continue to check if they exist in the users table
      }

      // Check if user exists in the users table
      try {
        final userResponse = await _supabase
            .from('users')
            .select('id, email')
            .eq('email', email)
            .maybeSingle();

        if (userResponse != null) {
          // User exists in the users table, update the temp_password
          await _supabase
              .from('users')
              .update({
            'temp_password': newPassword,
          })
              .eq('email', email);
          userExists = true;
        } else if (userExists) {
          // User exists in Auth but not in users table, create a new entry
          await _supabase
              .from('users')
              .insert({
            'email': email,
            'temp_password': newPassword,
          });
        }
      } catch (dbError) {
        print("Error updating users table: $dbError");
        // If there was an error with the database operation, but we know the user exists in Auth,
        // we'll still consider this a success
      }

      if (!userExists) {
        // If the user doesn't exist in either Auth or the users table, show an error
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop(); // Close loading dialog
        }

        setState(() {
          _isLoading = false;
        });

        NotificationDisplayService.showPopupNotification(
          context,
          title: "Error",
          message: "No user found with this email address or unable to reset password.",
          isError: true,
        );
        return;
      }

      // Store the email in SharedPreferences to track temporary password logins
      final prefs = await SharedPreferences.getInstance();
      List<String> tempPasswordEmails = prefs.getStringList('temp_password_emails') ?? [];
      if (!tempPasswordEmails.contains(email)) {
        tempPasswordEmails.add(email);
        await prefs.setStringList('temp_password_emails', tempPasswordEmails);
      }

      // Store the temporary password in SharedPreferences for immediate access during login
      await prefs.setString('temp_password_$email', newPassword);

      // Store the generated password to show to the user
      _generatedPassword = newPassword;

      // Hide loading dialog
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      setState(() {
        _isLoading = false;
        _passwordReset = true; // Show success message with generated password
      });
    } catch (error) {
      // Hide loading dialog on error
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      setState(() {
        _isLoading = false;
      });

      NotificationDisplayService.showPopupNotification(
        context,
        title: "Error",
        message: error.toString(),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPearl,
      appBar: AppBar(
        backgroundColor: kPaynesGrey,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Forgot Password",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
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
          "Enter your email and we'll generate a temporary password for you.",
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

        // Temporary password explanation
        Text(
          "We've generated a temporary password for you:",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: kPaynesGrey.withOpacity(0.8),
          ),
        ),

        const SizedBox(height: 16),

        // Display the generated password
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: SelectableText(
            _generatedPassword,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kPaynesGrey,
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 16),

        // Instructions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Text(
            "Use this temporary password to log in. You'll be redirected to your profile page to set a new password.",
            style: TextStyle(
              color: Colors.blue.shade800,
              fontSize: 14,
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Back to Login button
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
              "Back to Login",
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

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}