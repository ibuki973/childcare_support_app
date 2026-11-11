// lib/widgets/memo_buttons.dart
import 'package:flutter/material.dart';
import '../models/memo_category.dart';
import 'memo_dialog.dart';

// 病院・服薬・おやつ・予防接種の4つのボタンを横に並べる
// 記録画面の下のアイコン列（ミルク・おむつ…）の後ろに置く想定
class MemoButtonRow extends StatelessWidget {
  const MemoButtonRow({super.key, required this.date, this.childId});

  final DateTime date; // 記録画面で表示している日付
  final int? childId;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final category in MemoCategory.values)
          MemoCategoryButton(
            category: category,
            onTap: () => showMemoDialog(
              context,
              category: category,
              date: date,
              childId: childId,
            ),
          ),
      ],
    );
  }
}

// 1つ分のボタン（ミルクアイコンと同じ90×90の大きさ）
class MemoCategoryButton extends StatelessWidget {
  const MemoCategoryButton({
    super.key,
    required this.category,
    required this.onTap,
  });

  final MemoCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 90,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: category.color,
                shape: BoxShape.circle,
              ),
              child: Icon(category.icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 6),
            Text(
              category.label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: category.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
