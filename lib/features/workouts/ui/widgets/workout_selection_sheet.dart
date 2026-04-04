import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/measurements/widgets/weight_input.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';
import 'package:lifter/core/ui/widgets/app_card.dart';
import 'package:lifter/features/user/models/user_profile.dart';
import 'package:lifter/features/user/providers/user_settings_provider.dart';

import 'package:lifter/features/workouts/engines/peak_load_engine.dart';
import 'package:lifter/features/workouts/engines/repeater_engine.dart';
import 'package:lifter/features/workouts/models/base_models.dart';
import 'package:lifter/features/workouts/models/peak_load_state.dart';
import 'package:lifter/features/workouts/models/repeater_state.dart';
import 'package:lifter/features/workouts/sessions/peak_load_page.dart';
import 'package:lifter/features/workouts/sessions/repeater_workout_page.dart';
import 'package:lifter/core/models/workout_session.dart';
import 'package:lifter/core/ui/widgets/controls.dart';

class WorkoutSelectionSheet extends StatefulWidget {
  const WorkoutSelectionSheet({super.key});

  @override
  State<WorkoutSelectionSheet> createState() => _WorkoutSelectionSheetState();
}

class _WorkoutSelectionSheetState extends State<WorkoutSelectionSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  List<WorkoutType> _getWorkouts(BuildContext context) => [
    WorkoutType(
      name: 'Repeaters',
      description: 'Timed hang sets with rest intervals',
      icon: Icons.repeat_rounded,
      accentColor: context.repeaterAccent,
      options: [
        WorkoutOption(
          label: 'Sets',
          type: OptionType.stepper,
          min: 1,
          max: 20,
          step: 1,
          unit: '',
        ),
        WorkoutOption(
          label: 'Reps',
          type: OptionType.stepper,
          min: 1,
          max: 20,
          step: 1,
          unit: '',
        ),
        WorkoutOption(
          label: 'Work time',
          type: OptionType.stepper,
          min: 3,
          max: 60,
          step: 1,
          unit: 's',
        ),
        WorkoutOption(
          label: 'Rest time',
          type: OptionType.stepper,
          min: 3,
          max: 120,
          step: 3,
          unit: 's',
        ),
        WorkoutOption(
          label: 'Set rest',
          type: OptionType.stepper,
          min: 10,
          max: 300,
          step: 10,
          unit: 's',
        ),
        WorkoutOption(label: 'Starting hand', type: OptionType.handInput),
        WorkoutOption(
          label: 'Target intensity',
          type: OptionType.segmented,
          choices: ['Max', '80%', '70%', 'Custom'],
        ),
      ],
      sessionBuilder: (values) {
        final startingHand = values[5] as Hand;
        final workoutState = RepeaterState(
          sets: (values[0] as num).toInt(),
          reps: (values[1] as num).toInt(),
          workSeconds: (values[2] as num).toInt(),
          restSeconds: (values[3] as num).toInt(),
          setRestSeconds: (values[4] as num).toInt(),
          startingHand: startingHand,
          currentHand: startingHand,
        );
        return ProviderScope(
          overrides: [repeaterConfigProvider.overrideWithValue(workoutState)],
          child: const RepeaterWorkoutPage(),
        );
      },
    ),
    WorkoutType(
      name: 'Peak Load',
      description: 'Measure your maximum single effort',
      icon: Icons.arrow_upward_rounded,
      accentColor: context.peakLoadAccent,
      options: [
        WorkoutOption(label: 'Body weight', type: OptionType.weightInput),
        WorkoutOption(
          label: 'Rest time',
          type: OptionType.stepper,
          min: 120,
          max: 300,
          step: 30,
          unit: 's',
        ),
        WorkoutOption(label: 'Starting hand', type: OptionType.handInput),
      ],
      sessionBuilder: (values) {
        final bodyWeight = (values[0] as num).toDouble();
        final restSeconds = (values[1] as num).toInt();
        final startingHand = values[2] as Hand;
        final config = PeakLoadState(
          bodyWeight: bodyWeight,
          restSeconds: restSeconds,
          startingHand: startingHand,
          currentHand: startingHand,
        );
        return ProviderScope(
          overrides: [peakLoadConfigProvider.overrideWithValue(config)],
          child: const PeakLoadSessionPage(),
        );
      },
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  // 4. Clean up the controller
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openWorkout(BuildContext context, WorkoutType workout) {
    HapticFeedback.lightImpact();

    // Push using rootNavigator so it covers the bottom nav bar
    Navigator.of(context, rootNavigator: true).push(
      CupertinoPageRoute(builder: (_) => _WorkoutDetailPage(workout: workout)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workouts = _getWorkouts(context);

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: workouts.length,
      itemBuilder: (context, index) {
        final workout = workouts[index];
        return FadeSlide(
          animation: _controller,
          intervalStart: 0.1 + (index * 0.1),
          intervalEnd: 0.6 + (index * 0.1),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _WorkoutCard(
              workout: workout,
              onTap: () => _openWorkout(context, workout),
            ),
          ),
        );
      },
    );
  }
}

// ─── Workout Card ─────────────────────────────────────────────────────────────

class _WorkoutCard extends StatefulWidget {
  const _WorkoutCard({required this.workout, required this.onTap});

  final WorkoutType workout;
  final VoidCallback onTap;

  @override
  State<_WorkoutCard> createState() => _WorkoutCardState();
}

class _WorkoutCardState extends State<_WorkoutCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _press, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.workout;

    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) => _press.reverse(),
      onTapCancel: () => _press.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: w.accentColor.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: w.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(w.icon, color: w.accentColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      w.name,
                      style: context.body.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      w.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: w.accentColor.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Workout Detail Page ──────────────────────────────────────────────────────

class _WorkoutDetailPage extends ConsumerStatefulWidget {
  const _WorkoutDetailPage({required this.workout});

  final WorkoutType workout;

  @override
  ConsumerState<_WorkoutDetailPage> createState() => _WorkoutDetailPageState();
}

class _WorkoutDetailPageState extends ConsumerState<_WorkoutDetailPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  final Map<int, dynamic> _overrides = {};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  dynamic _getCurrentValue(
    int index,
    WorkoutOption opt,
    UserSettings settings,
  ) {
    if (_overrides.containsKey(index)) {
      return _overrides[index];
    }

    switch (opt.type) {
      case OptionType.toggle:
        return false;
      case OptionType.stepper:
        return opt.min ?? 1;
      case OptionType.segmented:
        return 0;
      case OptionType.weightInput:
        return settings.bodyWeight;
      case OptionType.handInput:
        return settings.preferredHand;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.workout;
    final settings = ref.watch(userSettingsProvider);

    return Scaffold(
      backgroundColor: context.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Container(
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
                          color: w.accentColor.withOpacity(0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Workouts',
                          style: context.cardTitle.copyWith(
                            fontSize: 13,
                            color: w.accentColor.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: w.accentColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: w.accentColor.withOpacity(0.25),
                          ),
                        ),
                        child: Icon(w.icon, color: w.accentColor, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              w.name,
                              style: context.h1.copyWith(
                                fontSize: 28,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              w.description,
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
                ],
              ),
            ),
          ),

          // Options Builder
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final opt = w.options[index];
                final defaultValue = _getCurrentValue(index, opt, settings);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _OptionRow(
                    option: opt,
                    accentColor: w.accentColor,
                    value: defaultValue,
                    // onChange we store new value in the overrides.
                    onChanged: (val) => setState(() => _overrides[index] = val),
                  ),
                );
              }, childCount: w.options.length),
            ),
          ),

          // Start Button
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.of(context).padding.bottom + 40,
              ),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  // Before starting, unpack the overrides to send to the workout.
                  final finalValues = {
                    for (int i = 0; i < w.options.length; i++)
                      i: _getCurrentValue(i, w.options[i], settings),
                  };
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          widget.workout.sessionBuilder(finalValues),
                    ),
                  );
                },
                child: Container(
                  height: 58,
                  decoration: BoxDecoration(
                    color: w.accentColor,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: w.accentColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Start ${w.name}',
                      style: context.cardTitle.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
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
  }
}

// ─── Option Row ───────────────────────────────────────────────────────────────

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.option,
    required this.accentColor,
    required this.value,
    required this.onChanged,
  });

  final WorkoutOption option;
  final Color accentColor;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      label: option.label,
      child: switch (option.type) {
        OptionType.toggle => ToggleControl(
          value: value as bool,
          accentColor: accentColor,
          onChanged: onChanged,
        ),
        OptionType.stepper => StepperControl(
          value: (value as num).toDouble(),
          min: option.min!.toDouble(),
          max: option.max!.toDouble(),
          step: option.step!.toDouble(),
          unit: option.unit ?? '',
          accentColor: accentColor,
          onChanged: onChanged,
        ),
        OptionType.segmented => SegmentedControl(
          choices: option.choices!,
          selectedIndex: value as int,
          accentColor: accentColor,
          onChanged: onChanged,
        ),
        OptionType.weightInput => WeightInput(
          weightKg: (value as num).toDouble(),
          onChangedKg: onChanged,
          accentColor: accentColor,
        ),
        OptionType.handInput => SegmentedControl(
          choices: Hand.values.map((h) => h.label).toList(),
          selectedIndex: (value as Hand).index,
          accentColor: accentColor,
          onChanged: (index) => onChanged(Hand.values[index]),
        ),
      },
    );
  }
}
