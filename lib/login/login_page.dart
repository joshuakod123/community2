// lib/login/login_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/loading_widget.dart';
import '../pages/main_page.dart';
import '../sub_screens/edit_profile_page.dart';
import 'register_page.dart';
import 'forgot_password.dart';
import 'package:experiment3/services/notification_display_service.dart';

// Define the app colors as constants
const Color kPaynesGrey = Color(0xFF536878);
const Color kPearl = Color(0xFFEAE0C8);

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  bool _mounted = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _mounted = false;
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Check if this is a temporary password attempt
  Future<bool> _isTemporaryPasswordAttempt(String email) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> tempPasswordEmails = prefs.getStringList('temp_password_emails') ?? [];
    return tempPasswordEmails.contains(email.toLowerCase());
  }

  // Handle temporary password login
  Future<Map<String, dynamic>?> _handleTemporaryPasswordLogin(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedTempPassword = prefs.getString('temp_password_$email');
      final storedUserId = prefs.getString('temp_user_id_$email');

      if (storedTempPassword != null && password == storedTempPassword && storedUserId != null) {
        // Verify the user exists in the database with this temporary password
        final userData = await _supabase
            .from('users')
            .select('id, email, first_name, last_name, temp_password')
            .eq('id', storedUserId)
            .eq('email', email)
            .maybeSingle();

        if (userData != null && userData['temp_password'] == password) {
          // Store user session info manually
          await prefs.setString('current_user_id', storedUserId);
          await prefs.setString('current_user_email', email);

          // Store user name
          final firstName = userData['first_name'] as String? ?? '';
          final lastName = userData['last_name'] as String? ?? '';
          final fullName = "$firstName $lastName".trim();
          if (fullName.isNotEmpty) {
            await prefs.setString('user_name', fullName);
          }
          return userData;
        }
      }
    } catch (e) {
      print("Error in temporary password login: $e");
    }
    return null;
  }


  // Main login function
  Future<void> _login() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    // Validate input
    if (email.isEmpty || password.isEmpty) {
      _showErrorMessage("Please enter both email and password");
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
      LoadingWidget.show(context, message: "Signing in...");

      // Check if this is a temporary password attempt
      if (await _isTemporaryPasswordAttempt(email)) {
        final userInfo = await _handleTemporaryPasswordLogin(email, password);

        if (userInfo != null) {
          // Hide loading dialog
          if (context.mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }

          if (_mounted) {
            setState(() {
              _isLoading = false;
            });
          }

          // Show notification about password change
          if (context.mounted) {
            NotificationDisplayService.showPopupNotification(
              context,
              title: "Please update your password",
              message: "For security, you must set a new password.",
              isSuccess: true,
              duration: const Duration(seconds: 4),
            );
          }

          // Navigate to Edit Profile page to force password change
          await Future.delayed(const Duration(seconds: 1));
          if (context.mounted) {
            final firstName = userInfo['first_name'] ?? '';
            final lastName = userInfo['last_name'] ?? '';
            final userEmail = userInfo['email'] ?? '';

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => EditProfilePage(
                  currentFirstName: firstName,
                  currentLastName: lastName,
                  currentEmail: userEmail,
                  forcePasswordChange: true, // Force password change view
                ),
              ),
            );
          }
          return;
        } else {
          // Temporary password login failed
          _hideLoadingAndShowError("Invalid temporary password. Please try again or reset it.");
          return;
        }
      }


      // Normal login process with Supabase Auth
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Hide loading dialog
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (!_mounted) return;

      if (response.user != null) {
        final userId = response.user!.id;
        final userEmail = response.user!.email ?? "";

        if (context.mounted) {
          LoadingWidget.show(context, message: "Setting up your account...");
        }

        // Ensure user exists in "users" table
        await _supabase.from('users').upsert({
          'id': userId,
          'email': userEmail,
        });

        // Fetch user name from database
        try {
          final userData = await _supabase
              .from('users')
              .select('first_name, last_name')
              .eq('id', response.user!.id)
              .maybeSingle();

          if (userData != null) {
            final firstName = userData['first_name'] as String? ?? '';
            final lastName = userData['last_name'] as String? ?? '';
            final fullName = "$firstName $lastName".trim();

            if (fullName.isNotEmpty) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('user_name', fullName);
            }
          }
        } catch (e) {
          print("Error fetching user data: $e");
        }

        // Hide loading dialog
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        if (_mounted) {
          setState(() {
            _isLoading = false;
          });
        }

        // Show success message
        if (context.mounted) {
          NotificationDisplayService.showPopupNotification(
            context,
            title: "Login successful!",
            message: "Welcome back!",
            isSuccess: true,
            duration: const Duration(seconds: 2),
          );
        }

        // Navigate to main page
        await Future.delayed(const Duration(seconds: 1));
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainPageUI()),
          );
        }
      }
    } on AuthException catch (authError) {
      String errorMessage = "Login failed";

      if (authError.message.contains('Invalid login credentials')) {
        errorMessage = "Invalid email or password. Please check your credentials.";
      } else if (authError.message.contains('Email not confirmed')) {
        errorMessage = "Please check your email and confirm your account.";
      } else if (authError.message.contains('Too many requests')) {
        errorMessage = "Too many login attempts. Please wait and try again.";
      }

      _hideLoadingAndShowError(errorMessage);
    } catch (error) {
      print("Login error: $error");
      _hideLoadingAndShowError("An unexpected error occurred. Please try again.");
    }
  }

  // Helper method to show error messages
  void _showErrorMessage(String message) {
    NotificationDisplayService.showPopupNotification(
      context,
      title: message,
      isError: true,
      duration: const Duration(seconds: 3),
    );
  }

  // Helper method to hide loading and show error
  void _hideLoadingAndShowError(String message) {
    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    if (_mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    _showErrorMessage(message);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kPearl, Colors.white],
          ),
        ),
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: size.height * 0.1),

                    // App Logo/Title
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: kPaynesGrey.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.school,
                        size: 60,
                        color: kPaynesGrey,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Welcome Text
                    Text(
                      "Welcome Back!",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: kPaynesGrey,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "Sign in to continue",
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

                    const SizedBox(height: 16),

                    // Password Field
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        hintText: "Password",
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: kPaynesGrey,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: kPaynesGrey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Forgot Password Link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: !_isLoading
                            ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ForgotPasswordPage(),
                            ),
                          );
                        }
                            : null,
                        child: Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: kPaynesGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: !_isLoading ? _login : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPaynesGrey,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Sign In",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: kPaynesGrey.withOpacity(0.3),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            "OR",
                            style: TextStyle(
                              color: kPaynesGrey.withOpacity(0.5),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: kPaynesGrey.withOpacity(0.3),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Register Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: !_isLoading
                            ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RegisterPage(),
                            ),
                          );
                        }
                            : null,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: kPaynesGrey, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Create New Account",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: kPaynesGrey,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
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
      ),
    );
  }
}