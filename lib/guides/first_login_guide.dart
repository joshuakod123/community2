import 'package:flutter/material.dart';
import 'app_guide_manager.dart';

/// Welcome guide shown on first login
class FirstLoginGuide {
  static const String _prefsKey = 'first_login_guide_completed';

  /// Show the first login guide as a modal bottom sheet
  static Future<void> show(BuildContext context) async {
    if (!context.mounted) return;

    // Show the guide
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => const _FirstLoginGuideContent(),
    );

    // Mark as completed
    await AppGuideManager.markGuideCompleted(_prefsKey);
  }
}

class _FirstLoginGuideContent extends StatefulWidget {
  const _FirstLoginGuideContent();

  @override
  _FirstLoginGuideContentState createState() => _FirstLoginGuideContentState();
}

class _FirstLoginGuideContentState extends State<_FirstLoginGuideContent> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _steps = [
    {
      'title': 'Welcome to OnlyPass!',
      'description': 'Your all-in-one app for tracking your university admission journey.',
      'image': 'assets/images/only_pass_logo.png',
      'color': Colors.blue.shade700,
    },
    {
      'title': 'Track Your Progress',
      'description': 'Enter your test scores and see your admission probability in real-time.',
      'icon': Icons.insert_chart,
      'color': Colors.purple.shade700,
    },
    {
      'title': 'Join the Community',
      'description': 'Connect with other students and share your journey together.',
      'icon': Icons.people,
      'color': Colors.amber.shade700,
    },
    {
      'title': 'Stay Organized',
      'description': 'Use the calendar to track important deadlines and events.',
      'icon': Icons.calendar_today,
      'color': Colors.green.shade700,
    },
    {
      'title': 'You\'re All Set!',
      'description': 'Tap the button below to start your journey to success.',
      'icon': Icons.school,
      'color': Colors.red.shade700,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle bar at top
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(5),
            ),
          ),

          // Page view with steps
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _steps.length,
              itemBuilder: (context, index) {
                final step = _steps[index];
                return _buildStepContent(step);
              },
            ),
          ),

          // Bottom navigation
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Page indicator
                Row(
                  children: List.generate(
                    _steps.length,
                        (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: _currentPage == index ? 16 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? _steps[_currentPage]['color']
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

                // Next/Finish button
                ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _steps[_currentPage]['color'],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    _currentPage == _steps.length - 1 ? 'Get Started' : 'Next',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(Map<String, dynamic> step) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image or Icon
          if (step.containsKey('image'))
            Image.asset(
              step['image'],
              height: 120,
              width: 120,
            )
          else if (step.containsKey('icon'))
            Icon(
              step['icon'],
              size: 100,
              color: step['color'],
            ),

          const SizedBox(height: 40),

          // Title
          Text(
            step['title'],
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: step['color'],
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // Description
          Text(
            step['description'],
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}