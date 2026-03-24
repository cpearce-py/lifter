import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/features/bluetooth/ble_service.dart';

final bleServiceProvider = Provider<WeiHengC06Service>((ref) {
  final service = WeiHengC06Service();
  // service.startListening();
  ref.onDispose(service.dispose);
  return service;
});

final weightStreamProvider = StreamProvider<WeightReading>((ref) {
  return ref.watch(bleServiceProvider).weightStream;
});

// Listens to the actual hardware to see if the antenna is currently scanning
final isBluetoothScanningProvider = StreamProvider<bool>((ref) {
  return FlutterBluePlus.isScanning;
});
