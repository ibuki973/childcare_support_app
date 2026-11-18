// lib/records/simple_record_types.dart
// 「簡易記録」の種類と選択肢の定義。
// 新しい簡易記録を足すときは simpleRecordTypes に1件足すだけでよい。
import 'package:flutter/material.dart';

import '../models/care_record.dart';

/// 選択肢1グループ分（例: 「程度」→ 軽い / ふつう / 強い）
class SimpleRecordField {
  final String key; // extra に保存するときのキー
  final String label; // 画面に出す見出し
  final List<String> options;
  final bool multiple; // true なら複数選択

  const SimpleRecordField({
    required this.key,
    required this.label,
    required this.options,
    this.multiple = false,
  });
}

class SimpleRecordType {
  final String type; // DBの type 列に入る値
  final String label;
  final IconData icon; // 仮アイコン。Figmaの画像に差し替える
  final List<SimpleRecordField> fields;
  final String memoHint;

  const SimpleRecordType({
    required this.type,
    required this.label,
    required this.icon,
    required this.fields,
    this.memoHint = 'メモ（任意）',
  });
}

const toiletRecord = SimpleRecordType(
  type: 'toilet',
  label: 'トイレ',
  icon: Icons.wc,
  fields: [
    SimpleRecordField(
      key: 'kind',
      label: '何をした？',
      options: ['おしっこ', 'うんち'],
      multiple: true,
    ),
    SimpleRecordField(
      key: 'result',
      label: '結果',
      options: ['トイレでできた', '間に合わなかった', '出なかった'],
    ),
  ],
);

const coughRecord = SimpleRecordType(
  type: 'cough',
  label: 'せき',
  icon: Icons.air,
  fields: [
    SimpleRecordField(
      key: 'severity',
      label: '程度',
      options: ['軽い', 'ふつう', '強い'],
    ),
    SimpleRecordField(
      key: 'kind',
      label: 'せきの様子',
      options: ['乾いたせき', '痰がからむ', 'ゼーゼー・ヒューヒュー'],
    ),
  ],
);

const vomitRecord = SimpleRecordType(
  type: 'vomit',
  label: '吐く',
  icon: Icons.sick_outlined,
  fields: [
    SimpleRecordField(
      key: 'amount',
      label: '量',
      options: ['少量', 'ふつう', '大量'],
    ),
    SimpleRecordField(
      key: 'timing',
      label: 'タイミング',
      options: ['授乳・食事の直後', '食後しばらくして', '食事と関係なし'],
    ),
  ],
);

const injuryRecord = SimpleRecordType(
  type: 'injury',
  label: '怪我',
  icon: Icons.healing,
  fields: [
    SimpleRecordField(
      key: 'part',
      label: '場所',
      options: ['頭', '顔', '腕・手', '足', 'おなか', '背中', 'その他'],
      multiple: true,
    ),
    SimpleRecordField(
      key: 'kind',
      label: 'どうなった？',
      options: ['ぶつけた', '転んだ', '切り傷', 'やけど', '挟んだ', 'その他'],
    ),
  ],
  memoHint: '状況や処置など（任意）',
);

/// 担当分の一覧。記録ボタンの並びに使う。
const simpleRecordTypes = <SimpleRecordType>[
  toiletRecord,
  coughRecord,
  vomitRecord,
  injuryRecord,
];

SimpleRecordType? findSimpleRecordType(String type) {
  for (final t in simpleRecordTypes) {
    if (t.type == type) return t;
  }
  return null;
}

/// ホームのタイムライン用の1行要約。
/// 例: 「せき（強い・乾いたせき）」「トイレ（おしっこ・うんち／トイレでできた）」
String summarizeSimpleRecord(CareRecord record) {
  final t = findSimpleRecordType(record.type);
  if (t == null) return record.type;

  final parts = <String>[];
  for (final f in t.fields) {
    final v = record.extra[f.key];
    if (v is List && v.isNotEmpty) {
      parts.add(v.join('・'));
    } else if (v is String && v.isNotEmpty) {
      parts.add(v);
    }
  }
  final detail = parts.isEmpty ? '' : '（${parts.join('・')}）';
  return '${t.label}$detail';
}
