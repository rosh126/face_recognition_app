import 'package:sqflite/sqflite.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'watchlist.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE watchlist(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            imagePath TEXT
          )
        ''');
      },
    );
  }

  // Add a face to the watchlist
  Future<int> addFace(String name, String imagePath) async {
    final db = await database;
    return await db.insert('watchlist', {'name': name, 'imagePath': imagePath});
  }

  // Get all watchlist faces
  Future<List<Map<String, dynamic>>> getWatchlist() async {
    final db = await database;
    return await db.query('watchlist');
  }

  // Remove a face from the watchlist
  Future<int> removeFace(int id) async {
    final db = await database;
    return await db.delete('watchlist', where: 'id = ?', whereArgs: [id]);
  }
}
