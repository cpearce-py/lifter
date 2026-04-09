import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';
import 'package:lifter/features/workouts/engines/repeater_engine.dart';
import 'package:lifter/features/workouts/models/actions.dart';
import 'package:lifter/features/workouts/models/base_models.dart';
import 'package:lifter/features/workouts/ui/generic_widgets.dart';
import 'package:lifter/features/workouts/ui/widgets/workout_live_stats.dart';
import 'package:lifter/features/workouts/ui/widgets/workout_top_bar.dart';
import 'package:lifter/features/workouts/workout_routing.dart';

String getPhaseLabel(Phase phase, BuildContext context) {
  return switch (phase) {
    Phase.idle => "-|-|-",
    Phase.starting => "Set..",
    Phase.switching => "Swap",
    Phase.working => "Pull!",
    Phase.paused => "-|-|-",
    Phase.resting || Phase.setResting => "Rest",
    Phase.done => "Done",
    Phase.cancelled => "Cancelled",
  };
}
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
    final accentColor = accentColorForPhase(state.phase, context);

    return Scaffold(
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
                accentColor.withValues(alpha: 0.04), // Subtle glow at the top
                accentColor.withValues(alpha: 0),
              ],
            ),
          ),
          child: Column(
            children: [
              WorkoutTopBar(
                onClose: () => Navigator.of(context).pop(),
                title: Text(
                  "Repeater",
                  style: context.h1.copyWith(
                    fontSize: 18,
                    color: context.textPrimary,
                  ),
                ),
              ),
              LinearProgressIndicator(
                value: state.secondsRemaining / state.currentPhaseDuration, // Will animate from 1.0 to 0.0
                backgroundColor: context.textPrimary.withValues(alpha: 0.05),
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                minHeight: 4, // Keep it thin and elegant
              ),
              const SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    WorkoutProgressIndicator(
                      currentSet: state.currentSet,
                      totalSets: state.sets,
                      currentRep: state.currentRep,
                      totalReps: state.reps,
                      accentColor: accentColor,
                    ),
                    PhaseLabel(phase: state.phase, accentColor: accentColor)
                  ],
                ),
              ),

              const SizedBox(height: 16),

              StatInfoBar(
                timeProvider: repeaterEngineProvider.select(
                  (s) => s.secondsRemaining,
                ),
              ),

              Expanded(
                child: GenericGraphArea(
                  phase: state.phase,
                  overlay: Text(
                    '${state.currentHand.name.toUpperCase()} HAND',
                    style: context.body.copyWith(
                      color: context.textMuted,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
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
      ),
    );
  }
}

class PhaseLabel extends StatelessWidget {
  const PhaseLabel({super.key, required this.phase, required this.accentColor});

  final Phase phase;
  final Color accentColor;

  String getPhaseLabel(Phase phase, BuildContext context) {
    return switch (phase) {
      Phase.idle => "-|-|-",
      Phase.starting => "Set..",
      Phase.switching => "Swap",
      Phase.working => "Pull!",
      Phase.paused => "-|-|-",
      Phase.resting || Phase.setResting => "Rest",
      Phase.done => "Done",
      Phase.cancelled => "Cancelled",
    };
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      getPhaseLabel(phase, context),
      key: ValueKey<Phase>(phase),
      style: context.h1.copyWith(
        fontSize: 48, // Much larger and draws immediate attention
        color: accentColor,
        letterSpacing: 4,
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

class WorkoutProgressIndicator extends StatelessWidget {
  final int currentSet;
  final int totalSets;
  final int currentRep;
  final int totalReps;
  final Color accentColor;

  const WorkoutProgressIndicator({
    super.key,
    required this.currentSet,
    required this.totalSets,
    required this.currentRep,
    required this.totalReps,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'SET $currentSet OF $totalSets',
          style: context.overline.copyWith(
            fontSize: 14, // Bumped up from 10
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: context.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalReps, (index) {
            final isCompleted = index < (currentRep - 1);
            final isCurrent = index == (currentRep - 1);

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: isCurrent ? 24 : 12,
              height: 12,
              decoration: BoxDecoration(
                color: isCompleted || isCurrent
                    ? accentColor
                    : context.textPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                // Add a subtle glow to the active rep to make it pop
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
            );
          }),
        ),
      ],
    );
  }
}
