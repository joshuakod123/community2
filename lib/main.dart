import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:async';
import 'screens/splash_screen.dart';
import 'localization/app_localizations.dart';
import 'providers/language_provider.dart';
import 'services/notification_service.dart';
import 'community/providers/post_provider.dart';
import 'community/providers/comment_provider.dart';
import 'community/providers/bookmark_provider.dart';
import 'community/providers/notification_provider.dart';

// Global navigator key for accessing context from outside of widgets
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Show initial splash screen
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    ),
  );

  try {
    // Initialize Supabase first - this is critical
    await Supabase.initialize(
      url: 'https://xrcuotrkuzhwmakfncld.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhyY3VvdHJrdXpod21ha2ZuY2xkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAwMzIxMzEsImV4cCI6MjA1NTYwODEzMX0.JS22WLKMwMSGQwsNiT2YjlT-t08LlAPCvSMs7_uakh4',
    );

    // Initialize Notification Service with proper error handling
    NotificationService notificationService = NotificationService();
    try {
      await notificationService.init();
    } catch (e) {
      print("Non-critical error initializing notifications: $e");
      // Continue without notifications if there's an error
    }

    // Run the actual app after initialization
    runApp(MyApp(notificationService: notificationService));
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

class MyApp extends StatefulWidget {
  final NotificationService notificationService;

  const MyApp({
    Key? key,
    required this.notificationService,
  }) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // Schedule the setup to run after build is complete with error handling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        // Setup post expiration cleanup
        setupPostExpirationCleanup();
      } catch (e) {
        print("Non-critical error during post expiration setup: $e");
        // Continue even if this fails
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provide the notification service
        Provider<NotificationService>.value(
          value: widget.notificationService,
        ),
        ChangeNotifierProvider(
          create: (context) => LanguageProvider(),
        ),
        // Community-related providers with the new structure
        ChangeNotifierProvider(
          create: (_) => PostProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => CommentProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => BookmarkProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(),
        ),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            theme: ThemeData(primarySwatch: Colors.blue),

            // Define routes BUT remove the '/' route since we use 'home'

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

            // Use home property for the initial route
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

// Setup post expiration cleanup when app is initialized with enhanced error handling
void setupPostExpirationCleanup() {
  // Initial cleanup after app starts with a longer delay to ensure app is properly initialized
  Future.delayed(const Duration(minutes: 2), () {
    if (navigatorKey.currentContext != null) {
      try {
        final postProvider = Provider.of<PostProvider>(navigatorKey.currentContext!, listen: false);
        // Fetch once to clean up expired posts
        postProvider.fetchPosts().catchError((error) {
          print("Error during initial post cleanup: $error");
        });

        // Setup a periodic task to clean expired posts with error handling
        Timer.periodic(const Duration(hours: 6), (_) {
          if (navigatorKey.currentContext != null) {
            try {
              final postProvider = Provider.of<PostProvider>(navigatorKey.currentContext!, listen: false);
              // Fetch fresh posts (will automatically filter out expired ones)
              postProvider.fetchPosts().catchError((error) {
                print("Error during scheduled post cleanup: $error");
              });
            } catch (e) {
              print("Error during scheduled cleanup: $e");
            }
          }
        });

        print("Post expiration cleanup scheduled successfully");
      } catch (e) {
        print("Error setting up post expiration cleanup: $e");
      }
    }
  });
}