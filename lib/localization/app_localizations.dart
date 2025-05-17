import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  Map<String, String> _localizedStrings = {};
  static Map<String, String> _fallbackStrings = {}; // For fallback to English

  AppLocalizations(this.locale);

  // Helper method to keep the code in the widgets concise
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  // Static member to have a simple access to the delegate from the MaterialApp
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  Future<bool> load() async {
    try {
      // Load English as fallback if not already loaded
      if (_fallbackStrings.isEmpty && locale.languageCode != 'en') {
        String fallbackJsonString = await rootBundle.loadString('assets/lang/en.json');
        Map<String, dynamic> fallbackJsonMap = json.decode(fallbackJsonString);
        _fallbackStrings = fallbackJsonMap.map((key, value) {
          return MapEntry(key, value.toString());
        });
      }

      // Load the language JSON file from the "lang" folder
      String jsonString = await rootBundle.loadString('assets/lang/${locale.languageCode}.json');
      Map<String, dynamic> jsonMap = json.decode(jsonString);

      _localizedStrings = jsonMap.map((key, value) {
        return MapEntry(key, value.toString());
      });

      return true;
    } catch (e) {
      print('Error loading language file: ${locale.languageCode} - $e');

      // In case of error, use fallback or an empty map
      if (locale.languageCode != 'en' && _fallbackStrings.isNotEmpty) {
        _localizedStrings = _fallbackStrings;
      } else {
        _localizedStrings = {};
      }

      return false;
    }
  }

  // This method will be called from every widget that needs a localized text
  String translate(String key) {
    // First try the current language
    if (_localizedStrings.containsKey(key)) {
      return _localizedStrings[key]!;
    }

    // If not found, try the fallback language
    if (_fallbackStrings.containsKey(key)) {
      return _fallbackStrings[key]!;
    }

    // If all else fails, return the key
    return key;
  }
}

// LocalizationsDelegate is a factory for a set of localized resources
class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  // This delegate instance will never change
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // Include all of your supported language codes here
    return ['en', 'ko', 'zh', 'ja'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    // AppLocalizations class is where the JSON loading actually runs
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}