
import 'package:flutter/material.dart';

class ToggleControl extends StatelessWidget {
  const ToggleControl({
      super.key,
      required this.value,
      required this.accentColor,
      required this.onChanged});

  final bool value;
  final Color accentColor;
  final ValueChanged<dynamic> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: () => onChanged(!value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 50,
            height: 28,
            decoration: BoxDecoration(
              color: value ? accentColor : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment:
                  value ? Alignment.centerRight : Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: value ? const Color(0xFF0A0A0F) : Colors.white38,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class StepperControl extends StatelessWidget {
  const StepperControl({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.unit,
    required this.accentColor,
    required this.onChanged,
  });

  final double value;
  final double min;
  final double max;
  final double step;
  final String unit;
  final Color accentColor;
  final ValueChanged<dynamic> onChanged;

  @override
  Widget build(BuildContext context) {
    final atMin = value <= min;
    final atMax = value >= max;

    return Row(
      children: [
        // Decrement
        StepButton(
          icon: Icons.remove_rounded,
          enabled: !atMin,
          accentColor: accentColor,
          onTap: atMin ? null : () => onChanged(value - step),
        ),
        const SizedBox(width: 16),

        // Value display
        Expanded(
          child: Center(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: _formatted(value),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                    ),
                  ),
                  if (unit.isNotEmpty)
                    TextSpan(
                      text: ' $unit',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: accentColor.withOpacity(0.55),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Increment
        StepButton(
          icon: Icons.add_rounded,
          enabled: !atMax,
          accentColor: accentColor,
          onTap: atMax ? null : () => onChanged(value + step),
        ),
      ],
    );
  }

  String _formatted(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toString();
}

class StepButton extends StatelessWidget {
  const StepButton(
      {
      super.key,
      required this.icon,
      required this.enabled,
      required this.accentColor,
      required this.onTap});

  final IconData icon;
  final bool enabled;
  final Color accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled
              ? accentColor.withOpacity(0.12)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled
                ? accentColor.withOpacity(0.3)
                : Colors.white.withOpacity(0.06),
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? accentColor : Colors.white24,
        ),
      ),
    );
  }
}
class SegmentedControl extends StatelessWidget {
  const SegmentedControl({
    super.key,
    required this.choices,
    required this.selectedIndex,
    required this.accentColor,
    required this.onChanged,
  });

  final List<String> choices;
  final int selectedIndex;
  final Color accentColor;
  final ValueChanged<dynamic> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(choices.length, (i) {
        final selected = i == selectedIndex;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < choices.length - 1 ? 6 : 0),
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 36,
                decoration: BoxDecoration(
                  color: selected
                      ? accentColor
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? accentColor
                        : Colors.white.withOpacity(0.08),
                  ),
                ),
                child: Center(
                  child: Text(
                    choices[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? const Color(0xFF0A0A0F)
                          : Colors.white.withOpacity(0.45),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
