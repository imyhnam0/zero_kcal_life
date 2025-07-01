import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'GlobalsName.dart';
import 'dart:math';
import 'CalenderCategoryPage.dart';

class FoodRecordPage extends StatefulWidget {
  const FoodRecordPage({super.key});

  @override
  State<FoodRecordPage> createState() => _FoodRecordPageState();
}

class _FoodRecordPageState extends State<FoodRecordPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  Map<String, int> macros = {
    'cal': 0,
    'carbs': 0,
    'protein': 0,
    'fat': 0,
  };

  @override
  void initState() {
    super.initState();

    _loadMacrosForDate(_selectedDay);
  }



  Future<void> _loadMacrosForDate(DateTime date) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final doc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(globalEmail)
        .collection('Calender')
        .doc(formattedDate)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        macros = {
          'cal': (data['kcal'] ?? 0) as int,
          'carbs': (data['carbs'] ?? 0) as int,
          'protein': (data['protein'] ?? 0) as int,
          'fat': (data['fat'] ?? 0) as int,
        };
      });
    } else {
      setState(() {
        macros = {'cal': 0, 'carbs': 0, 'protein': 0, 'fat': 0};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDay);

    return Scaffold(
      backgroundColor: const Color(0xFFF2FDFC),
      appBar: AppBar(
        title: const Text("식단 기록"),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final DocumentReference ref = FirebaseFirestore.instance
                  .collection('Users')
                  .doc(globalEmail)
                  .collection('CalenderKategorie')
                  .doc('Titles');

              List<Map<String, Map<String, dynamic>>> categoryList = [];

              // Firestore에서 기존 카테고리 불러오기
              final doc = await ref.get();
              if (doc.exists && doc.data() != null) {
                final data = doc.data() as Map<String, dynamic>;
                final raw = data['titles'];
                if (raw is List) {
                  categoryList = raw
                      .map((e) => Map<String, Map<String, dynamic>>.from(
                      Map<String, dynamic>.from(e)))
                      .toList();
                }
              }
              showDialog(
                context: context,
                builder: (context) {
                  return StatefulBuilder(
                    builder: (context, setState) {
                      return AlertDialog(
                        backgroundColor: Colors.grey[200],
                        title: const Text(
                          "카테고리 목록",
                          style: TextStyle(fontWeight: FontWeight.bold
                          , fontSize: 20, color: Colors.black),
                        ),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (categoryList.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Text("저장된 카테고리가 없습니다."),
                                ),
                              if (categoryList.isNotEmpty)
                                ...categoryList.map((map) {
                                  final title = map.keys.first;
                                  return Card(
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                    margin: const EdgeInsets.symmetric(vertical: 6),
                                    child: ListTile(
                                      title: Text(
                                        title,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              backgroundColor: const Color(0xFFFDFDFD),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              title: const Text(
                                                "삭제 확인",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              content: Text(
                                                '정말 "$title" 카테고리를 삭제할까요?',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                              actionsPadding: const EdgeInsets.only(right: 12, bottom: 8),
                                              actions: [
                                                TextButton(
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: Colors.grey[700],
                                                    textStyle: const TextStyle(fontSize: 15),
                                                  ),
                                                  child: const Text("취소"),
                                                  onPressed: () => Navigator.pop(context, false),
                                                ),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.redAccent,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                                  ),
                                                  child: const Text(
                                                    "삭제",
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  onPressed: () => Navigator.pop(context, true),
                                                ),
                                              ],
                                            )

                                          );

                                          if (confirm == true) {
                                            categoryList.removeWhere((item) => item.containsKey(title));
                                            await ref.set({'titles': categoryList}, SetOptions(merge: true));
                                            setState(() {});
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('"$title" 삭제됨')),
                                            );
                                          }
                                        },
                                      ),
                                      onTap: () {
                                        Navigator.of(context).pop();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => CalenderCategoryPage(categoryTitle: title),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton.icon(
                            onPressed: () {
                              final TextEditingController inputController = TextEditingController();

                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    backgroundColor: const Color(0xFFFDFDFD),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    title: const Text(
                                      "새 카테고리 입력",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    content: TextField(
                                      controller: inputController,
                                      decoration: InputDecoration(
                                        hintText: "카테고리 이름 입력",
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Colors.grey),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Colors.teal, width: 2),
                                        ),
                                      ),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    actionsPadding: const EdgeInsets.only(right: 12, bottom: 10),
                                    actions: [
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.grey[700],
                                          textStyle: const TextStyle(fontSize: 15),
                                        ),
                                        child: const Text("취소"),
                                        onPressed: () => Navigator.of(context).pop(),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.teal,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                        ),
                                        child: const Text(
                                          "저장",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        onPressed: () async {
                                          final input = inputController.text.trim();
                                          if (input.isEmpty) return;

                                          final exists = categoryList.any((item) => item.containsKey(input));
                                          if (!exists) {
                                            categoryList.add({
                                              input: {"startDate": "", "endDate": ""},
                                            });
                                            await ref.set({'titles': categoryList}, SetOptions(merge: true));
                                            setState(() {});
                                          }

                                          Navigator.of(context).pop();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('"$input" 카테고리 저장됨')),
                                          );
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text("생성"),
                            style: TextButton.styleFrom(foregroundColor: Colors.teal),
                          ),
                        ],
                      );
                    },
                  );
                },
              );



            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              '카테고리',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],




        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.teal),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
              _loadMacrosForDate(selected); // 🔥 날짜 선택 시 해당 데이터 로드
            },
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.orangeAccent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.teal,
                shape: BoxShape.circle,
              ),
              defaultTextStyle: TextStyle(color: Colors.black87),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const Divider(thickness: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  DateFormat('yyyy년 MM월 dd일').format(_selectedDay),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatTile('총 칼로리', macros['cal']!, Icons.local_fire_department, Colors.redAccent),
                const SizedBox(height: 8),
                _buildStatTile('탄수화물', macros['carbs']!, Icons.rice_bowl, Colors.orange),
                _buildStatTile('단백질', macros['protein']!, Icons.egg_alt, Colors.green),
                _buildStatTile('지방', macros['fat']!, Icons.water_drop, Colors.pinkAccent),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, int value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Text(
            '$label: $value ${label == '총 칼로리' ? "kcal" : "g"}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
