import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifter/core/providers/ble_provider.dart';
import 'package:lifter/core/providers/shared_preferences_provider.dart';
import 'package:lifter/features/bluetooth/ble_manager.dart';
import 'package:lifter/features/workouts/ui/widgets/workout_live_stats.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> pumpStats(WidgetTester tester, ScaleStatus status) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        liveWeightStreamProvider.overrideWith((ref) => Stream.value(20.0)),
        scaleStatusProvider.overrideWith((ref) => Stream.value(status)),
      ],
      child: const MaterialApp(
        home: Scaffold(body: WorkoutLiveStats(secondsRemaining: 30)),
      ),
    ));
    await tester.pump();
  }

  testWidgets('says when Bluetooth is off', (tester) async {
    await pumpStats(tester, ScaleStatus.bluetoothOff);
    expect(find.text('Turn on Bluetooth to read the scale'), findsOneWidget);
  });

  testWidgets('says nothing while readings come in', (tester) async {
    await pumpStats(tester, ScaleStatus.receiving);
    expect(find.textContaining('Bluetooth'), findsNothing);
    expect(find.textContaining('scale'), findsNothing);
    expect(find.text('20.0'), findsOneWidget);
  });
}
