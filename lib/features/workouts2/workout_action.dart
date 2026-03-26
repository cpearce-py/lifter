
import 'package:lifter/features/workouts2/models/base_models.dart';

sealed class WorkoutAction {}

class TickAction extends WorkoutAction {}

class WeightReceivedAction extends WorkoutAction {
  final double weightKg;
  WeightReceivedAction(this.weightKg);
}

class UserEventAction extends WorkoutAction {
  final Event event;
  UserEventAction(this.event);
}
