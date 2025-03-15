import 'package:flutter/material.dart';

class BottomBar extends StatelessWidget {
  final VoidCallback? onCalculate;

  const BottomBar({
    Key? key,
    this.onCalculate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Center(
        child: ElevatedButton(
          onPressed: onCalculate,
          child: const Text("Calculate"),
        ),
      ),
    );
  }
}
