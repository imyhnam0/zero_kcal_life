import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'GlobalsName.dart'; // globalEmail 변수를 선언한 파일
import 'dart:convert';
import 'package:http/http.dart' as http;

class TodayFoodPage extends StatefulWidget {
  const TodayFoodPage({super.key});

  @override
  State<TodayFoodPage> createState() => _TodayFoodPageState();

}

class _TodayFoodPageState extends State<TodayFoodPage> {

  bool isLoading = false;
  int carbs = 0;
  int protein = 0;
  int fat = 0;
  late int total = carbs + protein + fat;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<String> meals = ['Meal 1'];
  Map<String, List<Map<String, TextEditingController>>> mealItemControllers = {
    'Meal 1': [
      {'name': TextEditingController(), 'gram': TextEditingController()}
    ]
  };
  @override
  void initState() {
    super.initState();
    _loadFoodData(); // ← 저장된 데이터를 불러오는 함수
  }

  @override
  Widget build(BuildContext context) {
    Map<String, double> dataMap = {
      "탄수화물": carbs.toDouble(),
      "단백질": protein.toDouble(),
      "지방": fat.toDouble(),
    };

    final colorList = [
      Colors.orange,
      Colors.teal,
      Colors.pinkAccent,
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Today's Food"),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 1,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.teal),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: TextButton(
              onPressed: _saveFoodData,
              style: TextButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                isLoading
                    ? const SizedBox(
                  width: 140,
                  height: 140,
                  child: Center(child: CircularProgressIndicator()),
                )
                    :
                PieChart(
                  dataMap: dataMap,
                  animationDuration: const Duration(milliseconds: 1000),
                  chartRadius: 140,
                  chartType: ChartType.ring,
                  ringStrokeWidth: 26,
                  colorList: colorList,
                  chartValuesOptions: const ChartValuesOptions(
                    showChartValuesInPercentage: true,
                    decimalPlaces: 0,
                    showChartValueBackground: false,
                    chartValueStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),

                  ),
                  legendOptions: const LegendOptions(showLegends: false),

                ),
                const SizedBox(width: 28),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem(color: colorList[0], label: '탄수화물: $carbs g'),
                    const SizedBox(height: 10),
                    _buildLegendItem(color: colorList[1], label: '단백질: $protein g'),
                    const SizedBox(height: 10),
                    _buildLegendItem(color: colorList[2], label: '지방: $fat g'),
                  ],
                ),
              ],
            ),
          ),
          const Divider(thickness: 1, color: Colors.black12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: meals.length,
                      itemBuilder: (context, index) {
                        final meal = meals[index];
                        mealItemControllers.putIfAbsent(meal, () => [
                          {'name': TextEditingController(), 'gram': TextEditingController()}
                        ]);
                        final rows = mealItemControllers[meal]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              meal,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
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
                                          hint: '음식 이름'),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _styledTextField(
                                          controller: row['gram']!,
                                          hint: '그램 수',
                                          isNumber: true),
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
                                    color: Colors.purple,
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
                                      color: Colors.redAccent,
                                      onTap: () {
                                        setState(() {
                                          mealItemControllers[meal]!.removeLast();
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _styledButton(
                        label: 'Meal 추가',
                        icon: Icons.fastfood,
                        color: Colors.orange,
                        onTap: () {
                          setState(() {
                            final newMeal = 'Meal ${meals.length + 1}';
                            meals.add(newMeal);
                            mealItemControllers[newMeal] = [
                              {
                                'name': TextEditingController(),
                                'gram': TextEditingController(),
                              }
                            ];
                          });
                        },
                      ),
                      const SizedBox(width: 16),
                      if (meals.length > 1)
                        _styledButton(
                          label: 'Meal 삭제',
                          icon: Icons.delete_outline,
                          color: Colors.redAccent,
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
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      children: [
        Container(width: 14, height: 14, color: color),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.black87, fontSize: 16)),
      ],
    );
  }

  Widget _styledTextField({required TextEditingController controller, required String hint, bool isNumber = false}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.black87),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38),
        filled: true,
        fillColor: const Color(0xFFF2F2F2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.teal.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.teal.shade300, width: 2),
        ),
      ),
    );
  }

  Widget _styledButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: color),
      label: Text(label,
          style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        shadowColor: Colors.transparent,
        side: BorderSide(color: color, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
    );
  }
  Future<void> _loadFoodData() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      final doc = await _firestore
          .collection('Users')
          .doc(globalEmail)
          .collection('TodayFood')
          .doc(today)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        setState(() {
          meals = data.keys
              .where((key) => key != 'Sum')
              .toList()
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
            } else {
              print('⚠️ ${meal}의 데이터가 List가 아닙니다: ${value.runtimeType}');
            }
          }

          if (data.containsKey('Sum')) {
            final sum = Map<String, dynamic>.from(data['Sum']);
            carbs = sum['carbs'] ?? 0;
            protein = sum['protein'] ?? 0;
            fat = sum['fat'] ?? 0;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('불러오기 실패: $e')),
      );
    }
  }



  Future<void> _saveFoodData() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final Map<String, List<Map<String, String>>> dataToSave = {};

    for (final meal in meals) {
      final rows = mealItemControllers[meal];
      if (rows != null && rows.isNotEmpty) {
        dataToSave[meal] = rows.map((row) {
          return {
            'name': row['name']!.text.trim(),
            'gram': row['gram']!.text.trim(),
          };
        }).where((item) =>
        item['name']!.isNotEmpty || item['gram']!.isNotEmpty).toList();
      }
    }

    try {
      await _firestore
          .collection('Users')
          .doc(globalEmail)
          .collection('TodayFood')
          .doc(today)
          .set(dataToSave);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장 완료!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    }
    setState(() {
      isLoading = true;
    });
    await askGeminiByHttp(); // Gemini API 호출
    setState(() {
      isLoading = false;
    });
  }

  Future<void> askGeminiByHttp() async {
    const apiKey = 'AIzaSyBmyvzrPKDINiZfRuomuGdEmIOClxC9YeE';
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 1. Firebase에서 데이터 불러오기
    final doc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(globalEmail)
        .collection('TodayFood')
        .doc(today)
        .get();

    if (!doc.exists) {
      print("❗️오늘 저장된 데이터가 없습니다.");
      return;
    }

    final data = Map<String, dynamic>.from(doc.data()!);

    // 2. 프롬프트 만들기
    String prompt = "다음은 음식 이름과 그램 수입니다. 각 음식에 대한 칼로리, 탄수화물, 단백질, 지방을 예측해서 총합을 계산해주세요.\n\n";
    data.forEach((meal, items) {
      final list = List<Map<String, dynamic>>.from(items);
      for (var item in list) {
        final name = item['name'];
        final gram = item['gram'];
        prompt += "- $name ${gram}g\n";
      }
    });
    prompt += "\n총 칼로리= , 총 탄수화물= , 총 단백질= , 총 지방= 형식으로 요약해서 알려줘.";

    // 3. HTTP 요청 보내기
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey",
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ]
      }),
    );

    // 4. 응답 처리
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final text = decoded['candidates']?[0]['content']?['parts']?[0]['text'] ?? '응답 없음';
      print("✅ Gemini 응답:\n$text");

      // 정규식으로 수치 추출
      final carbMatch = RegExp(r'총 탄수화물\s*=\s*([\d.]+)').firstMatch(text);
      final proteinMatch = RegExp(r'총 단백질\s*=\s*([\d.]+)').firstMatch(text);
      final fatMatch = RegExp(r'총 지방\s*=\s*([\d.]+)').firstMatch(text);


      if (carbMatch != null && proteinMatch != null && fatMatch != null) {
        setState(() {
          carbs = double.parse(carbMatch.group(1)!).round();
          protein = double.parse(proteinMatch.group(1)!).round();
          fat = double.parse(fatMatch.group(1)!).round();
        });
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(globalEmail)
            .collection('TodayFood')
            .doc(today)
            .update({
          'Sum': {
            'carbs': carbs,
            'protein': protein,
            'fat': fat,
          }
        });
      }
    }
    else {
      print("❌ 오류: ${response.statusCode}\n${response.body}");
    }
  }
}
