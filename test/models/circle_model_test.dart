import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/models/circle_model.dart';

void main() {
  group('CircleMember', () {
    test('constructor sets all fields correctly', () {
      final member = CircleMember(
        userId: 'user-1',
        displayName: 'Alice',
        photoUrl: 'https://example.com/alice.jpg',
        activityScore: 42,
        rank: 1,
      );

      expect(member.userId, 'user-1');
      expect(member.displayName, 'Alice');
      expect(member.photoUrl, 'https://example.com/alice.jpg');
      expect(member.activityScore, 42);
      expect(member.rank, 1);
    });

    test('constructor defaults activityScore and rank to 0', () {
      final member = CircleMember(userId: 'user-2', displayName: 'Bob');

      expect(member.activityScore, 0);
      expect(member.rank, 0);
      expect(member.photoUrl, isNull);
    });

    test('toMap serializes fields correctly', () {
      final member = CircleMember(
        userId: 'user-3',
        displayName: 'Carol',
        photoUrl: 'https://example.com/carol.jpg',
        activityScore: 100,
      );

      final map = member.toMap();

      expect(map['userId'], 'user-3');
      expect(map['displayName'], 'Carol');
      expect(map['photoUrl'], 'https://example.com/carol.jpg');
      expect(map['activityScore'], 100);
    });

    test('fromMap deserializes fields correctly', () {
      final map = {
        'userId': 'user-4',
        'displayName': 'Dave',
        'photoUrl': 'https://example.com/dave.jpg',
        'activityScore': 50,
      };

      final member = CircleMember.fromMap(map);

      expect(member.userId, 'user-4');
      expect(member.displayName, 'Dave');
      expect(member.photoUrl, 'https://example.com/dave.jpg');
      expect(member.activityScore, 50);
    });

    test('fromMap uses defaults for missing fields', () {
      final member = CircleMember.fromMap({});

      expect(member.userId, '');
      expect(member.displayName, '');
      expect(member.photoUrl, isNull);
      expect(member.activityScore, 0);
    });

    test('round-trip toMap then fromMap preserves fields', () {
      final original = CircleMember(
        userId: 'user-5',
        displayName: 'Eve',
        activityScore: 75,
      );

      final restored = CircleMember.fromMap(original.toMap());

      expect(restored.userId, original.userId);
      expect(restored.displayName, original.displayName);
      expect(restored.photoUrl, original.photoUrl);
      expect(restored.activityScore, original.activityScore);
    });
  });

  group('CircleModel', () {
    final baseDate = DateTime(2024, 1, 15);

    CircleModel buildCircle({
      List<String>? memberIds,
      Map<String, int>? activityScores,
    }) {
      return CircleModel(
        id: 'circle-1',
        name: 'Fitness Crew',
        description: 'A group of fitness enthusiasts',
        creatorId: 'user-1',
        inviteCode: 'ABC123',
        memberIds: memberIds ?? ['user-1', 'user-2', 'user-3'],
        activityScores: activityScores ?? {},
        createdAt: baseDate,
      );
    }

    group('rankedMembers', () {
      test('returns a member for each memberIds entry', () {
        final circle = buildCircle(
          memberIds: ['user-1', 'user-2'],
          activityScores: {'user-1': 10, 'user-2': 5},
        );

        expect(circle.rankedMembers.length, 2);
      });

      test('ranks members in descending order of activityScore', () {
        final circle = buildCircle(
          memberIds: ['user-1', 'user-2', 'user-3'],
          activityScores: {'user-1': 10, 'user-2': 30, 'user-3': 20},
        );

        final ranked = circle.rankedMembers;

        expect(ranked[0].userId, 'user-2');
        expect(ranked[0].activityScore, 30);
        expect(ranked[1].userId, 'user-3');
        expect(ranked[1].activityScore, 20);
        expect(ranked[2].userId, 'user-1');
        expect(ranked[2].activityScore, 10);
      });

      test('assigns rank starting from 1', () {
        final circle = buildCircle(
          memberIds: ['user-1', 'user-2'],
          activityScores: {'user-1': 10, 'user-2': 5},
        );

        final ranked = circle.rankedMembers;

        expect(ranked[0].rank, 1);
        expect(ranked[1].rank, 2);
      });

      test('defaults to 0 activityScore for members missing from activityScores', () {
        final circle = buildCircle(
          memberIds: ['user-1', 'user-2'],
          activityScores: {'user-1': 15},
        );

        final ranked = circle.rankedMembers;
        final user2 = ranked.firstWhere((m) => m.userId == 'user-2');

        expect(user2.activityScore, 0);
      });

      test('returns empty list when there are no members', () {
        final circle = buildCircle(memberIds: [], activityScores: {});
        expect(circle.rankedMembers, isEmpty);
      });
    });

    group('copyWith', () {
      test('returns new instance with updated name', () {
        final original = buildCircle();
        final updated = original.copyWith(name: 'Iron Squad');

        expect(updated.name, 'Iron Squad');
        expect(updated.id, original.id);
        expect(updated.creatorId, original.creatorId);
        expect(updated.inviteCode, original.inviteCode);
      });

      test('returns new instance with updated description', () {
        final original = buildCircle();
        final updated = original.copyWith(description: 'Elite athletes only');

        expect(updated.description, 'Elite athletes only');
        expect(updated.name, original.name);
      });

      test('returns new instance with updated memberIds', () {
        final original = buildCircle(memberIds: ['user-1', 'user-2']);
        final updated = original.copyWith(memberIds: ['user-1', 'user-2', 'user-3']);

        expect(updated.memberIds.length, 3);
        expect(updated.memberIds.contains('user-3'), isTrue);
      });

      test('returns new instance with updated activityScores', () {
        final original = buildCircle(activityScores: {'user-1': 10});
        final updated = original.copyWith(activityScores: {'user-1': 25});

        expect(updated.activityScores['user-1'], 25);
      });

      test('returns new instance with updated updatedAt', () {
        final original = buildCircle();
        final newDate = DateTime(2024, 2, 1);
        final updated = original.copyWith(updatedAt: newDate);

        expect(updated.updatedAt, newDate);
        expect(updated.createdAt, original.createdAt);
      });

      test('preserves unchanged fields', () {
        final original = buildCircle(
          memberIds: ['user-1'],
          activityScores: {'user-1': 20},
        );

        final updated = original.copyWith(name: 'New Name');

        expect(updated.description, original.description);
        expect(updated.memberIds, original.memberIds);
        expect(updated.activityScores, original.activityScores);
        expect(updated.createdAt, original.createdAt);
      });
    });
  });
}
