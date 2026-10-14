import 'package:flutter_test/flutter_test.dart';
import 'package:lifter/features/workouts/models/actions.dart';
import 'package:lifter/features/workouts/models/base_models.dart';
import 'package:lifter/features/workouts/models/peak_load_state.dart';
import 'package:lifter/features/workouts/rules/peak_load_rules.dart';
import 'package:lifter/features/workouts/workout_routing.dart';

void main() {
  test('only a session with work in it asks before leaving', () {
    for (final phase in [Phase.idle, Phase.starting, Phase.done, Phase.cancelled]) {
      expect(isWorkoutUnderway(phase), isFalse, reason: '$phase');
    }
    for (final phase in [
      Phase.working,
      Phase.resting,
      Phase.setResting,
      Phase.switching,
      Phase.paused,
    ]) {
      expect(isWorkoutUnderway(phase), isTrue, reason: '$phase');
    }
  });

  test('Peak Load counts only the seconds spent pulling', () {
    const config = PeakLoadState(bodyWeight: 60, restSeconds: 3);
    final rules = PeakLoadRules(config);
    var state = rules.reduce(config, UserEventAction(Event.start));

    // 5s countdown, then a 7s pull, a 5s switch, a 7s pull and some rest.
    for (var i = 0; i < 5 + 7 + 5 + 7 + 2; i++) {
      state = rules.reduce(state, TickAction());
    }

    expect(state.phase, Phase.resting);
    expect(state.accumulatedWorkSeconds, 14);
  });
}
