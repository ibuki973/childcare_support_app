// lib/screens/record_screen.dart
import 'package:flutter/material.dart';
import '../widgets/memo_buttons.dart';

class RecordScreen extends StatelessWidget {
  const RecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Expanded(
          child: Center(
            child: Text('記録画面', style: TextStyle(fontSize: 24)),
          ),
        ),

        // 下のアイコン列（Figmaの白い角丸バー）
        // ミルク・おむつ等のアイコンができたら、MemoButtonRowの前に並べる
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          child: Container(
            height: 90,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 33),
              child: MemoButtonRow(date: DateTime.now()),
            ),
          ),
        ),
      ],
    );
  }
}
