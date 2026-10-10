import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifter/core/ui/themes/app_theme.dart';
import 'package:lifter/core/models/workout_session.dart';
import 'package:lifter/core/ui/widgets/controls.dart';
import 'package:lifter/features/workouts/models/custom/workout_template.dart';
import 'package:lifter/features/workouts/providers/templates_provider.dart';
import 'package:lifter/features/workouts/ui/builder/builder_widgets.dart';
import 'package:lifter/features/workouts/ui/builder/template_editor_page.dart';
import 'package:lifter/features/workouts/ui/builder/template_overview_page.dart';
import 'package:lifter/features/workouts/sessions/live_graph_page.dart';
import 'package:lifter/features/workouts/ui/config_pages/peak_load_config_page.dart';
import 'package:lifter/features/workouts/ui/config_pages/repeater_config_page.dart';

class WorkoutSelectionSheet extends ConsumerStatefulWidget {
  const WorkoutSelectionSheet({super.key});

  @override
  ConsumerState<WorkoutSelectionSheet> createState() =>
      _WorkoutSelectionSheetState();
}

class _WorkoutSelectionSheetState extends ConsumerState<WorkoutSelectionSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  List<WorkoutType> _getWorkouts(BuildContext context) => [

    WorkoutType(
      name: 'Live Graph',
      description: 'Mess with the live graph.',
      icon: Icons.timeline_rounded,
      accentColor: context.streakAccent,
      setupPageBuilder: (context) => const LiveGraphPage(),
    ),

    WorkoutType(
      name: 'Repeaters',
      description: 'Timed hang sets with rest intervals',
      icon: Icons.repeat_rounded,
      accentColor: context.repeaterAccent,
      setupPageBuilder: (context) => const RepeaterSetupPage(),
    ),

    WorkoutType(
      name: 'Peak Load',
      description: 'Measure your maximum single effort',
      icon: Icons.arrow_upward_rounded,
      accentColor: context.peakLoadAccent,
      setupPageBuilder: (context) =>
          const PeakLoadSetupPage(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  // 4. Clean up the controller
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openWorkout(BuildContext context, WorkoutType workout) {
    HapticFeedback.lightImpact();

    // Push using rootNavigator so it covers the bottom nav bar
    Navigator.of(
      context,
      rootNavigator: true,
    ).push(CupertinoPageRoute(builder: workout.setupPageBuilder));
  }

  WorkoutType _templateCard(BuildContext context, WorkoutTemplate template) {
    return WorkoutType(
      name: template.name,
      description:
          '${template.blocks.length} blocks · ${formatEstimate(template.estimatedSeconds)}',
      icon: Icons.playlist_play_rounded,
      accentColor: context.customAccent,
      setupPageBuilder: (context) =>
          TemplateOverviewPage(templateId: template.id!),
    );
  }

  void _showTemplateActions(BuildContext context, WorkoutTemplate template) {
    HapticFeedback.mediumImpact();
    final notifier = ref.read(templatesProvider.notifier);

    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBackground,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit_rounded, color: context.textPrimary),
              title: Text('Edit', style: context.body),
              onTap: () {
                Navigator.pop(sheetContext);
                _openWorkout(
                  context,
                  WorkoutType(
                    name: template.name,
                    description: '',
                    icon: Icons.edit_rounded,
                    accentColor: context.customAccent,
                    setupPageBuilder: (_) =>
                        TemplateEditorPage(template: template),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.copy_rounded, color: context.textPrimary),
              title: Text('Duplicate', style: context.body),
              onTap: () {
                Navigator.pop(sheetContext);
                notifier.duplicateTemplate(template);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: context.danger),
              title: Text(
                'Delete',
                style: context.body.copyWith(color: context.danger),
              ),
              onTap: () async {
                Navigator.pop(sheetContext);
                final confirmed = await _confirmDelete(context, template);
                if (confirmed) notifier.deleteTemplate(template.id!);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, WorkoutTemplate template) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardBackground,
        title: Text('Delete "${template.name}"?', style: context.body),
        content: Text(
          'Workouts you have already logged with it are kept.',
          style: TextStyle(color: context.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: context.textPrimary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: context.danger)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final workouts = _getWorkouts(context);
    final templates = ref.watch(templatesProvider).value ?? const [];

    final items = <Widget>[
      for (final workout in workouts)
        _WorkoutCard(
          workout: workout,
          onTap: () => _openWorkout(context, workout),
        ),
      const _SectionHeader(label: 'MY WORKOUTS'),
      for (final template in templates)
        _WorkoutCard(
          workout: _templateCard(context, template),
          onTap: () => _openWorkout(context, _templateCard(context, template)),
          onLongPress: () => _showTemplateActions(context, template),
        ),
      _WorkoutCard(
        workout: WorkoutType(
          name: 'Create workout',
          description: 'Build your own with warm-ups and working sets',
          icon: Icons.add_rounded,
          accentColor: context.customAccent,
          setupPageBuilder: (context) => const TemplateEditorPage(),
        ),
        onTap: () => _openWorkout(
          context,
          WorkoutType(
            name: 'Create workout',
            description: '',
            icon: Icons.add_rounded,
            accentColor: context.customAccent,
            setupPageBuilder: (context) => const TemplateEditorPage(),
          ),
        ),
      ),
    ];

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: items.length,
      itemBuilder: (context, index) {
        // Stagger the first few cards; the rest arrive with the last one.
        final stagger = (index.clamp(0, 4)) * 0.1;
        return FadeSlide(
          animation: _controller,
          intervalStart: 0.1 + stagger,
          intervalEnd: 0.6 + stagger,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: items[index],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 4),
      child: Text(
        label,
        style: context.overline.copyWith(
          color: context.textMuted,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _WorkoutCard extends StatefulWidget {
  const _WorkoutCard({
    required this.workout,
    required this.onTap,
    this.onLongPress,
  });

  final WorkoutType workout;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  State<_WorkoutCard> createState() => _WorkoutCardState();
}

class _WorkoutCardState extends State<_WorkoutCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _press, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.workout;

    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) => _press.reverse(),
      onTapCancel: () => _press.reverse(),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: w.accentColor.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: w.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(w.icon, color: w.accentColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      w.name,
                      style: context.body.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      w.description,
                      style: TextStyle(fontSize: 12, color: context.textMuted),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: w.accentColor.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
