import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/providers/repository_providers.dart';
import 'package:lifter/core/providers/stats_provider.dart';
import 'package:lifter/features/history/models/log_models.dart';
import 'package:lifter/features/history/models/workout_query_filter.dart';
import 'package:lifter/features/workouts/providers/weekly_provider.dart';

// A custom state to hold the list AND the pagination status
class HistoryPaginationState {
  final List<WorkoutLog> workouts;
  final bool hasMore; // True if there are more pages in the DB

  HistoryPaginationState({required this.workouts, required this.hasMore});
}

class WorkoutHistoryNotifier extends AsyncNotifier<HistoryPaginationState> {
  static const int _limit = 20;
  int _currentOffset = 0;

  @override
  Future<HistoryPaginationState> build() async {
    _currentOffset = 0;
    return _fetchPage();
  }

  Future<HistoryPaginationState> _fetchPage() async {
    final repo = await ref.read(workoutRepositoryProvider.future);

    // Fetch the specific chunk
    final newWorkouts = await repo.getWorkouts(
      filter: WorkoutQueryFilter(limit: _limit, offset: _currentOffset),
    );

    // If the DB returned a full 20 items, there is likely a page 2!
    // If it returned 19 or fewer, we know we've hit the end of the history.
    final hasMore = newWorkouts.length == _limit;

    // Grab whatever workouts we already loaded (if any)
    // if the offset is 0, we're not paginated and shouldn't keep the current
    // cached workouts.
    final currentWorkouts = _currentOffset == 0
        ? <WorkoutLog>[]
        : state.value?.workouts ?? [];

    return HistoryPaginationState(
      workouts: [
        ...currentWorkouts,
        ...newWorkouts,
      ], // Append the new ones to the bottom!
      hasMore: hasMore,
    );
  }

  Future<void> loadMore() async {
    // Prevent spam-clicking the button or fetching if we are already at the end
    if (state.isLoading || !(state.value?.hasMore ?? false)) return;

    // 1. Tell Riverpod we are loading, but KEEP the previous data visible
    // so the screen doesn't flash white!
    state = const AsyncLoading<HistoryPaginationState>().copyWithPrevious(
      state,
    );

    // 2. Increment the offset for the SQL query
    _currentOffset += _limit;

    // 3. Fetch and update the state
    try {
      final newState = await _fetchPage();
      state = AsyncData(newState);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> saveWorkout(WorkoutLog newWorkout) async {
    final repo = await ref.read(workoutRepositoryProvider.future);
    await repo.saveWorkout(newWorkout);
    _invalidateProviders();
    ref.invalidateSelf();
  }

  Future<void> deleteWorkout(int workoutId) async {
    final repo = await ref.read(workoutRepositoryProvider.future);
    await repo.deleteWorkout(workoutId);
    // Optimistic UI update.
    final currentState = state.value;
    if (currentState != null) {
      final updatedWorkouts = currentState.workouts
          .where((w) => w.id != workoutId)
          .toList();

      state = AsyncData(
        HistoryPaginationState(
          workouts: updatedWorkouts,
          hasMore: currentState.hasMore,
        ),
      );
    }
    
    _invalidateProviders();
  }

  Future<void> updateWorkoutNote(int workoutId, String newNote) async {
    final repo = await ref.read(workoutRepositoryProvider.future);
    await repo.updateWorkoutNote(workoutId, newNote);
    // Optimistically update our Riverpod cache
    final currentState = state.value;
    if (currentState != null) {
      final updatedWorkouts = currentState.workouts.map((w) {
        if (w.id == workoutId) return w.copyWith(notes: newNote);
        return w;
      }).toList();

      state = AsyncData(HistoryPaginationState(
        workouts: updatedWorkouts, 
        hasMore: currentState.hasMore,
      ));
    }
  }

  void _invalidateProviders() {
    // Invalidate required providers if a workout is Saved, or Deleted.
    ref.invalidate(userStatsProvider);
    ref.invalidate(weekWorkoutsProvider);
  }

  Future<void> injectDummyData() async {
    state = const AsyncLoading<HistoryPaginationState>().copyWithPrevious(state);
    
    try {
      final repo = await ref.read(workoutRepositoryProvider.future);
      await repo.seedDummyData();
      
      _invalidateProviders();
      ref.invalidateSelf();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  } 
}

final workoutHistoryProvider =
    AsyncNotifierProvider.autoDispose<
      WorkoutHistoryNotifier,
      HistoryPaginationState
    >(WorkoutHistoryNotifier.new);
