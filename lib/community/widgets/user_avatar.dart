// lib/community/widgets/user_avatar.dart
import 'package:flutter/material.dart';
import '../utils/string_helpers.dart';
import '../utils/ui_helpers.dart';

class UserAvatar extends StatelessWidget {
  final String userId;
  final String? displayName;
  final double size;
  final VoidCallback? onTap;

  const UserAvatar({
    Key? key,
    required this.userId,
    this.displayName,
    this.size = 40,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String name = displayName ?? 'User';
    final initials = StringHelpers.getInitials(name);
    final avatarColor = UIHelpers.getColorFromString(userId);

    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: avatarColor,
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }
}