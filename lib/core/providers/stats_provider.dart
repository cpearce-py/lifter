import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/providers/history_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:lifter/core/providers/repository_providers.dart';
import 'package:lifter/features/workouts/providers/weekly_provider.dart';

/// Sessions needed in a week for it to count towards the streak.
const streakSessionsPerWeek = 2;

class UserStats {
  final double hoursThisMonth;
  final int totalWorkouts;

  /// Consecutive weeks with at least [streakSessionsPerWeek] sessions.
  final int weekStreak;

  /// Best pulls from Peak Load sessions.
  final double maxPullLeft;
  final double maxPullRight;

  UserStats({
    required this.hoursThisMonth,
    required this.totalWorkouts,
    required this.weekStreak,
    required this.maxPullLeft,
    required this.maxPullRight,
  });
}

/// Counts back through Monday-start weeks while each has at least
/// [minSessions] workouts. The current week only adds to the streak once it
/// reaches the target; until then it doesn't break it either, so the streak
/// doesn't reset every Monday.
int weeklyStreak(
  Iterable<DateTime> workoutDates,
  DateTime now, {
  int minSessions = streakSessionsPerWeek,
}) {
  final sessionsPerWeek = <DateTime, int>{};
  for (final date in workoutDates) {
    final day = dateOnly(date);
    final monday = DateTime(day.year, day.month, day.day - (day.weekday - 1));
    sessionsPerWeek[monday] = (sessionsPerWeek[monday] ?? 0) + 1;
  }

  int sessionsInWeek(int weekOffset) =>
      sessionsPerWeek[mondayForWeekOffset(weekOffset, now: now)] ?? 0;

  var streak = sessionsInWeek(0) >= minSessions ? 1 : 0;
  for (var offset = -1; sessionsInWeek(offset) >= minSessions; offset--) {
    streak++;
  }
  return streak;
}

final userStatsProvider = FutureProvider.autoDispose<UserStats>((ref) async {

  // Watch for the Database for changes.
  ref.watch(workoutDatabaseSignalProvider);

  // Grab the raw database connection directly!
  final db = await ref.watch(databaseProvider.future);

  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
  final startOfNextMonth = DateTime(now.year, now.month+1, 1).toIso8601String();

  final countResult = await db.rawQuery(
    '''
    SELECT COUNT(*) FROM workout
    WHERE date_done >= ? AND date_done < ?
    ''',
    [startOfMonth, startOfNextMonth],
  );
  final totalWorkouts = Sqflite.firstIntValue(countResult) ?? 0;
  
  final sumResult = await db.rawQuery('''
    SELECT SUM(duration) 
    FROM workout 
    WHERE date_done >= ?
  ''', [startOfMonth]);
  
  final totalSecondsThisMonth = Sqflite.firstIntValue(sumResult) ?? 0;
  final hoursThisMonth = totalSecondsThisMonth / 3600.0;

  final datesResult = await db.rawQuery('SELECT date_done FROM workout');
  final streak = weeklyStreak(
    datesResult.map((row) => DateTime.parse(row['date_done'] as String)),
    now,
  );

  // Peak Load sessions update these when a new best is set.
  final userRows = await db.query(
    'user',
    columns: ['max_pull_left', 'max_pull_right'],
    where: 'user_id = ?',
    whereArgs: [1], // TODO: Assuming a single local user for now
  );
  final userRow = userRows.isEmpty ? null : userRows.first;

  return UserStats(
    hoursThisMonth: hoursThisMonth,
    totalWorkouts: totalWorkouts,
    weekStreak: streak,
    maxPullLeft: (userRow?['max_pull_left'] as num?)?.toDouble() ?? 0.0,
    maxPullRight: (userRow?['max_pull_right'] as num?)?.toDouble() ?? 0.0,
  );
});
