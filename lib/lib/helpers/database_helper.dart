import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
      version: 3, // memosテーブル追加に伴いバージョンを3に設定
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  // 新しくインストールした端末で実行される
  Future<void> _createDB(Database db, int version) async {
    await _createChildrenTable(db);
    await _createMemosTable(db);
  }

  // 既に古いDBが端末にある場合に、足りないテーブルだけ作成する
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createChildrenTable(db);
    }
    if (oldVersion < 3) {
      await _createMemosTable(db);
    }
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

  // ===== メモ =====

  // 指定した日・種類のメモを取得する（なければnull）
  Future<String?> getMemo({
    required String category,
    required DateTime date,
    int? childId,
  }) async {
    final db = await instance.database;
    final rows = await db.query(
      'memos',
      columns: ['note'],
      where: 'category = ? AND date = ? AND child_id IS ?',
      whereArgs: [category, dateKey(date), childId],
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
    const where = 'category = ? AND date = ? AND child_id IS ?';
    final whereArgs = [category, dateKey(date), childId];

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
