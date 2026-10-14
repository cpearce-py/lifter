import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifter/features/history/models/log_models.dart';
import 'package:lifter/features/workouts/notes/save_page.dart';

void main() {
  final log = WorkoutLog(
    workoutTypeId: WorkoutId.repeater,
    dateDone: DateTime(2026, 10, 1),
    duration: 125,
    workingTime: 40,
    graphData: null,
    sets: [],
  );

  Future<void> pumpSavePage(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(home: SaveWorkoutPage(workoutLog: log)),
    ));
  }

  testWidgets('shows the whole duration, not the working time', (tester) async {
    await pumpSavePage(tester);
    expect(find.text('2m 5s'), findsOneWidget);
  });

  testWidgets('asks before discarding the workout', (tester) async {
    await pumpSavePage(tester);

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.text('Discard workout?'), findsOneWidget);

    // Keeping it closes the dialog and stays on the page.
    await tester.tap(find.text('Keep it'));
    await tester.pumpAndSettle();
    expect(find.text('Discard workout?'), findsNothing);
    expect(find.byType(SaveWorkoutPage), findsOneWidget);
  });
}
