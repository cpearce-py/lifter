import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/measurements/widgets/weight_text.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';
import 'package:lifter/features/user/providers/user_settings_provider.dart';
import 'package:lifter/features/workouts/engines/custom_workout_engine.dart';
import 'package:lifter/features/workouts/models/custom/custom_workout_state.dart';
import 'package:lifter/features/workouts/models/custom/workout_template.dart';
import 'package:lifter/features/workouts/providers/templates_provider.dart';
import 'package:lifter/features/workouts/rules/custom_workout_rules.dart';
import 'package:lifter/features/workouts/sessions/custom_workout_page.dart';
import 'package:lifter/features/workouts/ui/builder/builder_widgets.dart';
import 'package:lifter/features/workouts/ui/builder/template_editor_page.dart';

/// Read-only summary of a template with resolved targets, and the Start
/// button. Watches the template list so edits show up straight away.
class TemplateOverviewPage extends ConsumerWidget {
  const TemplateOverviewPage({super.key, required this.templateId});

  final int templateId;

  void _start(BuildContext context, WorkoutTemplate template, List<WorkoutStep> steps) {
    final initialState = CustomWorkoutState(
      templateId: template.id,
      templateName: template.name,
      steps: steps,
      inner: steps.first.seed,
    );

    Navigator.of(context, rootNavigator: true).push(
      CupertinoPageRoute(
        builder: (_) => ProviderScope(
          overrides: [
            customWorkoutConfigProvider.overrideWithValue(initialState),
          ],
          child: const CustomWorkoutPage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(templatesProvider);
    final template = templatesAsync.value
        ?.where((t) => t.id == templateId)
        .firstOrNull;
    final accentColor = context.customAccent;

    if (template == null) {
      // Loading, or deleted from somewhere else while this page was open.
      return Scaffold(
        backgroundColor: context.background,
        body: Center(
          child: templatesAsync.isLoading
              ? const CircularProgressIndicator()
              : Text(
                  'This workout no longer exists.',
                  style: TextStyle(color: context.textMuted),
                ),
        ),
      );
    }

    final settings = ref.watch(userSettingsProvider);
    final steps = compileTemplate(template, settings);

    return BuilderScaffold(
      backLabel: 'Workouts',
      title: template.name,
      subtitle: [
        if (template.notes.isNotEmpty) template.notes,
        '${template.blocks.length} blocks · ${formatEstimate(template.estimatedSeconds)}',
      ].join('\n'),
      accentColor: accentColor,
      trailing: GestureDetector(
        onTap: () async {
          final deleted = await Navigator.of(context).push<bool>(
            CupertinoPageRoute(
              builder: (_) => TemplateEditorPage(template: template),
            ),
          );
          // Nothing left to show here once the workout is gone.
          if (deleted == true && context.mounted) Navigator.of(context).pop();
        },
        child: Text(
          'Edit',
          style: context.cardTitle.copyWith(
            fontSize: 13,
            color: accentColor.withValues(alpha: 0.8),
          ),
        ),
      ),
      buttonLabel: 'Start workout',
      onButtonTap: steps.isEmpty ? null : () => _start(context, template, steps),
      children: [
        for (var i = 0; i < template.blocks.length; i++)
          BlockCard(
            index: i,
            block: template.blocks[i],
            trailing: _TargetRange(
              steps: steps.where((s) => s.blockIndex == i).toList(),
            ),
          ),
      ],
    );
  }
}

/// Target load for a block, or the range it ramps over.
class _TargetRange extends StatelessWidget {
  const _TargetRange({required this.steps});

  final List<WorkoutStep> steps;

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) return const SizedBox.shrink();
    final style = context.body.copyWith(fontWeight: FontWeight.w700, fontSize: 13);
    final first = steps.first.targetWeight;
    final last = steps.last.targetWeight;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          WeightText(weightKg: first, style: style),
          if (last != first)
            WeightText(weightKg: last, prefix: '→ ', style: style),
        ],
      ),
    );
  }
}
