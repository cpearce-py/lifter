import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/providers/repository_providers.dart';
import 'package:lifter/features/history/models/log_models.dart';

final workoutHistoryProvider = FutureProvider.autoDispose<List<WorkoutLog>>((ref) async {
  final repository = await ref.watch(workoutRepositoryProvider.future);
  return repository.getWorkouts(); 
});
