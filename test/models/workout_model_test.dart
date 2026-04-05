import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/models/workout_model.dart';

void main() {
  group('WorkoutExercise', () {
    test('constructor sets all fields correctly', () {
      final exercise = WorkoutExercise(
        exerciseName: 'Bench Press',
        sets: 3,
        reps: 10,
        notes: 'Keep elbows tucked',
      );

      expect(exercise.exerciseName, 'Bench Press');
      expect(exercise.sets, 3);
      expect(exercise.reps, 10);
      expect(exercise.notes, 'Keep elbows tucked');
    });

    test('constructor allows null notes', () {
      final exercise = WorkoutExercise(
        exerciseName: 'Squat',
        sets: 4,
        reps: 8,
      );

      expect(exercise.notes, isNull);
    });

    test('toMap serializes all fields', () {
      final exercise = WorkoutExercise(
        exerciseName: 'Deadlift',
        sets: 5,
        reps: 5,
        notes: 'Neutral spine',
      );

      final map = exercise.toMap();

      expect(map['exerciseName'], 'Deadlift');
      expect(map['sets'], 5);
      expect(map['reps'], 5);
      expect(map['notes'], 'Neutral spine');
    });

    test('toMap includes null notes key', () {
      final exercise = WorkoutExercise(
        exerciseName: 'Pull-up',
        sets: 3,
        reps: 12,
      );

      final map = exercise.toMap();

      expect(map.containsKey('notes'), isTrue);
      expect(map['notes'], isNull);
    });

    test('fromMap deserializes all fields', () {
      final map = {
        'exerciseName': 'Overhead Press',
        'sets': 3,
        'reps': 8,
        'notes': 'Full lockout',
      };

      final exercise = WorkoutExercise.fromMap(map);

      expect(exercise.exerciseName, 'Overhead Press');
      expect(exercise.sets, 3);
      expect(exercise.reps, 8);
      expect(exercise.notes, 'Full lockout');
    });

    test('fromMap uses defaults for missing fields', () {
      final exercise = WorkoutExercise.fromMap({});

      expect(exercise.exerciseName, '');
      expect(exercise.sets, 3);
      expect(exercise.reps, 10);
      expect(exercise.notes, isNull);
    });

    test('round-trip toMap then fromMap preserves all fields', () {
      final original = WorkoutExercise(
        exerciseName: 'Lunge',
        sets: 3,
        reps: 15,
        notes: 'Keep knee aligned',
      );

      final restored = WorkoutExercise.fromMap(original.toMap());

      expect(restored.exerciseName, original.exerciseName);
      expect(restored.sets, original.sets);
      expect(restored.reps, original.reps);
      expect(restored.notes, original.notes);
    });
  });

  group('WorkoutModel', () {
    final baseDate = DateTime(2024, 3, 1);
    final exercises = [
      WorkoutExercise(exerciseName: 'Squat', sets: 3, reps: 10),
    ];

    WorkoutModel buildWorkout({DateTime? completedAt}) {
      return WorkoutModel(
        userId: 'user-1',
        workoutName: 'Leg Day',
        difficulty: 'Intermediate',
        exercises: exercises,
        createdAt: baseDate,
        completedAt: completedAt,
      );
    }

    group('isCompleted', () {
      test('returns false when completedAt is null', () {
        final workout = buildWorkout(completedAt: null);
        expect(workout.isCompleted, isFalse);
      });

      test('returns true when completedAt is set', () {
        final workout = buildWorkout(completedAt: DateTime(2024, 3, 1, 9, 0));
        expect(workout.isCompleted, isTrue);
      });
    });

    group('copyWith', () {
      test('returns new instance with updated workoutName', () {
        final original = buildWorkout();
        final updated = original.copyWith(workoutName: 'Upper Body');

        expect(updated.workoutName, 'Upper Body');
        expect(updated.userId, original.userId);
        expect(updated.difficulty, original.difficulty);
      });

      test('returns new instance with updated exercises', () {
        final original = buildWorkout();
        final newExercises = [
          WorkoutExercise(exerciseName: 'Deadlift', sets: 4, reps: 6),
        ];
        final updated = original.copyWith(exercises: newExercises);

        expect(updated.exercises.length, 1);
        expect(updated.exercises.first.exerciseName, 'Deadlift');
        expect(updated.workoutName, original.workoutName);
      });

      test('returns new instance with updated durationMinutes', () {
        final original = buildWorkout();
        final updated = original.copyWith(durationMinutes: 45);

        expect(updated.durationMinutes, 45);
        expect(updated.workoutName, original.workoutName);
      });

      test('returns new instance with updated intensityRating', () {
        final original = buildWorkout();
        final updated = original.copyWith(intensityRating: 4);

        expect(updated.intensityRating, 4);
      });

      test('returns new instance with updated AI fields', () {
        final original = buildWorkout();
        final updated = original.copyWith(
          isAiAdjusted: true,
          adjustedForMinutes: 30,
          estimatedMinutes: 45,
          allowUserOverride: false,
        );

        expect(updated.isAiAdjusted, isTrue);
        expect(updated.adjustedForMinutes, 30);
        expect(updated.estimatedMinutes, 45);
        expect(updated.allowUserOverride, isFalse);
      });

      test('preserves unchanged fields when only one field is updated', () {
        final original = WorkoutModel(
          id: 'w-1',
          userId: 'user-1',
          workoutName: 'Push Day',
          difficulty: 'Advanced',
          exercises: exercises,
          durationMinutes: 60,
          intensityRating: 3,
          createdAt: baseDate,
          isAiAdjusted: true,
          allowUserOverride: false,
        );

        final updated = original.copyWith(durationMinutes: 75);

        expect(updated.id, original.id);
        expect(updated.userId, original.userId);
        expect(updated.workoutName, original.workoutName);
        expect(updated.difficulty, original.difficulty);
        expect(updated.durationMinutes, 75);
        expect(updated.intensityRating, original.intensityRating);
        expect(updated.isAiAdjusted, original.isAiAdjusted);
        expect(updated.allowUserOverride, original.allowUserOverride);
      });
    });
  });
}
