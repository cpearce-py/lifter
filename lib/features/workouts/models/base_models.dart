enum Event { start, pause, resume, skip, cancel, reset, finish }

enum Phase {
  idle,       // not yet started
  starting,   // countdown to start
  working,    // actively hanging — graph recording
  switching,  // changing hands
  resting,    // rest between reps
  setResting, // longer rest between sets
  paused,     // frozen mid-phase
  done,       // all sets and reps complete
  cancelled,
}

enum Hand { right, left }

Event? primaryButtonEvent(Phase phase) => switch (phase) {
  Phase.idle => Event.start,
  Phase.paused => Event.resume,
  Phase.working => Event.pause,
  Phase.resting => Event.skip,
  Phase.setResting => Event.skip,
  _ => null,
};

