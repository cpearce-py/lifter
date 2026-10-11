import 'package:flutter_test/flutter_test.dart';
import 'package:lifter/core/providers/stats_provider.dart';
import 'package:lifter/features/workouts/providers/weekly_provider.dart';

void main() {
  // Thursday 8 October 2026. Its week starts Monday 5 October.
  final now = DateTime(2026, 10, 8, 18, 30);

  DateTime day(int month, int d, [int hour = 12]) => DateTime(2026, month, d, hour);

  group('mondayForWeekOffset', () {
    test('finds this and other weeks\' Mondays', () {
      expect(mondayForWeekOffset(0, now: now), DateTime(2026, 10, 5));
      expect(mondayForWeekOffset(-1, now: now), DateTime(2026, 9, 28));
      expect(mondayForWeekOffset(1, now: now), DateTime(2026, 10, 12));
    });

    test('treats Sunday as the end of the week', () {
      expect(mondayForWeekOffset(0, now: DateTime(2026, 10, 11)), DateTime(2026, 10, 5));
    });

    test('lands on midnight across a daylight saving change', () {
      // UK clocks go back on 25 October 2026.
      final monday = mondayForWeekOffset(0, now: DateTime(2026, 10, 28));
      expect(monday, DateTime(2026, 10, 26));
      expect(monday.hour, 0);
    });
  });

  group('weeklyStreak', () {
    test('is zero with no workouts', () {
      expect(weeklyStreak([], now), 0);
    });

    test('counts consecutive weeks that hit the target', () {
      final dates = [
        day(10, 6), day(10, 7), // this week: 2
        day(9, 30), day(10, 2), // last week: 2
        day(9, 22), day(9, 24), day(9, 26), // week before: 3
      ];
      expect(weeklyStreak(dates, now), 3);
    });

    test('an unfinished week does not break the streak', () {
      final dates = [
        day(10, 7), // this week: only 1 so far
        day(9, 30), day(10, 2),
        day(9, 22), day(9, 24),
      ];
      expect(weeklyStreak(dates, now), 2);
    });

    test('a past week below the target ends the streak', () {
      final dates = [
        day(10, 6), day(10, 7),
        day(9, 30), // last week: 1
        day(9, 22), day(9, 24),
      ];
      expect(weeklyStreak(dates, now), 1);
    });

    test('two sessions on the same day both count', () {
      expect(weeklyStreak([day(10, 6, 9), day(10, 6, 19)], now), 1);
    });

    test('Sunday night still belongs to that week', () {
      final dates = [day(10, 4, 23), day(9, 29)]; // Sun 4th + Tue 29th
      expect(weeklyStreak(dates, now), 1);
    });
  });
}
