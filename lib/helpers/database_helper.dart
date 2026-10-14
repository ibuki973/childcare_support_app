// lib/helpers/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('childcare_records.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // 例: 育児記録用のテーブル（ID、タイトル、メモ、作成日時）
    await db.execute('''
      CREATE TABLE records (
        id INTEGER PRIMARY KEY AUTOINCREMENT
      )
    ''');
  }

  // データ挿入
  Future<int> insertRecord(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('records', row);
  }

  // データ全取得
  Future<List<Map<String, dynamic>>> queryAllRecords() async {
    final db = await instance.database;
    return await db.query('records', orderBy: 'id DESC');
  }
}