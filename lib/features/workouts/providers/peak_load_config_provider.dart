import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/features/user/providers/user_settings_provider.dart';
import 'package:lifter/features/workouts/models/base_models.dart';
import 'package:lifter/features/workouts/models/configs/peak_load_config.dart';
import 'package:lifter/features/workouts/models/peak_load_state.dart';

final peakLoadSetupProvider = NotifierProvider<PeakLoadSetupNotifier, PeakLoadConfig>(
  PeakLoadSetupNotifier.new,
);

class PeakLoadSetupNotifier extends Notifier<PeakLoadConfig> {
  @override
  PeakLoadConfig build() {
    // Grab the user's saved settings for the perfect defaults!
    final settings = ref.watch(userSettingsProvider);
    
    return PeakLoadConfig(
      bodyWeight: settings.bodyWeight,
      startingHand: settings.preferredHand,
    );
  }

  void updateBodyWeight(double val) => state = state.copyWith(bodyWeight: val);
  void updateRestSeconds(double val) => state = state.copyWith(restSeconds: val.toInt());
  void updateStartingHand(int index) => state = state.copyWith(startingHand: Hand.values[index]);

  /// Called right before pushing the live workout screen.
  PeakLoadState buildActiveState() {
    return PeakLoadState(
      bodyWeight: state.bodyWeight,
      restSeconds: state.restSeconds,
      startingHand: state.startingHand,
      currentHand: state.startingHand, // Initialize current to starting
    );
  }
}
