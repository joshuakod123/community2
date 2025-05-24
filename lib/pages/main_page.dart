import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../localization/app_localizations.dart';
import '../screens/home_page.dart';
import '../community/screen/board.dart';
import '../screens/calculate_page.dart';
import '../screens/modern_calendar_screen.dart';
import '../screens/profile_page.dart';
import '../widgets/first_login_guide.dart';
import '../widgets/focused_element_guide.dart';
import '../services/guide_service.dart';

class MainPageUI extends StatefulWidget {
  const MainPageUI({Key? key}) : super(key: key);

  @override
  _MainPageUIState createState() => _MainPageUIState();
}

class _MainPageUIState extends State<MainPageUI> {
  final SupabaseClient _supabase = Supabase.instance.client;
  String _userName = "Guest";
  int _acceptanceRate = 33; // Default value to show immediately
  bool _isLoading = true;
  bool _mounted = true;
  String _profileIconPath = ""; // Path to the user's profile icon

  // For education info (university and major)
  String _university = "No university selected";
  String _major = "No major selected";
  bool _isLoadingEducation = true;

  // Keys for guide elements
  final GlobalKey _journeyKey = GlobalKey();
  final GlobalKey _percentageKey = GlobalKey();
  final GlobalKey _communityCardKey = GlobalKey();
  final GlobalKey _bottomNavHomeKey = GlobalKey();

  // Guide service
  final GuideService _guideService = GuideService();

  // For week days display
  late DateTime _currentDate;
  List<DateTime> _weekDays = [];

  // For upcoming events
  List<Map<String, dynamic>> _upcomingEvents = [];

  // Static cache for user data
  static String? _cachedUserName;
  static String? _cachedUniversity;
  static String? _cachedMajor;

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime.now();
    _generateWeekDays();

    // Use cached data if available for instant rendering
    if (_cachedUserName != null) {
      _userName = _cachedUserName!;

      if (_cachedUniversity != null) {
        _university = _cachedUniversity!;
        _major = _cachedMajor ?? "No major selected";
        _isLoadingEducation = false;
      }

      _isLoading = false;
    }

    // Fetch fresh data in the background
    _fetchDataInBackground();

    // Load the user's profile icon
    _loadProfileIcon();

    // Show first login guide with a delay to ensure the UI is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstTimeUser();
    });
  }

  // Check if it's the user's first time and show relevant guides
  Future<void> _checkFirstTimeUser() async {
    // Initialize guide service
    await _guideService.initializeGuides(context);

    // First show the welcome guide for new users
    await FirstLoginGuide.showIfNeeded(context);

    // After a delay, show the focused guides for UI elements
    await Future.delayed(const Duration(seconds: 1));
    _showElementGuides();
  }

  // Show focused element guides for key UI components
  void _showElementGuides() async {
    // Show main page guides in sequence using the guide service
    if (mounted) {
      await _guideService.showMainPageGuides(
        context,
        journeyKey: _journeyKey,
        hexagonKey: _percentageKey, // Using percentage circle as our "hexagon" element
        communityCardKey: _communityCardKey,
        bottomNavHomeKey: _bottomNavHomeKey,
      );
    }
  }

  // Load user profile icon from SharedPreferences with user-specific key
  Future<void> _loadProfileIcon() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = _supabase.auth.currentUser;
      String? iconPath;

      if (user != null) {
        // Try to get user-specific icon
        iconPath = prefs.getString('profile_icon_path_${user.id}');
      }

      // Fallback to generic key if needed
      if (iconPath == null) {
        iconPath = prefs.getString('profile_icon_path');
      }

      if (iconPath != null && mounted) {
        setState(() {
          _profileIconPath = iconPath!;
        });
      }
    } catch (e) {
      print('Error loading profile icon: $e');
    }
  }

  void _generateWeekDays() {
    // Get today and calculate the start of the week (Sunday)
    DateTime today = _currentDate;
    int difference = today.weekday % 7;
    DateTime startOfWeek = today.subtract(Duration(days: difference));

    // Generate more days to make it more scrollable (e.g., 2 weeks)
    _weekDays = List.generate(14, (index) => startOfWeek.add(Duration(days: index)));
  }

  Future<void> _fetchDataInBackground() async {
    if (!_mounted) return;

    // Start all fetches in parallel
    final userDataFuture = _fetchUserData();
    final educationInfoFuture = _fetchEducationInfo();
    final eventsFuture = _loadUpcomingEvents();

    // Wait for completion
    await Future.wait([userDataFuture, educationInfoFuture, eventsFuture]);

    // Update UI if still mounted
    if (_mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        final response = await _supabase
            .from('users')
            .select('first_name, last_name')
            .eq('id', user.id)
            .maybeSingle();

        if (_mounted && response != null && response.isNotEmpty) {
          String firstName = response['first_name'] ?? '';
          String lastName = response['last_name'] ?? '';
          final newUserName = firstName.isNotEmpty ? "$firstName $lastName".trim() : "Guest";

          // Cache the data for future use
          _cachedUserName = newUserName;

          if (_mounted) {
            setState(() {
              _userName = newUserName;
            });
          }
        }
      } catch (error) {
        print("Error fetching user data: $error");
      }
    }
  }

  Future<void> _fetchEducationInfo() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        final response = await _supabase
            .from('users')
            .select('university, major')
            .eq('id', user.id)
            .maybeSingle();

        if (_mounted && response != null) {
          // Cache the data for future use
          _cachedUniversity = response['university'] ?? "No university selected";
          _cachedMajor = response['major'] ?? "No major selected";

          if (_mounted) {
            setState(() {
              _university = _cachedUniversity!;
              _major = _cachedMajor!;
              _isLoadingEducation = false;
            });
          }
        }
      } catch (error) {
        print("Error fetching education info: $error");
        if (_mounted) {
          setState(() {
            _isLoadingEducation = false;
          });
        }
      }
    } else {
      if (_mounted) {
        setState(() {
          _isLoadingEducation = false;
        });
      }
    }
  }

  Future<void> _loadUpcomingEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedData = prefs.getString('taskData');

      if (_mounted && storedData != null) {
        Map<String, dynamic> taskData = json.decode(storedData);
        List<Map<String, dynamic>> events = [];

        // Get today's date formatted as a string for comparison
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final tomorrow = DateFormat('yyyy-MM-dd').format(
            DateTime.now().add(const Duration(days: 1)));

        // Process events for today and tomorrow
        taskData.forEach((dateKey, tasks) {
          if (dateKey == today || dateKey == tomorrow) {
            for (var task in tasks) {
              events.add({
                'title': task['title'] ?? 'Untitled Event',
                'time': task['time'] ?? '',
                'date': dateKey == today ? 'Today' : 'Tomorrow',
                'color': task['color'] != null ? Color(int.parse(task['color'])) : Colors.blue,
              });
            }
          }
        });

        // Sort events by time (if available)
        events.sort((a, b) => (a['time'] ?? '').compareTo(b['time'] ?? ''));

        // Keep only up to 3 events
        if (events.length > 3) {
          events = events.sublist(0, 3);
        }

        if (_mounted) {
          setState(() {
            _upcomingEvents = events;
          });
        }
      }
    } catch (error) {
      print('Error loading upcoming events: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the app localizations
    final appLocal = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom Header - Similar to first image
              _buildTopHeader(),

              // Your Journey section with university and major info
              _buildYourJourneySection(appLocal),

              // Week days scrollable selector
              _buildScrollableWeekDaysSelector(),

              // Upcoming events widget (new addition)
              if (_upcomingEvents.isNotEmpty) _buildUpcomingEventsWidget(),

              // Community Board widget (large)
              _buildCommunityWidget(appLocal),

              // Add space at the bottom for better scrolling experience
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildCustomBottomNavigationBar(appLocal),
    );
  }

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Profile image and greeting
          Row(
            children: [
              // Profile icon/image - using the loaded profile icon if available
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfilePage()),
                  ).then((_) {
                    // Reload profile icon when returning from profile page
                    _loadProfileIcon();
                  });
                },
                child: _profileIconPath.isNotEmpty
                    ? CircleAvatar(
                  radius: 24,
                  backgroundImage: AssetImage(_profileIconPath),
                )
                    : CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.purple.shade200,
                  child: Text(
                    _userName.isNotEmpty ? _userName[0].toUpperCase() : "G",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, $_userName',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Today ${DateFormat('dd MMM').format(DateTime.now())}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYourJourneySection(AppLocalizations appLocal) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        key: _journeyKey, // Add key for the guide
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.purple.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Left section - Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appLocal.translate('your_journey'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _isLoadingEducation
                      ? const SizedBox(
                    height: 15,
                    width: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black54,
                    ),
                  )
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _university,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _major,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Right section - Percentage circle
            GestureDetector(
              onTap: () {
                // Navigate to home page (roadmap)
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage())
                );
              },
              child: Container(
                key: _percentageKey, // Add key for the guide
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.3),
                    width: 4,
                  ),
                  color: Colors.black,
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "$_acceptanceRate",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text(
                          "%",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollableWeekDaysSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Optional: Add a label
          Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
            child: Text(
              'Calendar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),

          // Horizontal scrollable calendar
          SizedBox(
            height: 80, // Fixed height for the scrollable area
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _weekDays.length,
              itemBuilder: (context, index) {
                final day = _weekDays[index];
                final isToday = day.day == DateTime.now().day &&
                    day.month == DateTime.now().month &&
                    day.year == DateTime.now().year;

                return Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: _buildDayButton(
                    day: day.day.toString(),
                    weekday: DateFormat('E').format(day).substring(0, 3),
                    isSelected: isToday,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayButton({required String day, required String weekday, required bool isSelected}) {
    return Container(
      width: 60, // Made wider for better touch target
      decoration: BoxDecoration(
        color: isSelected ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            weekday,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.white : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            day,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEventsWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upcoming Events',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Event list
            ...List.generate(_upcomingEvents.length, (index) {
              final event = _upcomingEvents[index];
              final Color eventColor = event['color'] ?? Colors.blue;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    // Color indicator
                    Container(
                      width: 4,
                      height: 36,
                      decoration: BoxDecoration(
                        color: eventColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Event details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event['title'] ?? 'Untitled Event',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                event['date'] ?? 'Today',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (event['time'] != null && event['time'].isNotEmpty)
                                Text(
                                  ' · ${event['time']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            // View all button
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ModernCalendarScreen()),
                );
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                alignment: Alignment.centerLeft,
              ),
              child: const Text('View all events'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityWidget(AppLocalizations appLocal) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BoardScreen()),
          );
        },
        child: Container(
          key: _communityCardKey, // Add key for the guide
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.amber.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title
                  Text(
                    appLocal.translate('community'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.forum, color: Colors.black),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Date info
              Text(
                DateFormat('dd MMM, yyyy').format(DateTime.now()),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),

              // Description
              const Text(
                'Connect with fellow learners, share experiences, and discuss study tips.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomBottomNavigationBar(AppLocalizations appLocal) {
    return Container(
      height: 70, // Made taller for better spacing
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 20), // Added margin at the bottom to create space
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavBarItem(
            key: _bottomNavHomeKey, // Add key for guide
            icon: Icons.home,
            label: appLocal.translate('home'),
            isSelected: true,
            onTap: () {
              // Already on home page
            },
          ),
          _buildNavBarItem(
            icon: Icons.forum,
            label: appLocal.translate('community'),
            isSelected: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BoardScreen()),
              );
            },
          ),
          _buildNavBarItem(
            icon: Icons.calculate,
            label: appLocal.translate('calculate'),
            isSelected: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CalculatePage(scores: {})),
              );
            },
          ),
          _buildNavBarItem(
            icon: Icons.calendar_today,
            label: appLocal.translate('calendar'),
            isSelected: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ModernCalendarScreen()),
              );
            },
          ),
          _buildNavBarItem(
            icon: Icons.person,
            label: appLocal.translate('profile'),
            isSelected: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              ).then((_) {
                // Reload profile icon when returning from profile page
                _loadProfileIcon();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavBarItem({
    Key? key,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.blue : Colors.grey,
            size: 24,
          ),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.blue : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}