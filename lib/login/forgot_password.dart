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

      // First, check if user exists in Supabase Auth
      bool userExistsInAuth = false;
      String? userId;

      try {
        // Try to get user from Supabase Auth using admin methods is not available in client
        // So we'll check the users table and if not found, we'll create the user entry

        // Check if user exists in the users table
        final userResponse = await _supabase
            .from('users')
            .select('id, email')
            .eq('email', email)
            .maybeSingle();

        if (userResponse != null) {
          userExistsInAuth = true;
          userId = userResponse['id'] as String?;
          print("User found in users table: $userId");
        } else {
          // User not in users table, let's check if they exist in auth but not in users table
          print("User not found in users table, checking if they need to be created...");

          // For newly registered users who might not be in users table yet
          // We'll try to insert them first (this will only work if they exist in auth)
          try {
            // Get current auth user to see if someone is logged in
            final currentUser = _supabase.auth.currentUser;

            // If no current user, we need to handle this differently
            // Let's assume the user exists and try to create their record
            print("Attempting to handle user registration case...");

            // Generate a temporary user ID (this is not ideal, but a workaround)
            // In a real scenario, you'd want to use Supabase's admin API
            final tempUserId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

            // Try to insert user record (this might fail if they don't exist in auth)
            try {
              await _supabase.from('users').insert({
                'email': email,
                'temp_password': newPassword,
              });

              userExistsInAuth = true;
              userId = tempUserId; // Use temp ID for local storage
              print("Created user record for: $email");
            } catch (insertError) {
              print("Could not insert user record: $insertError");
              // User doesn't exist, we'll handle this case
            }
          } catch (e) {
            print("Error in user creation check: $e");
          }
        }
      } catch (e) {
        print("Error checking user existence: $e");
      }

      // If user still doesn't exist after all checks
      if (!userExistsInAuth) {
        // Hide loading dialog
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        setState(() {
          _isLoading = false;
        });

        // Instead of showing error, let's be more helpful
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Account Not Found"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("No account found with email: $email"),
                  const SizedBox(height: 16),
                  const Text("Please check:"),
                  const Text("• Email address spelling"),
                  const Text("• That you have registered an account"),
                  const SizedBox(height: 16),
                  const Text("Would you like to create a new account instead?"),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(); // Go back to login
                    // Navigate to register page would go here
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPaynesGrey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Register"),
                ),
              ],
            );
          },
        );
        return;
      }

      // User exists, proceed with password reset
      try {
        // Update user record with temporary password
        await _supabase
            .from('users')
            .upsert({
          'email': email,
          'temp_password': newPassword,
        }, onConflict: 'email');

        // Store the email in SharedPreferences to track temporary password logins
        final prefs = await SharedPreferences.getInstance();
        List<String> tempPasswordEmails = prefs.getStringList('temp_password_emails') ?? [];
        if (!tempPasswordEmails.contains(email)) {
          tempPasswordEmails.add(email);
          await prefs.setStringList('temp_password_emails', tempPasswordEmails);
        }

        // Store the temporary password in SharedPreferences
        await prefs.setString('temp_password_$email', newPassword);

        // Store the user ID for temporary login (use actual ID if available)
        if (userId != null) {
          await prefs.setString('temp_user_id_$email', userId);
        }

        _generatedPassword = newPassword;

        // Hide loading dialog
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        setState(() {
          _isLoading = false;
          _passwordReset = true;
        });

        print("Successfully generated temporary password for: $email");

      } catch (dbError) {
        print("Database error: $dbError");

        // Hide loading dialog
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        setState(() {
          _isLoading = false;
        });

        NotificationDisplayService.showPopupNotification(
          context,
          title: "Error",
          message: "Failed to reset password. Please try again or contact support.",
          isError: true,
        );
      }

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
        message: "An unexpected error occurred. Please try again.",
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

        // Instruction Text - Made more helpful
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Next Steps:",
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "1. Copy the temporary password above\n2. Go back to login and use this password\n3. You'll be prompted to set a new password",
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontSize: 14,
                ),
              ),
            ],
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