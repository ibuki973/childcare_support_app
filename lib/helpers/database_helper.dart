import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/care_record.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // 現在選択されている子どものIDを保持し、変更を画面へ通知するNotifier
  final ValueNotifier<int?> selectedChildIdNotifier = ValueNotifier<int?>(null);

  // 既存のコードとの互換性を保つための getter / setter
  int? get selectedChildId => selectedChildIdNotifier.value;
  set selectedChildId(int? id) {
    selectedChildIdNotifier.value = id;
  }

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    final db = await _initDB('childcare_support.db');
    // ブランチごとにDBのバージョンがずれていても、必要なテーブルを必ず用意する
    await _createAllTables(db);
    _database = db;
    return db;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      // 3: records テーブルを追加 / memos テーブルを追加（別ブランチで同時に3を使用）
      // 4: 両方のテーブルがそろうようにまとめた
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  // 新しくインストールした端末で実行される
  Future<void> _createDB(Database db, int version) async {
    await _createAllTables(db);
  }

  // 既に古いDBが端末にある場合に、足りないテーブルを作成する
  // （どのテーブルも IF NOT EXISTS なので、既にあれば何もしない）
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    await _createAllTables(db);
  }

  Future<void> _createAllTables(Database db) async {
    await _createChildrenTable(db);
    await _createRecordsTable(db);
    await _createMemosTable(db);
  }

  // 子どもの情報を保存するテーブル
  Future<void> _createChildrenTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS children (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        birthday TEXT NOT NULL,
        gender TEXT NOT NULL
      )
    ''');
  }

  // 全ての記録ボタン（ミルク・おむつ・睡眠・せき…）が共通で使うテーブル
  Future<void> _createRecordsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        child_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        recorded_at TEXT NOT NULL,
        ended_at TEXT,
        amount REAL,
        note TEXT,
        extra TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_records_child_time '
      'ON records (child_id, recorded_at)',
    );
  }

  // 病院・服薬・おやつ・予防接種のメモを保存するテーブル
  // 1日・1種類につき1つのメモを持つ
  Future<void> _createMemosTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS memos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        child_id INTEGER,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  // 日付を「2026-11-11」の形に変換する（DB保存用）
  static String dateKey(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  // ===== 子ども =====

  // 子どもを新規登録する（登録した子どもを自動的に選択状態にする）
  Future<int> insertChild(Map<String, dynamic> row) async {
    final db = await instance.database;
    final id = await db.insert('children', row);
    selectedChildId = id;
    return id;
  }

  // 登録されている子どもの一覧を取得する
  Future<List<Map<String, dynamic>>> getChildren() async {
    final db = await instance.database;
    return await db.query('children', orderBy: 'id ASC');
  }

  // 現在選択されている子どもの情報を取得する（未選択なら最新の子どもを選択）
  Future<Map<String, dynamic>?> getSelectedChild() async {
    final children = await getChildren();
    if (children.isEmpty) {
      selectedChildId = null;
      return null;
    }

    if (selectedChildId != null) {
      for (final child in children) {
        if (child['id'] == selectedChildId) {
          return child;
        }
      }
    }

    // まだ選択されていない場合は、最後に登録された子どもを初期選択にする
    final defaultChild = children.last;
    selectedChildId = defaultChild['id'] as int?;
    return defaultChild;
  }

  // ---- 記録（records） ----

  // 記録を1件保存する
  Future<int> insertRecord(CareRecord record) async {
    final db = await instance.database;
    return await db.insert('records', record.toMap());
  }

  // 指定した日の記録を時刻順に取得する。types を渡すと種類で絞り込める。
  Future<List<CareRecord>> getRecordsForDay(
    int childId,
    DateTime day, {
    List<String>? types,
  }) async {
    final db = await instance.database;
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    final where = StringBuffer('child_id = ? AND recorded_at >= ? AND recorded_at < ?');
    final args = <Object?>[
      childId,
      start.toIso8601String(),
      end.toIso8601String(),
    ];
    if (types != null && types.isNotEmpty) {
      where.write(' AND type IN (${List.filled(types.length, '?').join(',')})');
      args.addAll(types);
    }

    final rows = await db.query(
      'records',
      where: where.toString(),
      whereArgs: args,
      orderBy: 'recorded_at ASC',
    );
    return rows.map(CareRecord.fromMap).toList();
  }

  // 記録を削除する（入力ミスの取り消し用）
  Future<int> deleteRecord(int id) async {
    final db = await instance.database;
    return await db.delete('records', where: 'id = ?', whereArgs: [id]);
  }

  // ---- メモ（memos） ----

  // メモを探す条件を作る（childIdがnullのときは「IS NULL」で探す）
  static (String, List<Object>) _memoWhere(
    String category,
    DateTime date,
    int? childId,
  ) {
    if (childId == null) {
      return (
        'category = ? AND date = ? AND child_id IS NULL',
        [category, dateKey(date)],
      );
    }
    return (
      'category = ? AND date = ? AND child_id = ?',
      [category, dateKey(date), childId],
    );
  }

  // 指定した日・種類のメモを取得する（なければnull）
  Future<String?> getMemo({
    required String category,
    required DateTime date,
    int? childId,
  }) async {
    final db = await instance.database;
    final (where, whereArgs) = _memoWhere(category, date, childId);
    final rows = await db.query(
      'memos',
      columns: ['note'],
      where: where,
      whereArgs: whereArgs,
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['note'] as String?;
  }

  // メモを保存する（既にあれば上書き、空なら削除）
  Future<void> saveMemo({
    required String category,
    required DateTime date,
    required String note,
    int? childId,
  }) async {
    final db = await instance.database;
    final (where, whereArgs) = _memoWhere(category, date, childId);

    if (note.trim().isEmpty) {
      await db.delete('memos', where: where, whereArgs: whereArgs);
      return;
    }

    final now = DateTime.now().toIso8601String();
    final updated = await db.update(
      'memos',
      {'note': note, 'updated_at': now},
      where: where,
      whereArgs: whereArgs,
    );
    if (updated == 0) {
      await db.insert('memos', {
        'child_id': childId,
        'category': category,
        'date': dateKey(date),
        'note': note,
        'updated_at': now,
      });
    }
  }
}