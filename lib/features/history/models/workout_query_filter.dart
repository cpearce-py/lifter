class WorkoutQueryFilter {
  final int limit;
  final int offset;
  final DateTime? startDate;
  final DateTime? endDate;

  WorkoutQueryFilter({
    this.limit = 20, // Default to 20 workouts per page
    this.offset = 0,
    this.startDate,
    this.endDate,
  });
}
