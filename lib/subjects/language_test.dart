import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/calculate_page.dart';

class LanguageTestPage extends StatefulWidget {
  final Map<String, int> submittedScores;
  final Function(Map<String, int>) onSubmit;

  const LanguageTestPage({
    Key? key,
    this.submittedScores = const {},
    this.onSubmit = _defaultSubmit,
  }) : super(key: key);

  // Default empty function for when onSubmit isn't provided
  static void _defaultSubmit(Map<String, int> scores) {}

  @override
  _LanguageTestPageState createState() => _LanguageTestPageState();
}

class _LanguageTestPageState extends State<LanguageTestPage> {
  String _selectedTest = '';

  // For level-based tests
  int _selectedLevel = 0;

  // For score-based tests
  final TextEditingController _scoreController = TextEditingController();
  final GlobalKey<FormState> _scoreFormKey = GlobalKey<FormState>();

  bool _isSubmitting = false;

  // Level details for level-based tests
  final Map<String, Map<int, Map<String, dynamic>>> _levelBasedTests = {
    'JLPT': {
      1: {
        'description': 'Advanced Japanese Proficiency',
        'color': Color(0xFF8D6E63), // Brown
      },
      2: {
        'description': 'Upper Intermediate Japanese',
        'color': Color(0xFFAADABA), // Celadon
      },
      3: {
        'description': 'Intermediate Japanese',
        'color': Color(0xFFF8AC8B), // Atomic Tangerine
      },
      4: {
        'description': 'Basic Japanese',
        'color': Color(0xFFE788A0), // Rose Pompadour
      },
      5: {
        'description': 'Elementary Japanese',
        'color': Color(0xFFAF95C6), // African Violet
      },
    },
    'HSK': {
      1: {
        'description': 'Beginner Chinese Proficiency',
        'color': Color(0xFF6DEEC7), // Aquamarine
      },
      2: {
        'description': 'Elementary Chinese',
        'color': Color(0xFFAF95C6), // African Violet
      },
      3: {
        'description': 'Intermediate Chinese',
        'color': Color(0xFFE788A0), // Rose Pompadour
      },
      4: {
        'description': 'Advanced Chinese',
        'color': Color(0xFFF8AC8B), // Atomic Tangerine
      },
      5: {
        'description': 'Professional Chinese',
        'color': Color(0xFFAADABA), // Celadon
      },
      6: {
        'description': 'Mastery Level Chinese',
        'color': Color(0xFF8D6E63), // Brown
      },
    },
    'DELE': {
      1: {
        'description': 'A1 - Beginner Spanish',
        'color': Color(0xFF6DEEC7), // Aquamarine
      },
      2: {
        'description': 'A2 - Basic Spanish',
        'color': Color(0xFFAF95C6), // African Violet
      },
      3: {
        'description': 'B1 - Intermediate Spanish',
        'color': Color(0xFFE788A0), // Rose Pompadour
      },
      4: {
        'description': 'B2 - Upper Intermediate',
        'color': Color(0xFFF8AC8B), // Atomic Tangerine
      },
      5: {
        'description': 'C1 - Advanced Spanish',
        'color': Color(0xFFAADABA), // Celadon
      },
      6: {
        'description': 'C2 - Mastery Level Spanish',
        'color': Color(0xFF8D6E63), // Brown
      },
    },
  };

  // IELTS CEFR and Score Mapping
  final Map<String, Map<String, dynamic>> _ieltsLevels = {
    'A1': {'min': 0.0, 'max': 2.0},
    'A2': {'min': 2.5, 'max': 3.0},
    'B1': {'min': 3.5, 'max': 4.0},
    'B2': {'min': 4.5, 'max': 5.5},
    'C1': {'min': 6.0, 'max': 7.0},
    'C2': {'min': 7.5, 'max': 9.0},
  };

  void _selectTest(String test) {
    setState(() {
      _selectedTest = test;
      _selectedLevel = 0;
      _scoreController.clear();
    });
  }

  void _selectLevel(int level) {
    setState(() {
      _selectedLevel = level;
    });
  }

  void _submitLanguageTest() {
    if (_selectedTest.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Language Test')),
      );
      return;
    }

    // Handle different submission logic based on test type
    switch (_selectedTest) {
      case 'JLPT':
      case 'HSK':
      case 'DELE':
        _submitLevelBasedTest();
        break;
      case 'IELTS':
        _submitIELTS();
        break;
      case 'TOEIC':
        _submitTOEIC();
        break;
    }
  }

  void _submitLevelBasedTest() {
    if (_selectedLevel == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a $_selectedTest Level')),
      );
      return;
    }

    _performSubmission({'$_selectedTest Level': _selectedLevel});
  }

  void _submitIELTS() {
    if (!_scoreFormKey.currentState!.validate()) {
      return;
    }

    final score = double.parse(_scoreController.text);
    _performSubmission({'IELTS Score': (score * 10).toInt()});
  }

  void _submitTOEIC() {
    if (!_scoreFormKey.currentState!.validate()) {
      return;
    }

    final score = int.parse(_scoreController.text);
    _performSubmission({'TOEIC Score': score});
  }

  void _performSubmission(Map<String, int> testScore) {
    setState(() {
      _isSubmitting = true;
    });

    // Create updated scores map
    Map<String, int> updatedScores = {...widget.submittedScores, ...testScore};

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

  Widget _buildLevelGrid() {
    final levelDetails = _levelBasedTests[_selectedTest]!;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: levelDetails.length,
      itemBuilder: (context, index) {
        final level = index + 1;
        final details = levelDetails[level]!;

        return GestureDetector(
          onTap: () => _selectLevel(level),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: _selectedLevel == level
                  ? details['color']
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
              border: _selectedLevel == level
                  ? Border.all(color: Colors.white, width: 2)
                  : null,
              boxShadow: _selectedLevel == level
                  ? [
                BoxShadow(
                  color: details['color'].withOpacity(0.5),
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
                    '$_selectedTest Level $level',
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
                    details['description'],
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
    );
  }

  Widget _buildScoreInput() {
    String inputLabel = '';
    String hintText = '';
    String? Function(String?)? validator;

    switch (_selectedTest) {
      case 'IELTS':
        inputLabel = 'IELTS Score';
        hintText = 'Enter score (0.0 - 9.0)';
        validator = (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter an IELTS score';
          }
          final score = double.tryParse(value);
          if (score == null || score < 0 || score > 9) {
            return 'Score must be between 0.0 and 9.0';
          }
          return null;
        };
        break;
      case 'TOEIC':
        inputLabel = 'TOEIC Score';
        hintText = 'Enter total score (10-990)';
        validator = (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a TOEIC score';
          }
          final score = int.tryParse(value);
          if (score == null || score < 10 || score > 990) {
            return 'Score must be between 10 and 990';
          }
          return null;
        };
        break;
      default:
        return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _scoreFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              inputLabel,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _scoreController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: _selectedTest == 'IELTS'
                  ? [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d+\.?\d{0,1}'),
                )
              ]
                  : [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                hintText: hintText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                errorStyle: const TextStyle(color: Colors.red),
              ),
              validator: validator,
            ),
            if (_selectedTest == 'IELTS')
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _buildIELTSLevelIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIELTSLevelIndicator() {
    final scoreText = _scoreController.text;
    final score = double.tryParse(scoreText);
    String? matchedLevel;

    if (score != null) {
      for (var entry in _ieltsLevels.entries) {
        if (score >= entry.value['min'] && score <= entry.value['max']) {
          matchedLevel = entry.key;
          break;
        }
      }
    }

    return Row(
      children: [
        const Icon(Icons.info_outline, color: Colors.blue, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            matchedLevel != null
                ? 'CEFR Level: $matchedLevel'
                : 'Enter a valid IELTS score to see CEFR level',
            style: TextStyle(
              color: matchedLevel != null ? Colors.blue : Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Language Proficiency Tests",
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
            "Select Your Language Test",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Choose the language test and enter your score or level",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    ),

    // Language Test Selection
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            'JLPT', 'HSK', 'DELE', 'IELTS', 'TOEIC'
          ].map((test) {
            return Padding(
                padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
            onPressed: () => _selectTest(test),
            style: ElevatedButton.styleFrom(
            backgroundColor: _selectedTest == test
            ? const Color(0xFF6DEEC7)
                : Colors.grey[200],
            foregroundColor: _selectedTest == test
            ? Colors.black
                : Colors.black87,
            ),
            child: Text(test),
            ),
            );
          }).toList(),
        ),
      ),
    ),

            // Content based on selected test
            Expanded(
              child: _selectedTest.isEmpty
                  ? const SizedBox.shrink()
                  : (_levelBasedTests.containsKey(_selectedTest)
                  ? _buildLevelGrid()
                  : _buildScoreInput()),
            ),

            // Submit Button
            if (_selectedTest.isNotEmpty &&
                (_levelBasedTests.containsKey(_selectedTest) && _selectedLevel > 0 ||
                    (_selectedTest == 'IELTS' || _selectedTest == 'TOEIC') &&
                        _scoreController.text.isNotEmpty))
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitLanguageTest,
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

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
  }
}