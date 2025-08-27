import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'GlobalsName.dart';
import 'CalenderCategoryPage.dart';
import 'package:pie_chart/pie_chart.dart';

class FoodRecordPage extends StatefulWidget {
  const FoodRecordPage({super.key});

  @override
  State<FoodRecordPage> createState() => _FoodRecordPageState();
}

class _FoodRecordPageState extends State<FoodRecordPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, int> kcalPerDate = {};

  Map<String, int> macros = {'cal': 0, 'carbs': 0, 'protein': 0, 'fat': 0};

  @override
  void initState() {
    super.initState();
    _loadMacrosForDate(_selectedDay);
    _loadAllKcalData();
  }

  Future<void> _loadAllKcalData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(globalEmail)
        .collection('TodayFood')
        .get();

    Map<DateTime, int> loadedKcal = {};
    for (var doc in snapshot.docs) {
      final dateStr = doc.id;
      final sum = doc['Sum'] ?? {};
      final kcal = sum['kcal'] ?? 0;

      try {
        final date = DateFormat('yyyy-MM-dd').parse(dateStr);
        loadedKcal[DateTime(date.year, date.month, date.day)] = kcal;
      } catch (_) {}
    }

    setState(() {
      kcalPerDate = loadedKcal;
    });
  }

  Future<void> _loadMacrosForDate(DateTime date) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final doc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(globalEmail)
        .collection('TodayFood')
        .doc(formattedDate)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      final sum = data['Sum'] ?? {};

      setState(() {
        macros = {
          'cal': (sum['kcal'] ?? 0) as int,
          'carbs': (sum['carbs'] ?? 0) as int,
          'protein': (sum['protein'] ?? 0) as int,
          'fat': (sum['fat'] ?? 0) as int,
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
    return Scaffold(
      backgroundColor: const Color(0xFFF2FDFC),
      appBar: AppBar(
        title: const Text("식단 기록"),
        backgroundColor: Colors.green,
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
                      .map(
                        (e) => Map<String, Map<String, dynamic>>.from(
                          Map<String, dynamic>.from(e),
                        ),
                      )
                      .toList();
                }
              }
              showDialog(
                context: context,
                builder: (context) {
                  return StatefulBuilder(
                    builder: (context, setState) {
                      return AlertDialog(
                        backgroundColor: Colors.green[100],
                        title: const Text(
                          "카테고리 목록",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.black,
                          ),
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
                                    color: const Color(0xFFE8F5E9),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    child: ListTile(
                                      title: Text(
                                        title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.blueGrey,
                                            ),
                                            onPressed: () async {
                                              final TextEditingController
                                              editController =
                                                  TextEditingController(
                                                    text: title,
                                                  );
                                              final edited = await showDialog<String>(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                  backgroundColor: const Color(
                                                    0xFFFDFDFD,
                                                  ),
                                                  title: const Text(
                                                    "카테고리 이름 수정",
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  content: TextField(
                                                    controller: editController,
                                                    decoration: InputDecoration(
                                                      hintText: "새 이름 입력",
                                                      filled: true,
                                                      fillColor: Colors.white,
                                                      contentPadding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 16,
                                                            vertical: 14,
                                                          ),
                                                      border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        borderSide:
                                                            const BorderSide(
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                      ),
                                                      focusedBorder:
                                                          OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                            borderSide:
                                                                const BorderSide(
                                                                  color: Colors
                                                                      .teal,
                                                                  width: 2,
                                                                ),
                                                          ),
                                                    ),
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  actionsPadding:
                                                      const EdgeInsets.only(
                                                        right: 12,
                                                        bottom: 10,
                                                      ),
                                                  actions: [
                                                    TextButton(
                                                      style:
                                                          TextButton.styleFrom(
                                                            foregroundColor:
                                                                Colors
                                                                    .grey[700],
                                                            textStyle:
                                                                const TextStyle(
                                                                  fontSize: 15,
                                                                ),
                                                          ),
                                                      child: const Text("취소"),
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                          ),
                                                    ),
                                                    ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.teal,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10,
                                                              ),
                                                        ),
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 20,
                                                              vertical: 10,
                                                            ),
                                                      ),
                                                      child: const Text(
                                                        "확인",
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      onPressed: () {
                                                        final newName =
                                                            editController.text
                                                                .trim();
                                                        if (newName
                                                            .isNotEmpty) {
                                                          Navigator.pop(
                                                            context,
                                                            newName,
                                                          );
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              );

                                              if (edited != null &&
                                                  edited != title) {
                                                // 기존 항목 수정
                                                final oldItem = categoryList
                                                    .firstWhere(
                                                      (e) =>
                                                          e.containsKey(title),
                                                    );
                                                final content = oldItem[title];

                                                categoryList.removeWhere(
                                                  (e) => e.containsKey(title),
                                                );
                                                categoryList.add({
                                                  edited: content!,
                                                });

                                                await ref.update({
                                                  'titles': categoryList,
                                                });
                                                setState(() {});
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      '"$title" → "$edited" 이름 변경됨',
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () async {
                                              final confirm = await showDialog<bool>(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                  ),
                                                  backgroundColor:
                                                      Colors.green[100],
                                                  title: const Text(
                                                    "삭제 확인",
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  content: Text(
                                                    '정말 "$title" 카테고리를 삭제할까요?',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.grey[800],
                                                    ),
                                                  ),
                                                  actionsAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  actions: [
                                                    TextButton(
                                                      style:
                                                          TextButton.styleFrom(
                                                            foregroundColor:
                                                                Colors.teal,
                                                            textStyle:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                          ),
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                            false,
                                                          ),
                                                      child: const Text("취소"),
                                                    ),
                                                    TextButton(
                                                      style:
                                                          TextButton.styleFrom(
                                                            foregroundColor:
                                                                Colors.red,
                                                            textStyle:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                          ),
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                            true,
                                                          ),
                                                      child: const Text(
                                                        "삭제",
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );

                                              if (confirm == true) {
                                                categoryList.removeWhere(
                                                  (item) =>
                                                      item.containsKey(title),
                                                );
                                                await ref.set({
                                                  'titles': categoryList,
                                                }, SetOptions(merge: true));
                                                setState(() {});
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      '"$title" 삭제됨',
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        ],
                                      ),

                                      onTap: () {
                                        Navigator.of(context).pop();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                CalenderCategoryPage(
                                                  categoryTitle: title,
                                                ),
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
                              final TextEditingController inputController =
                                  TextEditingController();

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
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.grey,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.teal,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    actionsPadding: const EdgeInsets.only(
                                      right: 12,
                                      bottom: 10,
                                    ),
                                    actions: [
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.grey[700],
                                          textStyle: const TextStyle(
                                            fontSize: 15,
                                          ),
                                        ),
                                        child: const Text("취소"),
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.teal,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 10,
                                          ),
                                        ),
                                        child: const Text(
                                          "저장",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        onPressed: () async {
                                          final input = inputController.text
                                              .trim();
                                          if (input.isEmpty) return;

                                          final exists = categoryList.any(
                                            (item) => item.containsKey(input),
                                          );
                                          if (!exists) {
                                            categoryList.add({
                                              input: {
                                                "startDate": "",
                                                "endDate": "",
                                              },
                                            });
                                            await ref.set({
                                              'titles': categoryList,
                                            }, SetOptions(merge: true));
                                            setState(() {});
                                          }

                                          Navigator.of(context).pop();
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '"$input" 카테고리 저장됨',
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text(
                              "생성",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black,
                            ),
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
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],

        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  final kcal =
                      kcalPerDate[DateTime(day.year, day.month, day.day)];

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${day.day}'),
                      if (kcal != null)
                        Text(
                          '$kcal kcal',
                          style: TextStyle(fontSize: 10, color: Colors.teal),
                        ),
                    ],
                  );
                },
                todayBuilder: (context, day, focusedDay) {
                  final kcal =
                      kcalPerDate[DateTime(day.year, day.month, day.day)];

                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.orangeAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${day.day}',
                            style: TextStyle(color: Colors.white),
                          ),
                          if (kcal != null)
                            Text(
                              '$kcal kcal',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(thickness: 1),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    // 🔹 왼쪽: 차트
                    children: [
                      PieChart(
                        dataMap: {
                          "탄수화물": macros['carbs']!.toDouble(),
                          "단백질": macros['protein']!.toDouble(),
                          "지방": macros['fat']!.toDouble(),
                        },
                        animationDuration: const Duration(milliseconds: 1000),
                        chartRadius: 120,
                        chartType: ChartType.ring,
                        ringStrokeWidth: 22,
                        colorList: [
                          Colors.orange,
                          Colors.green,
                          Colors.pinkAccent,
                        ],
                        centerText: "${macros['cal']} kcal",
                        centerTextStyle: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        chartValuesOptions: const ChartValuesOptions(
                          showChartValuesInPercentage: true,
                          showChartValueBackground: false,
                          decimalPlaces: 0,
                          chartValueStyle: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        legendOptions: const LegendOptions(showLegends: false),
                      ),
                      const SizedBox(height: 40),

                      // 🔹 차트 아래 버튼
                      ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),

                                content: SizedBox(
                                  width: double.maxFinite,
                                  child: FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection('Users')
                                        .doc(globalEmail)
                                        .collection('TodayFood')
                                        .doc(DateFormat('yyyy-MM-dd').format(_selectedDay))
                                        .get(),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData || !snapshot.data!.exists) {
                                        return const Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Text("📭 오늘의 식단 정보가 없습니다."),
                                        );
                                      }

                                      final data = snapshot.data!.data()! as Map<String, dynamic>;
                                      final mealKeys = data.keys.where((k) => k != 'Sum').toList()
                                        ..sort();

                                      return SingleChildScrollView(
                                        child: Column(
                                          children: mealKeys.map((mealKey) {
                                            final items = List<Map<String, dynamic>>.from(data[mealKey]);

                                            return Card(
                                              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              elevation: 3,
                                              color: Colors.grey[50],
                                              child: Padding(
                                                padding: const EdgeInsets.all(16),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    // Meal 타이틀
                                                    Row(
                                                      children: [
                                                        const Icon(Icons.restaurant_menu, color: Colors.teal),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          "🍽️ $mealKey",
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 18,
                                                            color: Colors.black87,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 12),

                                                    // 음식 목록
                                                    ...items.map((item) {
                                                      final name = item['name'] ?? '';
                                                      final gram = item['gram'] ?? '';

                                                      return Container(
                                                        margin: const EdgeInsets.only(bottom: 8),
                                                        padding: const EdgeInsets.symmetric(
                                                            horizontal: 12, vertical: 10),
                                                        decoration: BoxDecoration(
                                                          color: Colors.teal.withOpacity(0.05),
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            Text(
                                                              name,
                                                              style: const TextStyle(
                                                                fontSize: 16,
                                                                fontWeight: FontWeight.w600,
                                                                color: Colors.black87,
                                                              ),
                                                            ),
                                                            Text(
                                                              gram,
                                                              style: const TextStyle(
                                                                fontSize: 15,
                                                                fontWeight: FontWeight.bold,
                                                                color: Colors.teal,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    }),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      );

                                    },
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text(
                                      "닫기",
                                      style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[800],   // ✅ 버튼 배경 (그레이톤)
                          foregroundColor: Colors.white,       // ✅ 글자색
                          padding: const EdgeInsets.symmetric( // ✅ 버튼 크기 (세로 늘리기)
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "식단 목록 보기",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    ],
                  ),

                  const SizedBox(width: 16),

                  // 🔹 오른쪽: 총 칼로리, 탄단지 카드들
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('yyyy년 MM월 dd일').format(_selectedDay),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        _buildStatTile(
                          '칼로리',
                          macros['cal']!,
                          Icons.local_fire_department,
                          Colors.redAccent,
                        ),
                        const SizedBox(height: 8),
                        _buildStatTile(
                          '탄수화물',
                          macros['carbs']!,
                          Icons.rice_bowl,
                          Colors.orange,
                        ),
                        _buildStatTile(
                          '단백질',
                          macros['protein']!,
                          Icons.egg_alt,
                          Colors.green,
                        ),
                        _buildStatTile(
                          '지방',
                          macros['fat']!,
                          Icons.water_drop,
                          Colors.pinkAccent,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          ],
        ),
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
