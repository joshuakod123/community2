import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/main_page.dart';
import '../login/login_page.dart';
import 'animated_logo.dart';

/// A reusable loading widget to show loading states across the app
class LoadingWidget extends StatelessWidget {
  final String? message;
  final Color backgroundColor;
  final Color indicatorColor;
  final Color textColor;

  const LoadingWidget({
    Key? key,
    this.message,
    this.backgroundColor = Colors.white,
    this.indicatorColor = Colors.blueAccent,
    this.textColor = Colors.black87,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school,
              size: 80,
              color: indicatorColor,
            ),
            const SizedBox(height: 20),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
            ),
            if (message != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  message!,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Show a loading dialog with the given message
  static void show(BuildContext context, {String? message}) {
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.white,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(message ?? "Please wait...", style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  /// Hide any showing loading dialog
  static void hide(BuildContext context) {
    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}

/// A fullscreen loading page with app branding
class LoadingScreenWidget extends StatelessWidget {
  final String? message;

  const LoadingScreenWidget({
    Key? key,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LoadingWidget(
        message: message ?? "Loading...",
      ),
    );
  }
}

/// A dedicated loading page that handles auth checking and navigation
class LoadingPage extends StatefulWidget {
  @override
  _LoadingPageState createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> with TickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  String _loadingMessage = "Initializing...";
  bool _isLoading = true;

  // Add animation controllers
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  late AnimationController _messageController;
  late Animation<double> _messageFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Set up progress animation
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOut,
      ),
    );

    // Set up message animation
    _messageController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _messageFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _messageController,
        curve: Curves.easeOut,
      ),
    );

    // Start progress animation
    _progressController.forward();

    // Delayed to allow the widget to be built before navigation
    Future.delayed(Duration.zero, () {
      _checkAuth();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    try {
      // Update message with animation
      _updateLoadingMessage("Checking authentication...");

      // Simulated loading for at least 2 seconds for a better user experience
      await Future.delayed(const Duration(seconds: 2));

      final session = _supabase.auth.currentSession;

      // Check if session is valid and not expired
      if (session != null && session.user != null) {
        // Update message with animation
        _updateLoadingMessage("Loading your profile...");

        // Additional delay for visual effect
        await Future.delayed(const Duration(milliseconds: 800));

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

  void _updateLoadingMessage(String newMessage) {
    // Start fade out
    _messageController.forward().then((_) {
      setState(() {
        _loadingMessage = newMessage;
      });
      // Reset and fade in the new message
      _messageController.reset();
    });
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
            colors: [Color(0xFFF5F9FF), Color(0xFFE6F0FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated ONLY PASS logo with floating effect
              AnimatedLogo(
                logoPath: 'assets/images/only_pass_logo.png',
                size: 120,
              ),

              const SizedBox(height: 30),

              Text(
                "Welcome to ONLY PASS",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4A78DB),
                  letterSpacing: 1.0,
                  shadows: [
                    Shadow(
                      blurRadius: 5.0,
                      color: const Color(0xFF4A78DB).withOpacity(0.3),
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 50),

              // Custom animated progress indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) {
                    return Column(
                      children: [
                        // Progress bar
                        Container(
                          height: 6,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _progressAnimation.value,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF4A78DB), Color(0xFF6AC3E9)],
                                ),
                                borderRadius: BorderRadius.circular(3),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4A78DB).withOpacity(0.3),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Loading message with fade animation
                        AnimatedBuilder(
                          animation: _messageController,
                          builder: (context, child) {
                            return Opacity(
                              opacity: 1.0 - _messageFadeAnimation.value,
                              child: Text(
                                _loadingMessage,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF5E6C85),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}