import 'package:lifter/features/workouts2/workout_action.dart';

abstract class WorkoutRules<T> {
  T reduce(T currentState, WorkoutAction action);
}
