// Fetch all workouts for a specific timeframe (unpaginated for charts!)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/providers/repository_providers.dart';
import 'package:lifter/features/history/models/log_models.dart';
import 'package:lifter/features/history/models/workout_query_filter.dart';

final chartWorkoutsProvider = FutureProvider.autoDispose<List<WorkoutLog>>((
  ref,
) async {
  final repo = await ref.watch(workoutRepositoryProvider.future);

  final startDate = DateTime(DateTime.now().year - 1, DateTime.now().month, DateTime.now().day);

  // Pass a massive limit to bypass standard pagination for graph accuracy
  return repo.getWorkouts(
    filter: WorkoutQueryFilter(startDate: startDate, limit: 10000),
  );
});
