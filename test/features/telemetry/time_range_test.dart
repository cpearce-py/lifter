import 'package:flutter_test/flutter_test.dart';
import 'package:lifter/features/telemetry/ui/helpers.dart';

void main() {
  // Wednesday 15 October 2025, 18:00.
  final now = DateTime(2025, 10, 15, 18);

  group('TimeRange.week', () {
    test('includes a workout from earlier on Monday', () {
      expect(TimeRange.week.bucketOf(DateTime(2025, 10, 13, 7), now), 0);
    });

    test('includes a workout from earlier today on a Monday', () {
      final monday = DateTime(2025, 10, 13, 18);
      expect(TimeRange.week.bucketOf(DateTime(2025, 10, 13, 7), monday), 0);
    });

    test('excludes last Sunday and next Monday', () {
      expect(TimeRange.week.bucketOf(DateTime(2025, 10, 12, 23), now), isNull);
      expect(TimeRange.week.bucketOf(DateTime(2025, 10, 20), now), isNull);
    });

    test('current bucket is today', () {
      expect(TimeRange.week.currentIndex(now), 2);
    });
  });

  group('TimeRange.month', () {
    test('clamps days 29-31 into the last week', () {
      expect(TimeRange.month.bucketOf(DateTime(2025, 10, 31), now), 3);
    });

    test('excludes other months', () {
      expect(TimeRange.month.bucketOf(DateTime(2025, 9, 30), now), isNull);
    });

    test('tooltip spells out the last bucket to the end of the month', () {
      expect(TimeRange.month.tooltipLabel(3, now), '22–31 Oct');
      expect(TimeRange.month.tooltipLabel(0, now), '1–7 Oct');
    });
  });

  group('rolling month ranges', () {
    test('1Y covers November last year to this month', () {
      expect(TimeRange.year.bucketOf(DateTime(2024, 11, 1), now), 0);
      expect(TimeRange.year.bucketOf(DateTime(2024, 10, 31), now), isNull);
      expect(TimeRange.year.bucketOf(DateTime(2025, 10, 1), now), 11);
      expect(TimeRange.year.tooltipLabel(0, now), 'November');
    });

    test('3M labels wrap across the year boundary', () {
      final february = DateTime(2025, 2, 10);
      expect(TimeRange.threeMonths.tooltipLabel(0, february), 'December');
      expect(TimeRange.threeMonths.axisLabel(1, february), 'J');
    });
  });

  group('TimeRange.ytd', () {
    test('has a visible span in January', () {
      expect(TimeRange.ytd.maxX(DateTime(2025, 1, 5)), 1);
      expect(TimeRange.ytd.axisLabel(1, DateTime(2025, 1, 5)), '');
    });

    test('excludes last year', () {
      expect(TimeRange.ytd.bucketOf(DateTime(2024, 12, 31), now), isNull);
    });
  });

  test('niceMax snaps above the value with headroom', () {
    expect(niceMax(0, 3), 3);
    expect(niceMax(1, 3), 3);
    expect(niceMax(4, 3), 6);
    expect(niceMax(40, 4), 48);
  });
}
