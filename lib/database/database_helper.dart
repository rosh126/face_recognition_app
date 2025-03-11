// ignore_for_file: depend_on_referenced_packages

import 'package:sqflite/sqflite.dart';
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
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE watchlist (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            faceId TEXT UNIQUE,  
            name TEXT,
            imagePath TEXT,
            confidenceScore REAL,
            createdAt TEXT
          )
        ''');
      },
    );
  }

  // Add a face to the watchlist
  Future<int> addFace(String faceId, String name, String imagePath, double confidenceScore) async {
    final db = await database;
    return await db.insert(
      'watchlist',
      {
        'faceId': faceId,
        'name': name,
        'imagePath': imagePath,
        'confidenceScore': confidenceScore,
        'createdAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace, // Prevents duplicates
    );
  }

  // Get all watchlist faces
  Future<List<Map<String, dynamic>>> getWatchlist() async {
    final db = await database;
    return await db.query('watchlist', orderBy: "createdAt DESC");
  }

  // Update a face entry
  Future<int> updateFace(int id, String name, double confidenceScore) async {
    final db = await database;
    return await db.update(
      'watchlist',
      {'name': name, 'confidenceScore': confidenceScore},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Remove a face from the watchlist
  Future<int> removeFace(int id) async {
    final db = await database;
    return await db.delete('watchlist', where: 'id = ?', whereArgs: [id]);
  }

  // Clear all watchlist entries (useful for syncing with the server)
  Future<void> clearWatchlist() async {
    final db = await database;
    await db.delete('watchlist');
  }
}
