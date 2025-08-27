import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'GlobalsName.dart'; // globalEmail 변수를 선언한 파일

class TodayFoodPage extends StatefulWidget {
  const TodayFoodPage({super.key});

  @override
  State<TodayFoodPage> createState() => _TodayFoodPageState();
}

class _TodayFoodPageState extends State<TodayFoodPage> {
  int carbs = 0;
  int protein = 0;
  int fat = 0;
  int kcal = 0;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();

  List<String> meals = ['Meal 1'];
  Map<String, List<Map<String, TextEditingController>>> mealItemControllers = {
    'Meal 1': [
      {'name': TextEditingController(), 'gram': TextEditingController()},
    ],
  };

  // 🔹 칼로리 / 탄단지 입력 컨트롤러
  final TextEditingController kcalController = TextEditingController();
  final TextEditingController carbController = TextEditingController();
  final TextEditingController proteinController = TextEditingController();
  final TextEditingController fatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFoodData();
  }

  @override
  Widget build(BuildContext context) {
    Map<String, double> dataMap = {
      "탄수화물": carbs.toDouble(),
      "단백질": protein.toDouble(),
      "지방": fat.toDouble(),
    };

    final colorList = [
      Colors.cyanAccent.shade400, // 청록
      Colors.deepPurpleAccent.shade200, // 보라
      Colors.limeAccent.shade400, // 라임
    ];

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFF121212), // 다크 배경
        appBar: AppBar(
          title: const Text("Today's Food"),
          backgroundColor: const Color(0xFF1E1E1E),
          centerTitle: true,
          elevation: 1,
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context, true),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: TextButton(
                onPressed: _saveFoodData,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '저장',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // 🔹 요약 차트 + 칼로리 입력칸
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  PieChart(
                    dataMap: dataMap,
                    animationDuration: const Duration(milliseconds: 1000),
                    chartRadius: 140,
                    chartType: ChartType.ring,
                    ringStrokeWidth: 26,
                    colorList: colorList,
                    centerText: "$kcal kcal",
                    centerTextStyle: const TextStyle(
                      color: Colors.redAccent, // 🔥 원하는 색상
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    chartValuesOptions: const ChartValuesOptions(
                      showChartValuesInPercentage: true,
                      decimalPlaces: 0,
                      showChartValueBackground: false,
                      chartValueStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    legendOptions: const LegendOptions(showLegends: false),
                  ),
                  const SizedBox(width: 28),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _inputField(
                          "칼로리 (kcal)",
                          kcalController,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 10),
                        _inputField(
                          "탄수화물 (g)",
                          carbController,
                          color: Colors.cyanAccent.shade400,
                        ),
                        const SizedBox(height: 10),
                        _inputField(
                          "단백질 (g)",
                          proteinController,
                          color: Colors.deepPurpleAccent.shade200,
                        ),
                        const SizedBox(height: 10),
                        _inputField(
                          "지방 (g)",
                          fatController,
                          color: Colors.limeAccent.shade400,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(thickness: 1, color: Colors.white24),

            // 🔹 Meal 입력 칸
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: meals.length,
                        itemBuilder: (context, index) {
                          final meal = meals[index];
                          mealItemControllers.putIfAbsent(
                            meal,
                            () => [
                              {
                                'name': TextEditingController(),
                                'gram': TextEditingController(),
                              },
                            ],
                          );
                          final rows = mealItemControllers[meal]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                meal,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.redAccent,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ...rows.map((row) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _styledTextField(
                                          controller: row['name']!,
                                          hint: '음식 이름',
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _styledTextField(
                                          controller: row['gram']!,
                                          hint: '예) 2개 , 150g..',
                                          isNumber: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _styledButton(
                                      label: '입력칸 추가',
                                      icon: Icons.add_circle_outline,
                                      color: Colors.white,
                                      onTap: () {
                                        setState(() {
                                          mealItemControllers[meal]!.add({
                                            'name': TextEditingController(),
                                            'gram': TextEditingController(),
                                          });
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 16),
                                    if (mealItemControllers[meal]!.length > 1)
                                      _styledButton(
                                        label: '입력칸 삭제',
                                        icon: Icons.remove_circle_outline,
                                        color: Colors.white,
                                        onTap: () {
                                          setState(() {
                                            mealItemControllers[meal]!
                                                .removeLast();
                                          });
                                        },
                                      ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),
                            ],
                          );
                        },
                      ),
                    ),
                    // 🔹 Meal 추가/삭제 버튼
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _styledButton(
                          label: 'Meal 추가',
                          icon: Icons.fastfood,
                          color: Colors.white,
                          onTap: () {
                            setState(() {
                              final newMeal = 'Meal ${meals.length + 1}';
                              meals.add(newMeal);
                              mealItemControllers[newMeal] = [
                                {
                                  'name': TextEditingController(),
                                  'gram': TextEditingController(),
                                },
                              ];
                            });
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _scrollController.animateTo(
                                _scrollController.position.maxScrollExtent,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            });
                          },
                        ),
                        const SizedBox(width: 16),
                        if (meals.length > 1)
                          _styledButton(
                            label: 'Meal 삭제',
                            icon: Icons.delete_outline,
                            color: Colors.white70,
                            onTap: () {
                              setState(() {
                                final removed = meals.removeLast();
                                mealItemControllers.remove(removed);
                              });
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 입력칸 위젯 (칼로리/탄단지)
  Widget _inputField(
    String label,
    TextEditingController controller, {
    Color? color,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(
          Icons.circle,
          color: color ?? Colors.white54,
          size: 14,
        ),
        // ← 색상 점 추가
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white38),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.tealAccent, width: 2),
        ),
      ),
    );
  }

  // 🔹 일반 음식 입력 칸
  Widget _styledTextField({
    required TextEditingController controller,
    required String hint,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white38),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.tealAccent, width: 2),
        ),
      ),
    );
  }

  // 🔹 버튼 위젯
  Widget _styledButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: color),
      label: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.bold, color: color),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        shadowColor: Colors.transparent,
        side: BorderSide(color: color, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
    );
  }

  // 🔹 저장 함수 (AI 제거, 직접 입력값 저장)
  Future<void> _saveFoodData() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final Map<String, List<Map<String, String>>> dataToSave = {};

    for (final meal in meals) {
      final rows = mealItemControllers[meal];
      if (rows != null && rows.isNotEmpty) {
        dataToSave[meal] = rows
            .map((row) {
              return {
                'name': row['name']!.text.trim(),
                'gram': row['gram']!.text.trim(),
              };
            })
            .where(
              (item) => item['name']!.isNotEmpty || item['gram']!.isNotEmpty,
            )
            .toList();
      }
    }

    // 🔹 직접 입력한 칼로리/탄단지 값 저장
    final int inputKcal = int.tryParse(kcalController.text) ?? 0;
    final int inputCarbs = int.tryParse(carbController.text) ?? 0;
    final int inputProtein = int.tryParse(proteinController.text) ?? 0;
    final int inputFat = int.tryParse(fatController.text) ?? 0;

    try {
      await _firestore
          .collection('Users')
          .doc(globalEmail)
          .collection('TodayFood')
          .doc(today)
          .set({
            ...dataToSave,
            'Sum': {
              'kcal': inputKcal,
              'carbs': inputCarbs,
              'protein': inputProtein,
              'fat': inputFat,
            },
          });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('저장 완료!')));
      setState(() {
        kcal = inputKcal;
        carbs = inputCarbs;
        protein = inputProtein;
        fat = inputFat;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
    }
  }

  // 🔹 데이터 불러오기
  Future<void> _loadFoodData() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayDocRef = _firestore
        .collection('Users')
        .doc(globalEmail)
        .collection('TodayFood')
        .doc(today);

    final todayDoc = await todayDocRef.get();

    if (todayDoc.exists) {
      _applyFoodData(todayDoc.data()!); // ✅ 오늘 데이터 있으면 그대로 사용
    } else {
      // ✅ 오늘 데이터가 없으면, 가장 가까운 과거 데이터 찾기
      final snapshot = await _firestore
          .collection('Users')
          .doc(globalEmail)
          .collection('TodayFood')
          .where(FieldPath.documentId, isLessThan: today) // 오늘보다 이전
          .orderBy(FieldPath.documentId, descending: true) // 최신순
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final nearestDoc = snapshot.docs.first;
        _applyFoodData(nearestDoc.data()); // ✅ 가장 가까운 날짜 데이터 적용
      } else {
        print("❌ 불러올 데이터가 전혀 없습니다.");
      }
    }
  }

  // 🔹 불러온 데이터 적용 함수 (중복 방지)
  void _applyFoodData(Map<String, dynamic> data) {
    setState(() {
      meals = data.keys.where((key) => key != 'Sum').toList()
        ..sort((a, b) {
          final aNum = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          final bNum = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          return aNum.compareTo(bNum);
        });

      mealItemControllers.clear();

      for (var meal in meals) {
        final value = data[meal];
        if (value is List) {
          final items = List<Map<String, dynamic>>.from(value);
          mealItemControllers[meal] = items.map((item) {
            return {
              'name': TextEditingController(text: item['name'] ?? ''),
              'gram': TextEditingController(text: item['gram'] ?? ''),
            };
          }).toList();
        }
      }

      if (data.containsKey('Sum')) {
        final sum = Map<String, dynamic>.from(data['Sum']);
        kcal = sum['kcal'] ?? 0;
        carbs = sum['carbs'] ?? 0;
        protein = sum['protein'] ?? 0;
        fat = sum['fat'] ?? 0;

        kcalController.text = kcal.toString();
        carbController.text = carbs.toString();
        proteinController.text = protein.toString();
        fatController.text = fat.toString();
      }
    });
  }
}
