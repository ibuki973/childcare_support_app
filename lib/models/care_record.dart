// lib/models/care_record.dart
// 全員で共有する「記録1件」のモデル。
// ミルク・おむつ・睡眠など、全ての記録ボタンが同じ形で保存する。
import 'dart:convert';

class CareRecord {
  final int? id;
  final int childId;

  /// 記録の種類。例: 'toilet' / 'cough' / 'vomit' / 'injury' / 'milk' ...
  final String type;

  /// 記録した日時（ローカル時刻）
  final DateTime recordedAt;

  /// 終了日時。睡眠・授乳タイマー・お風呂など「時間を計る」記録で使う。
  final DateTime? endedAt;

  /// 数値。ミルクのml、体温など。
  final double? amount;

  /// 自由メモ
  final String? note;

  /// 種類ごとの詳細（選択肢の結果など）。DBにはJSON文字列で保存する。
  final Map<String, dynamic> extra;

  const CareRecord({
    this.id,
    required this.childId,
    required this.type,
    required this.recordedAt,
    this.endedAt,
    this.amount,
    this.note,
    this.extra = const {},
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'child_id': childId,
        'type': type,
        'recorded_at': recordedAt.toIso8601String(),
        'ended_at': endedAt?.toIso8601String(),
        'amount': amount,
        'note': note,
        'extra': jsonEncode(extra),
      };

  factory CareRecord.fromMap(Map<String, dynamic> map) {
    final rawExtra = map['extra'] as String?;
    return CareRecord(
      id: map['id'] as int?,
      childId: map['child_id'] as int,
      type: map['type'] as String,
      recordedAt: DateTime.parse(map['recorded_at'] as String),
      endedAt: map['ended_at'] == null
          ? null
          : DateTime.parse(map['ended_at'] as String),
      amount: (map['amount'] as num?)?.toDouble(),
      note: map['note'] as String?,
      extra: (rawExtra == null || rawExtra.isEmpty)
          ? const {}
          : Map<String, dynamic>.from(jsonDecode(rawExtra) as Map),
    );
  }
}
