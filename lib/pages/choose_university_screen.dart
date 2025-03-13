import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/main_page.dart';
import '../widgets/loading_widget.dart';

class ChooseUniversityScreen extends StatefulWidget {
  @override
  _ChooseUniversityScreenState createState() => _ChooseUniversityScreenState();
}

class _ChooseUniversityScreenState extends State<ChooseUniversityScreen> {
  String? selectedUniversity;
  String? enteredMajor;
  final supabase = Supabase.instance.client;
  bool _isLoading = false;
  bool _mounted = true;
  final _majorController = TextEditingController();

  final List<Map<String, String>> universities = [
    {"name": "가천대학교", "image": "assets/universities/gacheon.png"},
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
    {"name": "대전대학교", "image": "assets/universities/daejeon_univ.png"},
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
    _majorController.dispose();
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
        LoadingWidget.show(context, message: "Saving your preferences...");
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

  void showModernMajorInputDialog() {
    _majorController.clear(); // Clear previous input

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Enter Your Major",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A78DB),
            ),
          ),
          content: TextField(
            controller: _majorController,
            decoration: InputDecoration(
              hintText: "예: 컴퓨터공학",
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close pop-up
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
              ),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_mounted) {
                  setState(() {
                    enteredMajor = _majorController.text;
                  });
                }

                Navigator.pop(context); // Close pop-up

                await saveUniversityAndMajorSelection(); // Save to Supabase
                proceedToMainPage(); // Navigate to main page
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A78DB),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
          MaterialPageRoute(builder: (context) => const MainPageUI()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Choose Your University",
          style: TextStyle(
            color: Color(0xFF4A78DB),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4A78DB)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Select your dream university",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A78DB),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Choose the university you want to attend",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 20,
                      childAspectRatio: 0.85,
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

                          showModernMajorInputDialog(); // Open Major Input Pop-up
                        } : null,
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                border: selectedUniversity == universityName ?
                                Border.all(color: const Color(0xFF4A78DB), width: 2) : null,
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      universityImage,
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 70,
                                          height: 70,
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.school, color: Colors.grey),
                                        );
                                      },
                                    ),
                                  ),
                                  if (selectedUniversity == universityName)
                                    Positioned(
                                      top: -4,
                                      right: -4,
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF4A78DB),
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(2),
                                        child: const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              universityName,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: selectedUniversity == universityName ?
                                const Color(0xFF4A78DB) : Colors.black87,
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