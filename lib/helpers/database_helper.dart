import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/care_record.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('childcare_support.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3, // 3: records テーブルを追加
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 子どもの情報を保存するテーブル
    await db.execute('''
      CREATE TABLE children (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        birthday TEXT NOT NULL,
        gender TEXT NOT NULL
      )
    ''');
    await _createRecordsTable(db);
  }

  // 既に古いDBが端末にある場合でもテーブルを作成する処理
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS children (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        birthday TEXT NOT NULL,
        gender TEXT NOT NULL
      )
    ''');
    if (oldVersion < 3) {
      await _createRecordsTable(db);
    }
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

  // 子どもを新規登録する
  Future<int> insertChild(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('children', row);
  }

  // 登録されている子どもの一覧を取得する
  Future<List<Map<String, dynamic>>> getChildren() async {
    final db = await instance.database;
    return await db.query('children', orderBy: 'id ASC');
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
}
