import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../localization/app_localizations.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({Key? key}) : super(key: key);

  @override
  _NotificationSettingsPageState createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final NotificationService _notificationService = NotificationService();
  bool _announcementsEnabled = true;
  bool _eventsEnabled = true;
  bool _remindersEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    final announcementsEnabled = await _notificationService.getNotificationPreference('announcements');
    final eventsEnabled = await _notificationService.getNotificationPreference('events');
    final remindersEnabled = await _notificationService.getNotificationPreference('reminders');

    setState(() {
      _announcementsEnabled = announcementsEnabled;
      _eventsEnabled = eventsEnabled;
      _remindersEnabled = remindersEnabled;
      _isLoading = false;
    });
  }

  Future<void> _toggleNotificationType(String category, bool enabled) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _notificationService.toggleNotificationCategory(category, enabled);

      // Show confirmation message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled
                  ? AppLocalizations.of(context).translate('notifications_enabled')
                  : AppLocalizations.of(context).translate('notifications_disabled'),
            ),
            backgroundColor: enabled ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error toggling notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('error_update_settings')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('notification_settings')),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFF0B090B),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6DEEC7)))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).translate('notification_preferences'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6DEEC7),
              ),
            ),
            const SizedBox(height: 20),
            _buildNotificationToggle(
              title: AppLocalizations.of(context).translate('announcements'),
              subtitle: AppLocalizations.of(context).translate('announcements_description'),
              value: _announcementsEnabled,
              onChanged: (value) {
                setState(() {
                  _announcementsEnabled = value;
                });
                _toggleNotificationType('announcements', value);
              },
            ),
            const Divider(color: Colors.grey),
            _buildNotificationToggle(
              title: AppLocalizations.of(context).translate('events'),
              subtitle: AppLocalizations.of(context).translate('events_description'),
              value: _eventsEnabled,
              onChanged: (value) {
                setState(() {
                  _eventsEnabled = value;
                });
                _toggleNotificationType('events', value);
              },
            ),
            const Divider(color: Colors.grey),
            _buildNotificationToggle(
              title: AppLocalizations.of(context).translate('reminders'),
              subtitle: AppLocalizations.of(context).translate('reminders_description'),
              value: _remindersEnabled,
              onChanged: (value) {
                setState(() {
                  _remindersEnabled = value;
                });
                _toggleNotificationType('reminders', value);
              },
            ),
            const Divider(color: Colors.grey),
            const SizedBox(height: 30),

            // Test notification button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _sendTestNotification,
              icon: const Icon(Icons.notifications_active),
              label: Text(AppLocalizations.of(context).translate('send_test_notification')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE38C96),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: _isLoading ? null : onChanged,
            activeColor: const Color(0xFF6DEEC7),
          ),
        ],
      ),
    );
  }

  Future<void> _sendTestNotification() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _notificationService.showLocalNotification(
        title: AppLocalizations.of(context).translate('test_notification'),
        body: AppLocalizations.of(context).translate('test_notification_body'),
        channelId: 'high_importance_channel',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('notification_sent')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error sending test notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('error_sending_notification')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}