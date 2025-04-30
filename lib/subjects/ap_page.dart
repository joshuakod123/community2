import 'package:flutter/material.dart';
import '../screens/calculate_page.dart';

class APPage extends StatefulWidget {
  final Map<String, int> submittedScores;
  final Function(Map<String, int>) onSubmit;

  const APPage({Key? key, required this.submittedScores, required this.onSubmit}) : super(key: key);

  @override
  _APPageState createState() => _APPageState();
}

class _APPageState extends State<APPage> {
  final List<String> subjects = [
    "AP Capstone Diploma",
    "AP Arts",
    "AP English",
    "AP History & Social Sciences",
    "AP Math & Computer Science",
    "AP Sciences",
    "AP World Language & Cultures"
  ];

  final Map<String, List<String>> subCategories = {
    "AP Capstone Diploma": ["AP Research", "AP Seminar"],
    "AP Arts": ["AP 2-D Art and Design", "AP 3-D Art and Design", "AP Drawing", "AP Art History", "AP Music Theory"],
    "AP English": ["AP English Language and Composition", "AP English Literature and Composition"],
    "AP History & Social Sciences": [
      "AP African American Studies",
      "AP Comparative Government and Politics",
      "AP European History",
      "AP Human Geography",
      "AP Macroeconomics",
      "AP Microeconomics",
      "AP Psychology",
      "AP United States Government and Politics",
      "AP United States History",
      "AP World History: Modern"
    ],
    "AP Math & Computer Science": ["AP Calculus AB", "AP Calculus BC", "AP Computer Science A", "AP Computer Science Principles", "AP Precalculus", "AP Statistics"],
    "AP Sciences": ["AP Biology", "AP Chemistry", "AP Environmental Science", "AP Physics 1: Algebra-Based", "AP Physics 2: Algebra-Based", "AP Physics C: Electricity and Magnetism", "AP Physics C: Mechanics"],
    "AP World Language & Cultures": ["AP Chinese Language and Culture", "AP French Language and Culture", "AP German Language and Culture", "AP Italian Language and Culture", "AP Japanese Language and Culture", "AP Latin", "AP Spanish Language and Culture", "AP Spanish Literature and Culture"],
  };

  List<Map<String, dynamic>> selectedSubjects = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Add initial empty subject if none exist
    if (selectedSubjects.isEmpty) {
      selectedSubjects.add({"subSubject": null, "score": null});
    }

    // Debug: Print the scores that were passed in
    print("Received submitted scores: ${widget.submittedScores}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Light background
      appBar: AppBar(
        title: const Text("AP Courses", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  "AP Courses",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: ListView.builder(
                    itemCount: selectedSubjects.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            _showSubCategoryDialog(context, index);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100], // Light gray background
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              selectedSubjects[index]["subSubject"] != null &&
                                  selectedSubjects[index]["score"] != null
                                  ? "${selectedSubjects[index]["subSubject"]} - Score: ${selectedSubjects[index]["score"]}"
                                  : "Select Subject",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                _buildButton(
                  text: "Add Another Subject",
                  color: Colors.grey[200]!, // Light gray
                  textColor: Colors.black87,
                  onTap: () {
                    setState(() {
                      selectedSubjects.add({"subSubject": null, "score": null});
                    });
                  },
                ),

                const SizedBox(height: 10),

                _buildButton(
                  text: "Submit",
                  color: Colors.black, // Black button
                  textColor: Colors.white,
                  onTap: () {
                    _submitScores(context);
                  },
                ),
              ],
            ),
          ),

          // Show loading overlay when submitting
          if (_isSubmitting)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  void _submitScores(BuildContext context) async {
    // Check if we have any valid scores to submit
    bool hasValidScores = selectedSubjects.any((subject) =>
    subject["subSubject"] != null && subject["score"] != null);

    if (!hasValidScores) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one subject and score")),
      );
      return;
    }

    // Show loading state
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Create a copy of the existing scores
      Map<String, int> updatedScores = {...widget.submittedScores};

      // Add all selected subjects that have both a subject and score
      for (var subject in selectedSubjects) {
        if (subject["subSubject"] != null && subject["score"] != null) {
          // Add "AP " prefix to clearly identify AP scores
          updatedScores["AP ${subject["subSubject"]}"] = subject["score"];
        }
      }

      // Debug log
      print("✅ Score submitted from AP Page: $updatedScores");

      // Call the callback to update scores in parent
      widget.onSubmit(updatedScores);

      // Add a small delay to ensure the callback completes
      await Future.delayed(const Duration(milliseconds: 800));

      // Clear loading state
      setState(() {
        _isSubmitting = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Scores submitted successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to CalculatePage with the updated scores
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CalculatePage(scores: updatedScores),
        ),
      );
    } catch (e) {
      print("Error submitting scores: $e");
      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error submitting scores: $e")),
      );
    }
  }

  void _showSubCategoryDialog(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Select a Course",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  children: subCategories.entries.map((entry) {
                    return ExpansionTile(
                      title: Text(
                        entry.key,
                        style: const TextStyle(color: Colors.black87),
                      ),
                      children: entry.value.map((sub) {
                        return ListTile(
                          title: Text(sub, style: const TextStyle(color: Colors.black87)),
                          onTap: () {
                            _showScoreDialog(context, index, sub);
                          },
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showScoreDialog(BuildContext context, int index, String selectedSub) {
    List<int> scores = [1, 2, 3, 4, 5];

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 300,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Select a Score",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: scores.length,
                  itemBuilder: (context, i) {
                    return ListTile(
                      title: Text("Score: ${scores[i]}", style: const TextStyle(color: Colors.black87)),
                      onTap: () {
                        setState(() {
                          selectedSubjects[index]["subSubject"] = selectedSub;
                          selectedSubjects[index]["score"] = scores[i];
                        });
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildButton({
    required String text,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}