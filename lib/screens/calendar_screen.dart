import 'package:flutter/material.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // 表示中の年月と選択中の日付
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final firstWeekday = DateTime(year, month, 1).weekday % 7; // 日曜=0, 土曜=6
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final totalCells = firstWeekday + daysInMonth;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          children: [
            // === 月切り替えヘッダー ===
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _focusedMonth = DateTime(year, month - 1, 1);
                    });
                  },
                ),
                Text(
                  '$year年 $month月',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _focusedMonth = DateTime(year, month + 1, 1);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),

            // === 曜日ヘッダー（日・月・火・水・木・金・土） ===
            Row(
              children: List.generate(7, (index) {
                const labels = ['日', '月', '火', '水', '木', '金', '土'];
                Color textColor = Colors.black87;
                if (index == 0) textColor = Colors.red;
                if (index == 6) textColor = Colors.blue;

                return Expanded(
                  child: Center(
                    child: Text(
                      labels[index],
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 6),

            // === カレンダーのマス目グリッド ===
            Expanded(
              child: GridView.builder(
                itemCount: totalCells,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7, // 7列
                  childAspectRatio: 0.62, // 縦長の四角比率
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                itemBuilder: (context, index) {
                  // 月初より前の空白マス
                  if (index < firstWeekday) {
                    return const SizedBox.shrink();
                  }

                  final day = index - firstWeekday + 1;
                  final currentDate = DateTime(year, month, day);
                  final isSelected = _selectedDay.year == currentDate.year &&
                      _selectedDay.month == currentDate.month &&
                      _selectedDay.day == currentDate.day;

                  // 曜日ごとの文字色
                  final weekday = index % 7;
                  Color dayColor = Colors.black87;
                  if (weekday == 0) dayColor = Colors.red;
                  if (weekday == 6) dayColor = Colors.blue;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDay = currentDate;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.grey.shade100 : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          // 選択したマスは太枠（2.5）、通常は細枠（1.0）
                          color: isSelected ? Colors.black : Colors.grey.shade600,
                          width: isSelected ? 2.5 : 1.0,
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontSize: isSelected ? 14 : 13,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal,
                            color: dayColor,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}