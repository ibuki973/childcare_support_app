import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import 'add_child_screen.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  List<Map<String, dynamic>> _children = [];
  int? _selectedChildId;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  // DBから登録済みの子ども一覧と現在の選択状態を取得する
  Future<void> _loadChildren() async {
    final data = await DatabaseHelper.instance.getChildren();
    final selected = await DatabaseHelper.instance.getSelectedChild();
    if (!mounted) return;
    setState(() {
      _children = data;
      _selectedChildId = selected?['id'] as int?;
    });
  }

  // 子どもの行をタップしたときに記録対象を切り替える
  void _selectChild(Map<String, dynamic> child) {
    final id = child['id'] as int;
    final name = child['name'] as String? ?? '';
    setState(() {
      _selectedChildId = id;
      DatabaseHelper.instance.selectedChildId = id;
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('記録対象を「$name」に切り替えました'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // 子どもの追加画面へ遷移する
  Future<void> _navigateToAddChild() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddChildScreen()),
    );
    // 登録が完了して戻ってきたら一覧を再取得する
    if (result == true) {
      _loadChildren();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF), // 画像に合わせた白背景
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 「メニュー」見出し（青色の下線付き）
              Container(
                padding: const EdgeInsets.only(bottom: 2),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.blue, width: 3),
                  ),
                ),
                child: const Text(
                  'メニュー',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // 「子ども」セクションラベル
              const Padding(
                padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                child: Text(
                  '子ども',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),

              // 子ども一覧＆追加ボタンの白カード
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 登録されている子どものリスト表示（タップで切り替え）
                    for (var child in _children) ...[
                      Builder(
                        builder: (context) {
                          final int childId = child['id'] as int;
                          final bool isSelected = (childId == _selectedChildId);

                          return InkWell(
                            onTap: () => _selectChild(child),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10.0,
                                horizontal: 4.0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            child['name'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isSelected) ...[
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.check,
                                            color: Colors.blue,
                                            size: 22,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    child['birthday'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const Divider(color: Colors.black26, thickness: 1),
                    ],

                    // 「＋ 子どもの追加」ボタン
                    InkWell(
                      onTap: _navigateToAddChild,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.add,
                                size: 20,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              '子どもの追加',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}