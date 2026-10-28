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
      version: 2, // テーブル追加に伴いバージョンを2に設定
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
  }

  // 既に古いDBが端末にある場合でもchildrenテーブルを作成する処理
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS children (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        birthday TEXT NOT NULL,
        gender TEXT NOT NULL
      )
    ''');
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
}