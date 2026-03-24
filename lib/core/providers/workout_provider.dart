import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/features/workouts/graph.dart';
import 'package:lifter/features/workouts/workout_state_machine.dart';

final workoutNotifierProvider = NotifierProvider<StateMachine, WorkoutState>(() {
  return StateMachine();
});

final graphControllerProvider = Provider<LiveGraphController>((ref) {
  return ref.read(workoutNotifierProvider.notifier).graphController;
});
