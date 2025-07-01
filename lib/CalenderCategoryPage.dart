import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'GlobalsName.dart';

class CalenderCategoryPage extends StatefulWidget {
  final String categoryTitle;

  const CalenderCategoryPage({super.key, required this.categoryTitle});

  @override
  State<CalenderCategoryPage> createState() => _CalenderCategoryPageState();
}

class _CalenderCategoryPageState extends State<CalenderCategoryPage> {
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  List<Map<String, dynamic>> calenderData = [];

  @override
  void initState() {
    super.initState();
    _loadCategoryDates();
  }

  Future<void> _loadCategoryDates() async {
    final ref = FirebaseFirestore.instance
        .collection('Users')
        .doc(globalEmail)
        .collection('CalenderKategorie')
        .doc('Titles');

    final doc = await ref.get();
    if (doc.exists) {
      final titles = List<Map<String, dynamic>>.from(doc['titles']);
      final item = titles.firstWhere(
              (e) => e.containsKey(widget.categoryTitle),
          orElse: () => {});
      if (item.isNotEmpty) {
        final data = Map<String, dynamic>.from(item[widget.categoryTitle]);
        _startDateController.text = data['startDate'] ?? '';
        _endDateController.text = data['endDate'] ?? '';
        print("✅ 카테고리 날짜 로드: ${_startDateController.text} ~ ${_endDateController.text}");
        if (_startDateController.text.isNotEmpty &&
            _endDateController.text.isNotEmpty) {
          _fetchCalenderData();
        }
      }
    }
  }

  Future<void> _saveDateRange() async {
    final ref = FirebaseFirestore.instance
        .collection('Users')
        .doc(globalEmail)
        .collection('CalenderKategorie')
        .doc('Titles');

    final doc = await ref.get();
    if (!doc.exists) return;

    final titles = List<Map<String, dynamic>>.from(doc['titles']);
    final idx = titles.indexWhere((e) => e.containsKey(widget.categoryTitle));
    if (idx != -1) {
      titles[idx][widget.categoryTitle] = {
        'startDate': _startDateController.text,
        'endDate': _endDateController.text,
      };
      await ref.set({'titles': titles}, SetOptions(merge: true));
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("✅ 날짜 저장 완료")));
    }
  }

  Future<void> _fetchCalenderData() async {
    if (_startDateController.text.isEmpty || _endDateController.text.isEmpty) return;

    final start = DateTime.parse(_startDateController.text);
    final end = DateTime.parse(_endDateController.text);
    final snapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(globalEmail)
        .collection('TodayFood')
        .get();

    final allData = snapshot.docs
        .map((doc) {
      final sum = doc.data()['Sum'] ?? {};
      return {
        'date': doc.id,
        'kcal': sum['kcal'] ?? 0,
        'carbs': sum['carbs'] ?? 0,
        'protein': sum['protein'] ?? 0,
        'fat': sum['fat'] ?? 0,
        'isExpanded': false,
      };
    })
        .where((entry) {
      final date = DateTime.tryParse(entry['date']);
      return date != null &&
          date.isAfter(start.subtract(const Duration(days: 1))) &&
          date.isBefore(end.add(const Duration(days: 1)));
    })
        .toList()
      ..sort((a, b) => a['date'].compareTo(b['date']));


    setState(() {
      calenderData = allData;
    });
  }

  Widget _buildDateField(String label, IconData icon, TextEditingController controller) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: TextField(
          controller: controller,
          readOnly: true, // 입력 불가능, 클릭만 가능
          onTap: () async {
            DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.tryParse(controller.text) ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: Colors.teal, // header background color
                      onPrimary: Colors.white, // header text color
                      onSurface: Colors.black, // body text color
                    ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(foregroundColor: Colors.teal),
                    ),
                  ),
                  child: child!,
                );
              },
            );

            if (picked != null) {
              controller.text = DateFormat('yyyy-MM-dd').format(picked);
            }
          },
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: Colors.teal),
            hintText: 'yyyy-MM-dd',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildMacroTag(String label, dynamic value, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        "$label: ${value ?? 0}${label == "칼로리" ? " kcal" : "g"}",
        style: TextStyle(fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FCFA),
      appBar: AppBar(
        title: Text(widget.categoryTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        foregroundColor: Colors.teal,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: Colors.green[100],
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    _buildDateField("시작 날짜", Icons.calendar_month, _startDateController),
                    _buildDateField("끝 날짜", Icons.calendar_today, _endDateController),
                    ElevatedButton(
                      onPressed: () async {
                        await _saveDateRange();
                        await _fetchCalenderData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      child: const Text("저장", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: calenderData.isEmpty
                  ? const Center(child: Text("📭 표시할 데이터가 없습니다."))
                  : ListView.builder(
                itemCount: calenderData.length,
                itemBuilder: (context, index) {
                  final entry = calenderData[index];
                  return Card(
                    color: Colors.green[100],
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(
                            entry['date'],
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          trailing: Icon(
                            entry['isExpanded'] ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          ),
                          onTap: () {
                            setState(() {
                              calenderData[index]['isExpanded'] = !calenderData[index]['isExpanded'];
                            });
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Wrap(
                            children: [
                              _buildMacroTag("칼로리", entry['kcal'], Colors.redAccent),
                              _buildMacroTag("탄수화물", entry['carbs'], Colors.orange),
                              _buildMacroTag("단백질", entry['protein'], Colors.green),
                              _buildMacroTag("지방", entry['fat'], Colors.pinkAccent),
                            ],
                          ),
                        ),
                        if (entry['isExpanded'] == true)
                          FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('Users')
                                .doc(globalEmail)
                                .collection('TodayFood')
                                .doc(entry['date'])
                                .get(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData || !snapshot.data!.exists) {
                                return const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text("MEAL 데이터 없음"),
                                );
                              }
                              final meals = snapshot.data!.data()! as Map<String, dynamic>;
                              final mealKeys = meals.keys.where((k) => k != 'Sum').toList();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: mealKeys.map((mealKey) {
                                  final items = List<Map<String, dynamic>>.from(meals[mealKey]);
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("🍽️ $mealKey", style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ...items.map((item) => Padding(
                                          padding: const EdgeInsets.only(left: 8.0, top: 2),
                                          child: Text("- ${item['name']} ${item['gram']}g"),
                                        )),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              );
                            },
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
    );
  }
}
