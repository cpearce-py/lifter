import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/providers/workout_provider.dart';

class MyWorkoutPage extends ConsumerWidget {
  const MyWorkoutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // use StateMachines state
    final workoutState = ref.watch(workoutNotifierProvider);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(workoutState.name),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: (){
                    ref.read(workoutNotifierProvider.notifier).send(Event.start);
                  }, 
                  child: Text("Start")
                ),
                TextButton(onPressed: (){
                  ref.read(workoutNotifierProvider.notifier).send(Event.pause);
                }, 
                child: Text("Stop")),
                TextButton(onPressed: (){
                  ref.read(workoutNotifierProvider.notifier).send(Event.reset);
                }, 
                child: Text("Reset")),
              ],
            ),
          ],
        ),
      )
    );
  }
}

void main() {
  StateMachine sm = StateMachine();
  sm.send(Event.start);
}
