import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/choose_university_screen.dart';
import '../fade_transition.dart';
import '../widgets/loading_widget.dart'; // Import our new loading widget

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
  bool _agreeToTerms = false;
  bool _isLoading = false;

  Future<void> _signUp() async {
    // Validate input fields
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    // Check password match
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    // Check terms agreement
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please accept Terms & Conditions")),
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


      // ✅ Sign up user
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;

      if (user != null) {
        // Update loading message
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(); // Pop current dialog
        }
        LoadingWidget.show(context, message: "Setting up your profile...");

        // ✅ Wait for the user to be inserted in `users` table by the trigger
        await Future.delayed(const Duration(seconds: 2));

        // ✅ Ensure the user's details are updated in `users` table
        await _supabase
            .from('users')
            .update({'first_name': firstName, 'last_name': lastName})
            .eq('id', user.id);

        // Hide loading dialog
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // ✅ Redirect to Choose University Screen
        Navigator.pushReplacement(context, fadeTransition(ChooseUniversityScreen()));
      } else {
        // Hide loading dialog on error
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        setState(() {
          _isLoading = false;
        });

        throw Exception("User creation failed, user is null");
      }
    } catch (error) {
      // Hide loading dialog on error
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${error.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
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
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  const Icon(Icons.school, size: 80, color: Colors.blue),
                  const SizedBox(height: 20),
                  const Text(
                      "Create Account",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(labelText: "First Name"),
                    enabled: !_isLoading,
                  ),
                  TextField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(labelText: "Last Name"),
                    enabled: !_isLoading,
                  ),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: "Email Address"),
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_isLoading,
                  ),
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
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    enabled: !_isLoading,
                    decoration: const InputDecoration(labelText: "Confirm Password"),
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: _agreeToTerms,
                        onChanged: !_isLoading
                            ? (value) => setState(() => _agreeToTerms = value ?? false)
                            : null,
                      ),
                      const Expanded(child: Text("I accept Terms & Privacy Policy")),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: !_isLoading ? _signUp : null,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    child: const Text("Sign Up"),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account?"),
                      TextButton(
                        onPressed: !_isLoading ? () => Navigator.pop(context) : null,
                        child: const Text("Login here", style: TextStyle(color: Colors.blue)),
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