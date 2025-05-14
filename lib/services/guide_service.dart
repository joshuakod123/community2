// lib/services/guide_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/first_login_guide.dart';
import '../widgets/journey_section_guide.dart';
import '../widgets/hexagon_guide.dart';
import '../widgets/focused_element_guide.dart';

/// A service to manage all user guides across the app
class GuideService {
  // Singleton pattern
  static final GuideService _instance = GuideService._internal();
  factory GuideService() => _instance;
  GuideService._internal();

  // Status keys for different guides
  static const String _firstLoginShownKey = 'first_login_guide_shown';
  static const String _allGuidesCompletedKey = 'all_guides_completed';

  /// Initialize and show guides in a coordinated sequence
  Future<void> initializeGuides(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    // Check if this is a first-time user
    final isFirstLogin = !(prefs.getBool(_firstLoginShownKey) ?? false);

    // Check if all guides have been completed
    final allGuidesCompleted = prefs.getBool(_allGuidesCompletedKey) ?? false;

    if (allGuidesCompleted) {
      // User has seen all guides, do nothing
      return;
    }

    if (isFirstLogin) {
      // Set first login shown
      await prefs.setBool(_firstLoginShownKey, true);

      // Show welcome guide first
      if (context.mounted) {
        await FirstLoginGuide.showIfNeeded(context);
      }
    }
  }

  /// Reset all guide states (for testing)
  Future<void> resetAllGuides() async {
    final prefs = await SharedPreferences.getInstance();

    // Reset all guide status keys
    await prefs.setBool(_firstLoginShownKey, false);
    await prefs.setBool(_allGuidesCompletedKey, false);
    await prefs.setBool('journey_section_guide_shown', false);
    await prefs.setBool('hexagon_guide_shown', false);
    await prefs.setBool('bottom_nav_guide_shown', false);
    await prefs.setBool('community_guide_shown', false);

    debugPrint('All guides have been reset');
  }

  /// Show a sequence of guides for the main page
  Future<void> showMainPageGuides(
      BuildContext context, {
        required GlobalKey journeyKey,
        required GlobalKey hexagonKey,
        required GlobalKey communityCardKey,
        required GlobalKey bottomNavHomeKey,
      }) async {
    // Wait to make sure UI is fully rendered
    await Future.delayed(const Duration(milliseconds: 500));

    // Show journey section guide
    if (context.mounted && journeyKey.currentContext != null) {
      final RenderBox box = journeyKey.currentContext!.findRenderObject() as RenderBox;
      final position = box.localToGlobal(Offset.zero);
      final size = box.size;

      await FocusedElementGuide.showIfNeeded(
        context,
        targetPosition: position,
        targetSize: size,
        title: 'Your Academic Journey',
        description: 'Track your progress toward your dream university. View your target school and major here.',
        prefsKey: 'journey_guide_shown',
      );
    }

    // Wait before showing next guide
    await Future.delayed(const Duration(seconds: 1));

    // Show hexagon guide if context still mounted
    if (context.mounted && hexagonKey.currentContext != null) {
      await HexagonGuide.showIfNeeded(context, hexagonKey);
    }

    // Wait before showing next guide
    await Future.delayed(const Duration(seconds: 1));

    // Show community card guide
    if (context.mounted && communityCardKey.currentContext != null) {
      final RenderBox box = communityCardKey.currentContext!.findRenderObject() as RenderBox;
      final position = box.localToGlobal(Offset.zero);
      final size = box.size;

      await FocusedElementGuide.showIfNeeded(
        context,
        targetPosition: position,
        targetSize: size,
        title: 'Community Board',
        description: 'Connect with other students, ask questions, and share your journey with the community.',
        prefsKey: 'community_guide_shown',
      );
    }

    // Wait before showing next guide
    await Future.delayed(const Duration(seconds: 1));

    // Show bottom navigation guide
    if (context.mounted && bottomNavHomeKey.currentContext != null) {
      final RenderBox box = bottomNavHomeKey.currentContext!.findRenderObject() as RenderBox;
      final position = box.localToGlobal(Offset.zero);
      final size = box.size;

      await FocusedElementGuide.showIfNeeded(
        context,
        targetPosition: position,
        targetSize: size,
        title: 'Navigation',
        description: 'Use these buttons to navigate between main sections of the app.',
        prefsKey: 'bottom_nav_guide_shown',
      );
    }

    // Mark all guides as completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_allGuidesCompletedKey, true);
  }

  /// Function to check if a specific guide has been shown
  Future<bool> hasGuideBeenShown(String guideKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(guideKey) ?? false;
  }

  /// Function to mark a specific guide as shown
  Future<void> markGuideAsShown(String guideKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(guideKey, true);
  }
}