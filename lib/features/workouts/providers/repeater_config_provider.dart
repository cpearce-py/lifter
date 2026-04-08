import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/features/user/providers/user_settings_provider.dart';
import 'package:lifter/features/workouts/models/base_models.dart';
import 'package:lifter/features/workouts/models/configs/repeater_config.dart';
import 'package:lifter/features/workouts/models/repeater_state.dart';

final repeaterSetupProvider = NotifierProvider<RepeaterSetupNotifier, RepeaterConfig>(
  RepeaterSetupNotifier.new,
);

class RepeaterSetupNotifier extends Notifier<RepeaterConfig> {
  @override
  RepeaterConfig build() {
    // We can pull the user's settings to set intelligent defaults!
    final settings = ref.watch(userSettingsProvider);
    
    return RepeaterConfig(
      customWeight: settings.bodyWeight * 0.5, // e.g., default custom to 50% bodyweight
      startingHand: settings.preferredHand,
    );
  }

  // --- UI Action Methods ---
  void updateSets(double val) => state = state.copyWith(sets: val.toInt());
  void updateReps(double val) => state = state.copyWith(reps: val.toInt());
  void updateWorkSeconds(double val) => state = state.copyWith(workSeconds: val.toInt());
  void updateRestSeconds(double val) => state = state.copyWith(restSeconds: val.toInt());
  void updateSetRestSeconds(double val) => state = state.copyWith(setRestSeconds: val.toInt());
  void updateStartingHand(Hand hand) => state = state.copyWith(startingHand: hand);
  
  void updateRelativeTo(int val) => state = state.copyWith(relativeTo: val);
  void updateTargetPercentage(int val) => state = state.copyWith(targetPercentage: val);
  void updateCustomWeight(double val) => state = state.copyWith(customWeight: val);

  // --- Final Assembly ---
  /// Called right before pushing the workout screen.
  RepeaterState buildActiveState() {
    final settings = ref.read(userSettingsProvider);
    
    // Resolve the dropdown selection to a concrete weight
    final referenceWt = switch (state.relativeTo) {
      0 => settings.bodyWeight,
      1 => 100.0, // Replace with settings.maxLift if you have it!
      2 => state.customWeight,
      _ => settings.bodyWeight,
    };

    final intensityMultiplier = state.targetPercentage / 100.0;

    return RepeaterState(
      sets: state.sets,
      reps: state.reps,
      workSeconds: state.workSeconds,
      restSeconds: state.restSeconds,
      setRestSeconds: state.setRestSeconds,
      startingHand: state.startingHand,
      currentHand: state.startingHand,
      referenceWeight: referenceWt,
      targetIntensity: intensityMultiplier,
    );
  }
}
