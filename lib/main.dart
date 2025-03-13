import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:async';
import 'screens/splash_screen.dart'; // Import our new SplashScreen
import 'pages/loading_page.dart';
import 'localization/app_localizations.dart';
import 'providers/language_provider.dart';
import 'services/notification_service.dart'; // This is your service
import 'community/provider/board_provider.dart';
import 'community/provider/post_provider.dart';
import 'community/provider/comment_provider.dart';
import 'community/models/notification.dart'; // For the model
import 'community/provider/bookmark_provider.dart';

// Global navigator key for accessing context from outside of widgets
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Show initial splash screen
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(), // Use our custom SplashScreen here
    ),
  );

  try {
    // Initialize Supabase first - this is critical
    await Supabase.initialize(
      url: 'https://xrcuotrkuzhwmakfncld.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhyY3VvdHJrdXpod21ha2ZuY2xkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAwMzIxMzEsImV4cCI6MjA1NTYwODEzMX0.JS22WLKMwMSGQwsNiT2YjlT-t08LlAPCvSMs7_uakh4',
    );

    // After Supabase is initialized, initialize Notification Service
    final notificationService = NotificationService();
    await notificationService.init();

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

    // Schedule the setup to run after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Setup post expiration cleanup
      setupPostExpirationCleanup();
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
        // Remove this provider if Notifications isn't a provider class
        // Or update it to match your actual provider class
        // ChangeNotifierProvider(
        //   create: (_) => Notifications(Supabase.instance.client.auth.currentUser?.id, []),
        // ),
        // Add the new BookmarkProvider
        ChangeNotifierProvider(
          create: (_) => BookmarkProvider(),
        ),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            navigatorKey: navigatorKey,
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

            home: const SplashScreen(), // Start with the splash screen
          );
        },
      ),
    );
  }
}

// Setup post expiration cleanup when app is initialized
void setupPostExpirationCleanup() {
  // Initial cleanup after app starts
  Future.delayed(const Duration(minutes: 2), () {
    if (navigatorKey.currentContext != null) {
      try {
        final postsProvider = Provider.of<Posts>(navigatorKey.currentContext!, listen: false);
        postsProvider.cleanupExpiredPosts();
        postsProvider.checkAndNotifyExpiringSoon();

        // Setup a periodic task to clean expired posts
        Timer.periodic(const Duration(hours: 6), (_) {
          if (navigatorKey.currentContext != null) {
            try {
              final postsProvider = Provider.of<Posts>(navigatorKey.currentContext!, listen: false);
              postsProvider.cleanupExpiredPosts();
              postsProvider.checkAndNotifyExpiringSoon();
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