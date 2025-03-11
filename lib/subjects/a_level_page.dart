import 'package:flutter/material.dart';

class ALevelPage extends StatelessWidget {
  const ALevelPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("A-Level Page")),
      body: const Center(
        child: Text("A-Level Content Here"),
      ),
    );
  }
}

