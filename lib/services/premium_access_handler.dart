import 'package:flutter/material.dart';
import 'premium_service.dart';
import '../screens/payment_page.dart';

class PremiumAccessHandler {
  // Singleton pattern
  static final PremiumAccessHandler _instance = PremiumAccessHandler._internal();
  factory PremiumAccessHandler() => _instance;
  PremiumAccessHandler._internal();

  final PremiumService _premiumService = PremiumService();

  // Validate if user should have access, show upgrade dialog if not
  Future<bool> validateAccess(BuildContext context) async {
    final isPremium = await _premiumService.isPremiumUser();

    if (!isPremium && context.mounted) {
      await _showPremiumRequiredDialog(context);
      return false;
    }

    return isPremium;
  }

  // Show a dialog when premium access is required
  Future<void> _showPremiumRequiredDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Premium Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock,
              size: 48,
              color: Colors.amber[800],
            ),
            const SizedBox(height: 16),
            const Text(
              'This feature requires a premium membership.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Use MaterialPageRoute instead of named route
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const PaymentPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[800],
              foregroundColor: Colors.white,
            ),
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  // Try to access premium content, return true if successful
  Future<bool> tryAccessPremiumContent(BuildContext context) async {
    final isPremium = await _premiumService.isPremiumUser();

    if (!isPremium && context.mounted) {
      final shouldUpgrade = await _showPremiumUpgradeDialog(context);

      if (shouldUpgrade && context.mounted) {
        // Use MaterialPageRoute instead of named route
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const PaymentPage()),
        );
      }

      return false;
    }

    return isPremium;
  }

  // Show a more detailed upgrade dialog with feature highlights
  Future<bool> _showPremiumUpgradeDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Premium icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.star,
                  size: 50,
                  color: Colors.amber[800],
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Unlock Premium Features',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Description
              const Text(
                'Upgrade to Premium to access:',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Features list
              ..._buildFeatureList(),

              const SizedBox(height: 20),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Maybe Later'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Upgrade Now'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return result ?? false;
  }

  // Build feature list for the dialog
  List<Widget> _buildFeatureList() {
    final features = [
      {'icon': Icons.download, 'text': 'Exclusive study materials'},
      {'icon': Icons.analytics, 'text': 'Advanced analytics'},
      {'icon': Icons.support_agent, 'text': 'Priority support'},
      {'icon': Icons.block, 'text': 'Ad-free experience'},
    ];

    return features.map((feature) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(feature['icon'] as IconData, color: Colors.amber[800], size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(feature['text'] as String)),
        ],
      ),
    )).toList();
  }
}