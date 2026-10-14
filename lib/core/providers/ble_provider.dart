import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/providers/shared_preferences_provider.dart';
import 'package:lifter/features/bluetooth/ble_manager.dart';

final bleManagerProvider = Provider<BleManager>((ref) => BleManager.instance);

final liveWeightStreamProvider = StreamProvider.autoDispose<double>((ref) {
  final bleManager = ref.watch(bleManagerProvider);
  
  // Start the hardware scan when the page opens
  bleManager.startListening();
  
  // Stop the hardware scan when the user leaves the page
  ref.onDispose(() {
    bleManager.stopListening();
  });

  // Pluck out just the double value for your UI
  return bleManager.weightStream.map((reading) => reading.weightKg);
});

/// Where the scale connection is at, starting from its current state.
final scaleStatusProvider = StreamProvider.autoDispose<ScaleStatus>((ref) async* {
  final bleManager = ref.watch(bleManagerProvider);
  yield bleManager.status;
  yield* bleManager.statusStream;
});

/// The id of the scale readings are taken from, or null until one has been
/// heard. Kept across launches so a scale nearby can't take over.
class PairedScaleNotifier extends Notifier<String?> {
  static const _prefsKey = 'pairedScaleId';

  @override
  String? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final bleManager = ref.watch(bleManagerProvider);
    final saved = prefs.getString(_prefsKey);
    bleManager.pairedDeviceId = saved;

    final sub = bleManager.pairedStream.listen((id) {
      prefs.setString(_prefsKey, id);
      state = id;
    });
    ref.onDispose(sub.cancel);

    return saved;
  }

  /// Lets the next scale heard become the paired one, e.g. a new scale.
  void forget() {
    ref.read(sharedPreferencesProvider).remove(_prefsKey);
    ref.read(bleManagerProvider).pairedDeviceId = null;
    state = null;
  }
}

final pairedScaleProvider = NotifierProvider<PairedScaleNotifier, String?>(
  PairedScaleNotifier.new,
);
