
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lifter/core/ui/themes/app_theme.dart';

class ToggleControl extends StatelessWidget {
  const ToggleControl({
      super.key,
      required this.value,
      required this.accentColor,
      required this.onChanged});

  final bool value;
  final Color accentColor;
  final ValueChanged<bool> onChanged;

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
              color: value ? accentColor : context.textMuted.withValues(alpha: 0.3),
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
                    color: value ? context.background : context.textPrimary.withValues(alpha: 0.38),
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
  final ValueChanged<double> onChanged;

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
                    style: context.h1.copyWith(
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
                        color: context.textMuted,
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
              ? accentColor.withValues(alpha: .12)
              : context.textPrimary.withValues(alpha: .04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled
                ? accentColor.withValues(alpha: .3)
                : context.textPrimary.withValues(alpha: .06),
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? accentColor : context.textPrimary.withValues(alpha: 0.24),
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
  final ValueChanged<int> onChanged;

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
                      : context.textPrimary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? accentColor
                        : context.textPrimary.withValues(alpha: 0.08),
                  ),
                ),
                child: Center(
                  child: Text(
                    choices[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? context.background
                          : context.textMuted,
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


class ScrollableControl extends StatefulWidget {
  final int initialPercentage;
  final Color accentColor;
  final ValueChanged<int> onChanged;

  const ScrollableControl({
    super.key,
    this.initialPercentage = 100,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  State<ScrollableControl> createState() => _ScrollableControlState();
}

class _ScrollableControlState extends State<ScrollableControl> {
  late PageController _controller;
  late int _selectedIndex;
  
  // Generates [100, 95, 90, 85 ... 5]
  final List<int> _percentages = List.generate(20, (i) => 100 - (i * 5)); 

  @override
  void initState() {
    super.initState();
    // Find the starting index based on the initial value
    _selectedIndex = _percentages.indexOf(widget.initialPercentage);
    if (_selectedIndex == -1) _selectedIndex = 0; // Fallback to MAX

    _controller = PageController(
      // A fraction of 0.33 means 3 items are visible vertically at once
      viewportFraction: 0.33, 
      initialPage: _selectedIndex,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleIndexChanged(int index) {
    if (index == _selectedIndex) return;
    
    HapticFeedback.selectionClick(); 
    setState(() => _selectedIndex = index);
    widget.onChanged(_percentages[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,  // Fixed width for the vertical tumbler
      height: 120, // Taller height to see numbers above and below
      decoration: BoxDecoration(
        color: context.textPrimary.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.textPrimary.withValues(alpha: 0.05)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. The Center Highlight "Lens"
          Container(
            width: 68, // slightly smaller than parent width
            height: 38,
            decoration: BoxDecoration(
              color: widget.accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: widget.accentColor.withValues(alpha: 0.3)),
            ),
          ),

          // 2. The Scrolling Numbers
          PageView.builder(
            scrollDirection: Axis.vertical, // Flips the scrolling physics to vertical!
            controller: _controller,
            onPageChanged: _handleIndexChanged,
            itemCount: _percentages.length,
            clipBehavior: Clip.hardEdge, 
            itemBuilder: (context, index) {
              final percentage = _percentages[index];
              final isSelected = index == _selectedIndex;

              return GestureDetector(
                onTap: () {
                  _controller.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                  );
                },
                child: Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 150),
                    style: TextStyle(
                      fontSize: isSelected ? 18 : 14,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                      color: isSelected 
                          ? widget.accentColor 
                          : context.textMuted.withValues(alpha: 0.5),
                    ),
                    child: Text(percentage == 100 ? "MAX" : "$percentage%"),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class DropdownControl extends StatelessWidget {
  final List<String> choices;
  final int selectedIndex;
  final Color accentColor;
  final ValueChanged<int> onChanged;

  const DropdownControl({
    super.key,
    required this.choices,
    required this.selectedIndex,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: context.textPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.textPrimary.withValues(alpha: 0.08)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedIndex,
          dropdownColor: context.cardBackground,
          borderRadius: BorderRadius.circular(12),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: context.textMuted,
            size: 20,
          ),
          alignment: AlignmentDirectional.centerEnd,
          items: List.generate(choices.length, (i) {
            final isSelected = i == selectedIndex;
            return DropdownMenuItem(
              value: i,
              child: Text(
                choices[i],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? accentColor : context.textPrimary,
                ),
              ),
            );
          }),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ),
    );
  }
}

// ─── FadeSlide ────────────────────────────────────────────────────────────────
// Wraps a child in a staggered fade + upward slide entrance animation.
//
// Usage:
//   FadeSlide(
//     animation: _controller,
//     intervalStart: 0.1,
//     intervalEnd: 0.5,
//     child: MyWidget(),
//   )
 
class FadeSlide extends StatelessWidget {
  const FadeSlide({
    super.key,
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
