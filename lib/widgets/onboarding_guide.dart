import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A step in the onboarding guide
class OnboardingStep {
  final String title;
  final String description;
  final IconData icon;
  final Color? color;

  OnboardingStep({
    required this.title,
    required this.description,
    required this.icon,
    this.color,
  });
}

/// A multi-step onboarding guide overlay widget
class OnboardingGuide extends StatefulWidget {
  final Widget child;
  final List<OnboardingStep> steps;
  final String prefsKey;

  const OnboardingGuide({
    Key? key,
    required this.child,
    required this.steps,
    required this.prefsKey,
  }) : super(key: key);

  @override
  _OnboardingGuideState createState() => _OnboardingGuideState();
}

class _OnboardingGuideState extends State<OnboardingGuide> {
  bool _showGuide = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _checkIfGuideNeeded();
  }

  Future<void> _checkIfGuideNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = Supabase.instance.client.auth.currentUser;

      // Create user-specific key
      final String userKey = user != null ? '${widget.prefsKey}_user_${user.id}' : widget.prefsKey;

      // Check if guide has been shown
      final bool guideShown = prefs.getBool(userKey) ?? false;

      if (!guideShown && mounted) {
        // Allow the widget to build first, then show the guide
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _showGuide = true;
            });
          }
        });
      }
    } catch (e) {
      print('Error checking if onboarding guide is needed: $e');
    }
  }

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      _completeGuide();
    }
  }

  void _completeGuide() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = Supabase.instance.client.auth.currentUser;

      // Create user-specific key
      final String userKey = user != null ? '${widget.prefsKey}_user_${user.id}' : widget.prefsKey;

      // Mark as completed
      await prefs.setBool(userKey, true);

      if (mounted) {
        setState(() {
          _showGuide = false;
        });
      }
    } catch (e) {
      print('Error completing onboarding guide: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // If not showing guide, just render the child
    if (!_showGuide) {
      return widget.child;
    }

    final currentStep = widget.steps[_currentStep];
    final stepColor = currentStep.color ?? Theme.of(context).primaryColor;

    return Stack(
      children: [
        // The main app content
        widget.child,

        // Semi-transparent overlay
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.7),
          ),
        ),

        // Guide content
        Positioned.fill(
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Step indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.steps.length,
                          (index) => Container(
                        width: index == _currentStep ? 12 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: index == _currentStep ? stepColor : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Icon
                  Icon(
                    currentStep.icon,
                    size: 80,
                    color: stepColor,
                  ),

                  const SizedBox(height: 24),

                  // Title
                  Text(
                    currentStep.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: stepColor,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // Description
                  Text(
                    currentStep.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // Next/Finish button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: stepColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        _currentStep == widget.steps.length - 1 ? 'Got It' : 'Next',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Skip button
                  TextButton(
                    onPressed: _completeGuide,
                    child: Text(
                      'Skip Tour',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}