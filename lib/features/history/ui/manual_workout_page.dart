import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifter/core/measurements/widgets/weight_input.dart';
import 'package:lifter/core/providers/history_provider.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';
import 'package:lifter/core/ui/widgets/app_card.dart';
import 'package:lifter/core/ui/widgets/confirm_dialog.dart';
import 'package:lifter/core/ui/widgets/controls.dart';
import 'package:lifter/features/history/models/log_models.dart';
import 'package:lifter/features/history/models/manual_workout.dart';
import 'package:lifter/features/workouts/models/grip.dart';
import 'package:lifter/features/workouts/ui/widgets/grip_setup_card.dart';
import 'package:lifter/features/workouts/ui/widgets/workout_notes.dart';

/// Logs a workout that was done without the app, e.g. on a different
/// board or when the scale wasn't to hand. Also edits saved workouts.
class ManualWorkoutPage extends ConsumerStatefulWidget {
  /// When set, the page edits this saved workout instead of logging a new
  /// one. Pass the full workout (from getWorkoutById), so its graph is there
  /// to tell whether it came from the scale.
  final WorkoutLog? initial;

  /// The day to log against, e.g. one picked on the home calendar.
  final DateTime? initialDate;

  const ManualWorkoutPage({super.key, this.initial, this.initialDate});

  @override
  ConsumerState<ManualWorkoutPage> createState() => _ManualWorkoutPageState();
}

class _ManualWorkoutPageState extends ConsumerState<ManualWorkoutPage> {
  static const _types = [
    WorkoutId.repeater,
    WorkoutId.peakLoad,
    WorkoutId.custom,
  ];
  static const _typeLabels = ['Repeater', 'Peak Load', 'Other'];

  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  int _typeIndex = 0;
  DateTime _dateDone = DateTime.now();
  int _durationMinutes = 30;
  GripSetup _grip = GripSetup.none;
  bool _splitHands = false;
  List<ManualSet> _sets = [const ManualSet(reps: 6)];
  bool _isSaving = false;
  bool _dirty = false;

  /// False when editing a workout from the scale: its sets hold more than
  /// this form can show, so they're kept as they are.
  bool _setsEditable = true;

  /// False when the sets were pulled on different grips (custom workouts
  /// with several blocks), so one grip can't stand for them all.
  bool _gripEditable = true;

  bool get _isEditing => widget.initial != null;

  int get _workoutTypeId => _types[_typeIndex];

  bool get _canSave =>
      !_isSaving && (!_setsEditable || _sets.any((s) => s.hasLoad));

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;

    if (initial == null) {
      final day = widget.initialDate;
      if (day != null) {
        // Keep the time of day, but never land in the future.
        final now = DateTime.now();
        final picked = DateTime(
          day.year,
          day.month,
          day.day,
          now.hour,
          now.minute,
        );
        _dateDone = picked.isAfter(now) ? now : picked;
      }
      return;
    }

    _typeIndex = _types
        .indexOf(initial.workoutTypeId)
        .clamp(0, _types.length - 1);
    _dateDone = initial.dateDone;
    _durationMinutes = (initial.duration / 60).round().clamp(1, 240);
    _notesController.text = initial.notes;
    if (initial.workoutTypeId == WorkoutId.custom) {
      _nameController.text = initial.templateName ?? '';
    }

    final grips = initial.grips;
    _gripEditable = grips.length <= 1;
    _grip = grips.length == 1 ? grips.single : GripSetup.none;

    final manualSets = manualSetsOf(initial);
    _setsEditable = manualSets != null;
    if (manualSets != null) {
      _sets = manualSets;
      _splitHands = manualSets.any((s) => s.loadLeftKg != s.loadRightKg);
    }
  }

  /// setState for anything the user changes, so leaving can warn about it.
  void _change(VoidCallback fn) {
    setState(() {
      fn();
      _dirty = true;
    });
  }

  Future<void> _confirmLeave() async {
    final discard = await showConfirmDialog(
      context,
      title: 'Discard changes?',
      message: _isEditing
          ? 'Your changes to this workout will be lost.'
          : 'This workout won\'t be logged.',
      confirmLabel: 'Discard',
      cancelLabel: 'Keep editing',
    );
    // Navigator.pop skips PopScope, so this closes the page.
    if (discard && mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Color _accent(BuildContext context) => switch (_workoutTypeId) {
    WorkoutId.repeater => context.repeaterAccent,
    WorkoutId.peakLoad => context.peakLoadAccent,
    _ => context.customAccent,
  };

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dateDone,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateDone),
    );
    if (!mounted) return;

    final picked = DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? _dateDone.hour,
      time?.minute ?? _dateDone.minute,
    );
    // Can't have done it in the future.
    _change(() => _dateDone = picked.isAfter(now) ? now : picked);
  }

  void _updateSet(int index, ManualSet set) {
    _change(() => _sets = [..._sets]..[index] = set);
  }

  void _addSet() {
    HapticFeedback.lightImpact();
    // Copy the last set, since sets are usually repeated at the same load.
    _change(
      () => _sets = [..._sets, _sets.isEmpty ? const ManualSet() : _sets.last],
    );
  }

  void _removeSet(int index) {
    _change(() => _sets = [..._sets]..removeAt(index));
  }

  void _setSplitHands(bool split) {
    _change(() {
      _splitHands = split;
      // Going back to one load, carry the left over to both hands.
      if (!split) {
        _sets = [for (final s in _sets) s.copyWith(loadRightKg: s.loadLeftKg)];
      }
    });
  }

  /// What saving the form gives, as a new workout or the edited one.
  WorkoutLog _buildLog() {
    final initial = widget.initial;

    if (initial != null && !_setsEditable) {
      // From the scale: keep its sets, and only retag their grip.
      return initial.copyWith(
        dateDone: _dateDone,
        duration: _durationMinutes * 60,
        notes: _notesController.text.trim(),
        sets: _gripEditable
            ? [for (final set in initial.sets) set.copyWith(grip: _grip)]
            : initial.sets,
      );
    }

    final log = buildManualWorkout(
      workoutTypeId: _workoutTypeId,
      dateDone: _dateDone,
      durationSeconds: _durationMinutes * 60,
      sets: _sets,
      grip: _grip,
      notes: _notesController.text,
      name: _nameController.text.isEmpty
          ? 'Manual Workout'
          : _nameController.text,
    );
    return initial == null ? log : log.copyWith(id: initial.id);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    final log = _buildLog();
    final history = ref.read(workoutHistoryProvider.notifier);

    try {
      if (_isEditing) {
        await history.updateWorkout(log);
      } else {
        await history.saveWorkout(log);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Workout updated!' : 'Workout logged!'),
          backgroundColor: context.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
      if (_isEditing) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(
          context,
          rootNavigator: true,
        ).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      debugPrint("Failed to save manual workout: $e");
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _accent(context);

    return PopScope(
      canPop: !_dirty || _isSaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        backgroundColor: context.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            _isEditing ? 'Edit Workout' : 'Log Workout',
            style: context.body.copyWith(fontWeight: FontWeight.bold),
          ),
          iconTheme: IconThemeData(color: context.textPrimary),
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(
                _isEditing
                    ? 'Fix anything that was logged wrong.'
                    : 'Add a workout you did without the app.',
                style: TextStyle(fontSize: 13, color: context.textMuted),
              ),
              const SizedBox(height: 16),

              // A workout from the scale stays the type it was recorded as.
              if (_setsEditable) ...[
                AppCard(
                  label: 'Workout type',
                  child: Column(
                    children: [
                      SegmentedControl(
                        choices: _typeLabels,
                        selectedIndex: _typeIndex,
                        accentColor: accentColor,
                        onChanged: (i) => _change(() => _typeIndex = i),
                      ),
                      if (_workoutTypeId == WorkoutId.custom) ...[
                        const SizedBox(height: 12),
                        _NameField(
                          controller: _nameController,
                          accentColor: accentColor,
                          onChanged: (_) => _change(() {}),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              AppCard(
                label: 'When',
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _pickDateTime,
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: context.inputBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                          color: accentColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            DateFormat(
                              'EEE d MMM yyyy · HH:mm',
                            ).format(_dateDone),
                            style: context.body.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.edit_rounded,
                          size: 16,
                          color: context.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              AppCard(
                label: 'Duration',
                child: StepperControl(
                  value: _durationMinutes.toDouble(),
                  min: 1,
                  max: 240,
                  step: 1,
                  unit: 'min',
                  accentColor: accentColor,
                  onChanged: (v) => _change(() => _durationMinutes = v.round()),
                ),
              ),
              const SizedBox(height: 10),

              if (_gripEditable)
                GripSetupCard(
                  grip: _grip,
                  accentColor: accentColor,
                  onChanged: (g) => _change(() => _grip = g),
                ),
              const SizedBox(height: 24),

              // --- Sets ---
              if (!_setsEditable)
                _RecordedSetsNote(setCount: widget.initial!.sets.length)
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Sets',
                        style: context.cardTitle.copyWith(fontSize: 16),
                      ),
                    ),
                    Text(
                      'Split hands',
                      style: TextStyle(fontSize: 13, color: context.textMuted),
                    ),
                    const SizedBox(width: 8),
                    ToggleControl(
                      value: _splitHands,
                      accentColor: accentColor,
                      onChanged: _setSplitHands,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                for (final (i, set) in _sets.indexed) ...[
                  _SetCard(
                    index: i,
                    set: set,
                    splitHands: _splitHands,
                    accentColor: accentColor,
                    onChanged: (s) => _updateSet(i, s),
                    onRemove: _sets.length > 1 ? () => _removeSet(i) : null,
                  ),
                  const SizedBox(height: 10),
                ],
                OutlinedButton.icon(
                  onPressed: _addSet,
                  icon: Icon(Icons.add_rounded, color: accentColor),
                  label: Text('Add set', style: TextStyle(color: accentColor)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: accentColor.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              Text('Notes', style: context.cardTitle.copyWith(fontSize: 16)),
              const SizedBox(height: 8),
              WorkoutNotesField(
                controller: _notesController,
                onChanged: (_) => _change(() {}),
              ),
              const SizedBox(height: 24),

              FilledButton(
                onPressed: _canSave ? _save : null,
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: context.background,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: context.background,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Save Workout',
                        style: context.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.background,
                        ),
                      ),
              ),
              if (!_canSave && !_isSaving) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Enter a load for at least one set to save.',
                    style: TextStyle(fontSize: 12, color: context.textMuted),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  final TextEditingController controller;
  final Color accentColor;
  final ValueChanged<String> onChanged;

  const _NameField({
    required this.controller,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    );

    return TextField(
      controller: controller,
      onChanged: onChanged,
      textCapitalization: TextCapitalization.sentences,
      style: context.body,
      cursorColor: accentColor,
      decoration: InputDecoration(
        hintText: 'Name, e.g. Max hangs',
        hintStyle: context.body.copyWith(
          color: context.textMuted.withValues(alpha: 0.6),
        ),
        filled: true,
        fillColor: context.inputBackground,
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: accentColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

class _SetCard extends StatelessWidget {
  final int index;
  final ManualSet set;
  final bool splitHands;
  final Color accentColor;
  final ValueChanged<ManualSet> onChanged;
  final VoidCallback? onRemove;

  const _SetCard({
    required this.index,
    required this.set,
    required this.splitHands,
    required this.accentColor,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 16),
      decoration: BoxDecoration(
        color: context.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Set ${index + 1}', style: context.cardTitle),
              ),
              IconButton(
                onPressed: onRemove,
                icon: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: onRemove == null
                      ? Colors.transparent
                      : context.textMuted,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Label('Reps'),
                StepperControl(
                  value: set.reps.toDouble(),
                  min: 1,
                  max: 50,
                  step: 1,
                  unit: '',
                  accentColor: accentColor,
                  onChanged: (v) => onChanged(set.copyWith(reps: v.round())),
                ),
                const SizedBox(height: 12),
                if (splitHands)
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label('Left', color: context.leftHandAccent),
                            WeightInput(
                              weightKg: set.loadLeftKg,
                              accentColor: accentColor,
                              onChangedKg: (kg) =>
                                  onChanged(set.copyWith(loadLeftKg: kg)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label('Right', color: context.rightHandAccent),
                            WeightInput(
                              weightKg: set.loadRightKg,
                              accentColor: accentColor,
                              onChangedKg: (kg) =>
                                  onChanged(set.copyWith(loadRightKg: kg)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  _Label('Load per hand'),
                  WeightInput(
                    weightKg: set.loadLeftKg,
                    accentColor: accentColor,
                    onChangedKg: (kg) => onChanged(
                      set.copyWith(loadLeftKg: kg, loadRightKg: kg),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final Color? color;

  const _Label(this.text, {this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color ?? context.textMuted,
        ),
      ),
    );
  }
}

/// Stands in for the set editor when a workout came from the scale.
class _RecordedSetsNote extends StatelessWidget {
  final int setCount;

  const _RecordedSetsNote({required this.setCount});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      label: 'Sets',
      child: Text(
        '$setCount ${setCount == 1 ? 'set was' : 'sets were'} recorded by the '
        'scale, so they can\'t be changed here.',
        style: TextStyle(fontSize: 13, color: context.textMuted),
      ),
    );
  }
}
