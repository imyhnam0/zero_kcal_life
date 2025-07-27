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
import 'bodyweight.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
      body: Center(child: CircularProgressIndicator()),
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
  int diffKcal = 0;
  int diffCarbs = 0;
  int diffProtein = 0;
  int diffFat = 0;
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

      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(globalEmail)
          .get();

      if (doc.exists && doc.data()!.containsKey('Sum')) {
        final sum = Map<String, dynamic>.from(doc['Sum']);
        final target = Map<String, dynamic>.from(userDoc['target'] ?? {});

        setState(() {
          kcal = sum['kcal'] ?? 0;
          carbs = sum['carbs'] ?? 0;
          protein = sum['protein'] ?? 0;
          fat = sum['fat'] ?? 0;

          diffKcal = (sum['kcal'] ?? 0) - (target['kcal'] ?? 0);
          diffCarbs = (sum['carbs'] ?? 0) - (target['carbs'] ?? 0);
          diffProtein = (sum['protein'] ?? 0) - (target['protein'] ?? 0);
          diffFat = (sum['fat'] ?? 0) - (target['fat'] ?? 0);
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
        title: const Text(
          'Zero_kcal_life',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFB2EBF2), // 진한 민트 (cyan 계열)
              Color(0xFFA5D6A7), // 진한 연두 (light green 계열)
              Color(0xFFF1F8E9), // 연초록 마무리
            ],

            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(18.0),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center, // ← 가운데 정렬
              children: [
                Text(
                  '환영합니다, $globalUserName 님! 👋',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade900,
                  ),
                ),
                Text(
                  DateFormat('yyyy년 MM월 dd일 EEEE').format(DateTime.now()),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: Colors.teal.shade800,
                    shadows: [
                      Shadow(
                        offset: Offset(0.5, 0.5),
                        blurRadius: 1,
                        color: Colors.black26,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                _buildSummaryCard(),
                const SizedBox(height: 20),
                _buildMainButton(
                  context,
                  icon: Icons.monitor_weight,
                  label: '몸무게 기록',
                  color: Colors.red,
                  onTap: () async {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BodyWeightPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _buildMainButton(
                  context,
                  icon: Icons.restaurant_menu,
                  label: '오늘의 식단',
                  color: Colors.teal,
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TodayFoodPage(),
                      ),
                    );

                    if (result == true) {
                      _loadTodaySummary(); // 저장했으면 다시 요약 갱신
                    }
                  },
                ),
                const SizedBox(height: 10),
                _buildMainButton(
                  context,
                  icon: Icons.edit_note_rounded,
                  label: '식단 기록',
                  color: Colors.lightGreen,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FoodRecordPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
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
      child: Stack(
        children: [
          Row(
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
                  showChartValueBackground: true,
                  showChartValues: true,
                ),
                legendOptions: const LegendOptions(showLegends: false),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem("칼로리", "$kcal kcal", Colors.black, diffKcal),
                    const SizedBox(height: 8),
                    _buildLegendItem("탄수화물", "$carbs g", colorList[0], diffCarbs),
                    const SizedBox(height: 8),
                    _buildLegendItem("단백질", "$protein g", colorList[1], diffProtein),
                    const SizedBox(height: 8),
                    _buildLegendItem("지방", "$fat g", colorList[2], diffFat),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: OutlinedButton(
              onPressed: () async {
                final TextEditingController kcalController =
                    TextEditingController();
                final TextEditingController carbController =
                    TextEditingController();
                final TextEditingController proteinController =
                    TextEditingController();
                final TextEditingController fatController =
                    TextEditingController();
                // 🔥 기존 목표값 불러오기
                final doc = await FirebaseFirestore.instance
                    .collection('Users')
                    .doc(globalEmail)
                    .get();

                if (doc.exists && doc.data() != null) {
                  final data = doc.data()!;
                  final target = data['target'] ?? {};
                  kcalController.text = (target['kcal'] ?? '').toString();
                  carbController.text = (target['carbs'] ?? '').toString();
                  proteinController.text = (target['protein'] ?? '').toString();
                  fatController.text = (target['fat'] ?? '').toString();
                }

                await showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      backgroundColor: const Color(0xFFF8FDFB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text(
                        "🎯 목표 설정",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black87,
                        ),
                      ),
                      content: SingleChildScrollView(
                        child: Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(bottom: 12.0),
                              child: Text(
                                "원하는 값을 입력하세요",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                            Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                "칼로리: ${kcalController.text} kcal",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),

                            _buildInputField("탄수화물 (g)", carbController),
                            _buildInputField("단백질 (g)", proteinController),
                            _buildInputField("지방 (g)", fatController),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("취소"),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {

                            final int carbs =
                                int.tryParse(carbController.text) ?? 0;
                            final int protein =
                                int.tryParse(proteinController.text) ?? 0;
                            final int fat =
                                int.tryParse(fatController.text) ?? 0;
                            final int kcal = (carbs * 4) + (protein * 4) + (fat * 9);

                            await FirebaseFirestore.instance
                                .collection('Users')
                                .doc(globalEmail)
                                .set({
                                  'target': {
                                    'kcal': kcal,
                                    'carbs': carbs,
                                    'protein': protein,
                                    'fat': fat,
                                  },
                                }, SetOptions(merge: true));

                            Navigator.pop(context);

                            _loadTodaySummary();

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("목표가 저장되었습니다!")),
                            );
                          },
                          child: const Text(
                            "저장",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },

              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.teal),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
              ),
              child: const Text(
                "목표",
                style: TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String value, Color color, int diff) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 12, height: 12, color: color),
            const SizedBox(width: 8),
            Text(
              "$label: ",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: Colors.black87,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        if (diff != 0)
          Padding(
            padding: const EdgeInsets.only(left: 20.0, top: 2),
            child: Text(
              diff > 0 ? "+$diff 초과" : "$diff 부족",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: diff > 0 ? Colors.red : Colors.blue,
              ),
            ),
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

Widget _buildInputField(String label, TextEditingController controller) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    ),
  );
}
