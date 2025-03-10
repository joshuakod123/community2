// lib/main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'pages/loading_page.dart';
import 'login/login_page.dart';
import 'pages/main_page.dart';
import 'pages/choose_university_screen.dart';
import 'widgets/loading_widget.dart';
import 'localization/app_localizations.dart';
import 'providers/language_provider.dart';
import 'services/notification_service.dart';
import 'community/provider/board_provider.dart';
import 'community/provider/post_provider.dart';
import 'community/provider/comment_provider.dart';
import 'community/provider/notification_provider.dart';
import 'community/provider/bookmark_provider.dart'; // New import for bookmark provider

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Show initial splash screen
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.school,
                size: 80,
                color: Colors.blueAccent,
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text("Starting up...", style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
      ),
    ),
  );

  try {
    // Initialize Supabase first - this is critical
    await Supabase.initialize(
      url: 'https://xrcuotrkuzhwmakfncld.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhyY3VvdHJrdXpod21ha2ZuY2xkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAwMzIxMzEsImV4cCI6MjA1NTYwODEzMX0.JS22WLKMwMSGQwsNiT2YjlT-t08LlAPCvSMs7_uakh4',
    );

    // After Supabase is initialized, then initialize Notification Service
    await NotificationService().init();

    // Run the actual app after initialization
    runApp(const MyApp());
  } catch (e) {
    // If initialization fails, show error screen
    print("Error initializing app: $e");
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 80, color: Colors.red),
                const SizedBox(height: 20),
                const Text(
                  "Failed to start the app",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text("Error: ${e.toString()}"),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Restart app on button press
                    main();
                  },
                  child: const Text("Retry"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => LanguageProvider(),
        ),
        // Add the community-related providers
        ChangeNotifierProvider(
          create: (_) => PostList(Supabase.instance.client),
        ),
        ChangeNotifierProvider(
          create: (_) => Posts(),
        ),
        ChangeNotifierProvider(
          create: (_) => Comments(),
        ),
        ChangeNotifierProvider(
          create: (_) => Notifications(Supabase.instance.client.auth.currentUser?.id, []),
        ),
        // Add the new BookmarkProvider
        ChangeNotifierProvider(
          create: (_) => BookmarkProvider(),
        ),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(primarySwatch: Colors.blue),

            // Localization setup
            locale: languageProvider.currentLocale,
            supportedLocales: const [
              Locale('en'), // English
              Locale('ko'), // Korean
              Locale('zh'), // Chinese
              Locale('ja'), // Japanese
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            home: LoadingPage(),
          );
        },
      ),
    );
  }
}