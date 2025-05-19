import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/main_page.dart';
import '../login/register_page.dart';
import '../login/forgot_password.dart';
import '../fade_transition.dart';
import '../widgets/loading_widget.dart';
import 'package:experiment3/services/notification_display_service.dart';
import '../screens/profile_page.dart'; // Add this import for the ProfilePage

// Define the app colors as constants
const Color kPaynesGrey = Color(0xFF536878);
const Color kPearl = Color(0xFFEAE0C8);

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _mounted = true;

  @override
  void dispose() {
    _mounted = false;
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // Validate input fields
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      NotificationDisplayService.showPopupNotification(
        context,
        title: "Please enter both email and passwords!",
        isSuccess: true,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // Show loading state
    if (_mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Show loading dialog during login process
      if (context.mounted) {
        LoadingWidget.show(context, message: "Logging in...");
      }

      // Use try-catch with await to properly handle errors
      try {
        final response = await supabase.auth.signInWithPassword(email: email, password: password);

        // Hide loading dialog
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        if (!_mounted) return;

        if (response.user != null) {
          final userId = response.user!.id;
          final userEmail = response.user!.email;

          if (context.mounted) {
            LoadingWidget.show(context, message: "Setting up your account...");
          }

          // Ensure user exists in "users" table
          await supabase.from('users').upsert({
            'id': userId,
            'email': userEmail,
          });

          // Check if this is a temporary password login by checking SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          bool isTemporaryPassword = false;

          // If the email exists in temp password list, this is a temporary password login
          if (prefs.getStringList('temp_password_emails') != null) {
            List<String> tempPasswordEmails = prefs.getStringList('temp_password_emails') ?? [];
            if (tempPasswordEmails.contains(email)) {
              isTemporaryPassword = true;

              // Remove email from temporary password list after successful login
              tempPasswordEmails.remove(email);
              await prefs.setStringList('temp_password_emails', tempPasswordEmails);
            }
          }

          // Fetch user name from database with proper error handling
          try {
            final userData = await supabase
                .from('users')
                .select('first_name, last_name')
                .eq('id', response.user!.id)
                .maybeSingle();

            // Fetch user name and handle null values safely
            if (userData != null) {
              String firstName = userData['first_name'] ?? '';
              String lastName = userData['last_name'] ?? '';
              String fullName = "$firstName $lastName".trim();
              await prefs.setString('user_name', fullName);
            }
          } catch (e) {
            print("Error fetching user data: $e");
          }

          // Hide loading dialog
          if (context.mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }

          // Navigate based on whether it's a temporary password login
          if (isTemporaryPassword) {
            // Show notification about temporary password
            if (context.mounted) {
              NotificationDisplayService.showPopupNotification(
                context,
                title: "Please update your password",
                message: "You are using a temporary password. You will be redirected to your profile to set a new password.",
                isSuccess: true,
                duration: const Duration(seconds: 3),
              );
            }

            // Navigate directly to Profile page after a short delay
            await Future.delayed(const Duration(seconds: 2));
            if (context.mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            }
          } else {
            // Normal login to MainPage
            if (context.mounted) {
              Navigator.pushReplacement(context, fadeTransition(const MainPageUI()));
            }
          }
        } else {
          // Set loading state to false if login fails
          if (_mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          if (context.mounted) {
            NotificationDisplayService.showPopupNotification(
              context,
              title: "Login failed. Please check you credentials!",
              isSuccess: true,
              duration: const Duration(seconds: 2),
            );
          }
        }
      } catch (authError) {
        // Hide loading dialog on auth error
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        if (_mounted) {
          setState(() {
            _isLoading = false;
          });
        }

        if (context.mounted) {
          NotificationDisplayService.showPopupNotification(
            context,
            title: "Authentication Error",
            message: authError.toString(),
            isError: true,
          );
        }
        return;
      }
    } catch (error) {
      // Hide loading dialog on general error
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Set loading state to false on error
      if (_mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      if (context.mounted) {
        NotificationDisplayService.showPopupNotification(
          context,
          title: "Error",
          message: error.toString(),
          isError: true,
        );
      }
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
                  const SizedBox(height: 60),
                  // Logo - INCREASED SIZE
                  Center(
                    child: Image.asset(
                      'assets/images/only_pass_logo.png',
                      height: 150, // Increased from 100
                      width: 150,  // Increased from 100
                    ),
                  ),
                  const SizedBox(height: 30), // Reduced gap since logo is bigger

                  // Sign in text
                  Text(
                    "Sign in",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: kPaynesGrey,
                    ),
                  ),
                  const SizedBox(height: 40),

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
                  const SizedBox(height: 8),

                  // Remember me and forgot password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Remember me
                      Row(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: !_isLoading
                                  ? (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              }
                                  : null,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              activeColor: kPaynesGrey,
                              checkColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Remember Me",
                            style: TextStyle(
                              color: kPaynesGrey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),

                      // Forgot password
                      TextButton(
                        onPressed: !_isLoading
                            ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ForgotPasswordPage()),
                          );
                        }
                            : null,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: kPaynesGrey,
                        ),
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Login button
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
                        "Login",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Create account
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: TextStyle(color: kPaynesGrey),
                      ),
                      TextButton(
                        onPressed: !_isLoading
                            ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => RegisterPage()),
                          );
                        }
                            : null,
                        style: TextButton.styleFrom(
                          foregroundColor: kPaynesGrey,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        child: const Text(
                          "Create Account",
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