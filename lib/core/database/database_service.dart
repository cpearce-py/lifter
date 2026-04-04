import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  // 1. Singleton Boilerplate
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;
  static const dbName = "lifter_database.db";

  DatabaseService._init();

  // 2. The Database Getter
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(dbName);
    return _database!;
  }

  // 3. Initialization
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    debugPrint("DB Path: $path");
    return await openDatabase(
      path,
      version: 1,
      onConfigure: _onConfigure,
      onCreate: _createDB,
    );
  }

  // 4. Enforce Foreign Keys (Crucial for SQLite!)
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // 5. Table Creation
  Future<void> _createDB(Database db, int version) async {
    // We wrap the word "set" in quotes because it is a reserved SQL keyword!

    debugPrint('Creating database tables...');

    // --- Create User Table ---
    await db.execute('''
      CREATE TABLE user (
        user_id INTEGER PRIMARY KEY AUTOINCREMENT,
        username VARCHAR(16) NOT NULL,
        first_name VARCHAR(45),
        last_name VARCHAR(45),
        email VARCHAR(255),
        max_pull_left REAL DEFAULT 0.0,
        max_pull_right REAL DEFAULT 0.0,
        create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        update_time DATETIME
      )
    ''');
    
    // --- Workout Table ---
    await db.execute('''
      CREATE TABLE workout (
        workout_id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_type_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        date_done TEXT NOT NULL,
        duration INTEGER NOT NULL,
        working_time INTEGER NOT NULL,
        notes TEXT
      )
    ''');

    // --- Set Table ---
    // Links back to the Workout. If a workout is deleted, its sets are CASCADE deleted.
    await db.execute('''
      CREATE TABLE "set" (
        set_id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_id INTEGER NOT NULL,
        FOREIGN KEY (workout_id) REFERENCES workout (workout_id) ON DELETE CASCADE
      )
    ''');

    // --- Repetition Table ---
    // Links back to the Set. If a set is deleted, its reps are CASCADE deleted.
    await db.execute('''
      CREATE TABLE repetition (
        rep_id INTEGER PRIMARY KEY AUTOINCREMENT,
        set_id INTEGER NOT NULL,
        peak_load_left REAL NOT NULL,
        peak_load_right REAL NOT NULL,
        FOREIGN KEY (set_id) REFERENCES "set" (set_id) ON DELETE CASCADE
      )
    ''');

    // Optional: If you want to seed the database with your friend's 'workout_type' table,
    // you can create it and populate it here!
    await db.execute('''
      CREATE TABLE workout_type (
        workout_type_id INTEGER PRIMARY KEY,
        workout_name TEXT NOT NULL
      )
    ''');

    // Seed the types so we have them ready
    await db.insert('workout_type', {'workout_type_id': 1, 'workout_name': 'Repeater'});
    await db.insert('workout_type', {'workout_type_id': 2, 'workout_name': 'Peak Load'});

    debugPrint('Database tables created successfully!');
  }

  // 6. Clean Shutdown (Useful for debugging or logging out)
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  Future<void> wipeDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);

    if (_database != null) {
      await _database!.close();
    }

    await deleteDatabase(path);
    _database = null;
    debugPrint("Database wiped clean!");
  }
}
