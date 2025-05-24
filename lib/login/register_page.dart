import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/choose_university_screen.dart';
import '../fade_transition.dart';
import '../widgets/loading_widget.dart';
import 'package:experiment3/services/notification_display_service.dart';

// Define the app colors as constants
const Color kPaynesGrey = Color(0xFF536878);
const Color kPearl = Color(0xFFEAE0C8);

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _supabase = Supabase.instance.client;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _isLoading = false;

  Future<void> _signUp() async {
    // Validate input fields
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      NotificationDisplayService.showPopupNotification(
        context,
        title: "Please fill in all fields",
        isError: true,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // Check password match
    if (_passwordController.text != _confirmPasswordController.text) {
      NotificationDisplayService.showPopupNotification(
        context,
        title: "Passwords do not match!",
        isError: true,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // Check terms agreement
    if (!_agreeToTerms) {
      NotificationDisplayService.showPopupNotification(
        context,
        title: "Please accept Terms & Conditions!",
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
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();

      // Show loading dialog
      LoadingWidget.show(context, message: "Creating your account...");

      // First check if user already exists in our users table
      try {
        final existingUser = await _supabase
            .from('users')
            .select('email')
            .eq('email', email)
            .maybeSingle();

        if (existingUser != null) {
          // User exists in our table, they should login instead
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(); // Close loading dialog
          }

          setState(() {
            _isLoading = false;
          });

          NotificationDisplayService.showPopupNotification(
            context,
            title: "Account already exists",
            message: "Please use the login page instead.",
            isError: true,
          );
          return;
        }
      } catch (e) {
        print("Error checking existing user: $e");
        // Continue with registration if check fails
      }

      // Sign up user with Supabase Auth
      AuthResponse response;
      try {
        response = await _supabase.auth.signUp(
          email: email,
          password: password,
          data: {
            'first_name': firstName,
            'last_name': lastName,
          },
        );
      } catch (authError) {
        // Hide loading dialog
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        setState(() {
          _isLoading = false;
        });

        // Handle specific auth errors
        String errorMessage = "Registration failed";
        if (authError.toString().contains('already_registered') ||
            authError.toString().contains('user_already_exists')) {
          errorMessage = "An account with this email already exists. Please login instead.";
        } else if (authError.toString().contains('weak_password')) {
          errorMessage = "Password is too weak. Please use a stronger password.";
        } else if (authError.toString().contains('invalid_email')) {
          errorMessage = "Please enter a valid email address.";
        }

        NotificationDisplayService.showPopupNotification(
          context,
          title: "Registration Error",
          message: errorMessage,
          isError: true,
        );
        return;
      }

      final user = response.user;

      if (user != null) {
        // Update loading message
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(); // Pop current dialog
        }
        LoadingWidget.show(context, message: "Setting up your profile...");

        // Wait a bit for any triggers to complete
        await Future.delayed(const Duration(seconds: 2));

        // Ensure the user's details are in our users table
        try {
          await _supabase
              .from('users')
              .upsert({
            'id': user.id,
            'email': email,
            'first_name': firstName,
            'last_name': lastName,
            'created_at': DateTime.now().toIso8601String(),
          }, onConflict: 'id');

          print("User record created/updated successfully");
        } catch (dbError) {
          print("Error creating user record: $dbError");
          // Continue anyway - the trigger might have handled it
        }

        // Hide loading dialog
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        NotificationDisplayService.showPopupNotification(
          context,
          title: "Account created successfully!",
          isSuccess: true,
          duration: const Duration(seconds: 2),
        );

        // Redirect to Choose University Screen
        Navigator.pushReplacement(context, fadeTransition(ChooseUniversityScreen()));
      } else {
        // Hide loading dialog on error
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        setState(() {
          _isLoading = false;
        });

        NotificationDisplayService.showPopupNotification(
          context,
          title: "Registration failed",
          message: "Please try again or contact support.",
          isError: true,
        );
      }
    } catch (error) {
      // Hide loading dialog on error
      if (Navigator.of(context).canPop()) {
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
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  // Logo - INCREASED SIZE
                  Center(
                    child: Image.asset(
                      'assets/images/only_pass_logo.png',
                      height: 150, // Increased from 100
                      width: 150,  // Increased from 100
                    ),
                  ),
                  const SizedBox(height: 20), // Reduced since logo is bigger

                  // Create Account text
                  Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: kPaynesGrey,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // First Name field
                  TextField(
                    controller: _firstNameController,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      hintText: "First Name",
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: kPaynesGrey,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Last Name field
                  TextField(
                    controller: _lastNameController,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      hintText: "Last Name",
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: kPaynesGrey,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email field
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

                  // Password field
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
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: kPaynesGrey.withOpacity(0.7),
                        ),
                        onPressed: !_isLoading
                            ? () => setState(() => _obscurePassword = !_obscurePassword)
                            : null,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password field
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      hintText: "Confirm Password",
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
                          _obscureConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: kPaynesGrey.withOpacity(0.7),
                        ),
                        onPressed: !_isLoading
                            ? () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)
                            : null,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Terms and Conditions
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _agreeToTerms,
                          onChanged: !_isLoading
                              ? (value) => setState(() => _agreeToTerms = value ?? false)
                              : null,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          activeColor: kPaynesGrey,
                          checkColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "I accept Terms & Privacy Policy",
                          style: TextStyle(
                            color: kPaynesGrey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Sign Up button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: !_isLoading ? _signUp : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPaynesGrey,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Already have an account
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account?",
                        style: TextStyle(color: kPaynesGrey),
                      ),
                      TextButton(
                        onPressed: !_isLoading
                            ? () => Navigator.pop(context)
                            : null,
                        style: TextButton.styleFrom(
                          foregroundColor: kPaynesGrey,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        child: const Text(
                          "Login here",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
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
    );
  }
}