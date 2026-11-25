// lib/widgets/memo_dialog.dart
import 'package:flutter/cupertino.dart';
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
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMemo();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  // 保存済みのメモがあれば読み込む
  // 読み込みに失敗しても、ぐるぐるで止まらないようにする
  Future<void> _loadMemo() async {
    String? note;
    try {
      note = await DatabaseHelper.instance.getMemo(
        category: widget.category.name,
        date: widget.date,
        childId: widget.childId,
      );
    } catch (e) {
      debugPrint('メモの読み込みに失敗: $e');
      _showError('メモを読み込めませんでした');
    }
    if (!mounted) return;

    if (widget.category.isTime) {
      if (note != null && note.contains(':')) {
        final parts = note.split(':');
        if (parts.length == 2) {
          final h = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          if (h != null && m != null) {
            _selectedTime = TimeOfDay(hour: h, minute: m);
          }
        }
      } else {
        _selectedTime = TimeOfDay.now();
      }
    } else {
      _controller.text = note ?? '';
    }

    setState(() {
      _loading = false;
    });
  }

  void _onTimeChanged(TimeOfDay newTime) {
    setState(() {
      _selectedTime = newTime;
    });
  }

  void _setNow() {
    setState(() {
      _selectedTime = TimeOfDay.now();
    });
  }

  // OKボタン：保存して閉じる
  Future<void> _save() async {
    try {
      final noteToSave = widget.category.isTime
          ? '${_two(_selectedTime.hour)}:${_two(_selectedTime.minute)}'
          : _controller.text;

      await DatabaseHelper.instance.saveMemo(
        category: widget.category.name,
        date: widget.date,
        note: noteToSave,
        childId: widget.childId,
      );
    } catch (e) {
      debugPrint('メモの保存に失敗: $e');
      _showError('メモを保存できませんでした');
      return; // 書いた内容が消えないよう、閉じずに残す
    }
    if (mounted) Navigator.pop(context);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
              // タイトル（例：病院、起きる）
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

              // メモ欄または時刻選択領域
              Container(
                height: 239,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : widget.category.isTime
                        ? _TimePickerContent(
                            category: widget.category,
                            time: _selectedTime,
                            onTimeChanged: _onTimeChanged,
                            onSetNow: _setNow,
                          )
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

class _TimePickerContent extends StatelessWidget {
  const _TimePickerContent({
    required this.category,
    required this.time,
    required this.onTimeChanged,
    required this.onSetNow,
  });

  final MemoCategory category;
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final VoidCallback onSetNow;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        // ヘッダー行（アイコン＋タイトル＋現在時刻にするボタン）
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(category.icon, size: 18, color: category.color),
              ),
              const SizedBox(width: 8),
              Text(
                '${category.label}時刻',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: category.color,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onSetNow,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_filled,
                        size: 14,
                        color: category.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '現在時刻',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: category.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // ドラムロール（ホイール選択画面）をカード内に直接表示
        Expanded(
          child: CupertinoTheme(
            data: CupertinoThemeData(
              textTheme: CupertinoTextThemeData(
                dateTimePickerTextStyle: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: category.color,
                ),
              ),
            ),
            child: CupertinoDatePicker(
              key: ValueKey('${time.hour}:${time.minute}'),
              mode: CupertinoDatePickerMode.time,
              use24hFormat: true,
              initialDateTime: DateTime(
                2026,
                1,
                1,
                time.hour,
                time.minute,
              ),
              onDateTimeChanged: (DateTime dt) {
                onTimeChanged(TimeOfDay(hour: dt.hour, minute: dt.minute));
              },
            ),
          ),
        ),
        const SizedBox(height: 6),
      ],
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
