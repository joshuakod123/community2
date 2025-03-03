import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Use late to defer initialization of the Supabase client
  late final SupabaseClient _supabase;

  // Channel IDs
  final String _highImportanceChannelId = 'high_importance_channel';
  final String _eventsChannelId = 'events_channel';
  final String _remindersChannelId = 'reminders_channel';

  Future<void> init() async {
    // Initialize Supabase client here to ensure Supabase.initialize() was called first
    _supabase = Supabase.instance.client;

    // Initialize timezone data for scheduled notifications
    tz_data.initializeTimeZones();

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Define notification channels for Android
    await _createNotificationChannels();

    // Start checking for notifications from Supabase
    _setupNotificationPolling();
  }

  // Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    // Properly cast to the correct type
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
    _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // High importance channel for critical notifications
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'high_importance_channel',
          'High Importance Notifications',
          description: 'This channel is used for important notifications.',
          importance: Importance.high,
          enableVibration: true,
          enableLights: true,
        ),
      );

      // Events channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'events_channel',
          'Event Notifications',
          description: 'This channel is used for event notifications.',
          importance: Importance.high,
        ),
      );

      // Reminders channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'reminders_channel',
          'Reminder Notifications',
          description: 'This channel is used for reminder notifications.',
          importance: Importance.high,
        ),
      );
    }
  }

  void _setupNotificationPolling() {
    // Poll every 15 minutes for new notifications from Supabase
    Future.delayed(const Duration(minutes: 15), () async {
      await _checkForNewNotifications();
      _setupNotificationPolling(); // Recursively setup next poll
    });
  }

  Future<void> _checkForNewNotifications() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final prefs = await SharedPreferences.getInstance();
      final lastChecked = prefs.getString('last_notification_check') ??
          DateTime.now().subtract(const Duration(days: 1)).toIso8601String();

      // Get notifications from after the last check time
      final response = await _supabase
          .from('notifications')
          .select()
          .gt('created_at', lastChecked)
          .order('created_at');

      if (response.isNotEmpty) {
        for (final notification in response) {
          // Check if the user's preferences allow this notification
          final category = notification['category'] ?? 'announcements';
          if (await _shouldShowNotification(category)) {
            await showLocalNotification(
              title: notification['title'] ?? 'New Notification',
              body: notification['body'] ?? '',
              channelId: _getChannelIdForCategory(category),
              payload: notification['id'].toString(),
            );
          }
        }
      }

      // Update the last checked time
      await prefs.setString('last_notification_check', DateTime.now().toIso8601String());
    } catch (e) {
      print('Error checking for notifications: $e');
    }
  }

  String _getChannelIdForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'events':
        return _eventsChannelId;
      case 'reminders':
        return _remindersChannelId;
      case 'announcements':
      default:
        return _highImportanceChannelId;
    }
  }

  Future<bool> _shouldShowNotification(String category) async {
    final prefs = await SharedPreferences.getInstance();
    switch (category.toLowerCase()) {
      case 'events':
        return prefs.getBool('events_notifications') ?? true;
      case 'reminders':
        return prefs.getBool('reminders_notifications') ?? true;
      case 'announcements':
      default:
        return prefs.getBool('announcements_notifications') ?? true;
    }
  }

  // Handle notification response (when a notification is tapped)
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped with payload: ${response.payload}');

    // Here you would handle navigation based on the notification payload
    // For example, navigate to the specific event details page
  }

  // Method to show a local notification
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String channelId = 'high_importance_channel',
    String? payload,
  }) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      channelId,
      channelId == 'events_channel' ? 'Event Notifications' :
      channelId == 'reminders_channel' ? 'Reminder Notifications' :
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    final NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotifications.show(
      DateTime.now().millisecond, // Use current time millisecond as a unique ID
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // Toggle notification category
  Future<void> toggleNotificationCategory(String category, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${category.toLowerCase()}_notifications', enabled);
  }

  // Get notification preference
  Future<bool> getNotificationPreference(String category) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('${category.toLowerCase()}_notifications') ?? true;
  }

  // Schedule notification for future event
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    String channelId = 'events_channel',
    String? payload,
  }) async {
    final int id = DateTime.now().millisecond;

    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId == 'events_channel' ? 'Event Notifications' :
          channelId == 'reminders_channel' ? 'Reminder Notifications' :
          'High Importance Notifications',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );

    print('Scheduled notification for ${scheduledDate.toString()}');
  }

  // Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Clear any stored notification data on logout
  Future<void> clearTokenOnLogout() async {
    // Simply clear notification preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_notification_check');
    // We don't need to do anything else since we're not using FCM
  }
}