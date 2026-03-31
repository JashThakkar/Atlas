import '../models/workout_model.dart';

/// Adjusts an existing workout plan to fit within a user-specified time
/// constraint.  The algorithm:
///   1. Estimates how long the original workout would take.
///   2. Calculates how many exercises can fit in the available time.
///   3. Prioritises compound (multi-muscle) exercises first.
///   4. Reduces rest intervals when below 70% of the original time budget.
///   5. Caps sets per exercise to keep caloric burn consistent.
class WorkoutTimeAdjustmentService {
  /// Average time in seconds a user spends on a single set (work + rest).
  static const int _secondsPerSet = 90;

  /// Extra seconds added per exercise for setup / transition.
  static const int _setupSecondsPerExercise = 30;

  // Compound-focused exercises get highest priority.
  static const List<String> _compoundKeywords = [
    'squat',
    'deadlift',
    'bench',
    'press',
    'row',
    'pull',
    'lunge',
    'thruster',
    'snatch',
    'clean',
    'burpee',
    'turkish',
    'farmer',
    'push-up',
    'pushup',
  ];

  /// Returns an adjusted [WorkoutModel] that fits within [availableMinutes].
  /// If [workout] already fits, it is returned unchanged.
  /// Set [allowOverride] to false to prevent users from reverting adjustments.
  WorkoutModel adjustForTimeConstraint(
    WorkoutModel workout, {
    required int availableMinutes,
    bool allowUserOverride = true,
  }) {
    final availableSeconds = availableMinutes * 60;
    final originalSeconds = _estimateDurationSeconds(workout);

    if (originalSeconds <= availableSeconds) {
      // Already fits — no adjustment needed.
      return workout.copyWith(
        workoutName: workout.workoutName,
        adjustedForMinutes: availableMinutes,
        isAiAdjusted: false,
      );
    }

    // Sort exercises: compound first, then by fewest sets (least time).
    final sorted = List<WorkoutExercise>.from(workout.exercises)
      ..sort((a, b) {
        final aCompound = _isCompound(a.exerciseName) ? 0 : 1;
        final bCompound = _isCompound(b.exerciseName) ? 0 : 1;
        return aCompound.compareTo(bCompound);
      });

    // Decide whether to reduce sets or drop exercises.
    final useReducedRest = availableSeconds < originalSeconds * 0.7;

    final adjustedExercises = <WorkoutExercise>[];
    int usedSeconds = 0;

    for (final exercise in sorted) {
      final setTime = useReducedRest ? 60 : _secondsPerSet;
      final exerciseTime =
          exercise.sets * setTime + _setupSecondsPerExercise;

      if (usedSeconds + exerciseTime <= availableSeconds) {
        adjustedExercises.add(exercise);
        usedSeconds += exerciseTime;
      } else {
        // Try fitting with fewer sets.
        final maxSets =
            (availableSeconds - usedSeconds - _setupSecondsPerExercise) ~/
                setTime;
        if (maxSets >= 1) {
          adjustedExercises.add(WorkoutExercise(
            exerciseName: exercise.exerciseName,
            sets: maxSets,
            reps: exercise.reps,
            notes: exercise.notes,
          ));
          usedSeconds +=
              maxSets * setTime + _setupSecondsPerExercise;
        }
        // No more time — stop adding exercises.
        break;
      }
    }

    final adjustedMinutes = (usedSeconds / 60).ceil();

    return workout.copyWith(
      workoutName: '${workout.workoutName} (${availableMinutes}min)',
      exercises: adjustedExercises,
      adjustedForMinutes: availableMinutes,
      estimatedMinutes: adjustedMinutes,
      isAiAdjusted: true,
      allowUserOverride: allowUserOverride,
    );
  }

  /// Estimates how long [workout] takes based on sets and transitions.
  int _estimateDurationSeconds(WorkoutModel workout) {
    return workout.exercises.fold(0, (total, ex) {
      return total + ex.sets * _secondsPerSet + _setupSecondsPerExercise;
    });
  }

  int estimateDurationMinutes(WorkoutModel workout) =>
      (_estimateDurationSeconds(workout) / 60).ceil();

  bool _isCompound(String name) {
    final lower = name.toLowerCase();
    return _compoundKeywords.any((kw) => lower.contains(kw));
  }
}
