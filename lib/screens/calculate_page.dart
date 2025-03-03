import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/main_page.dart';
import '../widgets/loading_widget.dart';

class CalculatePage extends StatefulWidget {
  final Map<String, int> scores;

  const CalculatePage({Key? key, required this.scores}) : super(key: key);

  @override
  _CalculatePageState createState() => _CalculatePageState();
}

class _CalculatePageState extends State<CalculatePage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  Map<String, List<Map<String, dynamic>>> _scoresByExam = {};
  bool _isLoading = true;
  Map<String, int> _displayScores = {};
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _displayScores = Map.from(widget.scores);

    // Debug the incoming scores
    print("DEBUG: Initial scores received in CalculatePage: ${widget.scores}");

    // Save scores first, then fetch all scores
    if (widget.scores.isNotEmpty) {
      _saveScoresToDatabase(widget.scores).then((_) {
        _fetchUserScores();
      });
    } else {
      _fetchUserScores();
    }
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  void _navigateBack() {
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainPage()),
            (Route<dynamic> route) => false
    );
  }

  Future<void> _fetchUserScores() async {
    if (!_mounted) return;

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (_mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // Debug: Print user ID for troubleshooting
      print("DEBUG: Fetching scores for user ID: ${user.id}");

      final response = await _supabase
          .from('user_scores')
          .select('*')
          .eq('user_id', user.id);

      // Debug: Print the raw response from Supabase
      print("DEBUG: Scores fetch response: $response");

      // If no scores exist, clear local data
      if (response.isEmpty) {
        if (_mounted) {
          setState(() {
            _scoresByExam.clear();
            _displayScores.clear();
            _isLoading = false;
          });
        }
        return;
      }

      Map<String, List<Map<String, dynamic>>> newScoresByExam = {};
      Map<String, int> newDisplayScores = {};

      for (var score in response) {
        String examType = score['exam_type'] ?? '';
        if (!newScoresByExam.containsKey(examType)) {
          newScoresByExam[examType] = [];
        }
        newScoresByExam[examType]!.add(score);

        if (score['subject'] != null && score['score'] != null) {
          String key = "${examType.isNotEmpty ? examType + ' ' : ''}${score['subject']}";
          newDisplayScores[key] = score['score'];
        }
      }

      if (_mounted) {
        setState(() {
          _scoresByExam = newScoresByExam;
          _displayScores = newDisplayScores;
          _isLoading = false;
        });
      }

      print('📊 Display Scores: $_displayScores');
      print('📊 Scores by Exam: $_scoresByExam');

    } catch (e) {
      print('Error fetching scores: $e');

      if (_mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveScoresToDatabase(Map<String, int> scores) async {
    if (!_mounted) return;

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print("DEBUG: No user found when trying to save scores");
        return;
      }

      print("DEBUG: Saving scores for user ID: ${user.id}");
      print("DEBUG: Scores to save: $scores");

      List<Map<String, dynamic>> scoresToInsert = [];

      scores.forEach((key, value) {
        String examType = "";
        String subject = key;

        // Parse exam type and subject
        if (key.startsWith("AP ")) {
          examType = "AP";
          subject = key.substring(3);
        } else if (key.startsWith("TOEFL ")) {
          examType = "TOEFL";
          subject = key.substring(6);
        } else if (key.startsWith("SAT ")) {
          examType = "SAT";
          subject = key.substring(4);
        } else if (key.startsWith("IB ")) {
          examType = "IB";
          subject = key.substring(3);
        }

        scoresToInsert.add({
          'user_id': user.id,
          'exam_type': examType,
          'subject': subject,
          'score': value,
          'created_at': DateTime.now().toIso8601String(),
        });
      });

      if (scoresToInsert.isNotEmpty) {
        // Debug what we're about to insert
        print("DEBUG: About to insert scores: $scoresToInsert");

        var response = await _supabase.from('user_scores').upsert(
          scoresToInsert,
          onConflict: 'user_id, exam_type, subject',
        );

        print("DEBUG: Score insertion response: $response");
      }
    } catch (e) {
      print('Error saving scores to database: $e');
      // Display error for debugging
      if (_mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving scores: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B090B),
      appBar: AppBar(
        title: const Text("Your Scores", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _navigateBack,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6DEEC7)))
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_displayScores.isNotEmpty) ...[
              const Text(
                "Your Recent Scores",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6DEEC7),
                ),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4E1B8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _displayScores.entries.map((entry) =>
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          "${entry.key}: ${entry.value}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                  ).toList(),
                ),
              ),
              const SizedBox(height: 30),
            ],

            const Text(
              "Saved Scores by Exam",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6DEEC7),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _scoresByExam.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "No scores saved yet!",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    // Add a hint for debugging
                    if (_displayScores.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Text(
                          "Try refreshing to see your recent submissions",
                          style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                        ),
                      ),
                  ],
                ),
              )
                  : ListView.separated(
                itemCount: _scoresByExam.keys.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  String examType = _scoresByExam.keys.elementAt(index);
                  return GestureDetector(
                    onTap: () => _showScoresDialog(examType),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4E1B8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            examType,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                "${_scoresByExam[examType]!.length} scores",
                                style: const TextStyle(color: Colors.black54),
                              ),
                              const SizedBox(width: 5),
                              const Icon(Icons.chevron_right)
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Refresh the data
                  setState(() {
                    _isLoading = true;
                  });
                  _fetchUserScores();
                },
                icon: const Icon(Icons.refresh),
                label: const Text("Refresh Scores"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAF95C6),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: ElevatedButton.icon(
                onPressed: _navigateBack,
                icon: const Icon(Icons.arrow_back),
                label: const Text("Back to Home"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE38C96),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showScoresDialog(String examType) {
    if (!_mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0B090B),
        title: Text(
          "$examType Scores",
          style: const TextStyle(color: Color(0xFF6DEEC7)),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _scoresByExam[examType]!.map((score) =>
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "${score['subject']}: ${score['score']}",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          // Close the current dialog first
                          Navigator.pop(context);

                          // Show confirmation dialog
                          _showDeleteConfirmationDialog(score);
                        },
                      ),
                    ],
                  ),
                )
            ).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: Color(0xFFE788A0))),
          )
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(Map<String, dynamic> score) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0B090B),
        title: const Text(
          "Confirm Deletion",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "Are you sure you want to delete ${score['subject']} score of ${score['score']}?",
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteScore(score['id'].toString());
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteScore(String scoreId) async {
    if (!_mounted) return;

    try {
      // Show loading dialog
      LoadingWidget.show(context, message: "Deleting score...");

      // Delete from Supabase
      await _supabase
          .from('user_scores')
          .delete()
          .eq('id', scoreId);

      // Remove loading dialog
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Update local state by refreshing scores
      await _fetchUserScores();

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Score deleted successfully"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Remove loading dialog
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      print('Error deleting score: $e');

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete score: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}