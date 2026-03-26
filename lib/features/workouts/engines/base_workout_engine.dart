import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/providers/scale_provider.dart';
import 'package:lifter/features/bluetooth/ble_service.dart';

abstract class BaseWorkoutEngine<T> extends Notifier<T> {
  Timer? _timer;
  StreamSubscription<WeightReading>? _scaleSub;
  WeiHengC06Service? _bleService;
  // Contracts that every child workout engine must fulfill
  void onTimerTick();
  void onWeightReceived(WeightReading reading);

  void startTimers() {
    stopTimers();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => onTimerTick());
  }

  void stopTimers() {
    _timer?.cancel();
    _timer = null;
  }

  void startBleListening() {
    stopBleListening();
    _bleService = ref.read(bleServiceProvider);
    _scaleSub = _bleService!.weightStream.listen(onWeightReceived);
    _bleService!.startListening();
  }

  void stopBleListening() {
    _scaleSub?.cancel();
    _scaleSub = null;
    _bleService?.stopListening();
  }
}
