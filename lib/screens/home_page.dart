import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/bottom_bar.dart';
import '../widgets/hexagon_widget.dart';
import '../painters/line_painter.dart';
import '../subjects/ib_page.dart';
import '../subjects/toefl_page.dart';
import '../subjects/a_level_page.dart';
import '../subjects/ap_page.dart';
import '../subjects/sat_page.dart';
import '../subjects/topik_page.dart';
import '../subjects/premium_page.dart';
import '../screens/calculate_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SupabaseClient supabase = Supabase.instance.client;
  bool isPremium = false; // ✅ Default to false
  Map<String, int> submittedScores = {}; // ✅ Store submitted scores globally

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  // ✅ Fetch the user's premium status
  Future<void> _checkPremiumStatus() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final response = await supabase
          .from('users')
          .select('is_premium')
          .eq('id', user.id)
          .single();

      if (response != null && response['is_premium'] == true) {
        setState(() {
          isPremium = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Offset> hexagonPositions = [
      const Offset(180, 100), // AP
      const Offset(100, 200), // SAT
      const Offset(250, 250), // IB
      const Offset(150, 350), // A-Level
      const Offset(220, 450), // TOEFL
      const Offset(100, 550), // ✅ TOPIK
      const Offset(250, 650),
      const Offset(180, 750), // Locked hexagon (Premium Content)
    ];

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: LinePainter(points: hexagonPositions),
                  ),
                ),
                ...hexagonPositions.asMap().entries.map((entry) {
                  int index = entry.key;
                  Offset position = entry.value;

                  return Positioned(
                    left: position.dx - 40,
                    top: position.dy - 40,
                    child: index == hexagonPositions.length - 1
                        ? _buildLockedHexagon(context)
                        : HexagonWidget(
                      onTap: () {
                        if (index == 0) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => APPage(submittedScores: submittedScores, onSubmit: _updateScores),
                            ),
                          );
                        } else if (index == 1) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SATPage()),
                          );
                        } else if (index == 2) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => IBPage(submittedScores: submittedScores, onSubmit: _updateScores),
                            ),
                          );
                        } else if (index == 3) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ALevelPage()),
                          );
                        } else if (index == 4) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const TOEFLPage()),
                          );
                        } else if (index == 5) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const TopikPage()),
                          );
                        }
                      },
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          Positioned(
            bottom: 70,
            left: 15,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.black,
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),

          // ✅ Navigate to CalculatePage with scores
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomBar(
              onCalculate: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CalculatePage(scores: submittedScores)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Stores submitted scores persistently
  void _updateScores(Map<String, int> scores) {
    setState(() {
      submittedScores.addAll(scores);
    });
  }

  Widget _buildLockedHexagon(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (isPremium) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumPage()));
        } else {
          _showPaymentPopup(context);
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(opacity: 0.3, child: HexagonWidget(onTap: () {})),
          const Icon(Icons.lock, size: 30, color: Colors.black),
        ],
      ),
    );
  }

  void _showPaymentPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Access Restricted"),
          content: const Text("Further payment is required to proceed."),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("OK")),
          ],
        );
      },
    );
  }
}
