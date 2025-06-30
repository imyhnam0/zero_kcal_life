import 'package:flutter/material.dart';
import 'TodayFood.dart';
import 'FoodRecord.dart';
import 'firebase_options.dart';
import 'loginpage.dart';
import 'Memo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'MyInfo.dart';
import 'GlobalsName.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

// SplashScreen에서 로그인 상태 확인 및 유저 정보 설정
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (!mounted) return;
      if (user != null) {
        globalUid = user.uid;
        globalEmail = user.email;
        try {

          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('Users')
              .doc(globalEmail)
              .get();

          if (userDoc.exists) {
            globalUserName = userDoc['name'];
            print("✅ globalUid: $globalUid, globalUserName: $globalUserName");
          }
        } catch (e) {
          print("❌ 사용자 이름 불러오기 실패: $e");
        }

        // 홈 화면으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyHomePage()),
        );
      } else {
        // 로그인 안된 경우 로그인 페이지로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

// 홈 화면
class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1C1F),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF122829),
        centerTitle: true,
        title: const Text(
          'Zero_kcal_life',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.local_dining_rounded, color: Colors.tealAccent),
          onPressed: () {
            // 여기에 기능 추가
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.tealAccent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyInfoPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildMainButton(
              context,
              icon: Icons.restaurant_menu,
              label: '오늘의 식단',
              color: Colors.tealAccent.shade400,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TodayFoodPage()),
                );
              },
            ),
            const SizedBox(height: 20),
            _buildMainButton(
              context,
              icon: Icons.edit_note_rounded,
              label: '식단 기록',
              color: Colors.lightGreenAccent.shade400,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FoodRecordPage()),
                );
              },
            ),
            const SizedBox(height: 20),
            _buildMainButton(
              context,
              icon: Icons.notes_rounded,
              label: '메모장',
              color: Colors.orangeAccent.shade200,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MemoPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainButton(
      BuildContext context, {
        required IconData icon,
        required String label,
        required Color color,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(width: 20),
            Text(
              label,
              style: TextStyle(
                fontSize: 20,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
