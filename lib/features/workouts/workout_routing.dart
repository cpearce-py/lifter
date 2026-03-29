import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:lifter/features/history/models/log_models.dart';
import 'package:lifter/features/workouts/models/base_models.dart';
import 'package:lifter/features/workouts/notes/save_page.dart';

/// Listens to any workout provider and automatically routes to the Save page when done.
void listenToWorkoutCompletion<T>(
  BuildContext context,
  WidgetRef ref, {
  required ProviderListenable<T> provider,
  required Phase Function(T state) getPhase,
  required WorkoutLog Function() getFinalLog,
}) {
  ref.listen<T>(provider, (previous, next) {
    final prevPhase = previous == null ? Phase.idle : getPhase(previous);
    final nextPhase = getPhase(next);

    if (prevPhase != Phase.done && nextPhase == Phase.done) {
      
      final finalLog = getFinalLog();

      Future.delayed(const Duration(seconds: 1), () {
        if (context.mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => SaveWorkoutPage(workoutLog: finalLog),
            ),
          );
        }
      });
    }
  });
}
