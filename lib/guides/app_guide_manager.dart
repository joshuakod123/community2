import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'first_login_guide.dart';
import 'focused_element_guide.dart';

/// A class that manages the sequence of all onboarding guides
class AppGuideManager {
  static const String _firstLoginGuideKey = 'first_login_guide_completed';
  static const String _featureGuideKeyPrefix = 'feature_guide_completed_';

  /// Main entry point - call this when user logs in or app starts
  static Future<void> showGuidesIfNeeded(BuildContext context) async {
    // First check if the welcome guide has been shown
    final bool welcomeGuideCompleted = await _isGuideCompleted(_firstLoginGuideKey);

    if (!welcomeGuideCompleted && context.mounted) {
      // Show welcome guide first
      await FirstLoginGuide.show(context);

      // After welcome guide is dismissed, start showing feature guides
      // We don't await this because it will manage its own sequence
      if (context.mounted) {
        _showFeatureGuidesSequentially(context);
      }
    } else {
      // If welcome guide already shown, check if any feature guides need to be shown
      _showFeatureGuidesSequentially(context);
    }
  }

  /// Shows a sequence of feature-specific guides in order
  static Future<void> _showFeatureGuidesSequentially(BuildContext context) async {
    // Define the sequence of feature guides to show
    final List<FeatureGuideConfig> guideSequence = [
      FeatureGuideConfig(
        featureKey: 'community_board',
        title: 'Community Board',
        description: 'Connect with other students, ask questions, and share your journey with the community.',
      ),
      FeatureGuideConfig(
        featureKey: 'calendar',
        title: 'Calendar',
        description: 'Keep track of important dates and deadlines for your university applications.',
      ),
      FeatureGuideConfig(
        featureKey: 'scores',
        title: 'Track Your Scores',
        description: 'Enter your test scores and see how they compare to admission requirements.',
      ),
    ];

    // Show guides in sequence
    for (final guide in guideSequence) {
      final bool guideCompleted = await _isGuideCompleted('${_featureGuideKeyPrefix}${guide.featureKey}');

      if (!guideCompleted && context.mounted) {
        // Find the target element in the UI
        final RenderBox? renderBox = _findTargetRenderBox(context, guide.featureKey);

        if (renderBox != null && context.mounted) {
          final Offset position = renderBox.localToGlobal(Offset.zero);
          final Size size = renderBox.size;

          // Show the guide and wait for it to be dismissed
          await FocusedElementGuide.show(
            context,
            targetPosition: position,
            targetSize: size,
            title: guide.title,
            description: guide.description,
            featureKey: guide.featureKey,
            isCircular: guide.isCircular,
          );
        }
      }

      // Break if context is no longer mounted
      if (!context.mounted) break;
    }
  }

  /// Helper to find target elements in the UI
  static RenderBox? _findTargetRenderBox(BuildContext context, String featureKey) {
    return GuideHelper.findTargetByKey(context, featureKey);
  }

  /// Check if a guide has been completed
  static Future<bool> _isGuideCompleted(String guideKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = Supabase.instance.client.auth.currentUser;

      // Create user-specific key
      final String userKey = user != null ? '${guideKey}_user_${user.id}' : guideKey;

      return prefs.getBool(userKey) ?? false;
    } catch (e) {
      debugPrint('Error checking guide completion: $e');
      return false;
    }
  }

  /// Mark a guide as completed
  static Future<void> markGuideCompleted(String guideKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = Supabase.instance.client.auth.currentUser;

      // Create user-specific key
      final String userKey = user != null ? '${guideKey}_user_${user.id}' : guideKey;

      await prefs.setBool(userKey, true);
    } catch (e) {
      debugPrint('Error marking guide as completed: $e');
    }
  }

  /// Reset all guides for testing purposes
  static Future<void> resetAllGuides() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.contains('guide_completed')) {
          await prefs.remove(key);
        }
      }

      debugPrint('All guides have been reset');
    } catch (e) {
      debugPrint('Error resetting guides: $e');
    }
  }
}

/// Configuration for a feature-specific guide
class FeatureGuideConfig {
  final String featureKey;
  final String title;
  final String description;
  final bool isCircular;

  FeatureGuideConfig({
    required this.featureKey,
    required this.title,
    required this.description,
    this.isCircular = false,
  });
}

/// Helper class to find UI elements for guides
class GuideHelper {
  // Helper method to find UI elements by key
  static RenderBox? findTargetByKey(BuildContext context, String featureKey) {
    final mainPageElement = MainPageGuideHelper.findMainPageElement(context, featureKey);
    if (mainPageElement != null) {
      return mainPageElement;
    }

    // Add additional element finding logic for other pages if needed

    return null;
  }
}

/// Helper class to find UI elements in MainPageUI
class MainPageGuideHelper {
  static RenderBox? findMainPageElement(BuildContext context, String featureKey) {
    // This method would be implemented in your main_page.dart file
    // and would return the RenderBox of the element with the matching key

    // For now, return null - will be implemented in the main page
    return null;
  }
}