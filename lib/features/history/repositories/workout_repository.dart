import 'package:lifter/features/history/models/log_models.dart';
import 'package:lifter/features/history/models/workout_query_filter.dart';

abstract class WorkoutRepository {
  Future<void> saveWorkout(WorkoutLog log);

  /// Overwrites a saved workout (matched by [WorkoutLog.id]) and its sets.
  /// The graph and template link are left as they were.
  Future<void> updateWorkout(WorkoutLog log);
  Future<List<WorkoutLog>> getWorkouts({WorkoutQueryFilter? filter});
  Future<WorkoutLog?> getWorkoutById(int id);
  Future<void> deleteWorkout(int id);
  Future<void> updateWorkoutNote(int id, String note);
}
