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
import 'package:intl/intl.dart';
import 'package:pie_chart/pie_chart.dart';

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

      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF9F9F9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.green,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
        ),
      ),
      home: SplashScreen(),
    );
  }
}

// SplashScreen
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

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyHomePage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF9F9F9),
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

// 홈 화면
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int kcal = 0;
  int carbs = 0;
  int protein = 0;
  int fat = 0;

  @override
  void initState() {
    super.initState();
    _loadTodaySummary();
  }

  Future<void> _loadTodaySummary() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(globalEmail)
          .collection('TodayFood')
          .doc(today)
          .get();

      if (doc.exists && doc.data()!.containsKey('Sum')) {
        final sum = Map<String, dynamic>.from(doc['Sum']);
        setState(() {
          kcal = sum['kcal'] ?? 0;
          carbs = sum['carbs'] ?? 0;
          protein = sum['protein'] ?? 0;
          fat = sum['fat'] ?? 0;
        });
      }
    } catch (e) {
      print('❌ TodayFood summary 불러오기 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: const Text('Zero_kcal_life',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            )),
        leading: IconButton(
          icon: const Icon(Icons.local_dining_rounded, color: Colors.teal),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
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
            _buildSummaryCard(),
            const SizedBox(height: 20),
            _buildMainButton(
              context,
              icon: Icons.restaurant_menu,
              label: '오늘의 식단',
              color: Colors.teal,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TodayFoodPage()),
                );

                if (result == true) {
                  _loadTodaySummary(); // 저장했으면 다시 요약 갱신
                }
              },

            ),
            const SizedBox(height: 40),
            _buildMainButton(
              context,
              icon: Icons.edit_note_rounded,
              label: '식단 기록',
              color: Colors.lightGreen,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FoodRecordPage()),
                );
              },
            ),
            const SizedBox(height: 40),
            _buildMainButton(
              context,
              icon: Icons.notes_rounded,
              label: '메모장',
              color: Colors.orange,
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
  Widget _buildSummaryCard() {
    final Map<String, double> dataMap = {
      "탄수화물": carbs.toDouble(),
      "단백질": protein.toDouble(),
      "지방": fat.toDouble(),
    };

    final List<Color> colorList = [
      Colors.orange,
      Colors.teal,
      Colors.pinkAccent,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Row(
        children: [
          PieChart(
            dataMap: dataMap,
            animationDuration: const Duration(milliseconds: 800),
            chartRadius: 80,
            chartType: ChartType.ring,
            ringStrokeWidth: 22,
            colorList: colorList,
            chartValuesOptions: const ChartValuesOptions(
              showChartValuesInPercentage: true,
              showChartValueBackground: false,
              showChartValues: false, // 퍼센트 텍스트 제거
            ),
            legendOptions: const LegendOptions(showLegends: false),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegendItem("칼로리", "$kcal kcal", Colors.black),
                const SizedBox(height: 8),
                _buildLegendItem("탄수화물", "$carbs g", colorList[0]),
                const SizedBox(height: 8),
                _buildLegendItem("단백질", "$protein g", colorList[1]),
                const SizedBox(height: 8),
                _buildLegendItem("지방", "$fat g", colorList[2]),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildLegendItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 15),
        ),
      ],
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
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
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

