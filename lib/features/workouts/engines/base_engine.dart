

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/providers/graph_controller_provider.dart';
import 'package:lifter/features/bluetooth/ble_manager.dart';
import 'package:lifter/features/history/models/log_models.dart';
import 'package:lifter/features/workouts/models/actions.dart';
import 'package:lifter/features/workouts/models/base_models.dart';
import 'package:lifter/features/workouts/rules/workout_rules.dart';

abstract class BaseEngine<T> extends Notifier<T> {
  // Child classes must assign this in their build() method
  late final WorkoutRules<T> rules; 
  
  Timer? _timer;
  StreamSubscription? _bleSub;
  Phase currentPhase = Phase.idle;

  // Child classes tell the base class how to read their specific phase
  Phase extractPhase(T state);

  // Every engine must know how to build a workout summary.
  WorkoutLog buildSummary(T state);

  void dispatch(WorkoutAction action) {
    // 1. Calculate the new state using the pure rules
    final newState = rules.reduce(state, action);
    
    // 2. Check if the environment needs to update
    final newPhase = extractPhase(newState);
    _syncEnvironment(currentPhase, newPhase);
    currentPhase = newPhase;

    // 3. Update Riverpod's state to trigger UI rebuilds
    state = newState;
  }

  void _syncEnvironment(Phase oldPhase, Phase newPhase) {
    if (oldPhase == newPhase) return;

    if (newPhase == Phase.working || newPhase == Phase.resting || 
        newPhase == Phase.setResting || newPhase == Phase.switching ||
        newPhase == Phase.starting) {
      startTimer();
    } else {
      stopTimer();
    }

    if (newPhase == Phase.done || newPhase == Phase.cancelled) {
      stopBle();
    }
  }

  WorkoutLog getFinalSummary() {
    return buildSummary(state);
  }

  void startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => dispatch(TickAction()));
  }

  void stopTimer() => _timer?.cancel();

  void startBle() {
    if (_bleSub != null) {
        stopBle();
    }
    BleManager.instance.startListening();
    _bleSub = BleManager.instance.weightStream.listen((reading) {
      if (currentPhase != Phase.idle && currentPhase != Phase.done) {
        ref.read(graphControllerProvider).addSample(reading.weightKg);
      }
      dispatch(WeightReceivedAction(reading.weightKg));
    });
  }

  void stopBle() {
    _bleSub?.cancel();
    BleManager.instance.stopListening();
  }
}
