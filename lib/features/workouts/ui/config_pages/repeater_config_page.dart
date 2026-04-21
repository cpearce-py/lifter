import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/measurements/widgets/weight_input.dart';
import 'package:lifter/core/ui/widgets/app_card.dart';
import 'package:lifter/core/ui/widgets/controls.dart';
import 'package:lifter/features/workouts/engines/repeater_engine.dart';
import 'package:lifter/features/workouts/models/base_models.dart';
import 'package:lifter/features/workouts/providers/repeater_config_provider.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';
import 'package:lifter/features/workouts/sessions/repeater_workout_page.dart';
import 'package:lifter/features/workouts/ui/wave_animator.dart';

class RepeaterSetupPage extends ConsumerWidget {
  const RepeaterSetupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(repeaterSetupProvider);
    final notifier = ref.read(repeaterSetupProvider.notifier);

    final accentColor = context.repeaterAccent;

    return WaveAnimator(
      builder: (context, waveItem) {
        return Scaffold(
          backgroundColor: context.background,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    MediaQuery.of(context).padding.top + 16,
                    24,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_back_ios_rounded,
                              size: 14,
                              color: accentColor.withOpacity(0.8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Workouts',
                              style: context.cardTitle.copyWith(
                                fontSize: 13,
                                color: accentColor.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      waveItem(
                        0,
                        Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "REPEATERS",
                              style: context.h1.copyWith(fontSize: 28),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Timed hang sets with rest intervals",
                              style: TextStyle(
                                fontSize: 13,
                                color: context.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // The Form Controls
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    waveItem(
                      1,
                      AppCard(
                        label: "Sets",
                        child: StepperControl(
                          value: config.sets.toDouble(),
                          min: 1,
                          max: 20,
                          step: 1,
                          unit: "",
                          accentColor: accentColor,
                          onChanged: notifier.updateSets,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    waveItem(
                      2,
                      AppCard(
                        label: "Reps",
                        child: StepperControl(
                          value: config.reps.toDouble(),
                          min: 1,
                          max: 20,
                          step: 1,
                          unit: "",
                          accentColor: accentColor,
                          onChanged: notifier.updateReps,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    waveItem(
                      3,
                      AppCard(
                        label: "Work time",
                        child: StepperControl(
                          value: config.workSeconds.toDouble(),
                          min: 3,
                          max: 60,
                          step: 1,
                          unit: "s",
                          accentColor: accentColor,
                          onChanged: notifier.updateWorkSeconds,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    waveItem(
                      4,
                      AppCard(
                        label: "Rest time",
                        child: StepperControl(
                          value: config.restSeconds.toDouble(),
                          min: 3,
                          max: 120,
                          step: 1,
                          unit: "s",
                          accentColor: accentColor,
                          onChanged: notifier.updateRestSeconds,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    waveItem(
                      5,
                      AppCard(
                        label: "Set rest",
                        child: StepperControl(
                          value: config.setRestSeconds.toDouble(),
                          min: 10,
                          max: 300,
                          step: 10,
                          unit: "s",
                          accentColor: accentColor,
                          onChanged: notifier.updateSetRestSeconds,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    waveItem(
                      6,
                      AppCard(
                        label: "Starting hand",
                        child: SegmentedControl(
                          choices: Hand.values.map((h) => h.label).toList(),
                          selectedIndex: config.startingHand.index,
                          accentColor: accentColor,
                          onChanged: (idx) =>
                              notifier.updateStartingHand(Hand.values[idx]),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 24,
                    ), // Extra spacing before the intensity group
                    // 3. Our Bespoke Intensity Group!
                    waveItem(
                      7,
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.cardBackground,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: context.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Target Intensity", style: context.cardTitle),
                            const SizedBox(height: 16),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Relative to", style: context.body),
                                DropdownControl(
                                  choices: const [
                                    'Bodyweight',
                                    'Max Lift',
                                    'Custom',
                                  ],
                                  selectedIndex: config.relativeTo,
                                  accentColor: accentColor,
                                  onChanged: (val) =>
                                      notifier.updateRelativeTo(val),
                                ),
                              ],
                            ),

                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Divider(
                                color: context.cardBorder,
                                height: 1,
                              ),
                            ),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Target", style: context.body),
                                ScrollableControl(
                                  initialPercentage: config.targetPercentage,
                                  accentColor: accentColor,
                                  onChanged: notifier.updateTargetPercentage,
                                ),
                              ],
                            ),

                            AnimatedSize(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              child: config.relativeTo == 2
                                  ? Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          child: Divider(
                                            color: context.cardBorder,
                                            height: 1,
                                          ),
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Custom Weight",
                                              style: context.body,
                                            ),
                                            WeightInput(
                                              weightKg: config.customWeight,
                                              accentColor: accentColor,
                                              onChangedKg:
                                                  notifier.updateCustomWeight,
                                            ),
                                          ],
                                        ),
                                      ],
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]),
                ),
              ),

              // Start Button
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    24,
                    16,
                    MediaQuery.of(context).padding.bottom + 40,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();

                      final activeState = notifier.buildActiveState();

                      Navigator.of(context, rootNavigator: true).push(
                        CupertinoPageRoute(
                          builder: (_) => ProviderScope(
                            overrides: [
                              repeaterConfigProvider.overrideWithValue(
                                activeState,
                              ),
                            ],
                            child: const RepeaterWorkoutPage(),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      height: 58,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Start Repeaters',
                          style: context.cardTitle.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: context.background,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
