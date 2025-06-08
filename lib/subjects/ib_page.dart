import 'package:flutter/material.dart';
import '../screens/calculate_page.dart';

class IBPage extends StatefulWidget {
  final Map<String, int> submittedScores;
  final Function(Map<String, int>) onSubmit;

  const IBPage({Key? key, required this.submittedScores, required this.onSubmit}) : super(key: key);

  @override
  _IBPageState createState() => _IBPageState();
}

class _IBPageState extends State<IBPage> {
  List<String> areas = [
    "Studies in Language and Literature",
    "Language Acquisition",
    "Individuals & Societies",
    "Sciences",
    "Mathematics",
    "The Arts"
  ];

  Map<String, List<String>> subjectsByArea = {
    "Studies in Language and Literature": ["English A Literature", "English A Language and Literature", "Literature and Performance"],
    "Language Acquisition": ["French B", "Spanish B", "German B", "Mandarin B", "Ab Initio Languages"],
    "Individuals & Societies": ["History", "Geography", "Economics", "Psychology", "Philosophy", "Global Politics", "Business Management", "World Religions"],
    "Sciences": ["Biology", "Chemistry", "Physics", "Computer Science", "Environmental Systems and Societies", "Sports, Exercise, and Health Science"],
    "Mathematics": ["Mathematics: Analysis & Approaches", "Mathematics: Applications & Interpretation"],
    "The Arts": ["Visual Arts", "Music", "Theatre", "Dance", "Film", "Literary Arts"]
  };

  List<int> scores = [1, 2, 3, 4, 5, 6, 7];

  // Store the selected subjects and their scores
  List<Map<String, dynamic>> selectedSubjects = [];
  int eeTokPoints = 0;
  int totalScore = 0;

  @override
  void initState() {
    super.initState();
    // Initialize with 6 empty subjects (standard IB curriculum)
    for (int i = 0; i < 6; i++) {
      selectedSubjects.add({
        "area": null,
        "subject": null,
        "score": null,
      });
    }
  }

  void _calculateTotalScore() {
    int subjectTotal = selectedSubjects
        .where((s) => s["score"] != null)
        .fold(0, (int sum, s) => sum + (s["score"] as int));

    setState(() {
      totalScore = subjectTotal + eeTokPoints;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("IB Page", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Total Score Container - like SAT Scores page
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100], // Light gray background like SAT page
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Your IB Total Score",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 18
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      "$totalScore / 45",
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              for (int i = 0; i < 6; i++) ...[
                // Subject header
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    "Subject ${i + 1}",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                _buildDropdown(
                    "Select Area",
                    selectedSubjects[i]["area"],
                    areas,
                        (value) {
                      setState(() {
                        selectedSubjects[i]["area"] = value;
                        selectedSubjects[i]["subject"] = null; // Reset subject when area changes
                      });
                    }
                ),
                _buildDropdown(
                  "Select Subject",
                  selectedSubjects[i]["subject"],
                  subjectsByArea[selectedSubjects[i]["area"]] ?? [],
                      (value) {
                    setState(() {
                      selectedSubjects[i]["subject"] = value;
                    });
                  },
                  enabled: selectedSubjects[i]["area"] != null,
                ),
                _buildDropdown(
                  "Enter Score (1-7)",
                  selectedSubjects[i]["score"] != null ? selectedSubjects[i]["score"].toString() : null,
                  scores.map((e) => e.toString()).toList(),
                      (value) {
                    setState(() {
                      selectedSubjects[i]["score"] = int.parse(value!);
                      _calculateTotalScore();
                    });
                  },
                  enabled: selectedSubjects[i]["subject"] != null,
                ),
                const SizedBox(height: 16),
              ],

              // EE & TOK header
              Align(
                alignment: Alignment.center,
                child: Text(
                  "EE & TOK Points",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              _buildDropdown(
                  "Select EE/TOK Points",
                  eeTokPoints > 0 ? eeTokPoints.toString() : null,
                  ["0", "1", "2", "3"],
                      (value) {
                    setState(() {
                      eeTokPoints = int.parse(value!);
                      _calculateTotalScore();
                    });
                  }
              ),

              const SizedBox(height: 24),

              // Black submit button matching SAT page
              InkWell(
                onTap: () {
                  _validateAndSubmitScores(context);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      "Submit Scores",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // New method to validate and show popup if needed
  void _validateAndSubmitScores(BuildContext context) {
    // Check if all subjects are filled
    bool allSubjectsFilled = true;

    for (var subject in selectedSubjects) {
      if (subject["area"] == null || subject["subject"] == null || subject["score"] == null) {
        allSubjectsFilled = false;
        break;
      }
    }

    // Check if EE/TOK score is selected
    bool eeTokSelected = eeTokPoints >= 0;

    // If all subjects and EE/TOK are filled, submit scores
    if (allSubjectsFilled && eeTokSelected) {
      _submitScores(context);
    } else {
      // Show popup if validation fails
      _showValidationPopup(context);
    }
  }

  // Show a popup message when validation fails
  void _showValidationPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Missing Information"),
          content: const Text(
            "Please make sure to fill in all subjects and the EE/TOK points to calculate your IB score correctly.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _submitScores(BuildContext context) {
    // Create a copy of the existing scores
    Map<String, int> updatedScores = {...widget.submittedScores};

    // Add all properly selected subjects with scores
    for (var subject in selectedSubjects) {
      if (subject["subject"] != null && subject["score"] != null) {
        updatedScores[subject["subject"]] = subject["score"];
      }
    }

    // Add EE & TOK points if set
    if (eeTokPoints > 0) {
      updatedScores["IB EE & TOK Points"] = eeTokPoints;
    }

    // Call the callback to update scores in parent
    widget.onSubmit(updatedScores);

    // Print for debugging
    print("✅ Score submitted from IB Page: $updatedScores");

    // Navigate to CalculatePage with updated scores
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CalculatePage(scores: updatedScores),
      ),
    );
  }

  Widget _buildDropdown(String hint, String? selectedValue, List<String> options, ValueChanged<String?> onChanged, {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100], // Light gray like SAT page
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[200]!), // Very light border
        ),
        child: DropdownButtonFormField<String>(
          value: selectedValue,
          dropdownColor: Colors.white,
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey[500]),
          items: options.isEmpty
              ? []
              : options.map((e) => DropdownMenuItem(
            value: e,
            child: Text(e, style: TextStyle(color: Colors.grey[700])),
          )).toList(),
          onChanged: enabled ? onChanged : null,
          style: TextStyle(color: Colors.grey[700], fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: enabled ? Colors.grey[500] : Colors.grey[400],
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }
}