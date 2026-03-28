// core/database/database_service.dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'lifter_database.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE workouts (
            id TEXT PRIMARY KEY,
            workoutType TEXT NOT NULL,
            date TEXT NOT NULL,
            peakWeight REAL NOT NULL,
            totalDurationSeconds INTEGER NOT NULL
          )
        ''');
      },
    );
  }
}
