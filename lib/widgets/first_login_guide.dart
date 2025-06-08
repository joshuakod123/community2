// lib/widgets/first_login_guide.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirstLoginGuide {
  static const String _firstLoginKey = 'first_login_guide_shown';

  /// Shows the first-time login welcome guide if it hasn't been shown before
  static Future<void> showIfNeeded(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyShown = prefs.getBool(_firstLoginKey) ?? false;

    if (alreadyShown) return;

    // Mark as shown for next time
    await prefs.setBool(_firstLoginKey, true);

    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _WelcomeGuideDialog(),
      );
    }
  }
}

class _WelcomeGuideDialog extends StatefulWidget {
  @override
  _WelcomeGuideDialogState createState() => _WelcomeGuideDialogState();
}

class _WelcomeGuideDialogState extends State<_WelcomeGuideDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Logo or Welcome Image
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF536878), // Payne's Grey
              ),
              child: const Icon(
                Icons.school,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Page Title
            const Text(
              'Welcome to ONLY PASS',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF536878), // Payne's Grey
              ),
            ),
            const SizedBox(height: 12),

            // Page Content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildPageContent(
                    icon: Icons.track_changes,
                    title: 'Track Your Progress',
                    description: 'Our app helps you track your academic journey and visualize your progress toward your dream university.',
                  ),
                  _buildPageContent(
                    icon: Icons.hexagon_outlined,
                    title: 'Interactive Elements',
                    description: 'Use the hexagons to navigate through various sections. Each hexagon represents a different step in your academic journey.',
                  ),
                  _buildPageContent(
                    icon: Icons.people,
                    title: 'Join Our Community',
                    description: 'Connect with fellow students, ask questions, and share experiences in our community section.',
                  ),
                ],
              ),
            ),

            // Page Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _totalPages,
                    (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? const Color(0xFF536878) // Active dot color
                        : Colors.grey.shade300, // Inactive dot color
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Navigation Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Skip',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _totalPages - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF536878), // Payne's Grey
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(
                    _currentPage < _totalPages - 1 ? 'Next' : 'Get Started',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageContent({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 60,
            color: const Color(0xFF536878), // Payne's Grey
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF536878), // Payne's Grey
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}