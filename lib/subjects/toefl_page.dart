import 'package:flutter/material.dart';
import '../screens/calculate_page.dart';

class TOEFLPage extends StatefulWidget {
  final Map<String, int> submittedScores;
  final Function(Map<String, int>) onSubmit;

  const TOEFLPage({
    Key? key,
    this.submittedScores = const {},
    this.onSubmit = _defaultSubmit,
  }) : super(key: key);

  // Default empty function for when onSubmit isn't provided
  static void _defaultSubmit(Map<String, int> scores) {}

  @override
  _TOEFLPageState createState() => _TOEFLPageState();
}

class _TOEFLPageState extends State<TOEFLPage> {
  final TextEditingController readingController = TextEditingController();
  final TextEditingController listeningController = TextEditingController();
  final TextEditingController speakingController = TextEditingController();
  final TextEditingController writingController = TextEditingController();

  int totalScore = 0;
  String errorMessage = "";
  bool showErrorMessage = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing scores if available
    if (widget.submittedScores.containsKey('TOEFL Reading')) {
      readingController.text = widget.submittedScores['TOEFL Reading'].toString();
    }
    if (widget.submittedScores.containsKey('TOEFL Listening')) {
      listeningController.text = widget.submittedScores['TOEFL Listening'].toString();
    }
    if (widget.submittedScores.containsKey('TOEFL Speaking')) {
      speakingController.text = widget.submittedScores['TOEFL Speaking'].toString();
    }
    if (widget.submittedScores.containsKey('TOEFL Writing')) {
      writingController.text = widget.submittedScores['TOEFL Writing'].toString();
    }

    // Calculate total from existing values
    _calculateTotal();
  }

  void _calculateTotal() {
    int r = int.tryParse(readingController.text) ?? 0;
    int l = int.tryParse(listeningController.text) ?? 0;
    int s = int.tryParse(speakingController.text) ?? 0;
    int w = int.tryParse(writingController.text) ?? 0;

    setState(() {
      totalScore = r + l + s + w;
    });
  }

  @override
  void dispose() {
    readingController.dispose();
    listeningController.dispose();
    speakingController.dispose();
    writingController.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    int r = int.tryParse(readingController.text) ?? 0;
    int l = int.tryParse(listeningController.text) ?? 0;
    int s = int.tryParse(speakingController.text) ?? 0;
    int w = int.tryParse(writingController.text) ?? 0;
    int newTotal = r + l + s + w;

    if ([r, l, s, w].any((score) => score < 1 || score > 30)) {
      setState(() {
        errorMessage = "Invalid score! Enter between 1 and 30.";
        showErrorMessage = true;
      });
      return;
    }

    setState(() {
      totalScore = newTotal;
      showErrorMessage = false;
      _isSubmitting = true;
    });

    if (newTotal < 1 || newTotal > 120) {
      setState(() {
        _isSubmitting = false;
      });
      _showInvalidScorePopup();
    } else {
      try {
        // Create updated scores map
        Map<String, int> updatedScores = {...widget.submittedScores};

        // Only add the total TOEFL score, not individual section scores
        updatedScores['TOEFL Total'] = newTotal;

        // Call the onSubmit callback to update scores in parent
        widget.onSubmit(updatedScores);

        print("✅ Score submitted from TOEFL Page: Total Score = $totalScore");

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
  }

  void _showInvalidScorePopup() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Invalid Score"),
          content: const Text("TOEFL total score must be between 1 and 120."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("TOEFL Scores", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Total Score Display
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  child: Column(
                    children: [
                      const Text(
                        "Your Total Score",
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        totalScore.toString(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "1 to 120",
                        style: TextStyle(color: Colors.black54, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Score Input Fields
                _buildScoreInput("Reading", readingController, Icons.menu_book),
                _buildScoreInput("Listening", listeningController, Icons.headphones),
                _buildScoreInput("Speaking", speakingController, Icons.mic),
                _buildScoreInput("Writing", writingController, Icons.edit),

                // Error Message
                if (showErrorMessage)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),

                const SizedBox(height: 10),

                // Submit Button
                _buildButton(
                  text: "Submit Scores",
                  color: Colors.black,
                  textColor: Colors.white,
                  onTap: _isSubmitting ? null : _validateAndSubmit,
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

  // Reusable Score Input Field
  Widget _buildScoreInput(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        onChanged: (_) => _calculateTotal(),
        decoration: InputDecoration(
          labelText: "$label (1-30)",
          labelStyle: TextStyle(color: Colors.grey[700]),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black),
            borderRadius: BorderRadius.circular(10),
          ),
          prefixIcon: Icon(icon, color: Colors.black54),
        ),
        style: const TextStyle(color: Colors.black),
      ),
    );
  }

  // Reusable Button Widget
  Widget _buildButton({
    required String text,
    required Color color,
    required Color textColor,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: onTap == null ? Colors.grey : color,
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