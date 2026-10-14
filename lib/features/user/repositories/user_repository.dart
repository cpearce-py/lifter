import 'package:sqflite/sqflite.dart';
import 'package:lifter/features/history/models/log_models.dart';
import 'package:lifter/features/user/models/user_profile.dart';

abstract class UserRepository {
  Future<UserProfile?> getUser(int id);
  Future<void> saveUser(UserProfile user);

  /// Best pulls from the user's Peak Load history. Zero if there are none.
  ///
  /// Worked out from the workouts rather than stored, so deleting or fixing
  /// a workout can lower it again.
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
    final rows = await db.rawQuery('''
      SELECT MAX(r.peak_load_left) AS max_left, MAX(r.peak_load_right) AS max_right
      FROM repetition r
      JOIN "set" s ON s.set_id = r.set_id
      JOIN workout w ON w.workout_id = s.workout_id
      WHERE w.user_id = ? AND w.workout_type_id = ?
    ''', [userId, WorkoutId.peakLoad]);

    return (
      left: (rows.first['max_left'] as num?)?.toDouble() ?? 0.0,
      right: (rows.first['max_right'] as num?)?.toDouble() ?? 0.0,
    );
  }

}
