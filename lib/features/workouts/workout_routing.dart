import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';
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

/// Whether leaving now would lose recorded work.
bool isWorkoutUnderway(Phase phase) => switch (phase) {
      Phase.idle || Phase.starting || Phase.done || Phase.cancelled => false,
      _ => true,
    };

/// Asks before a session that's under way is left, by the close button or
/// a back swipe, so a stray tap doesn't throw the workout away. [onFinish]
/// ends it early and goes on to the save page instead.
class WorkoutExitGuard extends StatelessWidget {
  final Phase phase;
  final VoidCallback onFinish;
  final Widget child;

  const WorkoutExitGuard({
    super.key,
    required this.phase,
    required this.onFinish,
    required this.child,
  });

  /// For the close button: leaves straight away unless there's work to lose.
  static Future<void> close(
    BuildContext context, {
    required Phase phase,
    required VoidCallback onFinish,
  }) async {
    if (!isWorkoutUnderway(phase)) {
      Navigator.of(context).pop();
      return;
    }
    await _confirm(context, onFinish);
  }

  static Future<void> _confirm(BuildContext context, VoidCallback onFinish) async {
    final choice = await showDialog<_ExitChoice>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardBackground,
        title: Text('End workout?', style: context.cardTitle),
        content: Text(
          'Finish now to save what you have so far, or discard this session.',
          style: context.body.copyWith(color: context.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_ExitChoice.discard),
            child: Text('Discard', style: TextStyle(color: context.danger)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_ExitChoice.keepGoing),
            child: Text('Keep going', style: TextStyle(color: context.textPrimary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_ExitChoice.finish),
            child: Text(
              'Finish',
              style: TextStyle(
                color: context.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    switch (choice) {
      case _ExitChoice.discard:
        // Navigator.pop skips PopScope, so this closes the page.
        Navigator.of(context).pop();
      case _ExitChoice.finish:
        onFinish();
      case _ExitChoice.keepGoing || null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isWorkoutUnderway(phase),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirm(context, onFinish);
      },
      child: child,
    );
  }
}

enum _ExitChoice { discard, keepGoing, finish }
