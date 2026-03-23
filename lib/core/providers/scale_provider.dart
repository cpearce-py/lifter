import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/features/bluetooth/ble_service.dart';

final weiHengServiceProvider = Provider<WeiHengC06Service>((ref) {
  final service = WeiHengC06Service();
  service.startListening();
  ref.onDispose(service.dispose);
  return service;
});

final weightStreamProvider = StreamProvider<WeightReading>((ref) {
  return ref.watch(weiHengServiceProvider).weightStream;
});
