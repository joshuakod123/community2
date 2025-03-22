import 'package:flutter/material.dart';
import 'package:pay/pay.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;

class PaymentPage extends StatefulWidget {
  const PaymentPage({Key? key}) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _isLoading = false;
  final String _premiumAmount = "9.99";

  // Apple Pay configuration
  late final List<PaymentItem> _paymentItems;

  @override
  void initState() {
    super.initState();
    _paymentItems = [
      PaymentItem(
        label: 'Premium Membership',
        amount: _premiumAmount,
        status: PaymentItemStatus.final_price,
      )
    ];
  }

  // Apple Pay payment configuration
  final _applePayConfig = ApplePayButtonType.subscribe;

  // Handle Apple Pay payment
  void onApplePayResult(Map<String, dynamic> result) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // This is where you would typically:
      // 1. Send payment details to your server
      // 2. Your server would make a call to Stripe or your payment processor
      // 3. Get confirmation back

      // Since we don't have a live server, we'll simulate success
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      // Mark the user as premium in your Supabase database or local storage
      // This would normally happen after server confirmation
      _markUserAsPremium();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful! You are now a premium member.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Handle errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${e.toString()}'),
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

  // Mark user as premium in your database
  Future<void> _markUserAsPremium() async {
    // In a real app, you would use your Supabase client to update user status
    // Example:
    // await Supabase.instance.client.from('users')
    //     .update({'is_premium': true})
    //     .eq('id', Supabase.instance.client.auth.currentUser?.id);

    // For this demo, we'll just show a success message
    print('User marked as premium');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Premium Membership")),
      body: Stack(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Premium logo or image
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
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                // Subtitle
                Text(
                  "Get unlimited access to all premium features",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),

                // Price
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "\$$_premiumAmount per month",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Features list
                ..._buildFeaturesList(),

                const SizedBox(height: 30),

                // Apple Pay button (iOS only)
                if (Platform.isIOS)
                  SizedBox(
                    width: double.infinity,
                    child: ApplePayButton(
                      paymentConfiguration: PaymentConfiguration.fromJsonString(
                        '{"provider": "apple_pay", "data": {"merchantIdentifier": "merchant.com.yourcompany.experiment3"}}',
                      ),
                      paymentItems: _paymentItems,
                      style: ApplePayButtonStyle.black,
                      type: _applePayConfig,
                      margin: const EdgeInsets.only(top: 15.0),
                      onPaymentResult: onApplePayResult,
                      loadingIndicator: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),

                // Regular button for Android or fallback
                if (!Platform.isIOS)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Apple Pay is only available on iOS devices")),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
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