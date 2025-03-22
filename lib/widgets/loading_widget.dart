import 'package:flutter/material.dart';

/// A reusable loading widget to show loading states across the app
class LoadingWidget extends StatelessWidget {
  final String? message;
  final Color backgroundColor;
  final Color indicatorColor;
  final Color textColor;

  const LoadingWidget({
    Key? key,
    this.message,
    this.backgroundColor = Colors.white,
    this.indicatorColor = Colors.blueAccent,
    this.textColor = Colors.black87,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school,
              size: 80,
              color: indicatorColor,
            ),
            const SizedBox(height: 20),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
            ),
            if (message != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  message!,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Show a loading dialog with the given message
  static void show(BuildContext context, {String? message}) {
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.white,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(message ?? "Please wait...", style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  /// Hide any showing loading dialog
  static void hide(BuildContext context) {
    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}

/// A fullscreen loading page with app branding
class LoadingScreenWidget extends StatelessWidget {  // Renamed from LoadingPage
final String? message;

const LoadingScreenWidget({  // Constructor name updated
Key? key,
this.message,
}) : super(key: key);

@override
Widget build(BuildContext context) {
return Scaffold(
body: LoadingWidget(
message: message ?? "Loading...",
),
);
}
}