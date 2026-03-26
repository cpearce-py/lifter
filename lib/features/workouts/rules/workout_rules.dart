
import 'package:lifter/features/workouts/models/actions.dart';

abstract class WorkoutRules<T> {
  T reduce(T currentState, WorkoutAction action);
}
