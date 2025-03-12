import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main_page.dart';
import '../login/login_page.dart';

class LoadingPage extends StatefulWidget {
  @override
  _LoadingPageState createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  final _supabase = Supabase.instance.client;
  String _loadingMessage = "Initializing...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Delayed to allow the widget to be built before navigation
    Future.delayed(Duration.zero, () {
      _checkAuth();
    });
  }

  Future<void> _checkAuth() async {
    try {
      setState(() {
        _loadingMessage = "Checking authentication...";
      });

      // Simulated loading for at least 2 seconds for a better user experience
      await Future.delayed(const Duration(seconds: 2));

      final session = _supabase.auth.currentSession;

      // Check if session is valid and not expired
      if (session != null && session.user != null) {
        setState(() {
          _loadingMessage = "Loading your profile...";
        });

        // Navigate to MainPage if authenticated
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => MainPageUI())
        );
      } else {
        setState(() {
          _isLoading = false;
        });

        // Navigate to LoginPage if not authenticated
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => LoginPage())
        );
      }
    } catch (error) {
      print("Error during authentication check: $error");

      setState(() {
        _isLoading = false;
      });

      // Navigate to LoginPage on error
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginPage())
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school,
              size: 100,
              color: Colors.blueAccent,
            ),
            SizedBox(height: 20),
            Text(
              "Welcome to My App",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(_loadingMessage, style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}