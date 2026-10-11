import 'package:sqflite/sqflite.dart';
import 'package:lifter/features/user/models/user_profile.dart';

abstract class UserRepository {
  Future<UserProfile?> getUser(int id);
  Future<void> saveUser(UserProfile user);

  /// Best pulls recorded by Peak Load sessions. Zero if none, or no user.
  Future<({double left, double right})> getMaxPulls(int userId);
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
    // Update rather than INSERT OR REPLACE: REPLACE deletes the old row, which
    // would reset columns the profile doesn't carry, like the max pulls.
    final updated = await db.update(
      'user',
      user.toMap(),
      where: 'user_id = ?',
      whereArgs: [user.id],
    );
    if (updated == 0) {
      await db.insert('user', user.toMap());
    }
  }

  @override
  Future<({double left, double right})> getMaxPulls(int userId) async {
    final rows = await db.query(
      'user',
      columns: ['max_pull_left', 'max_pull_right'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (rows.isEmpty) return (left: 0.0, right: 0.0);

    return (
      left: (rows.first['max_pull_left'] as num?)?.toDouble() ?? 0.0,
      right: (rows.first['max_pull_right'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
