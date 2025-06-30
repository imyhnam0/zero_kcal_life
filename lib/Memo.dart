import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'GlobalsName.dart';
import 'dart:async';

class MemoPage extends StatefulWidget {
  const MemoPage({super.key});

  @override
  State<MemoPage> createState() => _MemoPageState();
}

class _MemoPageState extends State<MemoPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? selectedTitle;
  TextEditingController _textController = TextEditingController();
  Timer? _debounce;
  int? expandedIndex;

  Map<String, dynamic> memoMap = {};

  @override
  void initState() {
    super.initState();
    _loadMemoData();
  }

  Future<void> _loadMemoData() async {
    final doc = await _firestore
        .collection('Users')
        .doc(globalEmail)
        .collection('memo')
        .doc('Alltitles')
        .get();

    if (doc.exists) {
      final updatedMap = Map<String, dynamic>.from(doc.data()?['title'] ?? {});
      setState(() {
        memoMap = updatedMap;

        if (selectedTitle == null && updatedMap.isNotEmpty) {
          selectedTitle = updatedMap.keys.first;
        }

        if (selectedTitle != null && updatedMap.containsKey(selectedTitle)) {
          _textController.text = updatedMap[selectedTitle]!['text'] ?? '';
        }
      });
    }
  }

  Future<void> _updateMemoText(String text) async {
    if (selectedTitle == null) return;

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () async {
      await _firestore
          .collection('Users')
          .doc(globalEmail)
          .collection('memo')
          .doc('Alltitles')
          .set({
            'title': {
              selectedTitle!: {'text': text, 'updatedAt': Timestamp.now()},
            },
          }, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          memoMap[selectedTitle!]!['text'] = text;
        });
      }
    });
  }

  Future<void> _showAddMemoDialog() async {
    TextEditingController _titleController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('메모 제목 입력', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _titleController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: '제목을 입력하세요',
            hintStyle: TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () async {
              String title = _titleController.text.trim();
              if (title.isNotEmpty) {
                await _firestore
                    .collection('Users')
                    .doc(globalEmail)
                    .collection('memo')
                    .doc('Alltitles')
                    .set({
                      'title': {
                        title: {'text': '', 'createdAt': Timestamp.now()},
                      },
                    }, SetOptions(merge: true));

                Navigator.pop(context);
                _loadMemoData();
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        backgroundColor: Colors.grey[100],
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 16),
          children: [
            ListTile(
              title: const Text('메모 추가', style: TextStyle(color: Colors.black87)),
              leading: const Icon(Icons.note_add, color: Colors.black),
              onTap: () {
                Navigator.pop(context);
                _showAddMemoDialog();
              },
            ),
            const Divider(color: Colors.black26),
            ...memoMap.keys.toList().asMap().entries.map((entry) {
              int index = entry.key;
              String title = entry.value;

              bool isExpanded = expandedIndex == index;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Text(
                      title,
                      style: TextStyle(
                        color: title == selectedTitle
                            ? Colors.black
                            : Colors.grey[700],
                        fontWeight: title == selectedTitle
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.black),
                      onPressed: () {
                        setState(() {
                          expandedIndex = isExpanded ? null : index; // toggle
                        });
                      },
                    ),
                    onTap: () {
                      setState(() {
                        selectedTitle = title;
                        _textController.text = memoMap[title]?['text'] ?? '';
                      });
                      Navigator.pop(context);
                    },
                  ),
                  if (isExpanded)
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              // 이름 수정 다이얼로그
                              TextEditingController renameController =
                                  TextEditingController(text: title);
                              await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: Colors.grey[900],
                                  title: const Text(
                                    "이름 수정",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  content: TextField(
                                    controller: renameController,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text(
                                        '취소',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        String newTitle = renameController.text.trim();
                                        if (newTitle.isNotEmpty && newTitle != title) {
                                          // 🔽 Firestore에서 최신 데이터 다시 가져오기
                                          final snapshot = await _firestore
                                              .collection('Users')
                                              .doc(globalEmail)
                                              .collection('memo')
                                              .doc('Alltitles')
                                              .get();

                                          final titleMap = snapshot.data()?['title'] ?? {};
                                          final currentText = titleMap[title]?['text'] ?? '';
                                          final createdAt = titleMap[title]?['createdAt'] ?? Timestamp.now();

                                          // 🔁 새 제목으로 이동 & 기존 제목 삭제
                                          await _firestore
                                              .collection('Users')
                                              .doc(globalEmail)
                                              .collection('memo')
                                              .doc('Alltitles')
                                              .set({
                                            'title': {
                                              title: FieldValue.delete(),
                                              newTitle: {
                                                'text': currentText,
                                                'createdAt': createdAt,
                                                'updatedAt': Timestamp.now(),
                                              },
                                            }
                                          }, SetOptions(merge: true));

                                          setState(() {
                                            selectedTitle = newTitle;
                                            expandedIndex = null;
                                          });
                                          await _loadMemoData();
                                        }
                                        Navigator.pop(context);
                                      },

                                      child: const Text('확인'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                '✏️ 이름 수정',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: Colors.grey[900],
                                  title: const Text("정말 삭제하시겠습니까?", style: TextStyle(color: Colors.white)),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text("아니오", style: TextStyle(color: Colors.white70)),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text("예", style: TextStyle(color: Colors.redAccent)),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await _firestore
                                    .collection('Users')
                                    .doc(globalEmail)
                                    .collection('memo')
                                    .doc('Alltitles')
                                    .update({
                                  'title.${title}': FieldValue.delete(),
                                });
                                if (selectedTitle == title) selectedTitle = null;
                                setState(() {
                                  expandedIndex = null;
                                });
                                await _loadMemoData();
                              }
                            },

                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                '🗑 삭제',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text(
          selectedTitle ?? 'Memo',
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ],
      ),
      body: memoMap.isEmpty
          ? const Center(
              child: Text('메모가 없습니다', style: TextStyle(color: Colors.white70)),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: TextField(
                controller: _textController,
                onChanged: _updateMemoText,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(color: Colors.black87, fontSize: 16),
                cursorColor: Colors.teal,
                decoration: const InputDecoration.collapsed(
                  hintText: '여기에 메모를 입력하세요...',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ),
      backgroundColor: Colors.white,

    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _textController.dispose();
    super.dispose();
  }
}
