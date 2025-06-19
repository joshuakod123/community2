// lib/subjects/a_level_page.dart
import 'package:flutter/material.dart';
import '../screens/calculate_page.dart';

class ALevelPage extends StatefulWidget {
  final Map<String, int> submittedScores;
  final Function(Map<String, int>) onSubmit;

  const ALevelPage({
    Key? key,
    required this.submittedScores,
    required this.onSubmit,
  }) : super(key: key);

  @override
  _ALevelPageState createState() => _ALevelPageState();
}

class _ALevelPageState extends State<ALevelPage> {
  // A-Level subject areas and their corresponding subjects
  final List<String> areas = [
    "Sciences",
    "Mathematics",
    "English & Literature",
    "Humanities & Social Sciences",
    "Business & Economics",
    "Creative Arts & Design",
    "Modern Languages",
    "Technology & Computing",
  ];

  final Map<String, List<String>> subjectsByArea = {
    "Sciences": ["Biology", "Chemistry", "Physics", "Environmental Science", "Marine Science"],
    "Mathematics": ["Mathematics", "Further Mathematics", "Statistics"],
    "English & Literature": ["English Language", "English Literature", "English Language and Literature"],
    "Humanities & Social Sciences": ["History", "Geography", "Psychology", "Sociology", "Law", "Politics", "Classical Civilisation", "Philosophy", "Religious Studies", "Anthropology", "Archaeology"],
    "Business & Economics": ["Business Studies", "Economics", "Accounting"],
    "Creative Arts & Design": ["Art and Design", "Drama and Theatre", "Music", "Music Technology", "Dance", "Design and Technology", "Fashion and Textiles", "Media Studies", "Film Studies"],
    "Modern Languages": ["French", "German", "Spanish", "Chinese", "Italian", "Japanese", "Russian"],
    "Technology & Computing": ["Computer Science", "Information Technology", "Electronics"],
  };

  final List<String> grades = ["A*", "A", "B", "C", "D", "E"];
  final Map<String, int> gradeToScore = {
    "A*": 6,
    "A": 5,
    "B": 4,
    "C": 3,
    "D": 2,
    "E": 1,
  };

  // Store the selected subjects and their grades
  List<Map<String, dynamic>> selectedSubjects = [];
  int totalScore = 0;

  @override
  void initState() {
    super.initState();
    // Initialize with 3 empty subjects, as students typically take 3-4 A-Levels
    for (int i = 0; i < 3; i++) {
      selectedSubjects.add({"area": null, "subject": null, "grade": null});
    }
  }

  void _calculateTotalScore() {
    int currentTotal = 0;
    for (var subject in selectedSubjects) {
      if (subject["grade"] != null) {
        currentTotal += gradeToScore[subject["grade"]]!;
      }
    }
    setState(() {
      totalScore = currentTotal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("A-Level Page", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Total Score Container - like SAT/IB Scores page
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Your A-Level Score",
                      style: TextStyle(color: Colors.black, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      "$totalScore",
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
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: selectedSubjects.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            "Subject ${index + 1}",
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
                          selectedSubjects[index]["area"],
                          areas,
                              (value) {
                            setState(() {
                              selectedSubjects[index]["area"] = value;
                              selectedSubjects[index]["subject"] = null; // Reset subject
                            });
                          },
                        ),
                        _buildDropdown(
                          "Select Subject",
                          selectedSubjects[index]["subject"],
                          subjectsByArea[selectedSubjects[index]["area"]] ?? [],
                              (value) {
                            setState(() {
                              selectedSubjects[index]["subject"] = value;
                            });
                          },
                          enabled: selectedSubjects[index]["area"] != null,
                        ),
                        _buildDropdown(
                          "Enter Grade (A*-E)",
                          selectedSubjects[index]["grade"],
                          grades,
                              (value) {
                            setState(() {
                              selectedSubjects[index]["grade"] = value;
                              _calculateTotalScore();
                            });
                          },
                          enabled: selectedSubjects[index]["subject"] != null,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          selectedSubjects.add({"area": null, "subject": null, "grade": null});
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: const Text("Add Another Subject", style: TextStyle(color: Colors.black)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: _submitScores,
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

  void _submitScores() {
    Map<String, int> scoresToSubmit = {};
    for (var subject in selectedSubjects) {
      if (subject["subject"] != null && subject["grade"] != null) {
        scoresToSubmit["A-Level ${subject["subject"]}"] = gradeToScore[subject["grade"]]!;
      }
    }

    if (scoresToSubmit.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one subject and grade.")),
      );
      return;
    }

    widget.onSubmit(scoresToSubmit);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CalculatePage(scores: scoresToSubmit),
      ),
    );
  }

  Widget _buildDropdown(
      String hint,
      String? selectedValue,
      List<String> options,
      ValueChanged<String?> onChanged, {
        bool enabled = true,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: DropdownButtonFormField<String>(
          value: selectedValue,
          dropdownColor: Colors.white,
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey[500]),
          items: options.isEmpty
              ? []
              : options
              .map((e) => DropdownMenuItem(
            value: e,
            child: Text(e, style: TextStyle(color: Colors.grey[700])),
          ))
              .toList(),
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