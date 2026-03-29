import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:lifter/core/providers/repository_providers.dart';

class UserStats {
  final double hoursThisMonth;
  final int totalWorkouts;
  final int currentStreak;

  UserStats({
    required this.hoursThisMonth,
    required this.totalWorkouts,
    required this.currentStreak,
  });
}

final userStatsProvider = FutureProvider.autoDispose<UserStats>((ref) async {
  // Grab the raw database connection directly!
  final db = await ref.watch(databaseProvider.future);

  // --- 1. Total Workouts Completed ---
  final countResult = await db.rawQuery('SELECT COUNT(*) FROM workout');
  final totalWorkouts = Sqflite.firstIntValue(countResult) ?? 0;

  // --- 2. Hours This Month ---
  final now = DateTime.now();
  // Get the 1st day of the current month in ISO format
  final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
  
  final sumResult = await db.rawQuery('''
    SELECT SUM(duration) 
    FROM workout 
    WHERE date_done >= ?
  ''', [startOfMonth]);
  
  final totalSecondsThisMonth = Sqflite.firstIntValue(sumResult) ?? 0;
  final hoursThisMonth = totalSecondsThisMonth / 3600.0;

  // --- 3. Current Streak (Days) ---
  // We grab just the unique dates (ignoring time of day) sorted newest to oldest
  final datesResult = await db.rawQuery('''
    SELECT DISTINCT date(date_done) as date_string
    FROM workout
    ORDER BY date_string DESC
  ''');

  int streak = 0;
  DateTime dateChecker = DateTime(now.year, now.month, now.day); // Start checking from today (midnight)

  for (var row in datesResult) {
    final dbDateStr = row['date_string'] as String;
    final dbDate = DateTime.parse(dbDateStr);
    final differenceInDays = dateChecker.difference(dbDate).inDays;

    if (differenceInDays == 0) {
      // Worked out on the day we are checking! 
      if (streak == 0) streak = 1; // Start the streak if it's today
    } else if (differenceInDays == 1) {
      // Worked out exactly one day prior to our checker. The streak continues!
      streak++;
      dateChecker = dbDate; // Shift our checker back a day
    } else if (differenceInDays > 1 && streak > 0) {
      // They missed a day, and we were already counting a streak. Stop here!
      break; 
    } else if (differenceInDays > 1 && streak == 0) {
      // They haven't worked out today OR yesterday. Streak is dead.
      break;
    }
  }

  return UserStats(
    hoursThisMonth: hoursThisMonth,
    totalWorkouts: totalWorkouts,
    currentStreak: streak,
  );
});
