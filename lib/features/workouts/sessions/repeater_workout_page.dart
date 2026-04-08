import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';
import 'package:lifter/features/workouts/engines/repeater_engine.dart';
import 'package:lifter/features/workouts/models/actions.dart';
import 'package:lifter/features/workouts/models/base_models.dart';
import 'package:lifter/features/workouts/models/repeater_state.dart';
import 'package:lifter/features/workouts/ui/generic_widgets.dart';
import 'package:lifter/features/workouts/ui/widgets/workout_live_stats.dart';
import 'package:lifter/features/workouts/ui/widgets/workout_top_bar.dart';
import 'package:lifter/features/workouts/workout_routing.dart';

class RepeaterWorkoutPage extends ConsumerWidget {
  const RepeaterWorkoutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // deals with re-routing to savepage
    listenToWorkoutCompletion(
      context,
      ref,
      provider: repeaterEngineProvider,
      getPhase: (state) => state.phase,
      getFinalLog: () =>
          ref.read(repeaterEngineProvider.notifier).getFinalSummary(),
    );

    final state = ref.watch(repeaterEngineProvider);

    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: Column(
          children: [
            WorkoutTopBar(
              phaseName: state.phase.name,
              onClose: () => Navigator.of(context).pop(),
              accent: context.repeaterAccent,
              trailing: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'SET ${state.currentSet} OF ${state.sets}',
                      style: context.overline.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(state.reps, (index) {
                        final isCompleted = index < (state.currentRep - 1);
                        final isCurrent = index == (state.currentRep - 1);
                        return Container(
                          margin: const EdgeInsets.only(left: 4),
                          width: isCurrent ? 12 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isCompleted || isCurrent
                                ? context.repeaterAccent
                                : context.textPrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
            StatInfoBar(
              timeProvider: repeaterEngineProvider.select(
                (s) => s.secondsRemaining,
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: GenericGraphArea(
                phase: state.phase,
                overlay: Text(
                  'HAND: ${state.currentHand.name.toUpperCase()}',
                  style: context.body.copyWith(color: context.textMuted),
                ),
              ),
            ),
            const SizedBox(height: 16),

            GenericWorkoutControls(
              phase: state.phase,
              onReset: () {
                HapticFeedback.lightImpact();
                ref
                  .read(repeaterEngineProvider.notifier)
                  .dispatch(UserEventAction(Event.reset));
                },
              onPrimaryAction: () {
                final event = primaryButtonEvent(state.phase);
                if (event != null) {
                  HapticFeedback.mediumImpact();
                  ref
                      .read(repeaterEngineProvider.notifier)
                      .dispatch(UserEventAction(event));
                }
              },
              onSecondaryAction: () {
                HapticFeedback.mediumImpact();
                ref
                  .read(repeaterEngineProvider.notifier)
                  .dispatch(UserEventAction(Event.finish));
                },
            ),
          ],
        ),
      ),
    );
  }
}

class StatInfoBar extends ConsumerWidget {
  final ProviderListenable<int> timeProvider;
  const StatInfoBar({super.key, required this.timeProvider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final secondsRemaining = ref.watch(timeProvider);

    return WorkoutLiveStats(secondsRemaining: secondsRemaining);
  }
}

