// lib/screens/main_navigation_screen.dart
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'record_screen.dart';
import 'setting_screen.dart';
import 'ai_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  // 現在選択されているタブのインデックス（0: Home, 1: Record, 2: Setting）
  int _currentIndex = 0;

  // フッターで切り替える画面のリスト
  final List<Widget> _screens = const [
    HomeScreen(),
    RecordScreen(),
    SettingScreen(),
  ];

  // タイトル表示用リスト
  final List<String> _titles = const [
    'ホーム',
    '記録',
    '設定',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // === ヘッダー（AppBar） ===
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          // ヘッダー右上に配置する AI 画面への遷移ボタン
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined), // AIロボットアイコン
            tooltip: 'AI相談',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AiScreen()),
              );
            },
          ),
        ],
      ),

      // === 画面本体 ===
      body: _screens[_currentIndex],

      // === フッター（BottomNavigationBar） ===
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_note),
            label: 'Record',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Setting',
          ),
        ],
      ),
    );
  }
}