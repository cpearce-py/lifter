import 'package:flutter/material.dart';
import 'package:lifter/ble/ble_service.dart';
import 'package:lifter/ble/widgets.dart';


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

class _WorkoutRow {
  const _WorkoutRow({
    required this.name,
    required this.duration,
    required this.daysAgo,
    required this.icon,
  });

  final String name;
  final String duration;
  final int daysAgo;
  final IconData icon;
}



class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.bleService});

  final BleService bleService;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // ── Dummy data — swap with real data source later ──────────────────────────
  static const _userName = 'Corin';
  static const _monthName = 'March';

  static const _stats = [
    _StatData(
      value: '14.5',
      unit: 'hrs',
      label: 'Worked out\nthis month',
      icon: Icons.timer_rounded,
      accentColor: Color(0xFFE8FF47),
    ),
    _StatData(
      value: '11',
      unit: 'sessions',
      label: 'Workouts\ncompleted',
      icon: Icons.fitness_center_rounded,
      accentColor: Color(0xFF47C8FF),
    ),
    _StatData(
      value: '8',
      unit: 'day streak',
      label: 'Current\nstreak',
      icon: Icons.local_fire_department_rounded,
      accentColor: Color(0xFFFF6B6B),
    ),
    _StatData(
      value: '24,810',
      unit: 'kcal',
      label: 'Calories\nburned',
      icon: Icons.bolt_rounded,
      accentColor: Color(0xFFB47FFF),
    ),
  ];

  static const _recentWorkouts = [
    _WorkoutRow(name: 'Upper Body Push',   duration: '52 min', daysAgo: 1, icon: Icons.accessibility_new_rounded),
    _WorkoutRow(name: 'Lower Body Day',    duration: '48 min', daysAgo: 2, icon: Icons.directions_run_rounded),
    _WorkoutRow(name: 'Pull & Core',       duration: '61 min', daysAgo: 4, icon: Icons.sports_gymnastics_rounded),
  ];
  // ──────────────────────────────────────────────────────────────────────────

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
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(),
          _buildBleBanner(),
          _buildSectionLabel('$_monthName at a glance'),
          _buildStatsGrid(),
          _buildSectionLabel('Recent workouts'),
          _buildRecentWorkouts(),
          // _buildMonthProgress(),
          // Bottom padding so last card clears the nav bar
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: _FadeSlide(
        animation: _controller,
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
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                        color: Colors.white.withOpacity(0.45),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userName,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        color: Color(0xFFF0F0F0),
                      ),
                    ),
                  ],
                ),
              ),
              // Avatar / initials badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE8FF47).withOpacity(0.12),
                  border: Border.all(
                    color: const Color(0xFFE8FF47).withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    _userName[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE8FF47),
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

  // ── Section label ──────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String text) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
            color: Colors.white.withOpacity(0.3),
          ),
        ),
      ),
    );
  }

  // ── Stats 2×2 grid ─────────────────────────────────────────────────────────

  Widget _buildStatsGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return _FadeSlide(
              animation: _controller,
              intervalStart: 0.1 + index * 0.08,
              intervalEnd:  0.5 + index * 0.08,
              child: _StatCard(data: _stats[index]),
            );
          },
          childCount: _stats.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.05,
        ),
      ),
    );
  }

  // ── Recent workouts list ───────────────────────────────────────────────────

  Widget _buildRecentWorkouts() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return _FadeSlide(
              animation: _controller,
              intervalStart: 0.35 + index * 0.08,
              intervalEnd:   0.75 + index * 0.08,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RecentWorkoutCard(data: _recentWorkouts[index]),
              ),
            );
          },
          childCount: _recentWorkouts.length,
        ),
      ),
    );
  }

  // ── BLE Banner ─────────────────────────────────────────────────────────────

  Widget _buildBleBanner() {
    return SliverToBoxAdapter(
      child: _FadeSlide(
        animation: _controller,
        intervalStart: 0.05,
        intervalEnd: 0.45,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: ListenableBuilder(
            listenable: widget.bleService,
            builder: (context, _) => BleBanner(service: widget.bleService),
          ),
        ),
      ),
    );
  }

  // ── Month progress bar ─────────────────────────────────────────────────────

  // Widget _buildMonthProgress() {
  //   final now = DateTime.now();
  //   final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
  //   final progress = now.day / daysInMonth;

  //   return SliverToBoxAdapter(
  //     child: _FadeSlide(
  //       animation: _controller,
  //       intervalStart: 0.6,
  //       intervalEnd: 1.0,
  //       child: Padding(
  //         padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
  //         child: Container(
  //           padding: const EdgeInsets.all(20),
  //           decoration: BoxDecoration(
  //             color: const Color(0xFF111118),
  //             borderRadius: BorderRadius.circular(20),
  //             border: Border.all(color: const Color(0xFF1E1E2A), width: 1),
  //           ),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                 children: [
  //                   const Text(
  //                     'Month progress',
  //                     style: TextStyle(
  //                       fontSize: 14,
  //                       fontWeight: FontWeight.w700,
  //                       color: Color(0xFFF0F0F0),
  //                     ),
  //                   ),
  //                   Text(
  //                     'Day ${now.day} of $daysInMonth',
  //                     style: TextStyle(
  //                       fontSize: 12,
  //                       color: Colors.white.withOpacity(0.4),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               const SizedBox(height: 14),
  //               ClipRRect(
  //                 borderRadius: BorderRadius.circular(8),
  //                 child: TweenAnimationBuilder<double>(
  //                   tween: Tween(begin: 0, end: progress),
  //                   duration: const Duration(milliseconds: 1200),
  //                   curve: Curves.easeOutCubic,
  //                   builder: (context, value, _) {
  //                     return LinearProgressIndicator(
  //                       value: value,
  //                       minHeight: 8,
  //                       backgroundColor: Colors.white.withOpacity(0.07),
  //                       valueColor: const AlwaysStoppedAnimation(Color(0xFFE8FF47)),
  //                     );
  //                   },
  //                 ),
  //               ),
  //               const SizedBox(height: 10),
  //               Text(
  //                 '${(progress * 100).round()}% of the month done — keep the momentum!',
  //                 style: TextStyle(
  //                   fontSize: 12,
  //                   color: Colors.white.withOpacity(0.35),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
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
        color: const Color(0xFF111118),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: data.accentColor.withOpacity(0.15),
          width: 1,
        ),
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
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: data.accentColor,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      data.unit,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: data.accentColor.withOpacity(0.6),
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
                  color: Colors.white.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Recent Workout Card ──────────────────────────────────────────────────────

class _RecentWorkoutCard extends StatelessWidget {
  const _RecentWorkoutCard({required this.data});
  final _WorkoutRow data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF111118),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E1E2A), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE8FF47).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon,
                color: const Color(0xFFE8FF47).withOpacity(0.7), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF0F0F0),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.duration,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.35),
                  ),
                ),
              ],
            ),
          ),
          Text(
            data.daysAgo == 1 ? 'Yesterday' : '${data.daysAgo}d ago',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.25),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Fade + Slide entrance animation helper ───────────────────────────────────

class _FadeSlide extends StatelessWidget {
  const _FadeSlide({
    required this.animation,
    required this.intervalStart,
    required this.intervalEnd,
    required this.child,
  });

  final AnimationController animation;
  final double intervalStart;
  final double intervalEnd;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(
        intervalStart.clamp(0.0, 1.0),
        intervalEnd.clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) => Opacity(
        opacity: curved.value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - curved.value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
