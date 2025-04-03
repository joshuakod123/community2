// lib/screens/payment_page.dart
import 'package:flutter/material.dart';
import 'package:pay/pay.dart';
import 'dart:io' show Platform;
import 'dart:math';
import '../services/premium_service.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({Key? key}) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _isLoading = false;
  final PremiumService _premiumService = PremiumService();

  // Pricing options
  final List<Map<String, dynamic>> _subscriptionPlans = [
    {
      'id': 'monthly',
      'name': 'Monthly',
      'price': 9.99,
      'period': 'per month',
      'months': 1,
      'mostPopular': false,
    },
    {
      'id': 'yearly',
      'name': 'Yearly',
      'price': 99.99,
      'period': 'per year',
      'months': 12,
      'mostPopular': true,
      'savings': '17%' // (12*9.99 - 99.99) / (12*9.99)
    },
    {
      'id': 'quarterly',
      'name': 'Quarterly',
      'price': 24.99,
      'period': 'per 3 months',
      'months': 3,
      'mostPopular': false,
    },
  ];

  Map<String, dynamic> _selectedPlan = {};

  // Payment items for Apple Pay
  late List<PaymentItem> _paymentItems;

  @override
  void initState() {
    super.initState();
    // Default to the yearly plan (most popular)
    _selectedPlan = _subscriptionPlans.firstWhere((plan) => plan['mostPopular'] == true);
    _updatePaymentItems();
  }

  void _updatePaymentItems() {
    _paymentItems = [
      PaymentItem(
        label: 'Premium Membership - ${_selectedPlan['name']}',
        amount: _selectedPlan['price'].toString(),
        status: PaymentItemStatus.final_price,
      )
    ];
  }

  // Handle Apple Pay result
  void onApplePayResult(Map<String, dynamic> result) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Generate a transaction ID
      final transactionId = 'APPLPAY_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';

      // Save payment record
      await _premiumService.savePaymentRecord(
        transactionId: transactionId,
        amount: _selectedPlan['price'],
        currency: 'USD',
        paymentMethod: 'Apple Pay',
      );

      // Mark user as premium
      final success = await _premiumService.setUserAsPremium(
        months: _selectedPlan['months'],
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          _showSuccessDialog();
        } else {
          _showErrorDialog('There was an error activating your premium membership.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Payment failed: ${e.toString()}');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Payment Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Your premium membership has been activated successfully!',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate back to previous screen
              Navigator.of(context).pop(true);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _selectPlan(Map<String, dynamic> plan) {
    setState(() {
      _selectedPlan = plan;
      _updatePaymentItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Premium Membership"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Premium logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.star,
                    size: 80,
                    color: Colors.amber.shade800,
                  ),
                ),

                const SizedBox(height: 20),

                // Title
                const Text(
                  "Upgrade to Premium",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                // Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    "Get unlimited access to all premium features",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 32),

                // Subscription options
                ..._buildSubscriptionOptions(),

                const SizedBox(height: 32),

                // Features list
                ..._buildFeaturesList(),

                const SizedBox(height: 32),

                // Apple Pay button (iOS only)
                if (Platform.isIOS)
                  SizedBox(
                    width: double.infinity,
                    child: ApplePayButton(
                      paymentConfiguration: PaymentConfiguration.fromJsonString(
                        '{"provider": "apple_pay", "data": {"merchantIdentifier": "merchant.com.ulliance.onlypass", "supportedNetworks": ["visa", "masterCard", "amex", "discover"], "merchantCapabilities": ["3DS", "debit", "credit"], "countryCode": "US", "currencyCode": "USD"}}',
                      ),
                      paymentItems: _paymentItems,
                      style: ApplePayButtonStyle.black,
                      type: ApplePayButtonType.subscribe,
                      margin: const EdgeInsets.only(top: 15.0),
                      onPaymentResult: onApplePayResult,
                      loadingIndicator: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),

                // Regular button for Android or as fallback
                if (!Platform.isIOS)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          _isLoading = true;
                        });

                        try {
                          // Generate a transaction ID
                          final transactionId = 'REGULAR_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';

                          // Save payment record
                          await _premiumService.savePaymentRecord(
                            transactionId: transactionId,
                            amount: _selectedPlan['price'],
                            currency: 'USD',
                            paymentMethod: 'Direct',
                          );

                          // Mark user as premium
                          final success = await _premiumService.setUserAsPremium(
                            months: _selectedPlan['months'],
                          );

                          setState(() {
                            _isLoading = false;
                          });

                          if (success) {
                            _showSuccessDialog();
                          } else {
                            _showErrorDialog('There was an error activating your premium membership.');
                          }
                        } catch (e) {
                          setState(() {
                            _isLoading = false;
                          });
                          _showErrorDialog('Payment failed: ${e.toString()}');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Subscribe Now",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),

                // Terms and privacy policy notice
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    "By subscribing, you agree to our Terms of Service and Privacy Policy. Subscription automatically renews unless auto-renew is turned off at least 24-hours before the end of the current period.",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildSubscriptionOptions() {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: _subscriptionPlans.map((plan) {
            final isSelected = plan['id'] == _selectedPlan['id'];
            return Expanded(
              child: GestureDetector(
                onTap: () => _selectPlan(plan),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6.0),
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 6.0),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.amber.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.amber.shade800 : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      if (plan['mostPopular'])
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade700,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'BEST VALUE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Text(
                        plan['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '\$${plan['price']}',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: '\n${plan['period']}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (plan['savings'] != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Save ${plan['savings']}',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    ];
  }

  List<Widget> _buildFeaturesList() {
    final features = [
      "Unlimited access to premium content",
      "No advertisements",
      "Priority support",
      "Exclusive study materials",
      "Advanced analytics"
    ];

    return features.map((feature) => Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    )).toList();
  }
}