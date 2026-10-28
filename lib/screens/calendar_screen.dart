import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // 表示形式（月・週などの切り替え用）
  CalendarFormat _calendarFormat = CalendarFormat.month;
  // 現在フォーカスされている日と選択された日
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('カレンダー'),
      ),
      body: TableCalendar(
        // カレンダーの表示範囲
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,

        // 日付が選択されているかの判定
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },

        // 日付をタップした時の処理
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },

        // 表示形式（月/週）の切り替え処理
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },

        // ページ（月）を切り替えた時の処理
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
      ),
    );
  }
}