import 'package:flutter_riverpod/flutter_riverpod.dart';
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
