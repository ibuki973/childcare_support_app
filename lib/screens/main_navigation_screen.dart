// lib/screens/main_navigation_screen.dart
import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import 'home_screen.dart';
import 'record_screen.dart';
import 'setting_screen.dart';
import 'ai_screen.dart';
import 'calendar_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  // 現在選択されているタブのインデックス（0: Home, 1: Record, 2: Calendar, 3: Setting）
  int _currentIndex = 0;

  // 表示用の子ども情報
  String _childName = '未登録';
  String _childAgeText = '0歳0カ月（生後0日）';

  // フッターで切り替える画面のリスト
  final List<Widget> _screens = const [
    HomeScreen(),
    RecordScreen(),
    CalendarScreen(),
    SettingScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // 選択中の子どもが切り替わったら即座にヘッダー表示も更新する
    DatabaseHelper.instance.selectedChildIdNotifier.addListener(_loadChildInfo);
    _loadChildInfo();
  }

  @override
  void dispose() {
    DatabaseHelper.instance.selectedChildIdNotifier.removeListener(_loadChildInfo);
    super.dispose();
  }

  /// DBから現在選択中の子どもの情報を読み込み、名前と年齢・生後日数を作成する
  Future<void> _loadChildInfo() async {
    final child = await DatabaseHelper.instance.getSelectedChild();
    if (child == null) {
      if (!mounted) return;
      setState(() {
        _childName = '子ども未登録';
        _childAgeText = '設定から登録してください';
      });
      return;
    }

    final name = (child['name'] as String?) ?? 'なまえ未設定';
    final birthdayStr = child['birthday'] as String?;

    String ageText = '誕生日未設定';
    if (birthdayStr != null && birthdayStr.trim().isNotEmpty) {
      final birthDate = _parseBirthday(birthdayStr.trim());
      if (birthDate != null) {
        ageText = _formatAgeAndDays(birthDate);
      }
    }

    if (!mounted) return;
    setState(() {
      _childName = name;
      _childAgeText = ageText;
    });
  }

  /// 「2026年11月18日生」や「2026-11-18」から年月日を取り出してDateTimeに変換する
  DateTime? _parseBirthday(String raw) {
    // 1. 標準形式（2026-11-18など）で試す
    final direct = DateTime.tryParse(raw);
    if (direct != null) return direct;

    // 2. 「2026年11月18日生」などから数字の塊（年・月・日）を正規表現で抜き出す
    final numbers = RegExp(r'\d+')
        .allMatches(raw)
        .map((m) => int.parse(m.group(0)!))
        .toList();

    if (numbers.length >= 3) {
      return DateTime(numbers[0], numbers[1], numbers[2]);
    }
    return null;
  }

  /// 誕生日から「〇歳〇カ月（生後〇日）」の文字列を計算する
  String _formatAgeAndDays(DateTime birthDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final birth = DateTime(birthDate.year, birthDate.month, birthDate.day);

    // 生後日数（当日を「生後0日」とする）
    final days = today.difference(birth).inDays;
    final safeDays = days < 0 ? 0 : days;

    // 歳・カ月の計算
    int years = today.year - birth.year;
    int months = today.month - birth.month;
    if (today.day < birth.day) {
      months -= 1;
    }
    if (months < 0) {
      years -= 1;
      months += 12;
    }
    if (years < 0) {
      years = 0;
      months = 0;
    }

    return '$years歳$monthsカ月（生後$safeDays日）';
  }

  /// 添付画像風のカスタムヘッダー（高さ：画面の8.5分の1、タブレット向けに中央寄せ）
  PreferredSizeWidget _buildCustomHeader(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final headerHeight = screenHeight / 8.5;
    // Redmi Pad 2 などで中央寄りになるよう画面幅の10%を左右の余白に設定
    final horizontalPadding = screenWidth * 0.1;

    return PreferredSize(
      preferredSize: Size.fromHeight(headerHeight),
      child: Container(
        height: headerHeight + MediaQuery.of(context).padding.top,
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top,
          left: horizontalPadding,
          right: horizontalPadding,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 左側：子供の名前 と 何歳何か月（生後何日）
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _childName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      height: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _childAgeText,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      height: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // 右側：ai_screen.dart への遷移ボタン
            Material(
              color: const Color(0xFFA6A6A6),
              borderRadius: BorderRadius.circular(4),
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AiScreen()),
                  );
                },
                child: const SizedBox(
                  width: 56,
                  height: 56,
                  child: Center(
                    child: Text(
                      'AI',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildCustomHeader(context),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey.shade600,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _loadChildInfo();
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
            icon: Icon(Icons.calendar_month),
            label: 'Calendar',
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