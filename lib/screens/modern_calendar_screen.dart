import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:experiment3/widgets/floating_bottom_navigation_bar.dart';
import '../services/notification_service.dart';
import '../pages/main_page.dart'; // Added import for MainPageUI

class ModernCalendarScreen extends StatefulWidget {
  const ModernCalendarScreen({Key? key}) : super(key: key);

  @override
  _ModernCalendarScreenState createState() => _ModernCalendarScreenState();
}

class _ModernCalendarScreenState extends State<ModernCalendarScreen> {
  late DateTime _selectedDate;
  late DateTime _currentMonth;
  Map<String, List<Map<String, dynamic>>> _events = {};
  bool _isLoading = true;
  bool _showFullCalendar = true;
  final ScrollController _scrollController = ScrollController();

  // For full calendar view
  late List<List<DateTime?>> _calendarDays;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _currentMonth = DateTime(_selectedDate.year, _selectedDate.month);
    _generateCalendarDays();
    _loadEvents();

    // Add scroll listener to toggle calendar visibility
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    // Show full calendar when scrolled to top, hide when scrolled down
    if (_scrollController.offset <= 50 && !_showFullCalendar) {
      setState(() {
        _showFullCalendar = true;
      });
    } else if (_scrollController.offset > 50 && _showFullCalendar) {
      setState(() {
        _showFullCalendar = false;
      });
    }
  }

  void _generateCalendarDays() {
    _calendarDays = [];

    // Get the first day of the month
    final DateTime firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);

    // Find what day of the week the month starts on (0 = Sunday, 1 = Monday, etc.)
    final int firstWeekday = firstDay.weekday % 7;

    // Get the number of days in the month
    final int daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;

    // Create a 2D array for the calendar grid (up to 6 weeks)
    List<DateTime?> week = List.filled(7, null);

    // Fill in leading empty cells with previous month days
    DateTime prevMonthDay = firstDay.subtract(Duration(days: firstWeekday));
    for (int i = 0; i < firstWeekday; i++) {
      week[i] = prevMonthDay.add(Duration(days: i));
    }

    // Fill in the days of the month
    int dayCounter = 1;
    for (int i = firstWeekday; i < 7; i++) {
      week[i] = DateTime(_currentMonth.year, _currentMonth.month, dayCounter++);
    }
    _calendarDays.add(week);

    // Fill in remaining weeks
    while (dayCounter <= daysInMonth) {
      week = List.filled(7, null);
      for (int i = 0; i < 7 && dayCounter <= daysInMonth; i++) {
        week[i] = DateTime(_currentMonth.year, _currentMonth.month, dayCounter++);
      }

      // Fill in trailing days with next month's dates
      if (dayCounter > daysInMonth) {
        for (int i = dayCounter - daysInMonth - 1; i < 7; i++) {
          if (i >= 0 && i < 7) {
            final int nextMonthDay = i - (dayCounter - daysInMonth - 1) + 1;
            week[i] = DateTime(_currentMonth.year, _currentMonth.month + 1, nextMonthDay);
          }
        }
      }
      _calendarDays.add(week);
    }
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final storedData = prefs.getString('taskData');

      if (storedData != null && storedData.isNotEmpty) {
        final decodedData = json.decode(storedData) as Map<String, dynamic>;

        setState(() {
          _events = decodedData.map((key, value) =>
              MapEntry(key, List<Map<String, dynamic>>.from(
                  value.map((task) => Map<String, dynamic>.from(task))
              )));
          _isLoading = false;
        });
      } else {
        setState(() {
          _events = {};
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading events: $e');
      setState(() {
        _events = {};
        _isLoading = false;
      });
    }
  }

  void _onDaySelected(DateTime day) {
    setState(() {
      _selectedDate = day;

      // If selecting a day from previous/next month, update the current month
      if (day.month != _currentMonth.month || day.year != _currentMonth.year) {
        _currentMonth = DateTime(day.year, day.month);
        _generateCalendarDays();
      }
    });
  }

  void _changeMonth(int monthsToAdd) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + monthsToAdd);
      _generateCalendarDays();
    });
  }

  // Safely navigate back to main page
  void _navigateBack() {
    // Use pushReplacement to avoid stacking screens
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainPageUI()),
    );
  }

  Future<void> _saveEvent(Map<String, dynamic> event) async {
    String dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);

    setState(() {
      if (!_events.containsKey(dateKey)) {
        _events[dateKey] = [];
      }
      _events[dateKey]!.add(event);
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('taskData', json.encode(_events));

      // Schedule reminder notification if alarm is enabled
      if (event['alarm'] == true) {
        // Get the selected date with the hour and minute from the event
        DateTime taskDateTime;

        // Parse the time string (format: "h:mm AM/PM")
        final String timeString = event['time'] ?? '';
        if (timeString.isNotEmpty) {
          try {
            // Extract hours and minutes from time string
            final List<String> timeParts = timeString.split(' ');
            final List<String> hourMinute = timeParts[0].split(':');
            final String amPm = timeParts[1];

            int hour = int.parse(hourMinute[0]);
            final int minute = int.parse(hourMinute[1]);

            // Convert 12-hour format to 24-hour if needed
            if (amPm.toUpperCase() == 'PM' && hour < 12) {
              hour += 12;
            } else if (amPm.toUpperCase() == 'AM' && hour == 12) {
              hour = 0;
            }

            // Create the task date time
            taskDateTime = DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
              hour,
              minute,
            );

            // Schedule the notification
            final notificationService = NotificationService();
            await notificationService.scheduleTaskReminder(
                event['title'] ?? 'Untitled Task',
                taskDateTime
            );

            print('Scheduled reminder for task "${event['title']}" at $taskDateTime');
          } catch (e) {
            print('Error parsing time for task notification: $e');
          }
        }
      }
    } catch (e) {
      print('Error saving event: $e');
    }
  }

  Future<void> _deleteEvent(String dateKey, int index) async {
    setState(() {
      if (_events.containsKey(dateKey) && _events[dateKey]!.length > index) {
        _events[dateKey]!.removeAt(index);

        // Remove the date key if no events remain for that day
        if (_events[dateKey]!.isEmpty) {
          _events.remove(dateKey);
        }
      }
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('taskData', json.encode(_events));
    } catch (e) {
      print('Error deleting event: $e');
    }
  }

  void _showDeleteConfirmation(String dateKey, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Delete Event', style: TextStyle(color: Colors.black)),
        content: Text('Are you sure you want to delete this event?', style: TextStyle(color: Colors.black)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteEvent(dateKey, index);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddEventModal() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController noteController = TextEditingController();

    // Date selection
    int selectedDay = _selectedDate.day;
    int selectedMonth = _selectedDate.month;
    int selectedHour = 8;
    int selectedMinute = 0;
    String selectedAmPm = "AM";

    // Color and alarm settings
    Color selectedColor = Color(0xFFFF9800); // Orange as default
    bool alarmEnabled = false;

    List<Color> colorOptions = [
      Color(0xFFFF9800), // Orange
      Color(0xFF8BC34A), // Light green
      Color(0xFF03A9F4), // Light blue
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: Color(0xFF8D9775), // Olive green background color
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Add Note and profile picture
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Icon(Icons.close, color: Colors.white),
                          ),
                          SizedBox(width: 16),
                          Text(
                            'Add Note',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      CircleAvatar(
                        backgroundColor: Colors.white70,
                        child: Icon(Icons.person, color: Colors.grey.shade800),
                        radius: 20,
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date and Time Section
                        Text(
                          'Date and Time',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 12),

                        // Date and Time Picker - Horizontal Layout
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Day
                            _buildTimePickerItem(
                              label: 'Day',
                              value: selectedDay.toString().padLeft(2, '0'),
                              onTap: () {
                                _showNumberPickerDialog(
                                  context,
                                  'Day',
                                  1,
                                  31,
                                  selectedDay,
                                      (value) => setModalState(() => selectedDay = value),
                                );
                              },
                            ),

                            // Month
                            _buildTimePickerItem(
                              label: 'Month',
                              value: selectedMonth.toString().padLeft(2, '0'),
                              onTap: () {
                                _showNumberPickerDialog(
                                  context,
                                  'Month',
                                  1,
                                  12,
                                  selectedMonth,
                                      (value) => setModalState(() => selectedMonth = value),
                                  useMonthNames: true,
                                );
                              },
                            ),

                            // Hour
                            _buildTimePickerItem(
                              label: 'Hour',
                              value: selectedHour.toString().padLeft(2, '0'),
                              onTap: () {
                                _showNumberPickerDialog(
                                  context,
                                  'Hour',
                                  1,
                                  12,
                                  selectedHour,
                                      (value) => setModalState(() => selectedHour = value),
                                );
                              },
                            ),

                            // Minute
                            _buildTimePickerItem(
                              label: 'Minute',
                              value: selectedMinute.toString().padLeft(2, '0'),
                              onTap: () {
                                _showNumberPickerDialog(
                                  context,
                                  'Minute',
                                  0,
                                  59,
                                  selectedMinute,
                                      (value) => setModalState(() => selectedMinute = value),
                                );
                              },
                            ),

                            // AM/PM
                            _buildTimePickerItem(
                              label: '',
                              value: selectedAmPm,
                              onTap: () {
                                setModalState(() {
                                  selectedAmPm = selectedAmPm == 'AM' ? 'PM' : 'AM';
                                });
                              },
                            ),
                          ],
                        ),

                        SizedBox(height: 30),

                        // Title Field
                        Text(
                          'Title',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white54),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: titleController,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Write the title',
                              hintStyle: TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                            ),
                          ),
                        ),

                        SizedBox(height: 20),

                        // Note Field
                        Text(
                          'Note',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white54),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: noteController,
                            style: TextStyle(color: Colors.white),
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Write your important note',
                              hintStyle: TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                            ),
                          ),
                        ),

                        SizedBox(height: 20),

                        // Color and Alarm Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Color Options
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Color',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: colorOptions.map((color) =>
                                      GestureDetector(
                                        onTap: () => setModalState(() => selectedColor = color),
                                        child: Container(
                                          margin: EdgeInsets.only(right: 10),
                                          width: 30,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                            border: selectedColor == color
                                                ? Border.all(color: Colors.white, width: 2)
                                                : null,
                                          ),
                                          child: selectedColor == color
                                              ? Icon(Icons.check, color: Colors.white, size: 16)
                                              : null,
                                        ),
                                      )
                                  ).toList(),
                                ),
                              ],
                            ),

                            // Alarm Switch
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Alarm',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Switch(
                                  value: alarmEnabled,
                                  onChanged: (value) => setModalState(() => alarmEnabled = value),
                                  activeColor: Colors.white,
                                  activeTrackColor: Colors.green,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Save Button
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: Container(
                      width: 120,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          if (titleController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Please enter a title')),
                            );
                            return;
                          }

                          // Update the selected date with the chosen values
                          _selectedDate = DateTime(
                            _selectedDate.year,
                            selectedMonth,
                            selectedDay,
                          );

                          // Convert 12-hour format to 24-hour
                          int hour24 = selectedHour;
                          if (selectedAmPm == "PM" && selectedHour < 12) {
                            hour24 += 12;
                          } else if (selectedAmPm == "AM" && selectedHour == 12) {
                            hour24 = 0;
                          }

                          // Create a TimeOfDay object
                          final TimeOfDay timeOfDay = TimeOfDay(hour: hour24, minute: selectedMinute);

                          _saveEvent({
                            'title': titleController.text,
                            'description': noteController.text,
                            'time': timeOfDay.format(context),
                            'color': selectedColor.value.toString(),
                            'alarm': alarmEnabled,
                            'createdAt': DateTime.now().toIso8601String(),
                          });

                          Navigator.pop(context);
                        },
                        child: Text('Save', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimePickerItem({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          if (label.isNotEmpty)
            Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
          SizedBox(height: 4),
          Container(
            width: 60,
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white54),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNumberPickerDialog(
      BuildContext context,
      String title,
      int min,
      int max,
      int currentValue,
      Function(int) onSelected,
      {bool useMonthNames = false}
      ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Container(
          width: 300,
          height: 300,
          child: ListView.builder(
            itemCount: max - min + 1,
            itemBuilder: (context, index) {
              final value = min + index;
              String displayText = value.toString();

              if (useMonthNames) {
                displayText = DateFormat('MMMM').format(DateTime(2023, value));
              }

              return ListTile(
                title: Text(displayText),
                selected: value == currentValue,
                selectedTileColor: Colors.blue.withOpacity(0.1),
                onTap: () {
                  onSelected(value);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event, String dateKey, int index) {
    // Parse color from stored string if available
    Color eventColor = Colors.blue;
    if (event['color'] != null) {
      try {
        eventColor = Color(int.parse(event['color']));
      } catch (e) {
        print('Error parsing color: $e');
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Color indicator bar
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: eventColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 15),

          // Event content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['title'] ?? '',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                if (event['description'] != null && event['description'].isNotEmpty)
                  Text(
                    event['description'],
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                if (event['alarm'] == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Row(
                      children: [
                        Icon(Icons.alarm, color: Colors.grey[600], size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Alarm set',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Time and actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                event['time'] ?? '',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              // Delete button
              GestureDetector(
                onTap: () => _showDeleteConfirmation(dateKey, index),
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final todaysEvents = _events[dateKey] ?? [];

    // WillPopScope to handle back button presses properly
    return WillPopScope(
      onWillPop: () async {
        // Use proper navigation when back button is pressed
        _navigateBack();
        return false; // Prevents default back behavior
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: _navigateBack, // Use the safe navigation method
          ),
          title: Text(
            DateFormat('MMMM yyyy').format(_currentMonth),
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            // Main content with padding for the floating navigation bar
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: Column(
                  children: [
                    // Month Calendar - Collapsible
                    AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      height: _showFullCalendar ? null : 0,
                      child: Column(
                        children: [
                          // Weekday headers
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) =>
                                  SizedBox(
                                    width: 30,
                                    child: Text(
                                      day,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ).toList(),
                            ),
                          ),
                          SizedBox(height: 8),

                          // Calendar grid - update colors
                          Column(
                            children: _calendarDays.map((week) =>
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: week.map((day) {
                                      if (day == null) {
                                        return SizedBox(width: 30);
                                      }

                                      final isSelected = day.year == _selectedDate.year &&
                                          day.month == _selectedDate.month &&
                                          day.day == _selectedDate.day;

                                      final isToday = day.year == DateTime.now().year &&
                                          day.month == DateTime.now().month &&
                                          day.day == DateTime.now().day;

                                      final isCurrentMonth = day.month == _currentMonth.month;

                                      // Check if day has events
                                      final dayKey = DateFormat('yyyy-MM-dd').format(day);
                                      final hasEvents = _events.containsKey(dayKey) && _events[dayKey]!.isNotEmpty;

                                      // Get event color if available
                                      Color? eventColor;
                                      if (hasEvents && _events[dayKey]!.isNotEmpty) {
                                        try {
                                          final colorString = _events[dayKey]![0]['color'];
                                          if (colorString != null) {
                                            eventColor = Color(int.parse(colorString));
                                          }
                                        } catch (e) {
                                          print('Error parsing color: $e');
                                          eventColor = Colors.blue; // Fallback color
                                        }
                                      }

                                      return GestureDetector(
                                        onTap: () => _onDaySelected(day),
                                        child: Container(
                                          width: 30,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? Colors.blue
                                                : hasEvents
                                                ? (eventColor ?? Colors.blue).withOpacity(0.2)
                                                : null,
                                            borderRadius: BorderRadius.circular(isSelected ? 18 : 8),
                                            border: isToday && !isSelected
                                                ? Border.all(color: Colors.blue, width: 1)
                                                : null,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${day.day}',
                                              style: TextStyle(
                                                color: isSelected
                                                    ? Colors.white
                                                    : !isCurrentMonth
                                                    ? Colors.grey[400]
                                                    : Colors.black,
                                                fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                            ).toList(),
                          ),
                        ],
                      ),
                    ),

                    // Month navigation row
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => _changeMonth(-1),
                            child: Text(
                              'Previous Month',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _changeMonth(1),
                            child: Text(
                              'Next Month',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Today's events header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            'Today',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 10),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${todaysEvents.length} events',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Events list - update event card styling
                    Expanded(
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (scrollInfo) {
                          // Keep existing scroll handler
                          return true;
                        },
                        child: _isLoading
                            ? Center(child: CircularProgressIndicator(color: Colors.blue))
                            : todaysEvents.isEmpty
                            ? Center(
                          child: Text(
                            'No events for today',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        )
                            : ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          itemCount: todaysEvents.length,
                          itemBuilder: (context, index) {
                            final event = todaysEvents[index];
                            return _buildEventCard(event, dateKey, index);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Floating Bottom Navigation Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FloatingBottomNavigationBar(currentIndex: 3),
            ),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 80),
          child: FloatingActionButton(
            backgroundColor: Color(0xFF6AC17E),
            onPressed: _showAddEventModal,
            child: Icon(Icons.add, color: Colors.white),
          ),
        ),
      ),
    );
  }
}