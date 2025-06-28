import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';

class TodayFoodPage extends StatefulWidget {
  const TodayFoodPage({super.key});

  @override
  State<TodayFoodPage> createState() => _TodayFoodPageState();
}

class _TodayFoodPageState extends State<TodayFoodPage> {
  final int carbs = 180;
  final int protein = 140;
  final int fat = 60;
  late final int total = carbs + protein + fat;

  List<String> meals = ['Meal 1'];

  Map<String, List<Map<String, TextEditingController>>> mealItemControllers = {
    'Meal 1': [
      {'name': TextEditingController(), 'gram': TextEditingController()}
    ]
  };

  @override
  Widget build(BuildContext context) {
    Map<String, double> dataMap = {
      "탄수화물": carbs.toDouble(),
      "단백질": protein.toDouble(),
      "지방": fat.toDouble(),
    };

    final colorList = [
      Colors.orangeAccent,
      Colors.tealAccent,
      Colors.pinkAccent,
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0E1C1F),
      appBar: AppBar(
        title: const Text("Today's Food"),
        backgroundColor: const Color(0xFF122829),
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.tealAccent),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: TextButton(
              onPressed: () {
                // TODO: 저장 동작 추가
              },
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
                      color: Colors.white,
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
          const Divider(thickness: 1, color: Colors.white24),
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
                                color: Colors.tealAccent,
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
                              child: // 기존의 입력칸 추가 버튼 아래를 아래로 교체
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _styledButton(
                                    label: '입력칸 추가',
                                    icon: Icons.add_circle_outline,
                                    color: Colors.purpleAccent,
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
                        color: Colors.orangeAccent,
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
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ],
    );
  }

  Widget _styledTextField({required TextEditingController controller, required String hint, bool isNumber = false}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF1F3A3D),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.tealAccent.shade100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.tealAccent.shade200, width: 2),
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
}
