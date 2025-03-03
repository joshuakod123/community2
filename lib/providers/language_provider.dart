import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  Locale _currentLocale = const Locale('en');
  static const String LANGUAGE_CODE = 'languageCode';

  Locale get currentLocale => _currentLocale;

  LanguageProvider() {
    _loadSavedLanguage();
  }

  _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    String languageCode = prefs.getString(LANGUAGE_CODE) ?? 'en';
    _currentLocale = Locale(languageCode);
    notifyListeners();
  }

  void changeLanguage(Locale newLocale) async {
    if (newLocale == _currentLocale) return;

    _currentLocale = newLocale;

    // Save selected language preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(LANGUAGE_CODE, newLocale.languageCode);

    notifyListeners();
  }

  // Get language name to display in UI
  String getDisplayLanguage() {
    switch (_currentLocale.languageCode) {
      case 'en':
        return 'English';
      case 'ko':
        return '한국어';
      case 'zh':
        return '中文';
      case 'ja':
        return '日本語';
      default:
        return 'English';
    }
  }
}