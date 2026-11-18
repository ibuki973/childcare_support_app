// lib/screens/record_screen.dart
import 'package:flutter/material.dart';
import '../records/simple_record_types.dart';
import '../widgets/memo_buttons.dart';
import '../widgets/simple_record_sheet.dart';

class RecordScreen extends StatelessWidget {
  const RecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 簡易記録（トイレ・せき・吐く…）のボタン
        Expanded(
          child: Center(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                for (final t in simpleRecordTypes)
                  ElevatedButton.icon(
                    icon: Icon(t.icon),
                    label: Text(t.label),
                    onPressed: () async {
                      final saved = await showSimpleRecordSheet(
                        context,
                        recordType: t,
                        childId: 1, // 仮。登録済みの子どもの id
                      );
                      if (saved && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${t.label}を記録しました')),
                        );
                      }
                    },
                  ),
              ],
            ),
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
