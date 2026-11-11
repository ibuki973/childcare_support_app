// lib/screens/record_screen.dart
import 'package:flutter/material.dart';
import '../records/simple_record_types.dart';
import '../widgets/simple_record_sheet.dart';

class RecordScreen extends StatelessWidget {
  const RecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
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
    );
  }
}