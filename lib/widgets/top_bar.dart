import 'package:flutter/material.dart';

class TopBar extends StatelessWidget {
  final String title;
  final VoidCallback? onBackPressed;

  const TopBar({
    Key? key,
    required this.title,
    this.onBackPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor: Colors.black,
      iconTheme: const IconThemeData(color: Colors.white),
      leading: onBackPressed != null
          ? IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBackPressed,
      )
          : null,
    );
  }
}