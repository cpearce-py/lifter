import 'package:sqflite/sqflite.dart';
import 'package:lifter/features/user/models/user_profile.dart';

abstract class UserRepository {
  Future<UserProfile?> getUser(int id);
  Future<void> saveUser(UserProfile user);
}

class LocalUserRepository implements UserRepository {
  final Database db;

  LocalUserRepository(this.db);

  @override
  Future<UserProfile?> getUser(int id) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'user',
      where: 'user_id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return UserProfile.fromMap(maps.first);
    }
    return null; // No user exists yet
  }

  @override
  Future<void> saveUser(UserProfile user) async {
    await db.insert(
      'user',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
