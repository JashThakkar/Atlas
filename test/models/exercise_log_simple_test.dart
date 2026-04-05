import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/models/exercise_log_simple.dart';

void main() {
  group('ExerciseLog', () {
    final testDate = DateTime(2024, 6, 15, 10, 30);

    test('constructor sets all fields correctly', () {
      final log = ExerciseLog(
        id: 'log-1',
        exerciseName: 'Push-up',
        duration: 30,
        date: testDate,
      );

      expect(log.id, 'log-1');
      expect(log.exerciseName, 'Push-up');
      expect(log.duration, 30);
      expect(log.date, testDate);
    });

    test('toMap serializes all fields correctly', () {
      final log = ExerciseLog(
        id: 'log-2',
        exerciseName: 'Squat',
        duration: 45,
        date: testDate,
      );

      final map = log.toMap();

      expect(map['id'], 'log-2');
      expect(map['exerciseName'], 'Squat');
      expect(map['duration'], 45);
      expect(map['date'], testDate.millisecondsSinceEpoch);
    });

    test('fromMap deserializes all fields correctly', () {
      final map = {
        'id': 'log-3',
        'exerciseName': 'Deadlift',
        'duration': 60,
        'date': testDate.millisecondsSinceEpoch,
      };

      final log = ExerciseLog.fromMap(map);

      expect(log.id, 'log-3');
      expect(log.exerciseName, 'Deadlift');
      expect(log.duration, 60);
      expect(log.date, testDate);
    });

    test('round-trip toMap then fromMap preserves all fields', () {
      final original = ExerciseLog(
        id: 'log-4',
        exerciseName: 'Bench Press',
        duration: 50,
        date: testDate,
      );

      final restored = ExerciseLog.fromMap(original.toMap());

      expect(restored.id, original.id);
      expect(restored.exerciseName, original.exerciseName);
      expect(restored.duration, original.duration);
      expect(restored.date, original.date);
    });

    test('fromMap uses defaults for missing fields', () {
      final log = ExerciseLog.fromMap({});

      expect(log.id, '');
      expect(log.exerciseName, '');
      expect(log.duration, 0);
      expect(log.date, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('handles zero duration', () {
      final log = ExerciseLog(
        id: 'log-5',
        exerciseName: 'Rest',
        duration: 0,
        date: testDate,
      );

      expect(log.duration, 0);
      expect(log.toMap()['duration'], 0);
    });
  });
}
