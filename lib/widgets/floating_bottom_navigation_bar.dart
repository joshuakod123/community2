// Updates for lib/widgets/floating_bottom_navigation_bar.dart

import 'package:flutter/material.dart';
import '../screens/home_page.dart';
import '../community/screen/board.dart';
import '../screens/calculate_page.dart';
import '../screens/modern_calendar_screen.dart';
import '../screens/profile_page.dart';
import '../pages/main_page.dart';
import '../localization/app_localizations.dart';

class FloatingBottomNavigationBar extends StatelessWidget {
  final int currentIndex;

  const FloatingBottomNavigationBar({
    Key? key,
    required this.currentIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the app localizations
    final appLocal = AppLocalizations.of(context);

    return Container(
      height: 70, // Made taller for better spacing
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 20), // Added margin at the bottom to create space
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavBarItem(
            context,
            0,
            Icons.home,
            appLocal.translate('home'),
            currentIndex == 0,
          ),
          _buildNavBarItem(
            context,
            1,
            Icons.forum,
            appLocal.translate('community'),
            currentIndex == 1,
          ),
          _buildNavBarItem(
            context,
            2,
            Icons.calculate,
            appLocal.translate('calculate'),
            currentIndex == 2,
          ),
          _buildNavBarItem(
            context,
            3,
            Icons.calendar_today,
            appLocal.translate('calendar'),
            currentIndex == 3,
          ),
          _buildNavBarItem(
            context,
            4,
            Icons.person,
            appLocal.translate('profile'),
            currentIndex == 4,
          ),
        ],
      ),
    );
  }

  Widget _buildNavBarItem(BuildContext context, int index, IconData icon, String label, bool isSelected) {
    return InkWell(
      onTap: () {
        if (index != currentIndex) {
          _navigateToPage(context, index);
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.blue : Colors.grey,
            size: 24,
          ),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.blue : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPage(BuildContext context, int index) {
    // Clear navigation stack and navigate to selected page
    Widget page;

    switch (index) {
      case 0:
        page = const MainPageUI();
        break;
      case 1:
        page = const BoardScreen();
        break;
      case 2:
        page = const CalculatePage(scores: {});
        break;
      case 3:
        page = const ModernCalendarScreen();
        break;
      case 4:
        page = const ProfilePage();
        break;
      default:
        page = const MainPageUI();
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => page),
          (route) => false, // Remove all previous routes
    );
  }
}