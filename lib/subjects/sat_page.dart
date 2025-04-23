import 'package:flutter/material.dart';
import '../screens/calculate_page.dart';

class SATPage extends StatefulWidget {
  final Map<String, int> submittedScores;
  final Function(Map<String, int>) onSubmit;

  const SATPage({
    Key? key,
    this.submittedScores = const {},
    this.onSubmit = _defaultSubmit,
  }) : super(key: key);

  // Default empty function for when onSubmit isn't provided
  static void _defaultSubmit(Map<String, int> scores) {}

  @override
  _SATPageState createState() => _SATPageState();
}

class _SATPageState extends State<SATPage> {
  final TextEditingController readingWritingController = TextEditingController();
  final TextEditingController mathController = TextEditingController();

  int totalScore = 0;
  String errorMessage = "";
  bool showErrorMessage = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing scores if available
    if (widget.submittedScores.containsKey('SAT Reading & Writing')) {
      readingWritingController.text = widget.submittedScores['SAT Reading & Writing'].toString();
    }
    if (widget.submittedScores.containsKey('SAT Math')) {
      mathController.text = widget.submittedScores['SAT Math'].toString();
    }

    // Calculate total from existing values
    _calculateTotal();
  }

  void _calculateTotal() {
    int rw = int.tryParse(readingWritingController.text) ?? 0;
    int math = int.tryParse(mathController.text) ?? 0;

    setState(() {
      totalScore = rw + math;
    });
  }

  @override
  void dispose() {
    readingWritingController.dispose();
    mathController.dispose();
    super.dispose();
  }

  void _validateAndSubmit() async {
    int rw = int.tryParse(readingWritingController.text) ?? 0;
    int math = int.tryParse(mathController.text) ?? 0;
    int newTotal = rw + math;

    if (rw < 200 || rw > 800 || math < 200 || math > 800) {
      setState(() {
        errorMessage = "Invalid score! Enter between 200 and 800.";
        showErrorMessage = true;
      });
      return;
    }

    setState(() {
      totalScore = newTotal;
      showErrorMessage = false;
      _isSubmitting = true;
    });

    if (newTotal < 400 || newTotal > 1600) {
      setState(() {
        _isSubmitting = false;
      });
      _showInvalidScorePopup();
    } else {
      try {
        // Create updated scores map - ONLY send the total score
        Map<String, int> updatedScores = {...widget.submittedScores};

        // Save section scores for UI display only (not sent to calculator)
        // These are stored locally in the widget
        final localScores = {
          'SAT Reading & Writing': rw,
          'SAT Math': math,
        };

        // Add ONLY the SAT Total to the scores passed to the calculator
        updatedScores['SAT Total'] = newTotal;

        // Debug log to verify what's being sent
        print("✅ Score submitted from SAT Page: Total Score = $newTotal");
        print("✅ Complete scores map being sent: $updatedScores");

        // Call the onSubmit callback to update scores in parent
        widget.onSubmit(updatedScores);

        // Add a small delay to ensure the callback completes
        await Future.delayed(const Duration(milliseconds: 800));

        setState(() {
          _isSubmitting = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("SAT score submitted successfully!"),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to CalculatePage
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
  }

  void _showInvalidScorePopup() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Invalid Score"),
          content: const Text("Total SAT score must be between 400 and 1600."),
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
        title: const Text("SAT Scores", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          Padding(
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
                        "400 to 1600",
                        style: TextStyle(color: Colors.black54, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Score Input Fields
                _buildScoreInput("Reading & Writing Score", readingWritingController, Icons.menu_book),
                _buildScoreInput("Math Score", mathController, Icons.calculate),

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
          labelText: "$label (200-800)",
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