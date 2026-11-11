// lib/widgets/memo_dialog.dart
import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/memo_category.dart';

// メモのポップアップを開く（Figmaのミルクのポップアップと同じ形）
Future<void> showMemoDialog(
  BuildContext context, {
  required MemoCategory category,
  required DateTime date,
  int? childId,
}) {
  return showDialog(
    context: context,
    barrierColor: const Color(0x80333333), // 背景を暗くする
    builder: (_) =>
        MemoDialog(category: category, date: date, childId: childId),
  );
}

class MemoDialog extends StatefulWidget {
  const MemoDialog({
    super.key,
    required this.category,
    required this.date,
    this.childId,
  });

  final MemoCategory category;
  final DateTime date;
  final int? childId;

  @override
  State<MemoDialog> createState() => _MemoDialogState();
}

class _MemoDialogState extends State<MemoDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMemo();
  }

  // 保存済みのメモがあれば読み込む
  Future<void> _loadMemo() async {
    final note = await DatabaseHelper.instance.getMemo(
      category: widget.category.name,
      date: widget.date,
      childId: widget.childId,
    );
    if (!mounted) return;
    setState(() {
      _controller.text = note ?? '';
      _loading = false;
    });
  }

  // OKボタン：保存して閉じる
  Future<void> _save() async {
    await DatabaseHelper.instance.saveMemo(
      category: widget.category.name,
      date: widget.date,
      note: _controller.text,
      childId: widget.childId,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: widget.category.color,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: SizedBox(
        width: 297,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(17, 22, 17, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // タイトル（例：病院）
              Padding(
                padding: const EdgeInsets.only(left: 9),
                child: Text(
                  widget.category.label,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 横線入りの白いメモ欄
              Container(
                height: 239,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : LinedMemoField(controller: _controller),
              ),
              const SizedBox(height: 15),

              // OKボタン
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 67,
                  height: 32,
                  child: TextButton(
                    onPressed: _loading ? null : _save,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w300,
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

// ノートのように横線が引かれた入力欄
// 文字が増えると線も増え、欄の中でスクロールできる
class LinedMemoField extends StatelessWidget {
  const LinedMemoField({super.key, required this.controller});

  final TextEditingController controller;

  static const double lineHeight = 37; // 線と線の間隔（Figmaと同じ）
  static const double fontSize = 20;
  static const EdgeInsets padding = EdgeInsets.fromLTRB(21, 12, 25, 5);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: CustomPaint(
        painter: _RuledLinesPainter(
          lineHeight: lineHeight,
          padding: padding,
        ),
        child: TextField(
          controller: controller,
          maxLines: null, // 改行で何行でも書ける
          minLines: 6,
          keyboardType: TextInputType.multiline,
          cursorColor: Colors.black,
          scrollPhysics: const NeverScrollableScrollPhysics(),
          style: const TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w300,
            color: Colors.black,
            height: lineHeight / fontSize,
          ),
          // 文字の高さを線の間隔に固定する
          strutStyle: const StrutStyle(
            fontSize: fontSize,
            height: lineHeight / fontSize,
            forceStrutHeight: true,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: padding,
          ),
        ),
      ),
    );
  }
}

class _RuledLinesPainter extends CustomPainter {
  _RuledLinesPainter({required this.lineHeight, required this.padding});

  final double lineHeight;
  final EdgeInsets padding;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1;

    // 各行の下に線を引く（一番下の行は欄の端なので線なし）
    for (var y = padding.top + lineHeight;
        y < size.height - padding.bottom - 1;
        y += lineHeight) {
      canvas.drawLine(
        Offset(padding.left, y),
        Offset(size.width - padding.right, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RuledLinesPainter oldDelegate) =>
      oldDelegate.lineHeight != lineHeight || oldDelegate.padding != padding;
}
