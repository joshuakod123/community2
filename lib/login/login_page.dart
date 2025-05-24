import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/main_page.dart';
import '../login/register_page.dart';
import '../login/forgot_password.dart';
import '../fade_transition.dart';
import '../widgets/loading_widget.dart';
import 'package:experiment3/services/notification_display_service.dart';
import '../screens/profile_page.dart';

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
        title: "Please enter both email and password!",
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

      // Check if this is a temporary password login
      final prefs = await SharedPreferences.getInstance();
      final tempPasswordEmails = prefs.getStringList('temp_password_emails') ?? [];
      bool isTemporaryPasswordAttempt = tempPasswordEmails.contains(email);

      if (isTemporaryPasswordAttempt) {
        // Handle temporary password login
        final storedTempPassword = prefs.getString('temp_password_$email');
        final storedUserId = prefs.getString('temp_user_id_$email');

        if (storedTempPassword != null && password == storedTempPassword && storedUserId != null) {
          // Temporary password matches - perform manual authentication
          try {
            // Verify the user exists in the database
            final userData = await supabase
                .from('users')
                .select('id, email, first_name, last_name, temp_password')
                .eq('id', storedUserId)
                .eq('email', email)
                .maybeSingle();

            if (userData != null && userData['temp_password'] == password) {
              // Hide loading dialog
              if (context.mounted && Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }

              // Clear temporary password data
              final updatedEmails = List<String>.from(tempPasswordEmails);
              updatedEmails.remove(email);
              await prefs.setStringList('temp_password_emails', updatedEmails);
              await prefs.remove('temp_password_$email');
              await prefs.remove('temp_user_id_$email');

              // Update user record to remove temp password
              await supabase
                  .from('users')
                  .update({
                'temp_password': null,
                'password_reset_required': null,
              })
                  .eq('id', storedUserId);

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
                  message: "You are using a temporary password. Please set a new password.",
                  isSuccess: true,
                  duration: const Duration(seconds: 3),
                );
              }

              // Navigate to Profile page to set new password
              await Future.delayed(const Duration(seconds: 2));
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              }
              return;
            }
          } catch (e) {
            print("Error in temporary password login: $e");
          }
        }

        // If temporary password login fails, show error
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        if (_mounted) {
          setState(() {
            _isLoading = false;
          });
        }

        NotificationDisplayService.showPopupNotification(
          context,
          title: "Invalid temporary password",
          message: "The temporary password is incorrect or has expired.",
          isError: true,
        );
        return;
      }

      // Normal login process with Supabase Auth
      try {
        final response = await supabase.auth.signInWithPassword(
            email: email,
            password: password
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
          await supabase.from('users').upsert({
            'id': userId,
            'email': userEmail,
          });

          // Fetch user name from database
          try {
            final userData = await supabase
                .from('users')
                .select('first_name, last_name')
                .eq('id', response.user!.id)
                .maybeSingle();

            if (userData != null) {
              final firstName = userData['first_name'] as String? ?? '';
              final lastName = userData['last_name'] as String? ?? '';
              final fullName = "$firstName $lastName".trim();

              if (fullName.isNotEmpty) {
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

          // Normal login to MainPage
          if (context.mounted) {
            Navigator.pushReplacement(context, fadeTransition(const MainPageUI()));
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
              title: "Login failed. Please check your credentials!",
              isError: true,
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
            message: "Invalid login credentials. Please check your email and password.",
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