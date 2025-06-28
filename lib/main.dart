import 'package:flutter/material.dart';
import 'TodayFood.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zero_kcal_life',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Zero_kcal_life'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1C1F), // 다크 그린 배경
      appBar: AppBar(
      elevation: 0, // 그림자 제거
      backgroundColor: const Color(0xFF122829), // 더 짙은 그린블루 계열
      centerTitle: true,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.local_dining_rounded, color: Colors.tealAccent),
        onPressed: () {
          // TODO: 원하는 기능 연결 (예: drawer 열기)
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.tealAccent),
          onPressed: () {
            // TODO: 설정 페이지 이동
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
                // TODO: 식단 기록 이동
              },
            ),
            const SizedBox(height: 20),
            _buildMainButton(
              context,
              icon: Icons.notes_rounded,
              label: '메모장',
              color: Colors.orangeAccent.shade200,
              onTap: () {
                // TODO: 메모장 이동
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
