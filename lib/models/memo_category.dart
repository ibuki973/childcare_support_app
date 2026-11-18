// lib/models/memo_category.dart
import 'package:flutter/material.dart';

// メモの種類（色・アイコンを変えたいときはここだけ直せばOK）
// DBには category.name（hospital など）が保存される
enum MemoCategory {
  hospital('病院', Color(0xFF8FD1BD), Icons.local_hospital),
  medicine('服薬', Color(0xFF7CB342), Icons.medication), // 濃い黄緑
  snack('おやつ', Color(0xFFFFC48C), Icons.cookie), // 薄いオレンジ
  vaccine('予防接種', Color(0xFF6FA8DC), Icons.vaccines); // 青

  const MemoCategory(this.label, this.color, this.icon);

  final String label;
  final Color color;
  final IconData icon;
}
