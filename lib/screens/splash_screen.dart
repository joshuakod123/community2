// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../pages/loading_page.dart';
import '../widgets/animated_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late Animation<Color?> _backgroundAnimation;
  late AnimationController _elementsController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Background color transition controller
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Background color animation from white to a soft blue gradient
    _backgroundAnimation = ColorTween(
      begin: Colors.white,
      end: const Color(0xFFF5F9FF),
    ).animate(_backgroundController);

    // Control text and other elements
    _elementsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Fade in animation for text
    _fadeAnimation = CurvedAnimation(
      parent: _elementsController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
    );

    // Slide up animation for text
    _slideAnimation = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(
        parent: _elementsController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    // Start animations
    _backgroundController.forward();

    // Delay starting the elements animation
    Future.delayed(const Duration(milliseconds: 500), () {
      _elementsController.forward();
    });

    // Navigate to LoadingPage after delay
    Timer(const Duration(milliseconds: 3000), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LoadingPage()),
      );
    });
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _elementsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, _) {
        return Scaffold(
          body: Container(
            width: size.width,
            height: size.height,
            decoration: BoxDecoration(
              color: _backgroundAnimation.value,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _backgroundAnimation.value ?? Colors.white,
                  const Color(0xFFE6F0FF),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Custom logo or directly using an Image
                  // Using direct Image.asset with larger size
                  Image.asset(
                    'assets/images/only_pass_logo.png',
                    height: 180, // Increased from 150
                    width: 180,  // Increased from 150
                  ),

                  const SizedBox(height: 40),

                  // App name with fade and slide animation
                  AnimatedBuilder(
                    animation: _elementsController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: Transform.translate(
                          offset: Offset(0, _slideAnimation.value),
                          child: const Text(
                            "ONLY PASS",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4A78DB),
                              letterSpacing: 3.0,
                              shadows: [
                                Shadow(
                                  blurRadius: 10.0,
                                  color: Color(0x664A78DB),
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Tagline with fade and slide animation
                  AnimatedBuilder(
                    animation: _elementsController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: Transform.translate(
                          offset: Offset(0, _slideAnimation.value),
                          child: const Text(
                            "Start your journey to success",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF5E6C85),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}