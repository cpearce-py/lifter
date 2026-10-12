import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/providers/cache_for.dart';
import 'package:lifter/core/providers/repository_providers.dart';
import 'package:lifter/features/history/models/log_models.dart';
import 'package:lifter/features/history/models/workout_query_filter.dart';
import 'package:lifter/features/history/repositories/workout_repository.dart';
import 'package:lifter/features/user/providers/user_settings_provider.dart';

class WorkoutDatabaseSignal extends Notifier<int> {
  @override 
  int build() {
    return 0;
  }

  void notifyChange() {
    state++;
  }
}

final workoutDatabaseSignalProvider = NotifierProvider<WorkoutDatabaseSignal, int>(
  WorkoutDatabaseSignal.new,
);

// A custom state to hold the list AND the pagination status
class HistoryPaginationState {
  final List<WorkoutLog> workouts;
  final bool hasMore; // True if there are more pages in the DB
  final bool isFetchingNextPage;

  HistoryPaginationState({
    required this.workouts, 
    required this.hasMore,
    this.isFetchingNextPage = false,
  });
}

class WorkoutHistoryNotifier extends AsyncNotifier<HistoryPaginationState> {
  static const int _limit = 20;
  int _currentOffset = 0;

  @override
  Future<HistoryPaginationState> build() async {
    // Watch the same things the calendar and stats do, so a new database
    // (e.g. after a nuke) or any change to it reloads this list too.
    ref.watch(workoutDatabaseSignalProvider);
    final repo = await ref.watch(workoutRepositoryProvider.future);

    // The home page stops listening while a calendar day is selected, so
    // keep the list around for a bit rather than reloading on the way back.
    ref.cacheFor(const Duration(seconds: 30));
    _currentOffset = 0;
    return _fetchPage(repo);
  }

  Future<HistoryPaginationState> _fetchPage(WorkoutRepository repo) async {

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
    final currentState = state.value;
    // Prevent spam-clicking the button or fetching if we are already at the end
    if (currentState == null || currentState.isFetchingNextPage || !currentState.hasMore) return;

    // 1. Tell Riverpod we are loading, but KEEP the previous data visible
    // so the screen doesn't flash white!
    state = AsyncData(HistoryPaginationState(
      workouts: currentState.workouts,
      hasMore: currentState.hasMore,
      isFetchingNextPage: true, 
    ));

    try {
      // 2. Increment the offset for the SQL query
      _currentOffset += _limit;
      // 3. Fetch and update the state
      final repo = await ref.read(workoutRepositoryProvider.future);
      final newState = await _fetchPage(repo);
      state = AsyncData(newState);

    } catch (e, st) {
      log(
        "Failed to load more", 
        error: e, 
        stackTrace: st, 
        name: "WorkoutHistoryNotifier"
      );

      // Turn off the loading spinner so they can try again
      state = AsyncData(HistoryPaginationState(
        workouts: currentState.workouts,
        hasMore: currentState.hasMore,
        isFetchingNextPage: false,
      ));
    }
  }

  Future<void> saveWorkout(WorkoutLog newWorkout) async {
    final repo = await ref.read(workoutRepositoryProvider.future);
    await repo.saveWorkout(newWorkout);
    // A Peak Load session may have set a new best.
    await ref.read(userSettingsProvider.notifier).syncMaxPullsFromDatabase();
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

    _invalidateProviders();
  }
  
  Future<WorkoutLog?> getWorkoutById(int workoutId) async {
    try {
      final repo = await ref.read(workoutRepositoryProvider.future);
      return await repo.getWorkoutById(workoutId);
    } catch (e, st) {
      log(
        "Failed to fetch full workout by ID: $workoutId", 
        error: e, 
        stackTrace: st, 
        name: "WorkoutHistoryNotifier"
      );
      return null;
    }
  }

  void _invalidateProviders() {
    ref.read(workoutDatabaseSignalProvider.notifier).state++;
  }

  /// Returns false if seeding failed. The error is logged rather than put
  /// in [state], so a failed seed doesn't take down the history list.
  Future<bool> injectDummyData() async {
    try {
      final repo = await ref.read(workoutRepositoryProvider.future);
      await repo.seedDummyData();
      await ref.read(userSettingsProvider.notifier).syncMaxPullsFromDatabase();
      
      _invalidateProviders();
      ref.invalidateSelf();
      return true;
    } catch (e, st) {
      log("Failed to seed dummy data", error: e, stackTrace: st, name: "WorkoutHistoryNotifier");
      return false;
    }
  } 
}

final workoutHistoryProvider =
    AsyncNotifierProvider.autoDispose<
      WorkoutHistoryNotifier,
      HistoryPaginationState
    >(WorkoutHistoryNotifier.new);
