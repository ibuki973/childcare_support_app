// lib/widgets/simple_record_sheet.dart
// 簡易記録の入力シート。選択肢をタップして「記録する」を押すだけで保存できる。
// すべての項目は任意なので、何も選ばずに保存してもよい（素早く記録できる）。
import 'package:flutter/material.dart';

import '../helpers/database_helper.dart';
import '../models/care_record.dart';
import '../records/simple_record_types.dart';

/// 使い方:
/// final saved = await showSimpleRecordSheet(
///   context,
///   recordType: coughRecord,
///   childId: currentChildId,
///   day: selectedDay, // ホームで表示中の日付。省略すると今日
/// );
/// if (saved) { /* ホームの表示を再読み込み */ }
Future<bool> showSimpleRecordSheet(
  BuildContext context, {
  required SimpleRecordType recordType,
  required int childId,
  DateTime? day,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _SimpleRecordSheet(
      recordType: recordType,
      childId: childId,
      day: day,
    ),
  );
  return saved ?? false;
}

class _SimpleRecordSheet extends StatefulWidget {
  final SimpleRecordType recordType;
  final int childId;
  final DateTime? day;

  const _SimpleRecordSheet({
    required this.recordType,
    required this.childId,
    this.day,
  });

  @override
  State<_SimpleRecordSheet> createState() => _SimpleRecordSheetState();
}

class _SimpleRecordSheetState extends State<_SimpleRecordSheet> {
  late DateTime _recordedAt;
  final Map<String, Set<String>> _selected = {};
  final TextEditingController _memoController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final base = widget.day ?? now;
    // 日付は表示中の日、時刻は今の時刻を初期値にする
    _recordedAt = DateTime(base.year, base.month, base.day, now.hour, now.minute);
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_recordedAt),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _recordedAt = DateTime(
        _recordedAt.year,
        _recordedAt.month,
        _recordedAt.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  void _toggle(SimpleRecordField field, String option) {
    setState(() {
      final set = _selected.putIfAbsent(field.key, () => <String>{});
      if (set.contains(option)) {
        set.remove(option); // もう一度タップで選択解除
      } else {
        if (!field.multiple) set.clear();
        set.add(option);
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final extra = <String, dynamic>{};
    for (final field in widget.recordType.fields) {
      final selected = _selected[field.key];
      if (selected == null || selected.isEmpty) continue;
      // 選択肢の並び順を保って保存する
      final ordered = field.options.where(selected.contains).toList();
      extra[field.key] = field.multiple ? ordered : ordered.first;
    }
    final memo = _memoController.text.trim();

    try {
      await DatabaseHelper.instance.insertRecord(
        CareRecord(
          childId: widget.childId,
          type: widget.recordType.type,
          recordedAt: _recordedAt,
          note: memo.isEmpty ? null : memo,
          extra: extra,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存に失敗しました。もう一度お試しください')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.recordType;
    final textTheme = Theme.of(context).textTheme;
    final date =
        '${_recordedAt.year}/${_two(_recordedAt.month)}/${_two(_recordedAt.day)}';
    final time = '${_two(_recordedAt.hour)}:${_two(_recordedAt.minute)}';

    return Padding(
      // キーボードが出てもメモ欄が隠れないようにする
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(t.icon),
                const SizedBox(width: 8),
                Text(t.label, style: textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: Text('$date  $time'),
              trailing: const Text('時刻を変更'),
              onTap: _pickTime,
            ),
            for (final field in t.fields) ...[
              const SizedBox(height: 8),
              Text(field.label, style: textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in field.options)
                    FilterChip(
                      label: Text(option),
                      selected: _selected[field.key]?.contains(option) ?? false,
                      onSelected: (_) => _toggle(field, option),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _memoController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: t.memoHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? '保存中…' : '記録する'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
