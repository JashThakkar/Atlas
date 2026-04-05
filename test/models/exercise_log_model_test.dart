import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/models/exercise_log_model.dart';

void main() {
  group('ExerciseSet', () {
    test('constructor sets all fields correctly', () {
      final set = ExerciseSet(setNumber: 1, reps: 10, weight: 50.0);

      expect(set.setNumber, 1);
      expect(set.reps, 10);
      expect(set.weight, 50.0);
    });

    test('constructor allows null weight', () {
      final set = ExerciseSet(setNumber: 2, reps: 15);
      expect(set.weight, isNull);
    });

    test('toMap serializes all fields', () {
      final set = ExerciseSet(setNumber: 1, reps: 12, weight: 25.5);
      final map = set.toMap();

      expect(map['setNumber'], 1);
      expect(map['reps'], 12);
      expect(map['weight'], 25.5);
    });

    test('toMap includes null weight key', () {
      final set = ExerciseSet(setNumber: 1, reps: 10);
      final map = set.toMap();

      expect(map.containsKey('weight'), isTrue);
      expect(map['weight'], isNull);
    });

    test('fromMap deserializes all fields', () {
      final map = {'setNumber': 3, 'reps': 8, 'weight': 100.0};
      final set = ExerciseSet.fromMap(map);

      expect(set.setNumber, 3);
      expect(set.reps, 8);
      expect(set.weight, 100.0);
    });

    test('fromMap uses defaults for missing fields', () {
      final set = ExerciseSet.fromMap({});

      expect(set.setNumber, 0);
      expect(set.reps, 0);
      expect(set.weight, isNull);
    });

    test('round-trip toMap then fromMap preserves all fields', () {
      final original = ExerciseSet(setNumber: 2, reps: 6, weight: 80.0);
      final restored = ExerciseSet.fromMap(original.toMap());

      expect(restored.setNumber, original.setNumber);
      expect(restored.reps, original.reps);
      expect(restored.weight, original.weight);
    });

    test('round-trip preserves null weight', () {
      final original = ExerciseSet(setNumber: 1, reps: 20);
      final restored = ExerciseSet.fromMap(original.toMap());

      expect(restored.weight, isNull);
    });
  });

  group('ExerciseLogModel', () {
    final testDate = DateTime(2024, 5, 10);

    ExerciseLogModel buildLog({List<ExerciseSet>? sets}) {
      return ExerciseLogModel(
        userId: 'user-1',
        exerciseName: 'Barbell Curl',
        sets: sets ??
            [
              ExerciseSet(setNumber: 1, reps: 10, weight: 20.0),
              ExerciseSet(setNumber: 2, reps: 8, weight: 22.5),
            ],
        date: testDate,
      );
    }

    group('totalReps', () {
      test('returns sum of reps across all sets', () {
        final log = buildLog(sets: [
          ExerciseSet(setNumber: 1, reps: 10, weight: 20.0),
          ExerciseSet(setNumber: 2, reps: 8, weight: 20.0),
          ExerciseSet(setNumber: 3, reps: 6, weight: 20.0),
        ]);

        expect(log.totalReps, 24);
      });

      test('returns zero when there are no sets', () {
        final log = buildLog(sets: []);
        expect(log.totalReps, 0);
      });

      test('returns reps of a single set', () {
        final log = buildLog(sets: [
          ExerciseSet(setNumber: 1, reps: 15),
        ]);
        expect(log.totalReps, 15);
      });
    });

    group('totalVolume', () {
      test('returns sum of reps * weight for all sets', () {
        final log = buildLog(sets: [
          ExerciseSet(setNumber: 1, reps: 10, weight: 20.0), // 200
          ExerciseSet(setNumber: 2, reps: 5, weight: 40.0),  // 200
        ]);

        expect(log.totalVolume, 400);
      });

      test('treats null weight as zero in volume calculation', () {
        final log = buildLog(sets: [
          ExerciseSet(setNumber: 1, reps: 10),            // 0
          ExerciseSet(setNumber: 2, reps: 8, weight: 30.0), // 240
        ]);

        expect(log.totalVolume, 240);
      });

      test('returns zero when there are no sets', () {
        final log = buildLog(sets: []);
        expect(log.totalVolume, 0);
      });

      test('returns zero when all weights are null', () {
        final log = buildLog(sets: [
          ExerciseSet(setNumber: 1, reps: 10),
          ExerciseSet(setNumber: 2, reps: 12),
        ]);

        expect(log.totalVolume, 0);
      });
    });

    test('constructor sets optional fields to defaults', () {
      final log = ExerciseLogModel(
        userId: 'user-2',
        exerciseName: 'Push-up',
        sets: [],
        date: testDate,
      );

      expect(log.id, isNull);
      expect(log.category, isNull);
      expect(log.notes, isNull);
    });

    test('constructor stores provided optional fields', () {
      final log = ExerciseLogModel(
        id: 'el-1',
        userId: 'user-2',
        exerciseName: 'Squat',
        category: 'Legs',
        sets: [],
        notes: 'ATG depth',
        date: testDate,
      );

      expect(log.id, 'el-1');
      expect(log.category, 'Legs');
      expect(log.notes, 'ATG depth');
    });
  });
}
