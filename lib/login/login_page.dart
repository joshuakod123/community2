import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/main_page.dart';
import '../login/register_page.dart';
import '../login/forgot_password.dart';
import '../fade_transition.dart';
import '../widgets/loading_widget.dart'; // Import our new loading widget


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
  bool _isLoading = false; // Add loading state
  bool _mounted = true; // Track if widget is mounted

  @override
  void dispose() {
    _mounted = false;
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// ✅ Handles User Login & Saves Name
  Future<void> _login() async {
    // Validate input fields
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both email and password")),
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

      final response = await supabase.auth.signInWithPassword(email: email, password: password);

      // Hide loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (!_mounted) return;

      if (response.user != null) {
        final userId = response.user!.id;
        final userEmail = response.user!.email;

        if (context.mounted) {
          LoadingWidget.show(context, message: "Setting up your account...");
        }

        // ✅ Ensure user exists in "users" table
        await supabase.from('users').upsert({
          'id': userId,
          'email': userEmail,
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('remember_me', _rememberMe);

        // ✅ Fetch user name from database
        final userData = await supabase
            .from('users')
            .select('first_name, last_name')
            .eq('id', response.user!.id)
            .single();

        // Fetch user name and handle null values safely
        if (userData != null) {
          String firstName = userData['first_name'] ?? '';
          String lastName = userData['last_name'] ?? '';
          String fullName = "$firstName $lastName".trim();
          await prefs.setString('user_name', fullName);
        }

        // Hide loading dialog
        if (context.mounted) {
          Navigator.of(context).pop();
        }

        // ✅ Proceed to MainPage
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Login failed. Please check your credentials.")),
          );
        }
      }
    } catch (error) {
      // Hide loading dialog on error
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${error.toString()}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  const Icon(Icons.school, size: 80, color: Colors.blue),
                  const SizedBox(height: 20),
                  const Text(
                      "Sign in",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 20),

                  // Email TextField
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: "Email Address"),
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_isLoading,
                  ),

                  // Password TextField
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: "Password",
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: !_isLoading
                            ? () => setState(() => _obscurePassword = !_obscurePassword)
                            : null,
                      ),
                    ),
                  ),

                  // ✅ Remember Me Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: !_isLoading
                            ? (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        }
                            : null,
                      ),
                      const Text("Remember Me"),
                    ],
                  ),

                  // ✅ Login Button
                  ElevatedButton(
                    onPressed: !_isLoading ? _login : null,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    child: const Text("Login"),
                  ),

                  const SizedBox(height: 10),

                  // ✅ Forgot Password & Register Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: !_isLoading
                            ? () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ForgotPasswordPage())
                          );
                        }
                            : null,
                        child: const Text("Forgot Password?", style: TextStyle(color: Colors.blue)),
                      ),
                      TextButton(
                        onPressed: !_isLoading
                            ? () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => RegisterPage())
                          );
                        }
                            : null,
                        child: const Text("Create Account", style: TextStyle(color: Colors.blue)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Overlay loading indicator when processing
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