import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/main_page.dart';
import '../widgets/loading_widget.dart'; // Import our new loading widget

class ChooseUniversityScreen extends StatefulWidget {
  @override
  _ChooseUniversityScreenState createState() => _ChooseUniversityScreenState();
}

class _ChooseUniversityScreenState extends State<ChooseUniversityScreen> {
  String? selectedUniversity;
  String? enteredMajor;
  final supabase = Supabase.instance.client;
  bool _isLoading = false; // Add loading state
  bool _mounted = true; // Track if widget is mounted

  final List<Map<String, String>> universities = [
    {"name": "가천대학교", "image": "assets/universities/가천대학교.png"},
    {"name": "가톨릭관동대학교", "image": "assets/universities/가톨릭관동대학교.png"},
    {"name": "가톨릭대학교", "image": "assets/universities/가톨릭대학교.png"},
    {"name": "건국대학교", "image": "assets/universities/건국대학교.png"},
    {"name": "건양대학교", "image": "assets/universities/건양대학교.png"},
    {"name": "경희대학교", "image": "assets/universities/경희대학교.png"},
    {"name": "고려대학교", "image": "assets/universities/고려대학교.png"},
    {"name": "광운대학교", "image": "assets/universities/광운대학교.png"},
    {"name": "국민대학교", "image": "assets/universities/국민대학교.png"},
    {"name": "단국대학교", "image": "assets/universities/단국대학교.png"},
    {"name": "동국대학교 (경주)", "image": "assets/universities/동국대학교.png"},
    {"name": "대전대학교", "image": "assets/universities/[크기변환]대전대학교.png"},
    {"name": "대구가톨릭대학교", "image": "assets/universities/daegu_catholic.png"},
    {"name": "상지대학교", "image": "assets/universities/상지대학교.png"},
    {"name": "서강대학교", "image": "assets/universities/서강대학교.png"},
    {"name": "서울대학교", "image": "assets/universities/서울대학교.png"},
    {"name": "성균관대학교", "image": "assets/universities/성균관대학교.png"},
    {"name": "숙명여자대학교", "image": "assets/universities/숙명여자대학교.png"},
    {"name": "순천향대학교", "image": "assets/universities/순천향대학교.png"},
    {"name": "아주대학교", "image": "assets/universities/아주대학교.png"},
    {"name": "연세대학교", "image": "assets/universities/연세대학교.png"},
    {"name": "우석대학교", "image": "assets/universities/우석대학교.png"},
    {"name": "을지대학교", "image": "assets/universities/을지대학교.png"},
    {"name": "이화여자대학교", "image": "assets/universities/이화여자대학교.png"},
    {"name": "인제대학교", "image": "assets/universities/인제대학교.png"},
    {"name": "인하대학교", "image": "assets/universities/인하대학교.png"},
    {"name": "제주대학교", "image": "assets/universities/제주대학교.png"},
    {"name": "중앙대학교", "image": "assets/universities/중앙대학교.png"},
    {"name": "차의과대학교", "image": "assets/universities/차의과학대학교.png"},
    {"name": "충북대학교", "image": "assets/universities/충북대학교.png"},
    {"name": "포항공과대학교", "image": "assets/universities/포항공과대학교.png"},
    {"name": "KAIST", "image": "assets/universities/한국과학기술원.png"},
    {"name": "한림대학교", "image": "assets/universities/한림대학교.png"},
    {"name": "한양대학교", "image": "assets/universities/한양대학교.png"},
    {"name": "홍익대학교", "image": "assets/universities/홍익대학교.png"},
  ];

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> saveUniversityAndMajorSelection() async {
    if (!_mounted) return;

    setState(() {
      _isLoading = true;
    });

    final user = supabase.auth.currentUser;
    if (user == null) {
      print("No authenticated user found.");
      if (_mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      // Show loading dialog
      if (context.mounted) {
        LoadingWidget.show(context,message: "Saving your preferences...");
      }

      await supabase.from('users').update({
        'university': selectedUniversity,
        'major': enteredMajor,
      }).eq('id', user.id);

      // Hide loading dialog
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      print("University & Major saved: $selectedUniversity, $enteredMajor");
    } catch (error) {
      // Hide loading dialog on error
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      print("Error saving university & major: $error");

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving preferences: ${error.toString()}")),
        );
      }
    }

    if (_mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void showMajorInputDialog() {
    TextEditingController majorController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Enter Your Major"),
          content: TextField(
            controller: majorController,
            decoration: const InputDecoration(hintText: "예: 컴퓨터공학"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close pop-up
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                if (_mounted) {
                  setState(() {
                    enteredMajor = majorController.text;
                  });
                }

                Navigator.pop(context); // Close pop-up

                await saveUniversityAndMajorSelection(); // Save to Supabase
                proceedToMainPage(); // Navigate to main page
              },
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  void proceedToMainPage() {
    // Show loading dialog
    if (context.mounted) {
      LoadingWidget.show(context, message: "Saving your preferences...");
    }

    // Add a small delay for better UX
    Future.delayed(const Duration(seconds: 1), () {
      // Hide loading dialog
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Navigate to main page
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Choose Your University"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  "Select your dream university",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 15,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: universities.length,
                    itemBuilder: (context, index) {
                      String universityName = universities[index]['name']!;
                      String universityImage = universities[index]['image']!;

                      return GestureDetector(
                        onTap: !_isLoading ? () {
                          setState(() {
                            selectedUniversity = universityName;
                          });

                          showMajorInputDialog(); // Open Major Input Pop-up
                        } : null,
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(
                                    universityImage,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                if (selectedUniversity == universityName)
                                  const Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Icon(Icons.check_circle, color: Colors.green, size: 20),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              universityName,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: selectedUniversity == universityName ? Colors.deepPurple : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Overlay loading indicator when processing
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const LoadingWidget(
                backgroundColor: Colors.transparent,
                textColor: Colors.white,
                message: "Processing...",
              ),
            ),
        ],
      ),
    );
  }
}