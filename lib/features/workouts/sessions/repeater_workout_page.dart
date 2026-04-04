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

// ─── Rep Counter Overlay ──────────────────────────────────────────────────────

class _RepeaterOverlay extends ConsumerWidget {
  const _RepeaterOverlay({required this.state});

  final RepeaterState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = state.phaseProgress;
    final accentColor = accentColorForPhase(state.phase, context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0F).withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Set indicator
          Column(
            children: [
              _SetLabel(accentColor: accentColor),
              const SizedBox(height: 6),

              // Rep dots
              _RepDots(accentColor: accentColor),
            ],
          ),
          const SizedBox(height: 8),
          // Let's add the hand indicator right below the set tracker!
          Text(
            state.currentHand.name.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          // Circular countdown
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  backgroundColor: Colors.white.withOpacity(0.07),
                  valueColor: AlwaysStoppedAnimation(accentColor),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.phase == Phase.idle || state.phase == Phase.done
                          ? '–'
                          : '${state.secondsRemaining}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: accentColor,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RepDots extends ConsumerWidget {
  const _RepDots({required this.accentColor});

  final Color accentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (reps, currentRep) = ref.watch(
      repeaterEngineProvider.select((s) => (s.reps, s.currentRep)),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(reps, (i) {
        final done = i < currentRep - 1;
        final active = i == currentRep - 1;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: active ? 10 : 7,
            height: active ? 10 : 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (done || active)
                  ? accentColor
                  : accentColor.withOpacity(0.15),
            ),
          ),
        );
      }),
    );
  }
}

class _SetLabel extends ConsumerWidget {
  const _SetLabel({required this.accentColor});

  final Color accentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (currentSet, sets) = ref.watch(
      repeaterEngineProvider.select((s) => (s.currentSet, s.sets)),
    );
    return Text(
      'SET $currentSet/$sets',
      style: context.overline.copyWith(
        fontSize: 9,
        color: accentColor.withValues(alpha: 0.6),
      ),
    );
  }
}
