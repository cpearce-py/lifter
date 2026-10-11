import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/providers/cache_for.dart';
import 'package:lifter/core/providers/history_provider.dart';
import 'package:lifter/core/providers/repository_providers.dart';
import 'package:lifter/features/history/models/log_models.dart';
import 'package:lifter/features/history/models/workout_query_filter.dart';

/// Midnight at the start of [date]'s day. Built from parts rather than by
/// subtracting a Duration, so daylight saving changes can't shift it.
DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// The Monday of the week [weekOffset] weeks away from today.
DateTime mondayForWeekOffset(int weekOffset, {DateTime? now}) {
  final today = dateOnly(now ?? DateTime.now());
  return DateTime(
    today.year,
    today.month,
    today.day + weekOffset * 7 - (today.weekday - 1),
  );
}

// The .family modifier allows us to pass a 'weekOffset' integer into the provider
final weekWorkoutsProvider = FutureProvider.family.autoDispose<List<WorkoutLog>, int>((ref, weekOffset) async {

  ref.watch(workoutDatabaseSignalProvider);

  final repo = await ref.watch(workoutRepositoryProvider.future);

  final startOfWeek = mondayForWeekOffset(weekOffset);
  final endOfWeek = DateTime(
    startOfWeek.year,
    startOfWeek.month,
    startOfWeek.day + 7,
  ).subtract(const Duration(microseconds: 1));

  return repo.getWorkouts(
    filter: WorkoutQueryFilter(
      startDate: startOfWeek,
      endDate: endOfWeek,
      limit: 100,
      offset: 0,
    ),
  );
});

/// Workouts done on a single day, newest first. Pass a date-only DateTime.
final dayWorkoutsProvider = FutureProvider.family.autoDispose<List<WorkoutLog>, DateTime>((ref, day) async {
  ref.watch(workoutDatabaseSignalProvider);
  // Flicking between days on the calendar shouldn't re-query each time.
  ref.cacheFor(const Duration(seconds: 30));

  final repo = await ref.watch(workoutRepositoryProvider.future);
  final endOfDay = DateTime(day.year, day.month, day.day + 1)
      .subtract(const Duration(microseconds: 1));

  return repo.getWorkouts(
    filter: WorkoutQueryFilter(startDate: day, endDate: endOfDay, limit: 100),
  );
});

/// The day tapped on the home page calendar, or null to show recent workouts.
final selectedDayProvider = NotifierProvider<SelectedDayNotifier, DateTime?>(
  SelectedDayNotifier.new,
);

class SelectedDayNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  /// Selects [day], or clears the selection if it's already selected.
  void toggle(DateTime day) {
    final date = dateOnly(day);
    state = state == date ? null : date;
  }

  void clear() => state = null;
}
