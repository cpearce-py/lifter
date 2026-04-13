import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/features/workouts/engines/peak_load_engine.dart';
import 'package:lifter/features/workouts/models/actions.dart';
import 'package:lifter/features/workouts/models/base_models.dart';
import 'package:lifter/features/workouts/models/peak_load_state.dart';
import 'package:lifter/features/workouts/sessions/repeater_workout_page.dart';
import 'package:lifter/features/workouts/ui/generic_widgets.dart';
import 'package:lifter/features/workouts/ui/widgets/workout_top_bar.dart';
import 'package:lifter/features/workouts/workout_routing.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';

class PeakLoadSessionPage extends ConsumerWidget {
  const PeakLoadSessionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    listenToWorkoutCompletion(
      context,
      ref,
      provider: peakLoadEngineProvider,
      getPhase: (state) => state.phase,
      getFinalLog: () =>
          ref.read(peakLoadEngineProvider.notifier).getFinalSummary(),
    );
    final state = ref.watch(peakLoadEngineProvider);
    final phase = state.phase;
    final accentColor = accentColorForPhase(phase, context);

    const double hPad = 15.0;
    const double sectionSpacing = 18.0;

    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: Column(
          children: [
            WorkoutTopBar(
              onClose: () => Navigator.of(context).pop(),
              title: Text(
                "Peak Load",
                style: context.h1.copyWith(
                  fontSize: 18,
                  color: context.textPrimary,
                ),
              ),
            ),

            LinearProgressIndicator(
              value:
                  state.secondsRemaining /
                  state.currentPhaseDuration, // Will animate from 1.0 to 0.0
              backgroundColor: context.textPrimary.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              minHeight: 4, // Keep it thin and elegant
            ),

            const SizedBox(height: sectionSpacing),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: hPad),
              child: Row(
                mainAxisAlignment:  MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SET ${state.repCount}',
                    style: context.overline.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: context.textPrimary,
                    ),
                  ),
                  PhaseLabel(phase: phase, accentColor: accentColor),
                ],
              ),
            ),

            const SizedBox(height: sectionSpacing),

            StatInfoBar(
              timeProvider: peakLoadEngineProvider.select(
                (s) => s.secondsRemaining,
              ),
            ),

            const SizedBox(height: sectionSpacing),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: hPad),
                child: GenericGraphArea(
                  phase: phase,
                  overlay: Text(
                    'HAND: ${state.currentHand.name.toUpperCase()}',
                    style: context.body.copyWith(
                      color: context.textMuted,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: sectionSpacing),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: hPad),
              child: phase == Phase.resting
                  ? _PeakLoadRestControls(state: state)
                  : GenericWorkoutControls(
                      phase: phase,
                      onReset: () => ref
                          .read(peakLoadEngineProvider.notifier)
                          .dispatch(UserEventAction(Event.reset)),
                      onPrimaryAction: () {
                        final event = primaryButtonEvent(phase);
                        if (event != null) {
                          HapticFeedback.mediumImpact();
                          ref
                              .read(peakLoadEngineProvider.notifier)
                              .dispatch(UserEventAction(event));
                        }
                      },
                      onSecondaryAction: () {
                        HapticFeedback.mediumImpact();
                        ref
                            .read(peakLoadEngineProvider.notifier)
                            .dispatch(UserEventAction(Event.finish));
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeakLoadRestControls extends ConsumerWidget {
  final PeakLoadState state;
  const _PeakLoadRestControls({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (!state.isLeftStopped)
          ElevatedButton(
            onPressed: () {
              ref
                  .read(peakLoadEngineProvider.notifier)
                  .dispatch(StopHandAction(Hand.left));
            },
            child: const Text('Stop Left'),
          ),
        if (!state.isRightStopped)
          ElevatedButton(
            onPressed: () {
              ref
                  .read(peakLoadEngineProvider.notifier)
                  .dispatch(StopHandAction(Hand.right));
            },
            child: const Text('Stop Right'),
          ),
        ElevatedButton(
          onPressed: () => ref
              .read(peakLoadEngineProvider.notifier)
              .dispatch(UserEventAction(Event.finish)),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          child: const Text('Finish', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
