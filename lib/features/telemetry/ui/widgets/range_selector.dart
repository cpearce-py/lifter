import 'package:flutter/material.dart';

import 'package:lifter/core/ui/themes/app_theme.dart';
import 'package:lifter/features/telemetry/ui/helpers.dart';

/// The row of timeframe chips under each Progression chart.
class RangeSelector extends StatelessWidget {
  const RangeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final TimeRange selected;
  final ValueChanged<TimeRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final range in TimeRange.values)
          GestureDetector(
            onTap: () => onChanged(range),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: range == selected
                    ? context.textPrimary.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                range.label,
                style: context.body.copyWith(
                  color: range == selected
                      ? context.textPrimary
                      : context.textMuted,
                  fontWeight: range == selected
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
