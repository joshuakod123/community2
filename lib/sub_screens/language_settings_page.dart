import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../localization/app_localizations.dart';

class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('language')),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFF0B090B),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).translate('language'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6DEEC7),
              ),
            ),
            const SizedBox(height: 20),

            _buildLanguageOption(
              context,
              'English',
              const Locale('en'),
              languageProvider,
            ),

            _buildLanguageOption(
              context,
              '한국어 (Korean)',
              const Locale('ko'),
              languageProvider,
            ),

            _buildLanguageOption(
              context,
              '中文 (Chinese)',
              const Locale('zh'),
              languageProvider,
            ),

            _buildLanguageOption(
              context,
              '日本語 (Japanese)',
              const Locale('ja'),
              languageProvider,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
      BuildContext context,
      String language,
      Locale locale,
      LanguageProvider provider,
      ) {
    final isSelected = provider.currentLocale.languageCode == locale.languageCode;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFAF95C6) : Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        title: Text(
          language,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Colors.white)
            : null,
        onTap: () async {
          await provider.changeLanguage(locale);
          if (context.mounted) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}