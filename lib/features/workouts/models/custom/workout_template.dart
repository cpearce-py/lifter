import 'package:flutter/material.dart';
import 'package:lifter/features/user/models/user_profile.dart';
import 'package:lifter/features/workouts/models/base_models.dart';
import 'package:lifter/features/workouts/models/grip.dart';
import 'package:lifter/features/workouts/models/intensity.dart';

enum BlockKind {
  warmup("Warm-up"),
  working("Working");

  final String label;

  const BlockKind(this.label);
}

/// One section of a custom workout, e.g. "3 ramping warm-up sets" or
/// "5 sets of max hangs". Each block runs like a Repeater.
@immutable
class WorkoutBlock {
  final String name;
  final BlockKind kind;
  final int sets;
  final int reps;
  final int workSeconds;
  final int restSeconds;
  final int setRestSeconds;

  /// Rest after this block, before the next block starts.
  final int restAfterSeconds;

  final int relativeTo;

  /// Intensity of the first set. When [endPercentage] differs, the sets
  /// ramp linearly from start to end (handy for warm-ups).
  final int startPercentage;
  final int endPercentage;
  final double customWeight;

  /// What every set in this block is pulled on.
  final GripSetup grip;

  const WorkoutBlock({
    required this.name,
    this.kind = BlockKind.working,
    this.sets = 3,
    this.reps = 3,
    this.workSeconds = 7,
    this.restSeconds = 3,
    this.setRestSeconds = 60,
    this.restAfterSeconds = 120,
    this.relativeTo = RelativeTo.maxPull,
    this.startPercentage = 80,
    this.endPercentage = 80,
    this.customWeight = 0,
    this.grip = GripSetup.none,
  });

  /// A sensible default warm-up: ramp from 30% to 60% of max pull.
  const WorkoutBlock.warmup()
      : this(
          name: "Warm-up",
          kind: BlockKind.warmup,
          sets: 3,
          reps: 2,
          workSeconds: 7,
          restSeconds: 3,
          setRestSeconds: 30,
          restAfterSeconds: 90,
          startPercentage: 30,
          endPercentage: 60,
        );

  const WorkoutBlock.working() : this(name: "Working sets");

  bool get isRamped => sets > 1 && startPercentage != endPercentage;

  /// Intensity percentage for a 0-based [setIndex] within this block.
  int percentageForSet(int setIndex) {
    if (!isRamped) return startPercentage;
    final t = setIndex / (sets - 1);
    return (startPercentage + (endPercentage - startPercentage) * t).round();
  }

  /// Rough length of the block in seconds, ignoring the rest after it.
  int get estimatedSeconds {
    const switchSeconds = 5;
    final perRep = (workSeconds * 2) + switchSeconds;
    final perSet = (perRep * reps) + (restSeconds * (reps - 1));
    return (perSet * sets) + (setRestSeconds * (sets - 1));
  }

  WorkoutBlock copyWith({
    String? name,
    BlockKind? kind,
    int? sets,
    int? reps,
    int? workSeconds,
    int? restSeconds,
    int? setRestSeconds,
    int? restAfterSeconds,
    int? relativeTo,
    int? startPercentage,
    int? endPercentage,
    double? customWeight,
    GripSetup? grip,
  }) {
    return WorkoutBlock(
      name: name ?? this.name,
      kind: kind ?? this.kind,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      workSeconds: workSeconds ?? this.workSeconds,
      restSeconds: restSeconds ?? this.restSeconds,
      setRestSeconds: setRestSeconds ?? this.setRestSeconds,
      restAfterSeconds: restAfterSeconds ?? this.restAfterSeconds,
      relativeTo: relativeTo ?? this.relativeTo,
      startPercentage: startPercentage ?? this.startPercentage,
      endPercentage: endPercentage ?? this.endPercentage,
      customWeight: customWeight ?? this.customWeight,
      grip: grip ?? this.grip,
    );
  }

  Map<String, dynamic> toMap({required int templateId, required int position}) {
    return {
      'template_id': templateId,
      'position': position,
      'name': name,
      'kind': kind.name,
      'sets': sets,
      'reps': reps,
      'work_seconds': workSeconds,
      'rest_seconds': restSeconds,
      'set_rest_seconds': setRestSeconds,
      'rest_after_seconds': restAfterSeconds,
      'relative_to': relativeTo,
      'start_pct': startPercentage,
      'end_pct': endPercentage,
      'custom_weight': customWeight,
      ...grip.toMap(),
    };
  }

  factory WorkoutBlock.fromMap(Map<String, dynamic> map) {
    return WorkoutBlock(
      name: map['name'] as String? ?? '',
      kind: BlockKind.values.byName(map['kind'] as String),
      sets: map['sets'] as int,
      reps: map['reps'] as int,
      workSeconds: map['work_seconds'] as int,
      restSeconds: map['rest_seconds'] as int,
      setRestSeconds: map['set_rest_seconds'] as int,
      restAfterSeconds: map['rest_after_seconds'] as int,
      relativeTo: map['relative_to'] as int,
      startPercentage: map['start_pct'] as int,
      endPercentage: map['end_pct'] as int,
      customWeight: (map['custom_weight'] as num?)?.toDouble() ?? 0.0,
      grip: GripSetup.fromMap(map),
    );
  }
}

@immutable
class WorkoutTemplate {
  final int? id;
  final String name;
  final String notes;
  final Hand startingHand;
  final List<WorkoutBlock> blocks;

  const WorkoutTemplate({
    this.id,
    required this.name,
    this.notes = "",
    this.startingHand = Hand.left,
    this.blocks = const [],
  });

  int get estimatedSeconds {
    if (blocks.isEmpty) return 0;
    final blockTime = blocks.fold(0, (sum, b) => sum + b.estimatedSeconds);
    final transitions = blocks
        .take(blocks.length - 1)
        .fold(0, (sum, b) => sum + b.restAfterSeconds);
    return blockTime + transitions;
  }

  WorkoutTemplate copyWith({
    int? id,
    String? name,
    String? notes,
    Hand? startingHand,
    List<WorkoutBlock>? blocks,
  }) {
    return WorkoutTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      startingHand: startingHand ?? this.startingHand,
      blocks: blocks ?? this.blocks,
    );
  }

  /// A copy without an id, so saving it creates a new template.
  WorkoutTemplate duplicate() {
    return WorkoutTemplate(
      name: "$name (copy)",
      notes: notes,
      startingHand: startingHand,
      blocks: blocks,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': localUserId,
      'name': name,
      'notes': notes,
      'starting_hand': startingHand.name,
      'update_time': DateTime.now().toIso8601String(),
    };
  }

  factory WorkoutTemplate.fromMap(
    Map<String, dynamic> map,
    List<WorkoutBlock> blocks,
  ) {
    return WorkoutTemplate(
      id: map['template_id'] as int,
      name: map['name'] as String,
      notes: map['notes'] as String? ?? '',
      startingHand: Hand.values.byName(
        map['starting_hand'] as String? ?? Hand.left.name,
      ),
      blocks: blocks,
    );
  }
}

/// Templates seeded into the database so new users have something to start
/// from. They are ordinary rows, so users can edit or delete them.
const starterTemplates = [
  WorkoutTemplate(
    name: "Max Hangs",
    notes: "Ramp up, then short heavy hangs with long rests.",
    blocks: [
      WorkoutBlock(
        name: "Warm-up",
        kind: BlockKind.warmup,
        sets: 3,
        reps: 2,
        workSeconds: 7,
        restSeconds: 3,
        setRestSeconds: 45,
        restAfterSeconds: 120,
        startPercentage: 40,
        endPercentage: 70,
      ),
      WorkoutBlock(
        name: "Max hangs",
        sets: 5,
        reps: 1,
        workSeconds: 10,
        restSeconds: 3,
        setRestSeconds: 180,
        startPercentage: 90,
        endPercentage: 90,
      ),
    ],
  ),
  WorkoutTemplate(
    name: "Density Hangs",
    notes: "Longer hangs at moderate load for endurance.",
    blocks: [
      WorkoutBlock(
        name: "Warm-up",
        kind: BlockKind.warmup,
        sets: 2,
        reps: 3,
        workSeconds: 7,
        restSeconds: 3,
        setRestSeconds: 30,
        restAfterSeconds: 90,
        startPercentage: 30,
        endPercentage: 50,
      ),
      WorkoutBlock(
        name: "Density hangs",
        sets: 4,
        reps: 3,
        workSeconds: 20,
        restSeconds: 10,
        setRestSeconds: 120,
        startPercentage: 60,
        endPercentage: 60,
      ),
    ],
  ),
  WorkoutTemplate(
    name: "Classic 7/3 Repeaters",
    notes: "A quick warm-up into the classic 7 on / 3 off protocol.",
    blocks: [
      WorkoutBlock(
        name: "Warm-up",
        kind: BlockKind.warmup,
        sets: 2,
        reps: 3,
        workSeconds: 7,
        restSeconds: 3,
        setRestSeconds: 30,
        restAfterSeconds: 90,
        startPercentage: 35,
        endPercentage: 50,
      ),
      WorkoutBlock(
        name: "Repeaters",
        sets: 6,
        reps: 6,
        workSeconds: 7,
        restSeconds: 3,
        setRestSeconds: 120,
        startPercentage: 65,
        endPercentage: 65,
      ),
    ],
  ),
];
