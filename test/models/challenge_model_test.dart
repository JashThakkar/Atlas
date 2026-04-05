import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/models/challenge_model.dart';

void main() {
  group('ChallengeModel', () {
    group('isActive', () {
      test('returns true when current time is between start and end dates', () {
        final now = DateTime.now();
        final challenge = ChallengeModel(
          title: 'Push-up Challenge',
          description: '100 push-ups in a week',
          type: 'Total Workouts',
          targetValue: 7,
          badgeId: 'badge-1',
          startDate: now.subtract(const Duration(days: 1)),
          endDate: now.add(const Duration(days: 6)),
        );

        expect(challenge.isActive, isTrue);
      });

      test('returns false when current time is after end date', () {
        final pastChallenge = ChallengeModel(
          title: 'Past Challenge',
          description: 'Already ended',
          type: 'Streak Days',
          targetValue: 5,
          badgeId: 'badge-2',
          startDate: DateTime(2020, 1, 1),
          endDate: DateTime(2020, 1, 7),
        );

        expect(pastChallenge.isActive, isFalse);
      });

      test('returns false when current time is before start date', () {
        final now = DateTime.now();
        final futureChallenge = ChallengeModel(
          title: 'Future Challenge',
          description: 'Has not started yet',
          type: 'Total Minutes',
          targetValue: 300,
          badgeId: 'badge-3',
          startDate: now.add(const Duration(days: 7)),
          endDate: now.add(const Duration(days: 14)),
        );

        expect(futureChallenge.isActive, isFalse);
      });
    });

    test('constructor sets participants to empty list by default', () {
      final challenge = ChallengeModel(
        title: 'Run Challenge',
        description: '5k every day',
        type: 'Streak Days',
        targetValue: 10,
        badgeId: 'badge-4',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
      );

      expect(challenge.participants, isEmpty);
    });

    test('constructor stores provided participants', () {
      final challenge = ChallengeModel(
        title: 'Run Challenge',
        description: '5k every day',
        type: 'Streak Days',
        targetValue: 10,
        badgeId: 'badge-4',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        participants: ['user-1', 'user-2'],
      );

      expect(challenge.participants, ['user-1', 'user-2']);
    });
  });

  group('UserChallengeProgress', () {
    test('constructor sets all fields correctly', () {
      final progress = UserChallengeProgress(
        userId: 'user-1',
        challengeId: 'challenge-1',
        currentValue: 3,
        completed: false,
      );

      expect(progress.userId, 'user-1');
      expect(progress.challengeId, 'challenge-1');
      expect(progress.currentValue, 3);
      expect(progress.completed, isFalse);
      expect(progress.completedAt, isNull);
    });

    test('toMap serializes fields when completedAt is null', () {
      final progress = UserChallengeProgress(
        userId: 'user-1',
        challengeId: 'challenge-1',
        currentValue: 5,
        completed: false,
      );

      final map = progress.toMap();

      expect(map['userId'], 'user-1');
      expect(map['challengeId'], 'challenge-1');
      expect(map['currentValue'], 5);
      expect(map['completed'], isFalse);
      expect(map['completedAt'], isNull);
    });

    test('fromMap deserializes fields when completedAt is null', () {
      final map = {
        'userId': 'user-2',
        'challengeId': 'challenge-2',
        'currentValue': 10,
        'completed': true,
        'completedAt': null,
      };

      final progress = UserChallengeProgress.fromMap(map);

      expect(progress.userId, 'user-2');
      expect(progress.challengeId, 'challenge-2');
      expect(progress.currentValue, 10);
      expect(progress.completed, isTrue);
      expect(progress.completedAt, isNull);
    });

    test('fromMap uses defaults for missing fields', () {
      final progress = UserChallengeProgress.fromMap({});

      expect(progress.userId, '');
      expect(progress.challengeId, '');
      expect(progress.currentValue, 0);
      expect(progress.completed, isFalse);
      expect(progress.completedAt, isNull);
    });

    test('round-trip toMap then fromMap preserves fields without completedAt',
        () {
      final original = UserChallengeProgress(
        userId: 'user-3',
        challengeId: 'ch-3',
        currentValue: 7,
        completed: false,
      );

      final restored = UserChallengeProgress.fromMap(original.toMap());

      expect(restored.userId, original.userId);
      expect(restored.challengeId, original.challengeId);
      expect(restored.currentValue, original.currentValue);
      expect(restored.completed, original.completed);
      expect(restored.completedAt, isNull);
    });
  });
}
