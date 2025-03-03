import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../login/login_page.dart';
import '../pages/choose_university_screen.dart';
import '../sub_screens/settings_page.dart';
import '../screens/payment_page.dart'; // Changed import from premium_page to payment_page
import '../fade_transition.dart';
import '../widgets/loading_widget.dart';
import '../services/notification_service.dart';
import '../localization/app_localizations.dart';
import '../providers/language_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final NotificationService _notificationService = NotificationService();

  // Default/cached values for instant rendering
  String fullName = "Guest";
  String email = "Not available";
  String university = "No university selected";
  String major = "No major selected";

  // Static cache for profile data
  static String? _cachedFullName;
  static String? _cachedEmail;
  static String? _cachedUniversity;
  static String? _cachedMajor;

  bool _isLoading = false; // Start as false to show UI immediately
  bool _isSyncingData = false; // Separate flag for background data operations
  bool _mounted = true;

  final _userData = ValueNotifier<Map<String, dynamic>>({
    'fullName': 'Guest',
    'email': 'Not available',
    'university': 'No university selected',
    'major': 'No major selected',
  });

  @override
  void initState() {
    super.initState();

    // Use cached data if available for instant rendering
    if (_cachedFullName != null) {
      fullName = _cachedFullName!;
      email = _cachedEmail ?? "Not available";
      university = _cachedUniversity ?? "No university selected";
      major = _cachedMajor ?? "No major selected";

      // Update the value notifier
      _userData.value = {
        'fullName': fullName,
        'email': email,
        'university': university,
        'major': major,
      };
    }

    // Fetch data in the background without showing loading indicator
    _fetchUserDataInBackground();
  }

  @override
  void dispose() {
    _mounted = false;
    _userData.dispose();
    super.dispose();
  }

  Future<void> _fetchUserDataInBackground() async {
    if (!_mounted) return;

    setState(() {
      _isSyncingData = true;
    });

    final user = supabase.auth.currentUser;
    if (user != null) {
      try {
        final response = await supabase
            .from('users')
            .select('first_name, last_name, email, university, major')
            .eq('id', user.id)
            .maybeSingle();

        if (_mounted && response != null && response.isNotEmpty) {
          // Create the updated data
          final updatedFullName = "${response['first_name'] ?? ''} ${response['last_name'] ?? ''}".trim();
          final updatedEmail = response['email'] ?? "Not available";
          final updatedUniversity = response['university'] ?? "No university selected";
          final updatedMajor = response['major'] ?? "No major selected";

          // Cache the data
          _cachedFullName = updatedFullName.isEmpty ? "Guest" : updatedFullName;
          _cachedEmail = updatedEmail;
          _cachedUniversity = updatedUniversity;
          _cachedMajor = updatedMajor;

          setState(() {
            fullName = _cachedFullName!;
            email = _cachedEmail!;
            university = _cachedUniversity!;
            major = _cachedMajor!;
            _isSyncingData = false;

            // Update the value notifier
            _userData.value = {
              'fullName': fullName,
              'email': email,
              'university': university,
              'major': major,
            };
          });
        }
      } catch (e) {
        if (_mounted) {
          setState(() {
            _isSyncingData = false;
          });
        }
        print("Error fetching user data: $e");
      }
    } else {
      if (_mounted) {
        setState(() {
          _isSyncingData = false;
        });
      }
    }
  }

  Future<void> _signOut(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Clear FCM token from database
      await _notificationService.clearTokenOnLogout();

      // Sign out from Supabase
      await supabase.auth.signOut();

      // Clear cached data
      _cachedFullName = null;
      _cachedEmail = null;
      _cachedUniversity = null;
      _cachedMajor = null;

      // Check if the widget is still mounted before navigating
      if (_mounted) {
        setState(() {
          _isLoading = false;
        });
        Navigator.pushReplacement(context, fadeTransition(LoginPage()));
      }
    } catch (e) {
      // Check if the widget is still mounted before updating state
      if (_mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error signing out: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the app localizations
    final appLocal = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _fetchUserDataInBackground,
            color: Colors.blue,
            backgroundColor: Colors.grey[900],
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header
                    Text(
                      appLocal.translate('my_profile'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Profile Info Card
                    ValueListenableBuilder<Map<String, dynamic>>(
                        valueListenable: _userData,
                        builder: (context, userData, child) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                // Avatar and Name
                                Row(
                                  children: [
                                    Hero(
                                      tag: 'profile-avatar',
                                      child: CircleAvatar(
                                        radius: 40,
                                        backgroundColor: Colors.blue[400],
                                        child: Text(
                                          userData['fullName'].isNotEmpty ? userData['fullName'].substring(0, 1).toUpperCase() : "G",
                                          style: const TextStyle(
                                            fontSize: 30,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            userData['fullName'],
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            userData['email'],
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_isSyncingData)
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[700]!),
                                        ),
                                      ),
                                  ],
                                ),

                                const SizedBox(height: 30),

                                // University Info
                                _buildInfoRow(
                                  icon: Icons.school,
                                  title: appLocal.translate('university'),
                                  value: userData['university'],
                                ),
                                const Divider(color: Colors.grey),

                                // Major Info
                                _buildInfoRow(
                                  icon: Icons.book,
                                  title: appLocal.translate('major'),
                                  value: userData['major'],
                                ),
                              ],
                            ),
                          );
                        }
                    ),

                    const SizedBox(height: 30),

                    // Menu Options - Change "Account Details" to "Switch My Goal"
                    _buildMenuOption(
                      icon: Icons.swap_horiz,
                      title: appLocal.translate('switch_my_goal'),
                      onTap: () {
                        // Show loading dialog for better UX
                        LoadingWidget.show(context, message: appLocal.translate('loading_universities'));

                        // Add a small delay for better UX
                        Future.delayed(const Duration(milliseconds: 300), () {
                          // Hide loading dialog
                          if (context.mounted && Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }

                          // Navigate to ChooseUniversityScreen
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ChooseUniversityScreen()),
                          );
                        });
                      },
                    ),

                    _buildMenuOption(
                      icon: Icons.settings,
                      title: appLocal.translate('settings'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsPage()),
                        );
                      },
                    ),

                    _buildMenuOption(
                      icon: Icons.payment, // Changed icon to payment
                      title: "Premium Payment", // Changed title to Premium Payment
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PaymentPage()), // Changed to PaymentPage
                        );
                      },
                    ),

                    const SizedBox(height: 30),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _signOut(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          appLocal.translate('sign_out'),
                          style: const TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),

                    // Add extra space at the bottom for better scrolling
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),

          // Show loading overlay only during critical operations like sign out
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOption({required IconData icon, required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 22),
            const SizedBox(width: 15),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}