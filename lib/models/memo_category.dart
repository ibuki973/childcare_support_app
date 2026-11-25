// lib/models/memo_category.dart
import 'package:flutter/material.dart';

// メモの種類（色・アイコンを変えたいときはここだけ直せばOK）
// DBには category.name（wake, sleep, hospital など）が保存される
enum MemoCategory {
  wake('起きる', Color(0xFFFFB74D), Icons.wb_sunny, isTime: true),
  sleep('寝る', Color(0xFF7E57C2), Icons.bedtime, isTime: true),
  hospital('病院', Color(0xFF8FD1BD), Icons.local_hospital),
  medicine('服薬', Color(0xFF7CB342), Icons.medication), // 濃い黄緑
  snack('おやつ', Color(0xFFFFC48C), Icons.cookie), // 薄いオレンジ
  vaccine('予防接種', Color(0xFF6FA8DC), Icons.vaccines); // 青

  const MemoCategory(
    this.label,
    this.color,
    this.icon, {
    this.isTime = false,
  });

  final String label;
  final Color color;
  final IconData icon;
  final bool isTime;
}
