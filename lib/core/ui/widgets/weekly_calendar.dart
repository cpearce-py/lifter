import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifter/features/history/ui/workout_theme_extension.dart';
import 'package:lifter/features/workouts/providers/weekly_provider.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';

class WeeklyCalendar extends ConsumerStatefulWidget {
  const WeeklyCalendar({super.key});

  @override
  ConsumerState<WeeklyCalendar> createState() => _WeeklyCalendarState();
}

class _WeeklyCalendarState extends ConsumerState<WeeklyCalendar> {
  // We use a high initial page so the user can swipe infinitely left (past) and right (future)
  static const int _initialPage = 10000;
  late final PageController _pageController;
  int _weekOffset = 0;

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

  void _jumpToToday() {
    HapticFeedback.selectionClick();
    _pageController.animateToPage(
      _initialPage,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  /// "October 2026", or "Sep – Oct 2026" for a week spanning two months.
  String _monthLabel(int weekOffset) {
    final monday = mondayForWeekOffset(weekOffset);
    final sunday = DateTime(monday.year, monday.month, monday.day + 6);

    if (monday.month == sunday.month) {
      return DateFormat('MMMM y').format(monday);
    }
    final start = DateFormat(monday.year == sunday.year ? 'MMM' : 'MMM y').format(monday);
    return '$start – ${DateFormat('MMM y').format(sunday)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.cardBorder, width: 1),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 28,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    _monthLabel(_weekOffset),
                    style: context.cardTitle.copyWith(fontSize: 13),
                  ),
                ),
                const Spacer(),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _weekOffset == 0 ? 0 : 1,
                  child: IgnorePointer(
                    ignoring: _weekOffset == 0,
                    child: GestureDetector(
                      onTap: _jumpToToday,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: context.textPrimary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Today',
                          style: context.cardTitle.copyWith(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // A PageView needs a constrained height. 82px fits a day plus its dots.
          SizedBox(
            height: 82,
            child: PageView.builder(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (page) =>
                  setState(() => _weekOffset = page - _initialPage),
              itemBuilder: (context, index) {
                // Calculate how many weeks away from "today" this page is
                return _WeekPage(weekOffset: index - _initialPage);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── The Individual Week Page ─────────────────────────────────────────────────

class _WeekPage extends ConsumerWidget {
  const _WeekPage({required this.weekOffset});

  final int weekOffset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = dateOnly(DateTime.now());
    final monday = mondayForWeekOffset(weekOffset);
    final weekDates = List.generate(
      7,
      (i) => DateTime(monday.year, monday.month, monday.day + i),
    );

    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final weekWorkouts = ref.watch(weekWorkoutsProvider(weekOffset)).value ?? const [];
    final selectedDay = ref.watch(selectedDayProvider);

    return Row(
      children: List.generate(7, (index) {
        final date = weekDates[index];

        // Newest first, one colour per workout type done that day.
        final dayWorkouts = weekWorkouts
            .where((w) => dateOnly(w.dateDone) == date)
            .toList();
        final typeColors = <Color>[];
        for (final w in dayWorkouts) {
          final color = w.uiAccentColor(context);
          if (!typeColors.contains(color)) typeColors.add(color);
        }

        final isFuture = date.isAfter(today);

        return Expanded(
          child: _DayItem(
            date: date,
            label: dayLabels[index],
            isToday: date == today,
            isSelected: date == selectedDay,
            typeColors: typeColors,
            onTap: isFuture
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    ref.read(selectedDayProvider.notifier).toggle(date);
                  },
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
    required this.isSelected,
    required this.typeColors,
    required this.onTap,
  });

  final DateTime date;
  final String label;
  final bool isToday;
  final bool isSelected;

  /// Accent colour of each workout type done that day, newest first.
  final List<Color> typeColors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasWorkout = typeColors.isNotEmpty;
    final todayColor = context.repeaterAccent;
    final ringColor = hasWorkout ? typeColors.first : Colors.transparent;

    final fill = isToday
        ? context.textPrimary.withValues(alpha: 0.08)
        : Colors.transparent;
    final textColor = isToday || hasWorkout || isSelected
        ? context.textPrimary
        : context.textMuted.withValues(alpha: onTap == null ? 0.5 : 1);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: context.overline.copyWith(
              fontSize: 10,
              letterSpacing: 1.0,
              color: isToday ? todayColor : context.textMuted,
            ),
          ),
          const SizedBox(height: 7),
          // Selection is a soft grey square behind the day's circle, so the
          // circle's ring and today tint still show through.
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? context.textPrimary.withValues(alpha: 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fill,
                border: Border.all(color: ringColor, width: 1.5),
              ),
              child: Center(
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isToday || hasWorkout || isSelected
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // One dot per type, only when a day mixes workout types.
          SizedBox(
            height: 5,
            child: typeColors.length > 1
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final color in typeColors.take(3))
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
