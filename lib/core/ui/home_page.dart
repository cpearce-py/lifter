import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifter/core/measurements/unit_converter.dart';
import 'package:lifter/core/providers/history_provider.dart';
import 'package:lifter/core/providers/stats_provider.dart';
import 'package:lifter/core/providers/user_provider.dart';
import 'package:lifter/core/ui/main_shell.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';
import 'package:lifter/core/ui/widgets/controls.dart';
import 'package:lifter/core/ui/widgets/weekly_calendar.dart';
import 'package:lifter/features/history/models/log_models.dart';
import 'package:lifter/features/history/ui/manual_workout_page.dart';
import 'package:lifter/features/user/providers/user_settings_provider.dart';
import 'package:lifter/features/workouts/providers/weekly_provider.dart';
import 'package:lifter/features/workouts/ui/widgets/workout_card.dart';

// ─── Layout ───────────────────────────────────────────────────────────────────
// One set of numbers for the whole page, so every section lines up.

/// Side margin for cards (calendar, workouts, stats). Matches the calendar.
const double _cardInset = 0;

/// Side margin for text outside cards (greeting, section labels, empty states).
const double _textInset = 24;

/// Space above each section label, separating it from the section before.
const double _sectionGap = 28;

/// Space between a section label and its content.
const double _labelGap = 12;

/// Space between cards within a section.
const double _cardGap = 10;

// ─── Data models ──────────────────────────────────────────────────────────────

class _StatData {
  const _StatData({
    required this.value,
    required this.unit,
    required this.label,
    required this.icon,
    required this.accentColor,
  });

  final String value;
  final String unit;
  final String label;
  final IconData icon;
  final Color accentColor;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String month = DateFormat("MMMM").format(DateTime.now());

    return Scaffold(
      backgroundColor: context.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          HomeHeaderSliver(animation: _controller),
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: _cardInset),
            sliver: SliverToBoxAdapter(child: WeeklyCalendar()),
          ),
          // Workouts sit straight under the calendar so tapping a day
          // visibly changes what's below it.
          RecentWorkoutsSliver(animation: _controller),
          SectionLabelSliver(text: '$month at a glance'),
          StatsGridSliver(animation: _controller),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class HomeHeaderSliver extends ConsumerWidget {
  final AnimationController animation;
  const HomeHeaderSliver({super.key, required this.animation});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider).value;
    final username = userProfile?.username ?? "Lifter";
    final initial = username.isNotEmpty ? username[0].toUpperCase() : "L";

    return SliverToBoxAdapter(
      child: FadeSlide(
        animation: animation,
        intervalStart: 0.0,
        intervalEnd: 0.5,
        child: Container(
          padding: EdgeInsets.fromLTRB(
            _textInset,
            MediaQuery.of(context).padding.top + 32,
            _textInset,
            _sectionGap,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: context.body.copyWith(
                        fontSize: 13,
                        color: context.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(username, style: context.h1),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.repeaterAccent.withValues(alpha: 0.12),
                  border: Border.all(
                    color: context.repeaterAccent.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: GestureDetector(
                onTap: () {
                  ref.read(mainTabProvider.notifier).state = 3;
                  },
                  child: Center(
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: context.repeaterAccent,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionLabelSliver extends StatelessWidget {
  final String text;
  const SectionLabelSliver({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(child: SectionLabel(text: text));
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionLabel({super.key, required this.text, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _textInset,
        _sectionGap,
        _textInset,
        _labelGap,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: context.overline.copyWith(letterSpacing: 2.5),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Recent workouts, or the workouts from the day picked on the calendar.
class RecentWorkoutsSliver extends ConsumerStatefulWidget {
  final AnimationController animation;
  const RecentWorkoutsSliver({super.key, required this.animation});

  @override
  ConsumerState<RecentWorkoutsSliver> createState() =>
      _RecentWorkoutsSliverState();
}

class _RecentWorkoutsSliverState extends ConsumerState<RecentWorkoutsSliver> {
  // What's currently on screen. While the next day loads we keep showing
  // this instead of a spinner, so the section (and everything under it)
  // doesn't collapse and jump back.
  List<WorkoutLog>? _shownWorkouts;
  DateTime? _shownDay;

  @override
  Widget build(BuildContext context) {
    final selectedDay = ref.watch(selectedDayProvider);

    final AsyncValue<List<WorkoutLog>> workoutsAsync = selectedDay == null
        ? ref
            .watch(workoutHistoryProvider)
            .whenData((page) => page.workouts.take(3).toList())
        : ref.watch(dayWorkoutsProvider(selectedDay));

    // Only record data that has finished loading. While reloading, or after
    // a failed reload, Riverpod still hands back the *previous* data, which
    // may come from a database that no longer exists (e.g. after a nuke).
    // Fields rather than setState: this only records what this build shows.
    final isFresh = workoutsAsync.hasValue &&
        !workoutsAsync.isLoading &&
        !workoutsAsync.hasError;
    if (isFresh) {
      _shownWorkouts = workoutsAsync.value;
      _shownDay = selectedDay;
    }

    if (workoutsAsync.hasError) {
      return SliverToBoxAdapter(
        child: Center(child: Text('Error: ${workoutsAsync.error}')),
      );
    }

    final workouts = _shownWorkouts;
    if (workouts == null) {
      // First load, nothing to keep on screen yet.
      return const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Heading follows the cards, so the two always change together.
          _heading(_shownDay),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topCenter,
                children: [...previous, ?current],
              ),
              child: KeyedSubtree(
                key: ValueKey(_shownDay),
                child: _workoutList(workouts, _shownDay),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heading(DateTime? day) {
    if (day == null) return const SectionLabel(text: 'Recent workouts');

    return SectionLabel(
      text: _dayLabel(day),
      trailing: GestureDetector(
        onTap: () => ref.read(selectedDayProvider.notifier).clear(),
        child: Row(
          children: [
            Text(
              'SHOW RECENT',
              style: context.overline.copyWith(letterSpacing: 1.5),
            ),
            const SizedBox(width: 2),
            Icon(Icons.close_rounded, size: 14, color: context.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _workoutList(List<WorkoutLog> workouts, DateTime? day) {
    if (workouts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: _textInset, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              day == null ? "No workouts yet." : "Rest day. No workouts logged.",
              style: TextStyle(color: context.textMuted),
            ),
            if (day != null) _logForDayButton(day),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _cardInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (index, workout) in workouts.indexed)
            FadeSlide(
              animation: widget.animation,
              intervalStart: 0.1 + index * 0.08,
              intervalEnd: 0.5 + index * 0.08,
              child: Padding(
                // Gap between cards only, so the next section's spacing
                // isn't padded out by the last card.
                padding: EdgeInsets.only(top: index == 0 ? 0 : _cardGap),
                child: WorkoutCard(workout: workout),
              ),
            ),
          if (day != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _textInset),
              child: _logForDayButton(day),
            ),
        ],
      ),
    );
  }

  /// For a workout done that day without the app.
  Widget _logForDayButton(DateTime day) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        foregroundColor: context.textMuted,
      ),
      onPressed: () => Navigator.of(context, rootNavigator: true).push(
        CupertinoPageRoute(builder: (_) => ManualWorkoutPage(initialDate: day)),
      ),
      icon: const Icon(Icons.add_rounded, size: 18),
      label: const Text('Log a workout for this day'),
    );
  }

  /// "Today", "Yesterday", or e.g. "Tue 7 Oct".
  String _dayLabel(DateTime day) {
    final today = dateOnly(DateTime.now());
    final difference = today.difference(day).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return DateFormat('EEE d MMM').format(day);
  }
}

class StatsGridSliver extends ConsumerWidget {
  final AnimationController animation;
  const StatsGridSliver({super.key, required this.animation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider);
    final useLbs = ref.watch(userSettingsProvider.select((s) => s.useLbs));
    String weight(double kg) =>
        (useLbs ? kgToLbs(kg) : kg).toStringAsFixed(1);

    return statsAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Center(child: Text('Error loading stats: $e')),
      ),
      data: (stats) {
        final statCardsData = [
          _StatData(
            value: stats.hoursThisMonth.toStringAsFixed(1), // E.g., "14.5"
            unit: 'hrs',
            label: 'Worked out\nthis month',
            icon: Icons.timer_rounded,
            accentColor: context.peakLoadAccent,
          ),
          _StatData(
            value: stats.totalWorkouts.toString(),
            unit: 'sessions',
            label: 'Workouts\ncompleted',
            icon: Icons.fitness_center_rounded,
            accentColor: context.repeaterAccent,
          ),
          _StatData(
            value: stats.weekStreak.toString(),
            unit: stats.weekStreak == 1 ? 'week' : 'weeks',
            label: 'Streak of\n$streakSessionsPerWeek+ sessions/week',
            icon: Icons.local_fire_department_rounded,
            accentColor: context.streakAccent,
          ),
          _maxPullStat(context, stats, weight, useLbs ? 'lbs' : 'kg'),
        ];

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: _cardInset),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate((context, index) {
              return FadeSlide(
                animation: animation,
                intervalStart: 0.35 + index * 0.08,
                intervalEnd: 0.75 + index * 0.08,
                child: _StatCard(data: statCardsData[index]),
              );
            }, childCount: statCardsData.length),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: _cardGap,
              mainAxisSpacing: _cardGap,
              childAspectRatio: 1.05,
            ),
          ),
        );
      },
    );
  }
}

/// Best single pull, with each hand's best underneath.
_StatData _maxPullStat(
  BuildContext context,
  UserStats stats,
  String Function(double kg) weight,
  String unit,
) {
  final best = stats.maxPullLeft > stats.maxPullRight
      ? stats.maxPullLeft
      : stats.maxPullRight;

  return _StatData(
    value: best > 0 ? weight(best) : '–',
    unit: best > 0 ? unit : '',
    label: best > 0
        ? 'Max pull\nL ${weight(stats.maxPullLeft)} · R ${weight(stats.maxPullRight)}'
        : 'Max pull\nDo a Peak Load test',
    icon: Icons.arrow_upward_rounded,
    accentColor: context.setRestAccent,
  );
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});
  final _StatData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: data.accentColor.withValues(alpha: 0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon badge
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: data.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: data.accentColor, size: 20),
          ),

          // Value + label
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    data.value,
                    style: context.h1.copyWith(
                      fontSize: 28,
                      color: data.accentColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      data.unit,
                      style: context.cardTitle.copyWith(
                        fontSize: 12,
                        color: data.accentColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                data.label,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.4,
                  color: context.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
