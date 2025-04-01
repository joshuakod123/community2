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
      backgroundColor: const Color(0xFF0B090B), // 🌙 Night Background
      appBar: AppBar(
        title: const Text("IB Page", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4E1B8), // ✅ Wheat
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    const Text("Your IB Total Score", style: TextStyle(color: Colors.black, fontSize: 18)),
                    Text(
                      "$totalScore / 45",
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              for (int i = 0; i < 6; i++) ...[
                Text("Subject ${i + 1}", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6DEEC7))), // ✅ Aquamarine text
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
                const SizedBox(height: 10),
              ],

              const Text("EE & TOK Points", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6DEEC7))), // ✅ Aquamarine text
              _buildDropdown("Select EE/TOK Points", eeTokPoints > 0 ? eeTokPoints.toString() : null, ["0", "1", "2", "3"], (value) {
                setState(() {
                  eeTokPoints = int.parse(value!);
                  _calculateTotalScore();
                });
              }),

              const SizedBox(height: 20),

              _buildButton(
                text: "Submit Scores",
                color: const Color(0xFFE38C96), // ✅ Salmon Pink
                textColor: Colors.white,
                onTap: () {
                  _submitScores(context);
                },
              ),
            ],
          ),
        ),
      ),
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

  Widget _buildButton({required String text, required Color color, required Color textColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
        child: Center(child: Text(text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor))),
      ),
    );
  }

  Widget _buildDropdown(String hint, String? selectedValue, List<String> options, ValueChanged<String?> onChanged, {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        dropdownColor: const Color(0xFF0B090B), // 🌙 Night Background
        items: options.isEmpty
            ? []
            : options.map((e) => DropdownMenuItem(
          value: e,
          child: Text(e, style: const TextStyle(color: Color(0xFFAF95C6))), // ✅ African Violet text
        )).toList(),
        onChanged: enabled ? onChanged : null,
        decoration: InputDecoration(
          labelText: hint,
          labelStyle: TextStyle(
            color: enabled ? const Color(0xFFAF95C6) : Colors.grey, // ✅ African Violet text
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFFAF95C6)),
            borderRadius: BorderRadius.circular(10),
          ),
          disabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}