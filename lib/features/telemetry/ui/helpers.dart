import 'dart:math';

const fullDays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const fullMonths = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// The timeframes the Progression charts can be zoomed to. Each one splits
/// its span into x-axis buckets: days for [week], weeks for [month] and
/// months for the rest.
enum TimeRange {
  week('1W'),
  month('1M'),
  threeMonths('3M'),
  sixMonths('6M'),
  ytd('YTD'),
  year('1Y');

  const TimeRange(this.label);
  final String label;

  /// Index of the final bucket on the axis.
  int lastIndex(DateTime now) => switch (this) {
    week => 6,
    month => 3,
    threeMonths => 2,
    sixMonths => 5,
    ytd => now.month - 1,
    year => 11,
  };

  /// The chart's maxX. Never 0, so YTD in January still has a visible span.
  double maxX(DateTime now) => max(lastIndex(now), 1).toDouble();

  /// Index of the bucket [now] falls in. Buckets after it haven't happened yet.
  int currentIndex(DateTime now) => switch (this) {
    week => now.weekday - 1,
    month => _weekOfMonth(now.day),
    ytd => now.month - 1,
    _ => lastIndex(now),
  };

  /// The bucket [date] falls in, or null when it's outside this range.
  int? bucketOf(DateTime date, DateTime now) {
    final int index;
    switch (this) {
      case week:
        final start = _startOfWeek(now);
        final end = DateTime(start.year, start.month, start.day + 7);
        if (date.isBefore(start) || !date.isBefore(end)) return null;
        index = date.weekday - 1;
      case month:
        if (date.year != now.year || date.month != now.month) return null;
        index = _weekOfMonth(date.day);
      case ytd:
        if (date.year != now.year) return null;
        index = date.month - 1;
      case threeMonths || sixMonths || year:
        final monthsAgo = (now.year - date.year) * 12 + now.month - date.month;
        index = lastIndex(now) - monthsAgo;
    }
    return index >= 0 && index <= lastIndex(now) ? index : null;
  }

  /// Short x-axis label for bucket [index].
  String axisLabel(int index, DateTime now) {
    if (index < 0 || index > lastIndex(now)) return '';
    return switch (this) {
      week => fullDays[index][0],
      month => 'W${index + 1}',
      ytd =>
        now.month > 6
            ? fullMonths[index][0]
            : fullMonths[index].substring(0, 3),
      _ => _rollingMonthName(index, now)[0],
    };
  }

  /// Full tooltip label for bucket [index].
  String tooltipLabel(int index, DateTime now) {
    if (index < 0 || index > lastIndex(now)) return '';
    return switch (this) {
      week => fullDays[index],
      month => _weekOfMonthSpan(index, now),
      ytd => fullMonths[index],
      _ => _rollingMonthName(index, now),
    };
  }

  String _rollingMonthName(int index, DateTime now) {
    final month = DateTime(
      now.year,
      now.month - (lastIndex(now) - index),
    ).month;
    return fullMonths[month - 1];
  }

  /// Day span of a [month] bucket, e.g. "22–31 Oct". The last bucket takes
  /// the rest of the month, so it can be up to 10 days long.
  String _weekOfMonthSpan(int index, DateTime now) {
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final first = index * 7 + 1;
    final last = index == 3 ? daysInMonth : first + 6;
    return '$first–$last ${fullMonths[now.month - 1].substring(0, 3)}';
  }

  static int _weekOfMonth(int day) => min((day - 1) ~/ 7, 3);

  static DateTime _startOfWeek(DateTime now) =>
      DateTime(now.year, now.month, now.day - (now.weekday - 1));
}

/// A y-axis max with 15% headroom above [value], snapped up to a multiple of
/// [divisions] so each of the [divisions] grid steps is a whole number.
double niceMax(double value, int divisions) {
  if (value <= 0) return divisions.toDouble();
  return ((value * 1.15) / divisions).ceil() * divisions.toDouble();
}

double displayWeight(double weightInKg, bool useLbs) {
  return useLbs ? weightInKg * 2.20462 : weightInKg;
}

String weightUnit(bool useLbs) => useLbs ? 'lbs' : 'kg';
