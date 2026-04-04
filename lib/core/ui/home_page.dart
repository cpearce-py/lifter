import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifter/core/providers/history_provider.dart';
import 'package:lifter/core/providers/stats_provider.dart';
import 'package:lifter/core/providers/user_provider.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';
import 'package:lifter/core/ui/widgets/controls.dart';
import 'package:lifter/core/ui/widgets/weekly_calendar.dart';
import 'package:lifter/features/workouts/ui/widgets/workout_card.dart';

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
          SliverToBoxAdapter(child: const WeeklyCalendar()),
          SectionLabelSliver(text: '$month at a glance'),
          StatsGridSliver(animation: _controller),
          const SectionLabelSliver(text: 'Recent workouts'),
          RecentWorkoutsSliver(animation: _controller),
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
            24,
            MediaQuery.of(context).padding.top + 32,
            24,
            28,
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
                    Text(
                      username,
                      style: context.h1,
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.repeaterAccent.withOpacity(0.12),
                  border: Border.all(
                    color: context.repeaterAccent.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
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
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
        child: Text(
          text.toUpperCase(),
          style: context.overline.copyWith(letterSpacing: 2.5),
        ),
      ),
    );
  }
}

class RecentWorkoutsSliver extends ConsumerWidget {
  final AnimationController animation;
  const RecentWorkoutsSliver({super.key, required this.animation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(workoutHistoryProvider);

    return historyAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) =>
          SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
      data: (pagination) {
        final recentWorkouts = pagination.workouts.take(3).toList();

        if (recentWorkouts.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Text(
                "No workouts yet.",
                style: TextStyle(color: context.textMuted),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return FadeSlide(
                animation: animation,
                intervalStart: 0.35 + index * 0.08,
                intervalEnd: 0.75 + index * 0.08,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: WorkoutCard(
                    workout: recentWorkouts[index],
                  ), 
                ),
              );
            }, childCount: recentWorkouts.length),
          ),
        );
      },
    );
  }
}

class StatsGridSliver extends ConsumerWidget {
  final AnimationController animation;
  const StatsGridSliver({super.key, required this.animation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider);

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
            value: stats.currentStreak.toString(),
            unit: 'day streak',
            label: 'Current\nstreak',
            icon: Icons.local_fire_department_rounded,
            accentColor: context.streakAccent,
          ),
        ];

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate((context, index) {
              return FadeSlide(
                animation: animation,
                intervalStart: 0.1 + index * 0.08,
                intervalEnd: 0.5 + index * 0.08,
                child: _StatCard(data: statCardsData[index]),
              );
            }, childCount: statCardsData.length),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.05,
            ),
          ),
        );
      },
    );
  }
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
        border: Border.all(color: data.accentColor.withOpacity(0.15), width: 1),
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
              color: data.accentColor.withOpacity(0.1),
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
