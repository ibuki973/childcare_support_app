import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';

class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  String _selectedGender = '男'; // 初期値

  // カレンダーから生年月日を選択する処理
  Future<void> _selectBirthday(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthdayController.text =
            '${picked.year}年${picked.month}月${picked.day}日生';
      });
    }
  }

  // データベースに子どもを登録する処理
  Future<void> _saveChild() async {
    final name = _nameController.text.trim();
    final birthday = _birthdayController.text.trim();

    if (name.isEmpty || birthday.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('名前と生年月日を入力してください')),
      );
      return;
    }

    await DatabaseHelper.instance.insertChild({
      'name': name,
      'birthday': birthday,
      'gender': _selectedGender,
    });

    if (mounted) {
      Navigator.pop(context, true); // 登録完了後、前の画面に戻る
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffffffff), // 背景色を白に設定
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左上の「＜」戻るボタン
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 32),

              // 子供の名前
              const Text(
                '子供の名前',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black87),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // 生年月日（タップでカレンダー表示）
              const Text(
                '生年月日',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              TextField(
                controller: _birthdayController,
                readOnly: true,
                onTap: () => _selectBirthday(context),
                decoration: const InputDecoration(
                  hintText: 'タップして選択',
                  hintStyle: TextStyle(color: Colors.black38, fontSize: 13),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black87),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // 性別（男女の選択）
              const Text(
                '性別',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('男の子'),
                      value: '男',
                      groupValue: _selectedGender,
                      activeColor: Colors.black87,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedGender = value);
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('女の子'),
                      value: '女',
                      groupValue: _selectedGender,
                      activeColor: Colors.black87,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedGender = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 64),

              // 「赤ちゃんを登録」ボタン
              Center(
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _saveChild,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      '赤ちゃんを登録',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}