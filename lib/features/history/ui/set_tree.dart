import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:lifter/core/measurements/widgets/weight_text.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';
import 'package:lifter/features/history/models/log_models.dart';
import 'package:lifter/features/history/models/set_groups.dart';

/// A workout's sets as a tree: warm-up and working phases, then each block
/// (named once, with its grip), then its sets and reps. Blocks fold away so
/// long workouts stay readable.
class SetTree extends StatelessWidget {
  const SetTree({super.key, required this.sets, required this.accentColor});

  final List<SetLog> sets;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final phases = phaseSets(sets);
    // Only label the phases when there's more than one to tell apart.
    final showPhases = phases.length > 1;

    return _SmoothShrink(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final phase in phases) ...[
            if (showPhases)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  phase.isWarmup ? 'WARM-UP' : 'WORKING',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: phase.isWarmup ? context.warmupAccent : accentColor,
                  ),
                ),
              ),
            _Branch(
              show: showPhases,
              color: phase.isWarmup ? context.warmupAccent : accentColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final group in phase.groups)
                    _GroupCard(
                      group: group,
                      color: group.isWarmup
                          ? context.warmupAccent
                          : accentColor,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

/// A small tag showing a grip, e.g. "10mm · Half crimp".
class GripChip extends StatelessWidget {
  const GripChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Lets its child grow straight away but shrink slowly. When a block
/// folds, the space it used is held briefly and then eased away, so the
/// page shortens gradually and the scroll view glides with it instead of
/// snapping to stay in range.
class _SmoothShrink extends StatefulWidget {
  const _SmoothShrink({required this.child});

  final Widget child;

  @override
  State<_SmoothShrink> createState() => _SmoothShrinkState();
}

class _SmoothShrinkState extends State<_SmoothShrink>
    with SingleTickerProviderStateMixin {
  late final _release = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  @override
  void dispose() {
    _release.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _SmoothShrinkBox(release: _release, child: widget.child);
}

class _SmoothShrinkBox extends SingleChildRenderObjectWidget {
  const _SmoothShrinkBox({required this.release, required super.child});

  final AnimationController release;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSmoothShrink(release);
}

class _RenderSmoothShrink extends RenderProxyBox {
  _RenderSmoothShrink(this._release);

  final AnimationController _release;
  static const _curve = Curves.easeInOutCubic;

  /// The height currently shown, never less than the child's.
  double _shown = 0;

  /// Where the current release started, and the child height it heads to.
  double _from = 0;
  double _target = 0;
  bool _releaseScheduled = false;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _release.addListener(markNeedsLayout);
  }

  @override
  void detach() {
    _release.removeListener(markNeedsLayout);
    super.detach();
  }

  @override
  void performLayout() {
    child!.layout(constraints, parentUsesSize: true);
    final childHeight = child!.size.height;

    if (childHeight >= _shown) {
      // Growing (or settled): follow the child exactly.
      _shown = childHeight;
      _target = childHeight;
      if (_release.isAnimating) _release.stop();
    } else if (childHeight < _target) {
      // Shrunk further than we were heading: ease down from where we are.
      // The animation can't start mid-layout, so it waits for the frame
      // to end, holding the current height until then.
      _from = _shown;
      _target = childHeight;
      if (!_releaseScheduled) {
        _releaseScheduled = true;
        SchedulerBinding.instance.addPostFrameCallback((_) {
          _releaseScheduled = false;
          if (attached) _release.forward(from: 0);
        });
      }
    } else if (_release.isAnimating || _release.isCompleted) {
      _target = childHeight;
      final t = _curve.transform(_release.value);
      _shown = _from + (_target - _from) * t;
    }

    size = constraints.constrain(Size(child!.size.width, _shown));
  }
}

/// Indents [child] behind a thin line, the "branch" of the tree.
class _Branch extends StatelessWidget {
  const _Branch({required this.child, required this.color, this.show = true});

  final Widget child;
  final Color color;
  final bool show;

  @override
  Widget build(BuildContext context) {
    if (!show) return child;
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: color.withValues(alpha: 0.3), width: 2),
        ),
      ),
      child: child,
    );
  }
}

class _GroupCard extends StatefulWidget {
  const _GroupCard({required this.group, required this.color});

  final SetGroup group;
  final Color color;

  @override
  State<_GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<_GroupCard> {
  // Warm-ups are usually the least interesting, so start them folded.
  late bool _expanded = !widget.group.isWarmup;

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final color = widget.color;
    final best = group.best;

    final title = group.name ?? (group.grip.isSet ? group.grip.label : 'Sets');
    final setCount = group.sets.length;
    // Without a block name the grip is already the title.
    final showGrip = group.name != null && group.grip.isSet;
    final details = [
      '$setCount ${setCount == 1 ? 'set' : 'sets'}',
      if (group.repCount != setCount) '${group.repCount} reps',
    ].join(' · ');

    final weightStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: context.textPrimary,
    );

    return Card(
      color: context.cardBackground,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: color,
                            letterSpacing: 1.2,
                          ),
                        ),
                        if (showGrip) ...[
                          const SizedBox(height: 6),
                          GripChip(label: group.grip.label, color: color),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          details,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'BEST',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: context.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          WeightText(
                            prefix: 'L ',
                            weightKg: best.left,
                            style: weightStyle,
                          ),
                          const SizedBox(width: 8),
                          WeightText(
                            prefix: 'R ',
                            weightKg: best.right,
                            style: weightStyle,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: context.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _Branch(
                      color: color,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < group.sets.length; i++)
                            _SetRows(
                              number: i + 1,
                              set: group.sets[i],
                              color: color,
                            ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// One set. A single-rep set (a max hang, a Peak Load attempt) fits on one
/// line; otherwise its reps branch off underneath.
class _SetRows extends StatelessWidget {
  const _SetRows({
    required this.number,
    required this.set,
    required this.color,
  });

  final int number;
  final SetLog set;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final reps = set.repetitions;
    final label = TextStyle(
      fontWeight: FontWeight.w700,
      color: context.textPrimary,
    );

    if (reps.length == 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: _LoadRow(
          label: Text('Set $number', style: label),
          rep: reps.single,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Set $number', style: label),
          const SizedBox(height: 6),
          _Branch(
            color: color,
            child: Column(
              children: [
                for (var r = 0; r < reps.length; r++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: _LoadRow(
                      label: Text(
                        'Rep ${r + 1}',
                        style: TextStyle(color: context.textMuted),
                      ),
                      rep: reps[r],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadRow extends StatelessWidget {
  const _LoadRow({required this.label, required this.rep});

  final Widget label;
  final RepetitionLog rep;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: context.textPrimary,
      fontWeight: FontWeight.w600,
    );
    return Row(
      children: [
        label,
        const SizedBox(width: 12),
        // Shrinks rather than overflows on narrow screens.
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Row(
              children: [
                WeightText(
                  prefix: 'L: ',
                  weightKg: rep.peakLoadLeft,
                  style: style,
                ),
                const SizedBox(width: 16),
                WeightText(
                  prefix: 'R: ',
                  weightKg: rep.peakLoadRight,
                  style: style,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
