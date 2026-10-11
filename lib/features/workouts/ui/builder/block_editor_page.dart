import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lifter/core/measurements/widgets/weight_input.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';
import 'package:lifter/core/ui/widgets/app_card.dart';
import 'package:lifter/core/ui/widgets/controls.dart';
import 'package:lifter/features/workouts/models/custom/workout_template.dart';
import 'package:lifter/features/workouts/models/intensity.dart';
import 'package:lifter/features/workouts/ui/builder/builder_widgets.dart';
import 'package:lifter/features/workouts/ui/widgets/grip_setup_card.dart';

/// Edits a single block. Pops with the updated [WorkoutBlock], or null if
/// the user backs out.
class BlockEditorPage extends StatefulWidget {
  const BlockEditorPage({super.key, required this.block, this.isNew = false});

  final WorkoutBlock block;
  final bool isNew;

  @override
  State<BlockEditorPage> createState() => _BlockEditorPageState();
}

class _BlockEditorPageState extends State<BlockEditorPage> {
  late WorkoutBlock _block = widget.block;
  late bool _ramp = widget.block.startPercentage != widget.block.endPercentage;
  late final _nameController = TextEditingController(text: widget.block.name);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _update(WorkoutBlock block) => setState(() => _block = block);

  void _setRamp(bool ramp) {
    setState(() {
      _ramp = ramp;
      if (ramp && _block.endPercentage == _block.startPercentage) {
        // Give the ramp somewhere to go.
        final end = math.min(_block.startPercentage + 30, 100);
        final start = math.min(_block.startPercentage, end - 5);
        _block = _block.copyWith(startPercentage: start, endPercentage: end);
      }
    });
  }

  void _save() {
    final name = _nameController.text.trim();
    Navigator.of(context).pop(_block.copyWith(
      name: name.isEmpty ? _block.kind.label : name,
      endPercentage: _ramp ? _block.endPercentage : _block.startPercentage,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _block.kind == BlockKind.warmup
        ? context.warmupAccent
        : context.customAccent;

    Widget stepper(
      String label,
      int value,
      double min,
      double max,
      double step,
      String unit,
      WorkoutBlock Function(int v) apply,
    ) {
      return AppCard(
        label: label,
        child: StepperControl(
          value: value.toDouble(),
          min: min,
          max: max,
          step: step,
          unit: unit,
          accentColor: accentColor,
          onChanged: (v) => _update(apply(v.toInt())),
        ),
      );
    }

    final divider = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(color: context.cardBorder, height: 1),
    );

    return BuilderScaffold(
      backLabel: 'Workout',
      title: widget.isNew ? 'New block' : 'Edit block',
      subtitle: 'Each block runs like a set of Repeaters',
      accentColor: accentColor,
      buttonLabel: 'Save block',
      onButtonTap: _save,
      children: [
        AppCard(
          label: 'Name',
          child: BuilderTextField(
            controller: _nameController,
            hintText: _block.kind.label,
          ),
        ),
        AppCard(
          label: 'Type',
          child: SegmentedControl(
            choices: BlockKind.values.map((k) => k.label).toList(),
            selectedIndex: _block.kind.index,
            accentColor: accentColor,
            onChanged: (i) => _update(_block.copyWith(kind: BlockKind.values[i])),
          ),
        ),
        GripSetupCard(
          grip: _block.grip,
          accentColor: accentColor,
          onChanged: (g) => _update(_block.copyWith(grip: g)),
        ),
        stepper('Sets', _block.sets, 1, 20, 1, '',
            (v) => _block.copyWith(sets: v)),
        stepper('Reps', _block.reps, 1, 20, 1, '',
            (v) => _block.copyWith(reps: v)),
        stepper('Work time', _block.workSeconds, 3, 60, 1, 's',
            (v) => _block.copyWith(workSeconds: v)),
        stepper('Rest time', _block.restSeconds, 3, 120, 1, 's',
            (v) => _block.copyWith(restSeconds: v)),
        stepper('Set rest', _block.setRestSeconds, 10, 300, 10, 's',
            (v) => _block.copyWith(setRestSeconds: v)),
        stepper('Rest after block', _block.restAfterSeconds, 10, 600, 10, 's',
            (v) => _block.copyWith(restAfterSeconds: v)),

        // Intensity group, laid out like the Repeater config page.
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Target Intensity', style: context.cardTitle),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Relative to', style: context.body),
                  DropdownControl(
                    choices: relativeToLabels,
                    selectedIndex: _block.relativeTo,
                    accentColor: accentColor,
                    onChanged: (v) => _update(_block.copyWith(relativeTo: v)),
                  ),
                ],
              ),
              divider,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ramp across sets', style: context.body),
                      Text(
                        'Build from a light to a heavier target',
                        style: TextStyle(fontSize: 12, color: context.textMuted),
                      ),
                    ],
                  ),
                  ToggleControl(
                    value: _ramp,
                    accentColor: accentColor,
                    onChanged: _setRamp,
                  ),
                ],
              ),
              divider,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _PercentagePicker(
                    // Rebuild the picker when ramp changes the value under it.
                    key: ValueKey('start-$_ramp'),
                    label: _ramp ? 'First set' : 'Target',
                    value: _block.startPercentage,
                    accentColor: accentColor,
                    onChanged: (v) =>
                        _update(_block.copyWith(startPercentage: v)),
                  ),
                  if (_ramp) ...[
                    Icon(Icons.arrow_forward_rounded, color: context.textMuted),
                    _PercentagePicker(
                      key: ValueKey('end-$_ramp'),
                      label: 'Last set',
                      value: _block.endPercentage,
                      accentColor: accentColor,
                      onChanged: (v) =>
                          _update(_block.copyWith(endPercentage: v)),
                    ),
                  ],
                ],
              ),
              if (_ramp && _block.sets < 2) ...[
                const SizedBox(height: 8),
                Text(
                  'Add at least 2 sets to ramp.',
                  style: TextStyle(fontSize: 12, color: context.textMuted),
                ),
              ],
              if (_block.relativeTo == RelativeTo.custom) ...[
                divider,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Custom Weight', style: context.body),
                    WeightInput(
                      weightKg: _block.customWeight,
                      accentColor: accentColor,
                      onChangedKg: (v) =>
                          _update(_block.copyWith(customWeight: v)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PercentagePicker extends StatelessWidget {
  const _PercentagePicker({
    super.key,
    required this.label,
    required this.value,
    required this.accentColor,
    required this.onChanged,
  });

  final String label;
  final int value;
  final Color accentColor;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: context.textMuted)),
        const SizedBox(height: 6),
        ScrollableControl(
          initialPercentage: value,
          accentColor: accentColor,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
