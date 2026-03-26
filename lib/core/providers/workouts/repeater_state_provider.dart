import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/features/workouts/engines/repeater_engine.dart';
import 'package:lifter/features/workouts/models/repeater_state.dart';

final repeaterEngineProvider = NotifierProvider.autoDispose<RepeaterEngine, RepeaterState>(
  () => RepeaterEngine(),
);
