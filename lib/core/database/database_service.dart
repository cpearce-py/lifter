import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import 'package:lifter/features/workouts/repositories/local_template_repository.dart';

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
      version: 4,
      onConfigure: _onConfigure,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
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
        notes TEXT,
        graph_data BLOB
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
        average_load_left REAL DEFAULT 0.0,
        average_load_right REAL DEFAULT 0.0,
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

    await _createCustomWorkoutTables(db);

    debugPrint('Database tables created successfully!');
  }

  // 6. Clean Shutdown (Useful for debugging or logging out)
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('Upgrading database from V$oldVersion to V$newVersion...');

    if (oldVersion < 2) {
      // 1. Add the BLOB column to the existing workout table
      await db.execute('ALTER TABLE workout ADD COLUMN graph_data BLOB;');
      
      // 2. Add the average columns to the existing repetition table
      await db.execute('ALTER TABLE repetition ADD COLUMN average_load_left REAL DEFAULT 0.0;');
      await db.execute('ALTER TABLE repetition ADD COLUMN average_load_right REAL DEFAULT 0.0;');
    }

    if (oldVersion < 3) {
      await _createCustomWorkoutTables(db);
    }

    if (oldVersion < 4) {
      // Before V3, _createDB left out the V2 columns, so databases created
      // fresh at V2 never got them. Add them if they're missing.
      await _addColumnIfMissing(db, 'workout', 'graph_data', 'BLOB');
      await _addColumnIfMissing(db, 'repetition', 'average_load_left', 'REAL DEFAULT 0.0');
      await _addColumnIfMissing(db, 'repetition', 'average_load_right', 'REAL DEFAULT 0.0');
    }
  }

  Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info("$table")');
    if (columns.any((c) => c['name'] == column)) return;

    debugPrint('Adding missing column $table.$column');
    await db.execute('ALTER TABLE "$table" ADD COLUMN $column $definition;');
  }

  // V3: user-built workout templates, and tagging logged sets by block.
  Future<void> _createCustomWorkoutTables(Database db) async {
    await db.execute('''
      CREATE TABLE workout_template (
        template_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        notes TEXT,
        starting_hand TEXT,
        create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        update_time DATETIME
      )
    ''');

    // Blocks belong to a template and are deleted with it.
    await db.execute('''
      CREATE TABLE template_block (
        block_id INTEGER PRIMARY KEY AUTOINCREMENT,
        template_id INTEGER NOT NULL,
        position INTEGER NOT NULL,
        name TEXT,
        kind TEXT NOT NULL,
        sets INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        work_seconds INTEGER NOT NULL,
        rest_seconds INTEGER NOT NULL,
        set_rest_seconds INTEGER NOT NULL,
        rest_after_seconds INTEGER NOT NULL,
        relative_to INTEGER NOT NULL,
        start_pct INTEGER NOT NULL,
        end_pct INTEGER NOT NULL,
        custom_weight REAL DEFAULT 0.0,
        FOREIGN KEY (template_id) REFERENCES workout_template (template_id) ON DELETE CASCADE
      )
    ''');

    await db.insert('workout_type', {'workout_type_id': 3, 'workout_name': 'Custom'});

    // No foreign key on template_id: history should outlive its template.
    await db.execute('ALTER TABLE workout ADD COLUMN template_id INTEGER;');
    await db.execute('ALTER TABLE workout ADD COLUMN template_name TEXT;');

    await db.execute('ALTER TABLE "set" ADD COLUMN is_warmup INTEGER DEFAULT 0;');
    await db.execute('ALTER TABLE "set" ADD COLUMN block_name TEXT;');
    await db.execute('ALTER TABLE "set" ADD COLUMN block_index INTEGER;');

    await LocalTemplateRepository.seedStarterTemplates(db);
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
