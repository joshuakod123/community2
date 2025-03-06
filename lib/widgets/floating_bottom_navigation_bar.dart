import 'package:flutter/material.dart';
import 'package:experiment3/pages/main_page.dart';

class FloatingBottomNavigationBar extends StatelessWidget {
  final int currentIndex;

  const FloatingBottomNavigationBar({
    Key? key,
    required this.currentIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, 0, Icons.home, "Home"),
              _buildNavItem(context, 1, Icons.forum, "Community"),
              _buildNavItem(context, 2, Icons.calculate, "Calculate"),
              _buildNavItem(context, 3, Icons.calendar_today, "Calendar"),
              _buildNavItem(context, 4, Icons.person, "Profile"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label) {
    final bool isSelected = index == currentIndex;

    return InkWell(
      onTap: () {
        if (index != currentIndex) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainPageUI(),
            ),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}