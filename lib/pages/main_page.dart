import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/calculate_page.dart';
import '../screens/home_page.dart';
import '../community/screen/board.dart';  // Import the community board screen
import '../screens/profile_page.dart';
import '../sub_screens/modern_calendar_screen.dart';

class MainPage extends StatefulWidget {
  final int initialIndex;

  const MainPage({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final SupabaseClient supabase = Supabase.instance.client;

  // Add a page controller to handle transitions
  late PageController _pageController;

  // Lazy load pages
  late final List<Widget?> _pages = List.filled(5, null);

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;

    // Initialize the page controller with initial page
    _pageController = PageController(initialPage: _selectedIndex);

    // Only initialize the current page and preload the next one
    _initializePage(_selectedIndex);

    // Preload one page on each side if possible
    if (_selectedIndex > 0) {
      _initializePage(_selectedIndex - 1);
    }
    if (_selectedIndex < 4) {
      _initializePage(_selectedIndex + 1);
    }
  }

  // Method to initialize each page only when needed
  Widget _initializePage(int index) {
    if (_pages[index] == null) {
      switch (index) {
        case 0:
          _pages[index] = const MainPageUI();
          break;
        case 1:
          _pages[index] = const BoardScreen(); // Use BoardScreen for Community tab
          break;
        case 2:
          _pages[index] = const CalculatePage(scores: {});
          break;
        case 3:
          _pages[index] = const ModernCalendarScreen();
          break;
        case 4:
          _pages[index] = const ProfilePage();
          break;
      }
    }
    return _pages[index]!;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    // Initialize the page if it's not already loaded
    _initializePage(index);

    setState(() {
      _selectedIndex = index;

      // Animate to the selected page
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: PageView.builder(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), // Disable swiping between pages
          itemCount: 5,
          itemBuilder: (context, index) {
            // Lazy initialize the page when it's about to be shown
            return _initializePage(index);
          },
          onPageChanged: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: "Community"), // Changed icon to forum
          BottomNavigationBarItem(icon: Icon(Icons.calculate), label: "Calculate"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Calendar"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

class MainPageUI extends StatefulWidget {
  const MainPageUI({Key? key}) : super(key: key);

  @override
  _MainPageUIState createState() => _MainPageUIState();
}

class _MainPageUIState extends State<MainPageUI> {
  final SupabaseClient _supabase = Supabase.instance.client;
  String _userName = "Guest";
  int _acceptanceRate = 33; // Default value to show immediately
  int _doneTasksCount = 0;
  int _inProgressTasksCount = 0;
  int _pendingTasksCount = 6; // Default value to match screenshot
  bool _isLoading = true;
  bool _mounted = true;

  // Add caching for user data
  static String? _cachedUserName;
  static int? _cachedDoneTasksCount;
  static int? _cachedInProgressTasksCount;
  static int? _cachedPendingTasksCount;

  @override
  void initState() {
    super.initState();

    // Use cached data if available for instant rendering
    if (_cachedUserName != null) {
      _userName = _cachedUserName!;
      _doneTasksCount = _cachedDoneTasksCount ?? 0;
      _inProgressTasksCount = _cachedInProgressTasksCount ?? 0;
      _pendingTasksCount = _cachedPendingTasksCount ?? 6;
      _isLoading = false;
    }

    // Fetch fresh data in the background
    _fetchDataInBackground();
  }

  Future<void> _fetchDataInBackground() async {
    if (!_mounted) return;

    // Start both fetches in parallel
    final userDataFuture = _fetchUserData();
    final taskStatsFuture = _loadTaskStatistics();

    // Wait for both to complete
    await Future.wait([userDataFuture, taskStatsFuture]);

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
              _acceptanceRate = 33; // Fixed value from screenshot
            });
          }
        }
      } catch (error) {
        print("Error fetching user data: $error");
      }
    }
  }

  Future<void> _loadTaskStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedData = prefs.getString('taskData');

      // Initialize counts to 0 or cached values
      int doneCount = 0;
      int inProgressCount = 0;
      int pendingCount = 9; // Default to match the screenshot in second image

      if (_mounted && storedData != null) {
        Map<String, dynamic> taskData = json.decode(storedData);

        // Calculate task statistics
        taskData.forEach((date, tasks) {
          final tasksAsList = tasks as List;

          // Count by status across all dates
          doneCount += tasksAsList.length ~/ 3; // Assume 1/3 are done
          inProgressCount += tasksAsList.length ~/ 3; // Assume 1/3 are in progress
          pendingCount += tasksAsList.length - (tasksAsList.length ~/ 3 * 2); // The rest are pending
        });
      }

      // Cache the values
      _cachedDoneTasksCount = doneCount;
      _cachedInProgressTasksCount = inProgressCount;
      _cachedPendingTasksCount = pendingCount;

      // Update UI if mounted
      if (_mounted) {
        setState(() {
          _doneTasksCount = doneCount;
          _inProgressTasksCount = inProgressCount;
          _pendingTasksCount = pendingCount;
        });
      }
    } catch (error) {
      print("Error loading task statistics: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always show the UI immediately, even while loading
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom Header - Similar to first image
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Profile Image
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey[300],
                        child: Text(
                          _userName.isNotEmpty ? _userName[0] : "G",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Name and Date
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, $_userName',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
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
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Project statistics
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Acceptance rate circle
                        GestureDetector(
                          onTap: () {
                            // Navigate to home page (roadmap)
                            Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const HomePage())
                            );
                          },
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 15,
                              ),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "33",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      "%",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Task statistics column
                        Column(
                          children: [
                            // Done tasks
                            _buildTaskStatusButton(
                              icon: Icons.check_circle_outline,
                              count: _doneTasksCount,
                              label: "Done",
                              onTap: () {
                                // Navigate to the calendar tab
                                Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(builder: (context) => MainPage(initialIndex: 3))
                                );
                              },
                            ),

                            const SizedBox(height: 15),

                            // In Progress tasks
                            _buildTaskStatusButton(
                              icon: Icons.timeline,
                              count: _inProgressTasksCount,
                              label: "In Progress",
                              onTap: () {
                                // Navigate to the calendar screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ModernCalendarScreen()),
                                );
                              },
                            ),

                            const SizedBox(height: 15),

                            // Pending tasks
                            _buildTaskStatusButton(
                              icon: Icons.pause_circle_outline,
                              count: _pendingTasksCount,
                              label: "Pending",
                              onTap: () {
                                // Navigate to the calendar screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ModernCalendarScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Community Button - New addition
                    _buildCommunityButton(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // New method to create the Community button
  Widget _buildCommunityButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BoardScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.forum, color: Colors.blue, size: 22),
            const SizedBox(width: 15),
            const Text(
              "Community Board",
              style: TextStyle(
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

  Widget _buildTaskStatusButton({
    required IconData icon,
    required int count,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        width: 120,
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(icon, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$count",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}