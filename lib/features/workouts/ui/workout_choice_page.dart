import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/features/workouts/engines/repeater_engine.dart';
import 'package:lifter/features/workouts/models/repeater_state.dart';
import 'package:lifter/features/workouts/sessions/repeater_workout_page.dart';

import 'package:lifter/core/models/workout_session.dart';
import 'package:lifter/core/ui/widgets/controls.dart';

class WorkoutPage extends ConsumerStatefulWidget {
  const WorkoutPage({super.key});

  @override
  ConsumerState<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends ConsumerState<WorkoutPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static final _workouts = [
    WorkoutType(
      name: 'Live Data',
      description: 'Real-time feed from your sensor',
      icon: Icons.sensors_rounded,
      accentColor: Color(0xFF47C8FF),
      options: [
        WorkoutOption(label: 'Units',           type: OptionType.segmented, choices: ['kg', 'lb', 'N']),
        WorkoutOption(label: 'Graph duration',  type: OptionType.stepper,   min: 10, max: 120, step: 10, unit: 's'),
        WorkoutOption(label: 'Show peak line',  type: OptionType.toggle),
        WorkoutOption(label: 'Auto-zero on start', type: OptionType.toggle),
      ],
      sessionBuilder: (values) {
        return const SizedBox.shrink();
      }
    ),
    WorkoutType(
      name: 'Repeaters',
      description: 'Timed hang sets with rest intervals',
      icon: Icons.repeat_rounded,
      accentColor: Color(0xFFE8FF47),
      options: [
        WorkoutOption(label: 'Sets',       type: OptionType.stepper, min: 1, max: 20, step: 1, unit: ''),
        WorkoutOption(label: 'Reps',       type: OptionType.stepper, min: 1, max: 20, step: 1, unit: ''),
        WorkoutOption(label: 'Work time',  type: OptionType.stepper, min: 3, max: 60, step: 1, unit: 's'),
        WorkoutOption(label: 'Rest time',  type: OptionType.stepper, min: 3, max: 120, step: 3, unit: 's'),
        WorkoutOption(label: 'Set rest',   type: OptionType.stepper, min: 10, max: 300, step: 10, unit: 's'),
        WorkoutOption(label: 'Target intensity', type: OptionType.segmented, choices: ['Max', '80%', '70%', 'Custom']),
      ],
      sessionBuilder: (values) {
        final workoutState = RepeaterState(
          sets:           (values[0] as num).toInt(),
          reps:           (values[1] as num).toInt(),
          workSeconds:    (values[2] as num).toInt(),
          restSeconds:    (values[3] as num).toInt(),
          setRestSeconds: (values[4] as num).toInt(),
        );
        return ProviderScope(
          overrides: [repeaterConfigProvider.overrideWithValue(workoutState)],
          child: const RepeaterWorkoutPage(),
        );
      }
      ),
    WorkoutType(
      name: 'Peak Load',
      description: 'Measure your maximum single effort',
      icon: Icons.arrow_upward_rounded,
      accentColor: Color(0xFFFF6B6B),
      options: [
        WorkoutOption(label: 'Attempts',          type: OptionType.stepper, min: 1, max: 10, step: 1, unit: ''),
        WorkoutOption(label: 'Rest between',      type: OptionType.stepper, min: 30, max: 300, step: 30, unit: 's'),
        WorkoutOption(label: 'Hold duration',     type: OptionType.stepper, min: 1, max: 10, step: 1, unit: 's'),
        WorkoutOption(label: 'Beep countdown',    type: OptionType.toggle),
        WorkoutOption(label: 'Auto-detect peak',  type: OptionType.toggle),
      ],
      sessionBuilder: (values) { 
        return const SizedBox.shrink();
      }
      // PeakLoadSessionPage(
      //   attempts:       (values[0] as num).toInt(),
      //   restSeconds:    (values[1] as num).toInt(),
      //   holdSeconds:    (values[2] as num).toInt(),
      //   beepCountdown:  values[3] as bool,
      // ),
    ),
    WorkoutType(
      name: 'Critical Force',
      description: 'Estimate your aerobic threshold',
      icon: Icons.show_chart_rounded,
      accentColor: Color(0xFFB47FFF),
      options: [
        WorkoutOption(label: 'Protocol',    type: OptionType.segmented, choices: ['7/3', '6/4', '10/5', 'Custom']),
        WorkoutOption(label: 'Total time',  type: OptionType.stepper, min: 5, max: 30, step: 5, unit: 'min'),
        WorkoutOption(label: 'Reps',        type: OptionType.stepper, min: 3, max: 20, step: 1, unit: ''),
        WorkoutOption(label: 'Show CF line', type: OptionType.toggle),
        WorkoutOption(label: 'Save result',  type: OptionType.toggle),
      ],
      sessionBuilder: (values) {
        // TODO: return CriticalForceSessionPage(...)
        return const SizedBox.shrink();
      }
    ),
    WorkoutType(
      name: 'Trainings',
      description: 'Follow a structured training plan',
      icon: Icons.calendar_today_rounded,
      accentColor: Color(0xFF47FF8A),
      options: [
        WorkoutOption(label: 'Plan',        type: OptionType.segmented, choices: ['Beginner', 'Intermediate', 'Advanced']),
        WorkoutOption(label: 'Duration',    type: OptionType.stepper, min: 15, max: 90, step: 15, unit: 'min'),
        WorkoutOption(label: 'Difficulty',  type: OptionType.segmented, choices: ['Easy', 'Medium', 'Hard']),
        WorkoutOption(label: 'Rest alerts', type: OptionType.toggle),
        WorkoutOption(label: 'Voice cues',  type: OptionType.toggle),
      ],
      sessionBuilder: (values) {
        // TODO: return CriticalForceSessionPage(...)
        return const SizedBox.shrink();
      }
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openWorkout(BuildContext context, WorkoutType workout) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => _WorkoutDetailPage(
          workout: workout,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: FadeSlide(
              animation: _controller,
              intervalStart: 0.0,
              intervalEnd: 0.5,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  MediaQuery.of(context).padding.top + 32,
                  24,
                  28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WORKOUTS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                        color: const Color(0xFFE8FF47).withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose a\nworkout type',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        height: 1.1,
                        color: Color(0xFFF0F0F0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Workout list ──────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final workout = _workouts[index];
                  return FadeSlide(
                    animation: _controller,
                    intervalStart: 0.1 + index * 0.08,
                    intervalEnd: 0.5 + index * 0.08,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _WorkoutCard(
                        workout: workout,
                        onTap: () => _openWorkout(context, workout),
                      ),
                    ),
                  );
                },
                childCount: _workouts.length,
              ),
            ),
          ),
        ],
      ),
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
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _press, curve: Curves.easeInOut),
    );
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
            color: const Color(0xFF111118),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: w.accentColor.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Icon badge
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

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      w.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFF0F0F0),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      w.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),

              // Option count chip + arrow
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(height: 8),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: w.accentColor.withOpacity(0.4),
                  ),
                ],
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
  const _WorkoutDetailPage({
    required this.workout,
  });

  final WorkoutType workout;

  @override
  ConsumerState<_WorkoutDetailPage> createState() => _WorkoutDetailPageState();
}

class _WorkoutDetailPageState extends ConsumerState<_WorkoutDetailPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Mutable state for each option: toggles (bool) and steppers (num) and
  // segmented selections (int index). Keyed by option index.
  late final Map<int, dynamic> _values;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    // Initialise default values for each option
    _values = {
      for (int i = 0; i < widget.workout.options.length; i++)
        i: _defaultValue(widget.workout.options[i]),
    };
  }

  dynamic _defaultValue(WorkoutOption opt) {
    switch (opt.type) {
      case OptionType.toggle:
        return false;
      case OptionType.stepper:
        return opt.min ?? 1;
      case OptionType.segmented:
        return 0;
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
    // Need to anchor the provider so we don't overwrite on transition
    // ref.watch(workoutNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
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
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_ios_rounded,
                            size: 14,
                            color: w.accentColor.withOpacity(0.8)),
                        const SizedBox(width: 4),
                        Text(
                          'Workouts',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: w.accentColor.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Icon + title
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: w.accentColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: w.accentColor.withOpacity(0.25)),
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
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                color: Color(0xFFF0F0F0),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              w.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.4),
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

          // ── Options ────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final opt = w.options[index];
                  return FadeSlide(
                    animation: _controller,
                    intervalStart: 0.1 + index * 0.08,
                    intervalEnd: 0.5 + index * 0.08,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _OptionRow(
                        option: opt,
                        accentColor: w.accentColor,
                        value: _values[index],
                        onChanged: (val) =>
                            setState(() => _values[index] = val),
                      ),
                    ),
                  );
                },
                childCount: w.options.length,
              ),
            ),
          ),

          // ── Start button ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: FadeSlide(
              animation: _controller,
              intervalStart: 0.5,
              intervalEnd: 1.0,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  MediaQuery.of(context).padding.bottom + 100,
                ),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => widget.workout.sessionBuilder(_values)
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
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          color: Color(0xFF0A0A0F),
                        ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF111118),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E1E2A), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            option.label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFFF0F0F0),
            ),
          ),
          const SizedBox(height: 12),

          // Control
          switch (option.type) {
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
          },
        ],
      ),
    );
  }
}
