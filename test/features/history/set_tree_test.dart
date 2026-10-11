import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifter/core/providers/shared_preferences_provider.dart';
import 'package:lifter/features/history/models/log_models.dart';
import 'package:lifter/features/history/models/set_groups.dart';
import 'package:lifter/features/history/ui/set_tree.dart';
import 'package:lifter/features/workouts/models/grip.dart';
import 'package:shared_preferences/shared_preferences.dart';

RepetitionLog rep(double kg) => RepetitionLog(
      peakLoadLeft: kg,
      peakLoadRight: kg + 1,
      averageLoadLeft: kg,
      averageLoadRight: kg,
    );

const open20 = GripSetup(grip: GripType.openHand, edgeMm: 20);
const crimp10 = GripSetup(grip: GripType.halfCrimp, edgeMm: 10);

SetLog warmup(double kg) => SetLog(
    repetitions: [rep(kg), rep(kg)],
    isWarmup: true,
    blockName: 'Warm-up',
    blockIndex: 0,
    grip: open20);

SetLog maxHang(double kg) => SetLog(
    repetitions: [rep(kg)], blockName: 'Max hangs', blockIndex: 1, grip: crimp10);

final customSets = [
  warmup(10), warmup(14), warmup(18),
  maxHang(30), maxHang(32), maxHang(31),
];

void main() {
  group('groupSets', () {
    test('groups consecutive sets from the same block', () {
      final groups = groupSets(customSets);
      expect(groups.map((g) => g.name), ['Warm-up', 'Max hangs']);
      expect(groups.map((g) => g.sets.length), [3, 3]);
      expect(groups.map((g) => g.grip), [open20, crimp10]);
      expect(groups.first.repCount, 6);
      expect((groups.last.best.left, groups.last.best.right), (32, 33));
    });

    test('keeps a plain workout on one grip as a single group', () {
      final sets = [for (final kg in [20.0, 21.0]) SetLog(repetitions: [rep(kg)], grip: open20)];
      final groups = groupSets(sets);
      expect(groups.length, 1);
      expect(groups.single.name, isNull);
    });

    test('splits when the grip changes, even outside a block', () {
      final sets = [
        SetLog(repetitions: [rep(20)], grip: open20),
        SetLog(repetitions: [rep(20)], grip: crimp10),
        SetLog(repetitions: [rep(20)], grip: open20),
      ];
      expect(groupSets(sets).length, 3);
    });

    test('splits the same block name when it appears twice', () {
      final sets = [
        maxHang(30),
        SetLog(repetitions: [rep(30)], blockName: 'Max hangs', blockIndex: 2, grip: crimp10),
      ];
      expect(groupSets(sets).length, 2);
    });
  });

  test('phaseSets puts warm-ups first and skips missing phases', () {
    final phases = phaseSets(customSets);
    expect(phases.map((p) => p.isWarmup), [true, false]);
    expect(phaseSets([maxHang(30)]).map((p) => p.isWarmup), [false]);
  });

  testWidgets('SetTree names each block once and folds warm-ups', (tester) async {
    // A small phone, to catch the header row overflowing.
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SetTree(sets: customSets, accentColor: Colors.blue),
          ),
        ),
      ),
    ));

    expect(find.text('WARM-UP'), findsNWidgets(2)); // phase + block title
    expect(find.text('MAX HANGS'), findsOneWidget);
    expect(find.text('10mm · Half crimp'), findsOneWidget);
    expect(find.text('3 sets'), findsOneWidget);
    expect(find.text('20mm · Open hand'), findsOneWidget);
    expect(find.text('3 sets · 6 reps'), findsOneWidget);

    // Working sets start open, warm-up sets start folded.
    expect(find.text('Set 1'), findsOneWidget);
    await tester.tap(find.text('WARM-UP').last);
    await tester.pumpAndSettle();
    expect(find.text('Set 1'), findsNWidgets(2));
    expect(find.text('Rep 2'), findsNWidgets(3));
  });

  testWidgets('folding a block gives its space back slowly', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SetTree(sets: customSets, accentColor: Colors.blue),
          ),
        ),
      ),
    ));
    double height() => tester.getSize(find.byType(SetTree)).height;

    final open = height();
    await tester.tap(find.text('MAX HANGS'));

    // Held while the block folds...
    await tester.pump(const Duration(milliseconds: 100));
    expect(height(), open);

    // ...then partway through easing down, a frame at a time like a device.
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final midway = height();

    // ...and finally gone.
    await tester.pumpAndSettle();
    final folded = height();
    expect(find.text('Set 1'), findsNothing);
    expect(folded, lessThan(open));
    expect(midway, inExclusiveRange(folded, open));

    // Opening it again grows straight back.
    await tester.tap(find.text('MAX HANGS'));
    await tester.pumpAndSettle();
    expect(height(), open);
  });
}
