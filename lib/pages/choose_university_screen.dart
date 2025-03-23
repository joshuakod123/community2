import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/main_page.dart';
import '../widgets/loading_widget.dart';

// Define the app colors as constants
const Color kPaynesGrey = Color(0xFF536878);
const Color kPearl = Color(0xFFEAE0C8);

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
    {"name": "가톨릭관동대학교", "image": "assets/universities/catholic_kwan.png"},
    {"name": "가톨릭대학교", "image": "assets/universities/catholic.png"},
    {"name": "건국대학교", "image": "assets/universities/gunguk.png"},
    {"name": "건양대학교", "image": "assets/universities/gunyang.png"},
    {"name": "경희대학교", "image": "assets/universities/kyunghee.png"},
    {"name": "고려대학교", "image": "assets/universities/korea.png"},
    {"name": "광운대학교", "image": "assets/universities/gwangwoon.png"},
    {"name": "국민대학교", "image": "assets/universities/kookmin.png"},
    {"name": "단국대학교", "image": "assets/universities/danguk.png"},
    {"name": "동국대학교 (경주)", "image": "assets/universities/dongguk.png"},
    {"name": "대전대학교", "image": "assets/universities/daejeon_univ.png"},
    {"name": "대구가톨릭대학교", "image": "assets/universities/daegu_catholic.png"},
    {"name": "상지대학교", "image": "assets/universities/shangji.png"},
    {"name": "서강대학교", "image": "assets/universities/seogang.png"},
    {"name": "서울대학교", "image": "assets/universities/seoul.png"},
    {"name": "성균관대학교", "image": "assets/universities/sungkunkwan.png"},
    {"name": "숙명여자대학교", "image": "assets/universities/sookmyung.png"},
    {"name": "순천향대학교", "image": "assets/universities/soonchun.png"},
    {"name": "아주대학교", "image": "assets/universities/aju.png"},
    {"name": "연세대학교", "image": "assets/universities/yonsei.png"},
    {"name": "우석대학교", "image": "assets/universities/woosuk.png"},
    {"name": "을지대학교", "image": "assets/universities/eulji.png"},
    {"name": "이화여자대학교", "image": "assets/universities/ewha.png"},
    {"name": "인제대학교", "image": "assets/universities/inje.png"},
    {"name": "인하대학교", "image": "assets/universities/inha.png"},
    {"name": "제주대학교", "image": "assets/universities/jejuuniv.png"},
    {"name": "중앙대학교", "image": "assets/universities/joongang.png"},
    {"name": "차의과대학교", "image": "assets/universities/cha_medical.png"},
    {"name": "충북대학교", "image": "assets/universities/chungbook.png"},
    {"name": "포항공과대학교", "image": "assets/universities/postech.png"},
    {"name": "KAIST", "image": "assets/universities/kaist.png"},
    {"name": "한림대학교", "image": "assets/universities/hanlim.png"},
    {"name": "한양대학교", "image": "assets/universities/hanyang.png"},
    {"name": "홍익대학교", "image": "assets/universities/hongik.png"},
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
          backgroundColor: kPearl,
          title: Text(
            "Enter Your Major",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kPaynesGrey,
            ),
          ),
          content: TextField(
            controller: _majorController,
            decoration: InputDecoration(
              hintText: "예: 컴퓨터공학",
              filled: true,
              fillColor: Colors.white.withOpacity(0.8),
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
                foregroundColor: kPaynesGrey,
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
                backgroundColor: kPaynesGrey,
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
      backgroundColor: kPearl,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: kPaynesGrey,
        centerTitle: true,
        title: const Text(
          "Choose Your University",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                Text(
                  "Select your dream university",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: kPaynesGrey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Choose the university you want to attend",
                  style: TextStyle(
                    fontSize: 16,
                    color: kPaynesGrey.withOpacity(0.7),
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
                                Border.all(color: kPaynesGrey, width: 2) : null,
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
                                        decoration: BoxDecoration(
                                          color: kPaynesGrey,
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
                                kPaynesGrey : kPaynesGrey.withOpacity(0.8),
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