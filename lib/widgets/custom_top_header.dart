import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomTopHeader extends StatelessWidget {
  final String userName;
  final String? profileImageUrl;

  const CustomTopHeader({
    Key? key,
    required this.userName,
    this.profileImageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get today's date in the format "Today DD MMM"
    final String formattedDate = 'Today ${DateFormat('dd MMM').format(DateTime.now())}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Image
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[300],
            backgroundImage: profileImageUrl != null
                ? NetworkImage(profileImageUrl!)
                : null,
            child: profileImageUrl == null
                ? Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : "?",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            )
                : null,
          ),
          const SizedBox(width: 12),

          // Name and Date
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $userName',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}