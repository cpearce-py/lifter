import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';
import 'package:lifter/features/workouts/models/custom/workout_template.dart';
import 'package:lifter/features/workouts/models/intensity.dart';
import 'package:lifter/features/workouts/ui/wave_animator.dart';

/// Formats seconds as "~12 min" (or "45s" when under a minute).
String formatEstimate(int seconds) {
  if (seconds < 60) return '${seconds}s';
  return '~${(seconds / 60).round()} min';
}

/// One-line summary of a block, e.g. "3×2 · 7s/3s · 30→60% Max Lift".
String blockSummary(WorkoutBlock block) {
  final intensity = block.isRamped
      ? '${block.startPercentage}→${block.endPercentage}%'
      : '${block.startPercentage}%';
  final reference = block.relativeTo == RelativeTo.custom
      ? 'custom'
      : relativeToLabels[block.relativeTo];
  return '${block.sets}×${block.reps} · ${block.workSeconds}s/${block.restSeconds}s'
      ' · $intensity $reference';
}

/// Page shell shared by the builder screens: back link, title, a scrolling
/// list of cards, and a big action button at the bottom. Matches the
/// look of the workout config pages.
class BuilderScaffold extends StatelessWidget {
  const BuilderScaffold({
    super.key,
    required this.backLabel,
    required this.title,
    this.subtitle,
    required this.accentColor,
    required this.children,
    required this.buttonLabel,
    required this.onButtonTap,
    this.trailing,
  });

  final String backLabel;
  final String title;
  final String? subtitle;
  final Color accentColor;
  final List<Widget> children;
  final String buttonLabel;
  final VoidCallback? onButtonTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return WaveAnimator(
      builder: (context, waveItem) {
        return Scaffold(
          backgroundColor: context.background,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    MediaQuery.of(context).padding.top + 16,
                    24,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            // maybePop so pages can guard unsaved changes.
                            onTap: () => Navigator.maybePop(context),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.arrow_back_ios_rounded,
                                  size: 14,
                                  color: accentColor.withValues(alpha: 0.8),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  backLabel,
                                  style: context.cardTitle.copyWith(
                                    fontSize: 13,
                                    color: accentColor.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          ?trailing,
                        ],
                      ),
                      const SizedBox(height: 24),
                      waveItem(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title.toUpperCase(),
                              style: context.h1.copyWith(fontSize: 28),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: context.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    for (final child in children)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: waveItem(child),
                      ),
                  ]),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    14,
                    16,
                    MediaQuery.of(context).padding.bottom + 40,
                  ),
                  child: BigActionButton(
                    label: buttonLabel,
                    accentColor: accentColor,
                    onTap: onButtonTap,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class BigActionButton extends StatelessWidget {
  const BigActionButton({
    super.key,
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  final String label;
  final Color accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: enabled
          ? () {
              HapticFeedback.mediumImpact();
              onTap!();
            }
          : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1 : 0.4,
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: context.cardTitle.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: context.background,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BuilderTextField extends StatelessWidget {
  const BuilderTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLines: maxLines,
      minLines: 1,
      style: context.body,
      cursorColor: context.textPrimary,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: context.body.copyWith(
          color: context.textMuted.withValues(alpha: 0.6),
        ),
        filled: true,
        fillColor: context.inputBackground,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
