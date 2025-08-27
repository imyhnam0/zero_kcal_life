// 상단 import들은 그대로 유지
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'GlobalsName.dart';
import 'dart:math';

class BodyWeightPage extends StatefulWidget {
  const BodyWeightPage({super.key});

  @override
  State<BodyWeightPage> createState() => _BodyWeightPageState();
}

class _BodyWeightPageState extends State<BodyWeightPage> {
  final TextEditingController _weightController = TextEditingController();
  List<DateWeight> _data = [];
  Set<String> _selectedDateKeys = {};

  double chartHeight = 240.0;

  @override
  void initState() {
    super.initState();
    _loadWeights();
    //addRandomWeights();
  }

  // Future<void> addRandomWeights() async {
  //   final random = Random();
  //   final userRef = FirebaseFirestore.instance
  //       .collection('Users')
  //       .doc(globalEmail)
  //       .collection('BodyWeight');
  //
  //   for (int i = 1; i <= 10; i++) {
  //     final date = DateTime(2025, 7, i); // 2025년 7월 1일부터 10일까지
  //     final dateStr = DateFormat('yyyy-MM-dd').format(date);
  //
  //     final weight = 70 + random.nextDouble() * 10; // 70.0 ~ 80.0 kg
  //
  //     await userRef.doc(dateStr).set({
  //       'weight': double.parse(weight.toStringAsFixed(1)),
  //       'selected': true,
  //     }, SetOptions(merge: true));
  //   }
  //
  //   debugPrint('랜덤 몸무게 데이터 추가 완료');
  // }

  Future<void> _loadWeights() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(globalEmail)
        .collection('BodyWeight')
        .orderBy(FieldPath.documentId)
        .get();

    List<DateWeight> list = [];
    Set<String> selectedKeys = {};

    for (var doc in snapshot.docs) {
      final date = DateFormat('yyyy-MM-dd').parse(doc.id);
      final weight = (doc['weight'] as num).toDouble();
      final selected = (doc['selected'] ?? true) == true;

      list.add(DateWeight(date: date, weight: weight));
      if (selected) selectedKeys.add(doc.id);
    }

    for (int i = 1; i < list.length; i++) {
      final prev = list[i - 1].weight;
      final curr = list[i].weight;
      final diff = curr - prev;
      final pct = prev > 0 ? diff / prev * 100 : 0.0;
      list[i]
        ..delta = diff
        ..pct = pct.toDouble();
    }

    setState(() {
      _data = list;
      _selectedDateKeys = selectedKeys;
    });
  }

  List<DateWeight> get _filteredData => _selectedDateKeys.isEmpty
      ? _data
      : _data.where((d) {
          final key = DateFormat('yyyy-MM-dd').format(d.date);
          return _selectedDateKeys.contains(key);
        }).toList();

  List<FlSpot> get _spots => _filteredData
      .asMap()
      .entries
      .map((e) => FlSpot(e.key.toDouble(), e.value.weight))
      .toList();

  List<String> get _labels =>
      _filteredData.map((d) => DateFormat('MM-dd').format(d.date)).toList();

  void _showWeightInputDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          title: Row(
            children: const [
              Icon(Icons.monitor_weight, color: Colors.teal),
              SizedBox(width: 8),
              Text(
                "오늘의 몸무게 입력",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: TextField(
            controller: _weightController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: '몸무게 (kg)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.fitness_center),
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.grey),
              label: const Text("취소", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final weight = double.tryParse(_weightController.text);
                if (weight != null) {
                  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
                  await FirebaseFirestore.instance
                      .collection('Users')
                      .doc(globalEmail)
                      .collection('BodyWeight')
                      .doc(today)
                      .set({
                    'weight': weight,
                    'selected': true,
                  }, SetOptions(merge: true));
                  _weightController.clear();
                  Navigator.pop(context);
                  await _loadWeights();
                }
              },
              icon: const Icon(Icons.save),
              label: const Text("저장"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }


  void _showDateSelectionDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.checklist, color: Colors.teal),
                      SizedBox(width: 8),
                      Text(
                        "날짜 선택",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      itemCount: _data.length,
                      itemBuilder: (context, index) {
                        final dateKey = DateFormat('yyyy-MM-dd').format(_data[index].date);
                        final isSelected = _selectedDateKeys.contains(dateKey);
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          child: CheckboxListTile(
                            title: Text(
                              DateFormat('yyyy년 MM월 dd일').format(_data[index].date),
                              style: const TextStyle(fontSize: 15),
                            ),
                            value: isSelected,
                            onChanged: (checked) async {
                              setStateSheet(() {
                                if (checked == true) {
                                  _selectedDateKeys.add(dateKey);
                                } else {
                                  _selectedDateKeys.remove(dateKey);
                                }
                              });

                              setState(() {}); // 부모 위젯도 갱신

                              await FirebaseFirestore.instance
                                  .collection('Users')
                                  .doc(globalEmail)
                                  .collection('BodyWeight')
                                  .doc(dateKey)
                                  .set({'selected': checked}, SetOptions(merge: true));
                            },
                            activeColor: Colors.teal,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.teal),
                      label: const Text(
                        "닫기",
                        style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final filtered = _filteredData;
    final spots = _spots;
    double? minY;
    double? maxY;

    if (spots.isNotEmpty) {
      minY = spots.map((e) => e.y).reduce(min);
      maxY = spots.map((e) => e.y).reduce(max);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '📈 몸무게 기록',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF121212), // 가장 어두운 톤
          Color(0xFF1E1E1E), // 중간 다크그레이
          Color(0xFF2C2C2C),], // 조금 밝은 그레이],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showDateSelectionDialog,
                    icon: const Icon(Icons.calendar_month, color: Colors.white),
                    label: const Text(
                      "날짜 선택",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2C2C2C), // 진한 다크그레이
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showWeightInputDialog,
                    icon: const Icon(Icons.monitor_weight, color: Colors.white),
                    label: const Text(
                      "몸무게 입력",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2C2C2C), // 진한 다크그레이
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            if (spots.isNotEmpty && minY != null && maxY != null)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: Colors.white,
                shadowColor: Colors.tealAccent,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (filtered.isNotEmpty)
                        Text(
                          '${filtered.last.weight.toStringAsFixed(1)}kg',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: chartHeight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: LineChart(
                                LineChartData(
                                  minY: minY - 1,
                                  maxY: maxY + 1,
                                  gridData: FlGridData(show: true),
                                  titlesData: FlTitlesData(
                                    topTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: spots,
                                      isCurved: true,
                                      color: Colors.black,
                                      barWidth: 3,
                                      dotData: FlDotData(show: true),
                                      belowBarData: BarAreaData(
                                        show: false,
                                        gradient: const LinearGradient(
                                          colors: [
                                            Colors.tealAccent,
                                            Colors.transparent,
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            ...spots.asMap().entries.map((entry) {
                              final i = entry.key;
                              final spot = entry.value;
                              final yPercent =
                                  (spot.y - minY!) / (maxY! - minY + 2);
                              final xPercent =
                                  spot.x / (spots.length - 1).clamp(1, 999);

                              return Positioned(
                                left:
                                    24 +
                                    xPercent *
                                        (MediaQuery.of(context).size.width *
                                                0.8 -
                                            48),
                                top: (1 - yPercent) * chartHeight - 24,
                                child: Text(
                                  '${spot.y.toStringAsFixed(1)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              const Expanded(child: Center(child: Text('데이터가 없습니다'))),
            const SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (ctx, i) {
                  final item = filtered[i];
                  final delta = item.delta;
                  final pct = item.pct;
                  final hasChange = i > 0;
                  Color color;
                  String sign;
                  if (!hasChange || delta == 0) {
                    color = Colors.black54;
                    sign = '';
                  } else if (delta > 0) {
                    color = Colors.red;
                    sign = '+';
                  } else {
                    color = Colors.blue;
                    sign = '-';
                  }
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        DateFormat('yyyy-MM-dd').format(item.date),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Row(
                        children: [
                          Text(
                            '${item.weight.toStringAsFixed(1)}kg',
                            style: const TextStyle(fontSize: 16),
                          ),
                          if (hasChange)
                            Text(
                              ' ($sign${delta.abs().toStringAsFixed(1)}kg, ${sign}${pct.abs().toStringAsFixed(1)}%)',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
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

class DateWeight {
  final DateTime date;
  final double weight;
  double delta = 0.0;
  double pct = 0.0;

  DateWeight({required this.date, required this.weight});
}
