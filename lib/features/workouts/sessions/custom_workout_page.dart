import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/measurements/widgets/weight_text.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';
import 'package:lifter/features/workouts/engines/custom_workout_engine.dart';
import 'package:lifter/features/workouts/models/actions.dart';
import 'package:lifter/features/workouts/models/base_models.dart';
import 'package:lifter/features/workouts/models/custom/custom_workout_state.dart';
import 'package:lifter/features/workouts/sessions/repeater_workout_page.dart';
import 'package:lifter/features/workouts/ui/generic_widgets.dart';
import 'package:lifter/features/workouts/ui/widgets/workout_top_bar.dart';
import 'package:lifter/features/workouts/workout_routing.dart';

class CustomWorkoutPage extends ConsumerWidget {
  const CustomWorkoutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // deals with re-routing to savepage
    listenToWorkoutCompletion(
      context,
      ref,
      provider: customWorkoutEngineProvider,
      getPhase: (state) => state.phase,
      getFinalLog: () =>
          ref.read(customWorkoutEngineProvider.notifier).getFinalSummary(),
    );

    final state = ref.watch(customWorkoutEngineProvider);
    final inner = state.inner;
    final step = state.currentStep;
    final workingAccent = step.isWarmup
        ? context.warmupAccent
        : context.customAccent;
    final accentColor = accentColorForPhase(
      state.phase,
      context,
      working: workingAccent,
    );

    // Between blocks the next block is already loaded and resting.
    final isBlockTransition =
        state.phase == Phase.setResting &&
        step.isFirstOfBlock &&
        state.stepIndex > 0;

    const double hPad = 15.0;
    const double sectionSpacing = 18.0;

    void send(Event event) => ref
        .read(customWorkoutEngineProvider.notifier)
        .dispatch(UserEventAction(event));

    return WorkoutExitGuard(
      phase: state.phase,
      onFinish: () => send(Event.finish),
      child: Scaffold(
        backgroundColor: context.background,
        body: SafeArea(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: context.background,
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                stops: const [0.75, 1],
                colors: [
                  accentColor.withValues(alpha: 0.04),
                  accentColor.withValues(alpha: 0),
                ],
              ),
            ),
            child: Column(
              children: [
                WorkoutTopBar(
                  onClose: () => WorkoutExitGuard.close(
                    context,
                    phase: state.phase,
                    onFinish: () => send(Event.finish),
                  ),
                  title: Text(
                    state.templateName,
                    overflow: TextOverflow.ellipsis,
                    style: context.h1.copyWith(
                      fontSize: 18,
                      color: context.textPrimary,
                    ),
                  ),
                ),

                LinearProgressIndicator(
                  value: inner.currentPhaseDuration == 0
                      ? 0
                      : inner.secondsRemaining / inner.currentPhaseDuration,
                  backgroundColor: context.textPrimary.withValues(alpha: 0.05),
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  minHeight: 4,
                ),

                const SizedBox(height: sectionSpacing),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: hPad),
                  child: BlockHeader(state: state, isUpNext: isBlockTransition),
                ),

                const SizedBox(height: sectionSpacing),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: hPad),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SetsAndRepsIndicator(
                        currentSet: state.blockSet,
                        totalSets: step.block.sets,
                        currentRep: inner.currentRep,
                        totalReps: inner.reps,
                        accentColor: accentColor,
                      ),
                      PhaseLabel(phase: state.phase, accentColor: accentColor),
                    ],
                  ),
                ),

                const SizedBox(height: sectionSpacing),

                StatInfoBar(
                  timeProvider: customWorkoutEngineProvider.select(
                    (s) => s.inner.secondsRemaining,
                  ),
                ),

                const SizedBox(height: sectionSpacing),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: hPad),
                    child: GenericGraphArea(
                      phase: state.phase,
                      workingAccent: workingAccent,
                      overlay: Text(
                        isBlockTransition
                            ? 'UP NEXT'
                            : '${inner.currentHand.name.toUpperCase()} HAND',
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
                  child: GenericWorkoutControls(
                    phase: state.phase,
                    // Restarts the current block, not the whole workout.
                    onReset: () {
                      HapticFeedback.lightImpact();
                      send(Event.reset);
                    },
                    onPrimaryAction: () {
                      final event = primaryButtonEvent(state.phase);
                      if (event != null) {
                        HapticFeedback.mediumImpact();
                        send(event);
                      }
                    },
                    onSecondaryAction: () {
                      HapticFeedback.mediumImpact();
                      send(Event.finish);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows which block is running (or coming up), its kind, and the target.
class BlockHeader extends StatelessWidget {
  const BlockHeader({super.key, required this.state, required this.isUpNext});

  final CustomWorkoutState state;
  final bool isUpNext;

  @override
  Widget build(BuildContext context) {
    final step = state.currentStep;
    final kindColor = step.isWarmup
        ? context.warmupAccent
        : context.customAccent;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: kindColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      step.block.kind.label.toUpperCase(),
                      style: context.overline.copyWith(
                        color: kindColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'BLOCK ${step.blockIndex + 1} OF ${state.blockCount}',
                    style: context.overline.copyWith(
                      color: context.textMuted,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                isUpNext ? 'Next: ${step.block.name}' : step.block.name,
                overflow: TextOverflow.ellipsis,
                style: context.body.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${step.percentage}%',
              style: context.body.copyWith(
                fontWeight: FontWeight.w800,
                color: kindColor,
              ),
            ),
            WeightText(
              weightKg: step.targetWeight,
              style: TextStyle(fontSize: 12, color: context.textMuted),
            ),
          ],
        ),
      ],
    );
  }
}
