import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/features/workouts/ui/graph.dart';

final graphControllerProvider = Provider.autoDispose<LiveGraphController>((ref) {
  final controller = LiveGraphController(initialMax: 100.0);
  ref.onDispose(() => controller.dispose());
  return controller;
});
