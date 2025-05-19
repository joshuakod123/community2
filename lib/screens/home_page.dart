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
import '../pages/main_page.dart';
import '../subjects/language_test.dart';
// Add necessary imports for guides and widgets
import '../widgets/first_login_guide.dart';
import '../widgets/focused_element_guide.dart';
import '../widgets/tutorial_overlay.dart'; // For OnboardingStep

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

// Define the OnboardingGuide and OnboardingStep classes since they're referenced but not imported
class OnboardingGuide extends StatelessWidget {
  final String prefsKey;
  final List<OnboardingStep> steps;
  final Widget child;

  const OnboardingGuide({
    Key? key,
    required this.prefsKey,
    required this.steps,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class OnboardingStep {
  final String title;
  final String description;
  final IconData? icon;

  OnboardingStep({
    required this.title,
    required this.description,
    this.icon,
  });
}

class _HomePageState extends State<HomePage> {
  final SupabaseClient supabase = Supabase.instance.client;
  bool isPremium = false; // ✅ Default to false
  Map<String, int> submittedScores = {}; // ✅ Store submitted scores globally
  bool _isLoading = false;

  // References to interact with focus guides
  final GlobalKey _calculateButtonKey = GlobalKey();
  final GlobalKey _apHexagonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
    _loadSavedScores();

    // Schedule the guides to show after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showGuides();
    });
  }

  void _showGuides() {
    // Check if this is a new user or a different user from before
    final user = supabase.auth.currentUser;

    // Show the first login guide for this user
    FirstLoginGuide.showIfNeeded(context);

    // Show focused element guides after a delay to ensure all widgets are rendered
    Future.delayed(const Duration(seconds: 2), () {
      // Ensure the widget is still mounted and the context is valid
      if (!mounted) return;

      // Get the position and size of the calculate button
      if (_calculateButtonKey.currentContext != null) {
        final RenderBox renderBox = _calculateButtonKey.currentContext!.findRenderObject() as RenderBox;
        final position = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;

        // Show guide for the calculate button
        FocusedElementGuide.showIfNeeded(
          context,
          targetPosition: position,
          targetSize: size,
          title: 'Calculate Your Score',
          description: 'Tap here to calculate your admission probability based on your test scores.',
          isCircular: false,
          prefsKey: 'calculate_button_guide_showed',
        );
      }
    });

    // Show a guide for the AP hexagon after the first guide completes
    Future.delayed(const Duration(seconds: 8), () {
      // Ensure the widget is still mounted and the context is valid
      if (!mounted) return;

      if (_apHexagonKey.currentContext != null) {
        final RenderBox renderBox = _apHexagonKey.currentContext!.findRenderObject() as RenderBox;
        final position = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;

        FocusedElementGuide.showIfNeeded(
          context,
          targetPosition: position,
          targetSize: size,
          title: 'Add Your AP Scores',
          description: 'Tap on these hexagons to enter your test scores for different exams.',
          isCircular: true,
          prefsKey: 'ap_hexagon_guide_showed',
          onTryNow: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => APPage(submittedScores: submittedScores, onSubmit: _updateScores),
              ),
            );
          },
        );
      }
    });
  }

  // ✅ Fetch the user's premium status
  Future<void> _checkPremiumStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
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
    } catch (e) {
      print('Error checking premium status: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Load any previously saved scores
  Future<void> _loadSavedScores() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final response = await supabase
            .from('user_scores')
            .select('*')
            .eq('user_id', user.id);

        if (response != null && response.isNotEmpty) {
          Map<String, int> scores = {};

          for (var score in response) {
            if (score['subject'] != null && score['score'] != null) {
              String examType = score['exam_type'] ?? '';
              String subject = score['subject'] ?? '';

              String key = examType.isNotEmpty
                  ? '$examType $subject'
                  : subject;

              scores[key] = score['score'];
            }
          }

          setState(() {
            submittedScores = scores;
          });

          print('Loaded saved scores: $submittedScores');
        }
      }
    } catch (e) {
      print('Error loading saved scores: $e');
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

    // Wrap the entire page with the OnboardingGuide (now user-specific)
    return OnboardingGuide(
      prefsKey: 'home_onboarding_guide_showed',
      steps: [
        OnboardingStep(
          title: 'Welcome to Your Exam Journey',
          description: 'This is where you can track and manage all your standardized test scores.',
          icon: Icons.school,
        ),
        OnboardingStep(
          title: 'Choose Your Tests',
          description: 'Tap on the hexagons to enter your scores for different exams like AP, SAT, IB, and more.',
          icon: Icons.hexagon,
        ),
        OnboardingStep(
          title: 'Calculate Admission Chances',
          description: 'Use the Calculate button at the bottom to see your probability of getting admitted to your dream university.',
          icon: Icons.calculate,
        ),
        OnboardingStep(
          title: 'Unlock Premium Features',
          description: 'Subscribe to Premium for advanced insights and additional features.',
          icon: Icons.star,
        ),
      ],
      child: Scaffold(
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

                    // For the first hexagon (AP), add a key
                    GlobalKey? hexKey = (index == 0) ? _apHexagonKey : null;

                    return Positioned(
                      left: position.dx - 40,
                      top: position.dy - 40,
                      child: index == hexagonPositions.length - 1
                          ? _buildLockedHexagon(context)
                          : HexagonWidget(
                        key: hexKey,
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
                              MaterialPageRoute(
                                builder: (context) => SATPage(submittedScores: submittedScores, onSubmit: _updateScores),
                              ),
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
                              MaterialPageRoute(
                                builder: (context) => TOEFLPage(submittedScores: submittedScores, onSubmit: _updateScores),
                              ),
                            );
                          } else if (index == 5) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TopikPage(submittedScores: submittedScores, onSubmit: _updateScores),
                              ),
                            );
                          } else if (index == 6) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LanguageTestPage(submittedScores: submittedScores, onSubmit: _updateScores),
                              ),
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
                  // Navigate back to MainPageUI instead of just popping
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const MainPageUI()),
                  );
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
                key: _calculateButtonKey, // Add key for the focused element guide
                onCalculate: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CalculatePage(scores: submittedScores)),
                  );
                },
              ),
            ),

            // Show loading indicator when necessary
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ✅ Stores submitted scores persistently
  void _updateScores(Map<String, int> scores) {
    setState(() {
      submittedScores.addAll(scores);
    });

    // Print for debugging
    print('Updated scores: $submittedScores');
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