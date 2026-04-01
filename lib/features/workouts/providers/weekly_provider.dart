import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/providers/repository_providers.dart';
import 'package:lifter/features/history/models/workout_query_filter.dart';

// The .family modifier allows us to pass a 'weekOffset' integer into the provider
final weekWorkoutsProvider = FutureProvider.family.autoDispose<List<DateTime>, int>((ref, weekOffset) async {
  final repo = await ref.watch(workoutRepositoryProvider.future);
  
  final now = DateTime.now();
  // Shift our reference date by the requested number of weeks.
  final targetDate = now.add(Duration(days: weekOffset * 7)); 
  
  final monday = targetDate.subtract(Duration(days: targetDate.weekday - 1));
  
  final startOfWeek = DateTime(monday.year, monday.month, monday.day);
  final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

  final weekWorkouts = await repo.getWorkouts(
    filter: WorkoutQueryFilter(
      startDate: startOfWeek,
      endDate: endOfWeek,
      limit: 100, 
      offset: 0,
    ),
  );

  return weekWorkouts.map((w) => w.dateDone).toList();
});
