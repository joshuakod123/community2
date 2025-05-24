import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../localization/app_localizations.dart';
import 'language_settings_page.dart';
import 'notification_settings_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final appLocal = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          appLocal.translate('settings'),
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appLocal.translate('settings'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6DEEC7),
              ),
            ),
            const SizedBox(height: 20),

            // Language Settings
            _buildSettingsOption(
              context: context,
              title: appLocal.translate('language'),
              subtitle: languageProvider.getDisplayLanguage(),
              icon: Icons.language,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LanguageSettingsPage()),
                );
              },
            ),

            const Divider(color: Colors.grey),

            // Notification Settings
            _buildSettingsOption(
              context: context,
              title: appLocal.translate('notifications'),
              subtitle: appLocal.translate('manage_notifications'),
              icon: Icons.notifications,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationSettingsPage()),
                );
              },
            ),

            const Divider(color: Colors.grey),

            // About Settings
            _buildSettingsOption(
              context: context,
              title: appLocal.translate('about'),
              subtitle: appLocal.translate('app_info'),
              icon: Icons.info_outline,
              onTap: () {
                _showAboutDialog(context);
              },
            ),

            const Divider(color: Colors.grey),

            // Help & Support
            _buildSettingsOption(
              context: context,
              title: appLocal.translate('help_support'),
              subtitle: appLocal.translate('get_help'),
              icon: Icons.help_outline,
              onTap: () {
                _showHelpDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: const Color(0xFF6DEEC7),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final appLocal = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            appLocal.translate('about'),
            style: const TextStyle(color: Color(0xFF6DEEC7)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${appLocal.translate('app_name')}: OnlyPass",
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 8),
              Text(
                "${appLocal.translate('version')}: 1.0.0",
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 8),
              Text(
                appLocal.translate('about_description'),
                style: const TextStyle(color: Colors.black),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                appLocal.translate('close'),
                style: const TextStyle(color: Color(0xFFE38C96)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showHelpDialog(BuildContext context) {
    final appLocal = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            appLocal.translate('help_support'),
            style: const TextStyle(color: Color(0xFF6DEEC7)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appLocal.translate('contact_email'),
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 8),
              const Text(
                "shuajo222@gmail.com",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                appLocal.translate('help_description'),
                style: const TextStyle(color: Colors.black),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                appLocal.translate('close'),
                style: const TextStyle(color: Color(0xFFE38C96)),
              ),
            ),
          ],
        );
      },
    );
  }
}
