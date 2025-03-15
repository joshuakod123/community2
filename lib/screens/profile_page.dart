import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login/login_page.dart';
import '../pages/choose_university_screen.dart';
import '../sub_screens/settings_page.dart';
import '../screens/payment_page.dart';
import '../fade_transition.dart';
import '../widgets/loading_widget.dart';
import '../services/notification_service.dart';
import '../localization/app_localizations.dart';
import '../providers/language_provider.dart';
import '../pages/main_page.dart'; // For home button navigation
import '../widgets/floating_bottom_navigation_bar.dart';

// Define the app colors as constants
const Color kPaynesGrey = Color(0xFF536878);
const Color kPearl = Color(0xFFEAE0C8);

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
  String profileIconPath = ""; // Path to the selected profile icon

  // Static cache for profile data
  static String? _cachedFullName;
  static String? _cachedEmail;
  static String? _cachedUniversity;
  static String? _cachedMajor;
  static String? _cachedProfileIconPath;

  bool _isLoading = false;
  bool _isSyncingData = false;
  bool _mounted = true;

  final _userData = ValueNotifier<Map<String, dynamic>>({
    'fullName': 'Guest',
    'email': 'Not available',
    'university': 'No university selected',
    'major': 'No major selected',
    'profileIconPath': '',
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
      profileIconPath = _cachedProfileIconPath ?? "";

      // Update the value notifier
      _userData.value = {
        'fullName': fullName,
        'email': email,
        'university': university,
        'major': major,
        'profileIconPath': profileIconPath,
      };
    }

    // Fetch data in the background without showing loading indicator
    _fetchUserDataInBackground();
    _loadProfileIcon();
  }

  @override
  void dispose() {
    _mounted = false;
    _userData.dispose();
    super.dispose();
  }

  Future<void> _loadProfileIcon() async {
    final prefs = await SharedPreferences.getInstance();
    final user = supabase.auth.currentUser;
    String? iconPath;

    if (user != null) {
      // Try to get user-specific icon first
      iconPath = prefs.getString('profile_icon_path_${user.id}');
    }

    // If no user-specific icon found, try the fallback
    if (iconPath == null) {
      iconPath = prefs.getString('profile_icon_path');
    }

    if (iconPath != null && _mounted) {
      setState(() {
        profileIconPath = iconPath!;
        _cachedProfileIconPath = iconPath;

        // Update value notifier
        final updatedData = Map<String, dynamic>.from(_userData.value);
        updatedData['profileIconPath'] = iconPath;
        _userData.value = updatedData;
      });
    }
  }

  Future<void> _saveProfileIcon(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final user = supabase.auth.currentUser;

    // Save with user-specific key if user is available
    if (user != null) {
      await prefs.setString('profile_icon_path_${user.id}', path);
    } else {
      // Fallback to generic key
      await prefs.setString('profile_icon_path', path);
    }

    if (_mounted) {
      setState(() {
        profileIconPath = path;
        _cachedProfileIconPath = path;

        // Update value notifier
        final updatedData = Map<String, dynamic>.from(_userData.value);
        updatedData['profileIconPath'] = path;
        _userData.value = updatedData;
      });
    }
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
              'profileIconPath': profileIconPath,
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
      _cachedProfileIconPath = null;

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

  void _navigateToSelectProfileIcon() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileIconSelectionPage(
          onIconSelected: (String path) {
            _saveProfileIcon(path);
          },
          currentSelectedPath: profileIconPath,
          userName: fullName,
        ),
      ),
    );
  }

  // Ensure proper navigation back to MainPageUI with updated profile
  void _navigateBackToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainPageUI()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the app localizations
    final appLocal = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: kPearl,
      body: Stack(
        children: [
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _fetchUserDataInBackground,
              color: kPaynesGrey,
              backgroundColor: Colors.white,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ValueListenableBuilder<Map<String, dynamic>>(
                      valueListenable: _userData,
                      builder: (context, userData, child) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top navigation
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Home button
                                IconButton(
                                  icon: Icon(Icons.arrow_back, color: kPaynesGrey),
                                  onPressed: _navigateBackToHome,
                                ),

                                // Page title
                                Text(
                                  "My Profile",
                                  style: TextStyle(
                                    color: kPaynesGrey,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                // Empty SizedBox for alignment
                                const SizedBox(width: 48),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Profile Info Card
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: kPaynesGrey.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                border: Border.all(color: kPaynesGrey.withOpacity(0.2)),
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  // Avatar and Name
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: _navigateToSelectProfileIcon,
                                        child: profileIconPath.isNotEmpty
                                            ? CircleAvatar(
                                          radius: 40,
                                          backgroundImage: AssetImage(profileIconPath),
                                        )
                                            : CircleAvatar(
                                          radius: 40,
                                          backgroundColor: kPaynesGrey,
                                          child: Text(
                                            userData['fullName'].isNotEmpty ? userData['fullName'].substring(0, 1).toUpperCase() : "G",
                                            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
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
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: kPaynesGrey,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              userData['email'],
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: kPaynesGrey.withOpacity(0.7),
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
                                            valueColor: AlwaysStoppedAnimation<Color>(kPaynesGrey.withOpacity(0.5)),
                                          ),
                                        ),
                                    ],
                                  ),

                                  const SizedBox(height: 30),

                                  // University Info
                                  _buildInfoRow(
                                    icon: Icons.school,
                                    title: "University",
                                    value: userData['university'],
                                    iconColor: kPaynesGrey,
                                  ),

                                  // Divider
                                  Divider(color: kPaynesGrey.withOpacity(0.2)),

                                  // Major Info
                                  _buildInfoRow(
                                    icon: Icons.menu_book,
                                    title: "Major",
                                    value: userData['major'],
                                    iconColor: kPaynesGrey,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Settings Header
                            Text(
                              "Settings",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: kPaynesGrey,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Switch My Goal
                            _buildSettingsOption(
                              icon: Icons.swap_horiz,
                              iconColor: kPaynesGrey,
                              title: "Switch My Goal",
                              onTap: () {
                                LoadingWidget.show(context, message: appLocal.translate('loading_universities'));
                                Future.delayed(const Duration(milliseconds: 300), () {
                                  if (context.mounted && Navigator.of(context).canPop()) {
                                    Navigator.of(context).pop();
                                  }
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => ChooseUniversityScreen()),
                                  );
                                });
                              },
                            ),

                            const SizedBox(height: 10),

                            // Settings
                            _buildSettingsOption(
                              icon: Icons.settings,
                              iconColor: kPaynesGrey,
                              title: "Settings",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                                );
                              },
                            ),

                            const SizedBox(height: 10),

                            // Premium Payment
                            _buildSettingsOption(
                              icon: Icons.payment,
                              iconColor: kPaynesGrey,
                              title: "Premium Payment",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const PaymentPage()),
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
                                  backgroundColor: const Color(0xFFE74C3C), // Red color
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                    : Text(
                                  "Sign Out",
                                  style: TextStyle(fontSize: 16, color: Colors.white),
                                ),
                              ),
                            ),

                            // Add extra space at the bottom for better scrolling
                            const SizedBox(height: 100),
                          ],
                        );
                      }
                  ),
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

          // Add the floating bottom navigation bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingBottomNavigationBar(currentIndex: 4), // 4 is for Profile
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: kPaynesGrey.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: kPaynesGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPaynesGrey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: kPaynesGrey.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kPaynesGrey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: TextStyle(color: kPaynesGrey),
        ),
        trailing: Icon(Icons.chevron_right, color: kPaynesGrey.withOpacity(0.5)),
        onTap: onTap,
      ),
    );
  }
}

// Updated Profile Icon Selection Page with Netflix-like UI
class ProfileIconSelectionPage extends StatefulWidget {
  final Function(String) onIconSelected;
  final String currentSelectedPath;
  final String userName; // Add user name parameter

  const ProfileIconSelectionPage({
    Key? key,
    required this.onIconSelected,
    required this.currentSelectedPath,
    required this.userName,
  }) : super(key: key);

  @override
  _ProfileIconSelectionPageState createState() => _ProfileIconSelectionPageState();
}

class _ProfileIconSelectionPageState extends State<ProfileIconSelectionPage> {
  // Only keeping a single "Icon" collection
  final List<String> iconCollection = [
    "assets/profile_icons/icons1.png",
    "assets/profile_icons/icons2.png",
    "assets/profile_icons/icons3.png",
    "assets/profile_icons/icons4.png",
    "assets/profile_icons/icons5.png",
    "assets/profile_icons/icons6.png",
    "assets/profile_icons/icons7.png",
    "assets/profile_icons/icons8.png",
    "assets/profile_icons/icons9.png",
    "assets/profile_icons/icons10.png",
    "assets/profile_icons/icons11.png",
    "assets/profile_icons/icons12.png",
    "assets/profile_icons/icons13.png",
    "assets/profile_icons/icons14.png",
    "assets/profile_icons/icons15.png",
    "assets/profile_icons/icons16.png",
    "assets/profile_icons/icons17.png",
    "assets/profile_icons/icons18.png",
    "assets/profile_icons/icons19.png",
    "assets/profile_icons/icons20.png",
    "assets/profile_icons/icons21.png",
    "assets/profile_icons/icons22.png",
    "assets/profile_icons/icons23.png",
    "assets/profile_icons/icons24.png",
    "assets/profile_icons/icons25.png",
    "assets/profile_icons/icons26.png",
    "assets/profile_icons/icons27.png",
  ];

  // Currently selected icon for preview
  String? previewIconPath;

  @override
  void initState() {
    super.initState();
    // Initialize preview with current selection
    previewIconPath = widget.currentSelectedPath.isNotEmpty
        ? widget.currentSelectedPath
        : iconCollection.isNotEmpty ? iconCollection[0] : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPaynesGrey,
      // Dark gray background similar to Netflix
      appBar: AppBar(
        backgroundColor: kPaynesGrey.withOpacity(0.9),
        elevation: 0,
        title: const Text(
          "EDIT PROFILE",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section with instructions
          Container(
            padding: const EdgeInsets.all(16),
            color: kPaynesGrey.withOpacity(0.9),
            width: double.infinity,
            child: const Text(
              "Choose a character for your profile",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),

          // Selected icon preview
          if (previewIconPath != null)
            Container(
              color: kPaynesGrey.withOpacity(0.9),
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          image: DecorationImage(
                            image: AssetImage(previewIconPath!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Title for icon grid
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Icon",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Icon grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: iconCollection.length,
              itemBuilder: (context, index) {
                final iconPath = iconCollection[index];
                final isSelected = iconPath == previewIconPath;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      previewIconPath = iconPath;
                    });
                    widget.onIconSelected(iconPath);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 2)
                          : Border.all(color: Colors.transparent),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Image.asset(
                      iconPath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey,
                          child: Center(
                            child: Text(
                              "${index + 1}",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    "Back",
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (previewIconPath != null) {
                      widget.onIconSelected(previewIconPath!);
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: kPaynesGrey,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: const Text("Next"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}