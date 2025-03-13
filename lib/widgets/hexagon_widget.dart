import 'package:flutter/material.dart';
import 'dart:math';

class HexagonWidget extends StatelessWidget {
  final VoidCallback onTap; // ✅ Change from `destinationPage` to `onTap`

  const HexagonWidget({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // ✅ Use the passed `onTap` function
      child: ClipPath(
        clipper: HexagonClipper(),
        child: Container(
          width: 80,
          height: 80,
          color: Colors.grey[400], // Hexagon background color
        ),
      ),
    );
  }
}

class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    double w = size.width;
    double h = size.height;
    double a = w / 2;
    double b = h / 4;

    return Path()
      ..moveTo(a, 0)
      ..lineTo(w, b)
      ..lineTo(w, h - b)
      ..lineTo(a, h)
      ..lineTo(0, h - b)
      ..lineTo(0, b)
      ..close();
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
