import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/features/workouts/providers/weekly_provider.dart';

class WeeklyCalendar extends ConsumerStatefulWidget {
  const WeeklyCalendar({super.key});

  @override
  ConsumerState<WeeklyCalendar> createState() => _WeeklyCalendarState();
}

class _WeeklyCalendarState extends ConsumerState<WeeklyCalendar> {
  // We use a high initial page so the user can swipe infinitely left (past) and right (future)
  final int _initialPage = 10000;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF111118),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E1E2A), width: 1),
      ),
      // A PageView needs a constrained height. 70px perfectly fits our Day items.
      child: SizedBox(
        height: 70, 
        child: PageView.builder(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            // Calculate how many weeks away from "today" this page is
            final weekOffset = index - _initialPage;
            
            return _WeekPage(
              weekOffset: weekOffset,
              isSameDay: _isSameDay,
            );
          },
        ),
      ),
    );
  }
}

// ─── The Individual Week Page ─────────────────────────────────────────────────

class _WeekPage extends ConsumerWidget {
  const _WeekPage({
    required this.weekOffset,
    required this.isSameDay,
  });

  final int weekOffset;
  final bool Function(DateTime, DateTime) isSameDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const accent = Color(0xFFE8FF47);
    final now = DateTime.now();
    
    // Calculate the dates for THIS specific page's week
    final targetDate = now.add(Duration(days: weekOffset * 7));
    final currentWeekday = targetDate.weekday;
    final monday = targetDate.subtract(Duration(days: currentWeekday - 1));
    final weekDates = List.generate(7, (index) => monday.add(Duration(days: index)));
    
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final weekWorkoutsAsync = ref.watch(weekWorkoutsProvider(weekOffset));
    final completedWorkouts = weekWorkoutsAsync.value ?? <DateTime>[];

    return Row(
      children: List.generate(7, (index) {
        final date = weekDates[index];
        final label = dayLabels[index];
        
        final isToday = isSameDay(date, now);
        final hasWorkout = completedWorkouts.any((d) => isSameDay(d, date));

        return Expanded(
          child: _DayItem(
            date: date,
            label: label,
            isToday: isToday,
            hasWorkout: hasWorkout,
            accentColor: accent,
          ),
        );
      }),
    );
  }
}

class _DayItem extends StatelessWidget {
  const _DayItem({
    required this.date,
    required this.label,
    required this.isToday,
    required this.hasWorkout,
    required this.accentColor,
  });

  final DateTime date;
  final String label;
  final bool isToday;
  final bool hasWorkout;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: isToday ? accentColor : Colors.white.withOpacity(0.35),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isToday ? Colors.white.withOpacity(0.1) : Colors.transparent,
            border: hasWorkout
                ? Border.all(color: accentColor, width: 1.5)
                : Border.all(color: Colors.transparent, width: 1.5),
          ),
          child: Center(
            child: Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: isToday || hasWorkout ? FontWeight.bold : FontWeight.w500,
                color: isToday || hasWorkout 
                    ? Colors.white 
                    : Colors.white.withOpacity(0.6),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
