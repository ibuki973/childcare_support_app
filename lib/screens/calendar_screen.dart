// lib/screens/calendar_screen.dart
import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // 表示中の年月と選択中の日付
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDay = DateTime.now();

  // 記録が存在する日付のセット
  Set<String> _recordedDates = {};
  int? _currentChildId;

  @override
  void initState() {
    super.initState();
    _currentChildId = DatabaseHelper.instance.selectedChildId;
    DatabaseHelper.instance.selectedChildIdNotifier.addListener(_onChildChanged);
    _loadRecordedDates();
  }

  @override
  void dispose() {
    DatabaseHelper.instance.selectedChildIdNotifier.removeListener(_onChildChanged);
    super.dispose();
  }

  void _onChildChanged() {
    if (mounted) {
      setState(() {
        _currentChildId = DatabaseHelper.instance.selectedChildId;
      });
      _loadRecordedDates();
    }
  }

  // 表示中の月における記録済み日付リストをロードする
  Future<void> _loadRecordedDates() async {
    final dates = await DatabaseHelper.instance.getDiaryDatesForMonth(
      _currentChildId,
      _focusedMonth.year,
      _focusedMonth.month,
    );
    if (!mounted) return;
    setState(() {
      _recordedDates = dates;
    });
  }

  // 選択した日付の日記入力・編集ダイアログを開く
  Future<void> _openDiaryDialog() async {
    final existingMemo = await DatabaseHelper.instance.getMemo(
      category: 'diary',
      date: _selectedDay,
      childId: _currentChildId,
    );

    final controller = TextEditingController(text: existingMemo ?? '');

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${_selectedDay.year}年${_selectedDay.month}月${_selectedDay.day}日の記録'),
          content: TextField(
            controller: controller,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: '今日の出来事や日記を入力してください...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () async {
                await DatabaseHelper.instance.saveMemo(
                  category: 'diary',
                  date: _selectedDay,
                  note: controller.text,
                  childId: _currentChildId,
                );
                Navigator.pop(context);
                _loadRecordedDates();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('記録を保存しました')),
                );
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  // 記録ボタンのウィジェット（3枠分の横幅）
  Widget _buildRecordButtonWidget() {
    return GestureDetector(
      onTap: _openDiaryDialog,
      child: Container(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 🌸 【自作画像への差し替えポイント】
              Image.asset(
                'assets/images/diary_icon.png',
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // カレンダーマスの記録マーク
  Widget _buildRecordMark() {
    return const Icon(
      Icons.favorite,
      size: 18,
      color: Colors.pinkAccent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final firstWeekday = DateTime(year, month, 1).weekday % 7; // 日曜=0
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final totalDaysCells = firstWeekday + daysInMonth;

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
                    _loadRecordedDates();
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
                    _loadRecordedDates();
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),

            // === 曜日ヘッダー（日〜土） ===
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

            // === カレンダー本体 + 浮動ボタンの配置エリア ===
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const double horizontalPadding = 0.0;
                  final double availableWidth = constraints.maxWidth - (horizontalPadding * 2);
                  const double crossAxisSpacing = 2.0;
                  const double mainAxisSpacing = 2.0;
                  
                  final double cellWidth = (availableWidth - (crossAxisSpacing * 6)) / 7;
                  final double cellHeight = cellWidth / 0.62; // 縦長比率を維持

                  // 最後の行の空き状況と配置位置の計算
                  final lastRowElementCount = totalDaysCells % 7;
                  final emptySpacesInLastRow = lastRowElementCount == 0 ? 0 : 7 - lastRowElementCount;
                  final fullRowsCount = totalDaysCells ~/ 7;

                  int buttonRow;
                  int gridItemCount = totalDaysCells;

                  // 💡 【判定】右端の空きが3枠以上あるか
                  if (emptySpacesInLastRow >= 3) {
                    buttonRow = fullRowsCount; // 最後の行にそのまま配置
                  } else {
                    buttonRow = fullRowsCount + 1; // 下の行に配置
                    // 下の行に置く場合は、GridView自体に次の行を描画させるためアイテム数を拡張
                    gridItemCount = (fullRowsCount + 2) * 7;
                  }

                  // 3枠分の幅をとるため、左端から4列目（インデックス4）に配置
                  const int buttonCol = 7 - 3; 

                  // ボタンの座標とサイズの計算
                  final double buttonLeft = buttonCol * (cellWidth + crossAxisSpacing);
                  final double buttonTop = buttonRow * (cellHeight + mainAxisSpacing);
                  // 3枠分の幅（セル幅3つ分 + その間のスペース2つ分）
                  final double buttonWidth = (cellWidth * 3) + (crossAxisSpacing * 2);

                  return SingleChildScrollView(
                    child: Stack(
                      children: [
                        // 1. カレンダー本体（必要に応じて次の行まで描画）
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: gridItemCount,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            childAspectRatio: 0.62,
                            crossAxisSpacing: crossAxisSpacing,
                            mainAxisSpacing: mainAxisSpacing,
                          ),
                          itemBuilder: (context, index) {
                            // 日付範囲外の空白マス（または拡張された空行のマス）
                            if (index < firstWeekday || index >= totalDaysCells) {
                              return const SizedBox.shrink();
                            }

                            final day = index - firstWeekday + 1;
                            final currentDate = DateTime(year, month, day);
                            final dateKey = DatabaseHelper.dateKey(currentDate);
                            final hasRecord = _recordedDates.contains(dateKey);

                            final isSelected = _selectedDay.year == currentDate.year &&
                                _selectedDay.month == currentDate.month &&
                                _selectedDay.day == currentDate.day;

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
                                    color: isSelected ? Colors.black : Colors.grey.shade600,
                                    width: isSelected ? 2.5 : 1.0,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Align(
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
                                    if (hasRecord)
                                      Center(
                                        child: Padding(
                                          padding: const EdgeInsets.only(top: 4.0),
                                          child: Align(
                                            alignment: Alignment.topCenter,
                                            child: _buildRecordMark(),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        // 2. 3枠分の横長記録ボタン
                        Positioned(
                          left: buttonLeft,
                          top: buttonTop,
                          width: buttonWidth,
                          height: cellHeight,
                          child: _buildRecordButtonWidget(),
                        ),
                      ],
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