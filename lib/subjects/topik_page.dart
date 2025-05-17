import 'package:flutter/material.dart';
import '../screens/calculate_page.dart';
import 'package:experiment3/services/notification_display_service.dart';

class TopikPage extends StatefulWidget {
  final Map<String, int> submittedScores;
  final Function(Map<String, int>) onSubmit;

  const TopikPage({
    Key? key,
    this.submittedScores = const {},
    this.onSubmit = _defaultSubmit,
  }) : super(key: key);

  // Default empty function for when onSubmit isn't provided
  static void _defaultSubmit(Map<String, int> scores) {}

  @override
  _TopikPageState createState() => _TopikPageState();
}

class _TopikPageState extends State<TopikPage> {
  int _selectedLevel = 0;
  bool _isSubmitting = false;

  // TOPIK Level details for more context
  final Map<int, Map<String, dynamic>> _topikLevels = {
    1: {
      'description': 'Beginner Level',
      'color': Color(0xFF6DEEC7), // Aquamarine
    },
    2: {
      'description': 'Elementary Level',
      'color': Color(0xFFAF95C6), // African Violet
    },
    3: {
      'description': 'Low Intermediate',
      'color': Color(0xFFE788A0), // Rose Pompadour
    },
    4: {
      'description': 'Intermediate Level',
      'color': Color(0xFFF8AC8B), // Atomic Tangerine
    },
    5: {
      'description': 'High Intermediate',
      'color': Color(0xFFAADABA), // Celadon
    },
    6: {
      'description': 'Advanced Level',
      'color': Color(0xFF8D6E63), // Brown
    },
  };

  void _selectLevel(int level) {
    setState(() {
      _selectedLevel = level;
    });
  }

  void _submitTopikLevel() {
    if (_selectedLevel == 0) {
      NotificationDisplayService.showPopupNotification(
        context,
        title: "Please select a TOPIK level",
        isSuccess: true,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Create updated scores map
    Map<String, int> updatedScores = {...widget.submittedScores};
    updatedScores['TOPIK Level'] = _selectedLevel;

    // Call onSubmit callback
    widget.onSubmit(updatedScores);

    // Navigate to CalculatePage
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CalculatePage(scores: updatedScores),
      ),
    );

    setState(() {
      _isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "TOPIK Level",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Select Your TOPIK Level",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87, // Adjusted for light theme
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Choose the level that best represents your Korean language proficiency",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // TOPIK Level Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                final level = index + 1;
                final levelDetails = _topikLevels[level]!;

                return GestureDetector(
                  onTap: () => _selectLevel(level),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: _selectedLevel == level
                          ? levelDetails['color']
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                      border: _selectedLevel == level
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                      boxShadow: _selectedLevel == level
                          ? [
                        BoxShadow(
                          color: levelDetails['color'].withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 2,
                        )
                      ]
                          : [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 5,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOPIK Level $level',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _selectedLevel == level
                                  ? Colors.black
                                  : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            levelDetails['description'],
                            style: TextStyle(
                              fontSize: 14,
                              color: _selectedLevel == level
                                  ? Colors.black87
                                  : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Submit Button
          if (_selectedLevel > 0)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitTopikLevel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6DEEC7),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                    'Continue to Calculation',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}