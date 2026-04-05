import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/models/user_model.dart';

void main() {
  group('UserModel', () {
    final baseDate = DateTime(2024, 1, 1);
    final lastWorkout = DateTime(2024, 3, 15);

    UserModel buildUser({
      String uid = 'user-1',
      String email = 'alice@example.com',
      String displayName = 'Alice',
      String? photoUrl,
      String? bio,
      int currentStreak = 5,
      int longestStreak = 10,
      List<String>? badges,
      DateTime? lastWorkoutDate,
      bool isAdmin = false,
    }) {
      return UserModel(
        uid: uid,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        bio: bio,
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        badges: badges ?? [],
        createdAt: baseDate,
        lastWorkoutDate: lastWorkoutDate,
        isAdmin: isAdmin,
      );
    }

    test('constructor stores all fields correctly', () {
      final user = buildUser(
        photoUrl: 'https://example.com/photo.jpg',
        bio: 'Fitness lover',
        badges: ['badge-1', 'badge-2'],
        lastWorkoutDate: lastWorkout,
        isAdmin: true,
      );

      expect(user.uid, 'user-1');
      expect(user.email, 'alice@example.com');
      expect(user.displayName, 'Alice');
      expect(user.photoUrl, 'https://example.com/photo.jpg');
      expect(user.bio, 'Fitness lover');
      expect(user.currentStreak, 5);
      expect(user.longestStreak, 10);
      expect(user.badges, ['badge-1', 'badge-2']);
      expect(user.createdAt, baseDate);
      expect(user.lastWorkoutDate, lastWorkout);
      expect(user.isAdmin, isTrue);
    });

    test('constructor sets defaults correctly', () {
      final user = UserModel(
        uid: 'user-2',
        email: 'bob@example.com',
        displayName: 'Bob',
        createdAt: baseDate,
      );

      expect(user.currentStreak, 0);
      expect(user.longestStreak, 0);
      expect(user.badges, isEmpty);
      expect(user.photoUrl, isNull);
      expect(user.bio, isNull);
      expect(user.lastWorkoutDate, isNull);
      expect(user.isAdmin, isFalse);
    });

    group('copyWith', () {
      test('updates displayName', () {
        final original = buildUser();
        final updated = original.copyWith(displayName: 'Alicia');

        expect(updated.displayName, 'Alicia');
        expect(updated.uid, original.uid);
        expect(updated.email, original.email);
      });

      test('updates photoUrl', () {
        final original = buildUser();
        final updated = original.copyWith(
          photoUrl: 'https://example.com/new-photo.jpg',
        );

        expect(updated.photoUrl, 'https://example.com/new-photo.jpg');
        expect(updated.displayName, original.displayName);
      });

      test('updates bio', () {
        final original = buildUser();
        final updated = original.copyWith(bio: 'Runner and weightlifter');

        expect(updated.bio, 'Runner and weightlifter');
      });

      test('updates currentStreak', () {
        final original = buildUser(currentStreak: 3);
        final updated = original.copyWith(currentStreak: 7);

        expect(updated.currentStreak, 7);
        expect(updated.longestStreak, original.longestStreak);
      });

      test('updates longestStreak', () {
        final original = buildUser(longestStreak: 10);
        final updated = original.copyWith(longestStreak: 15);

        expect(updated.longestStreak, 15);
        expect(updated.currentStreak, original.currentStreak);
      });

      test('updates badges', () {
        final original = buildUser(badges: ['badge-1']);
        final updated = original.copyWith(badges: ['badge-1', 'badge-2']);

        expect(updated.badges.length, 2);
        expect(updated.badges.contains('badge-2'), isTrue);
      });

      test('updates lastWorkoutDate', () {
        final original = buildUser();
        final newDate = DateTime(2024, 6, 1);
        final updated = original.copyWith(lastWorkoutDate: newDate);

        expect(updated.lastWorkoutDate, newDate);
      });

      test('updates isAdmin', () {
        final original = buildUser(isAdmin: false);
        final updated = original.copyWith(isAdmin: true);

        expect(updated.isAdmin, isTrue);
      });

      test('preserves uid, email, and createdAt when using copyWith', () {
        final original = buildUser();
        final updated = original.copyWith(displayName: 'New Name');

        expect(updated.uid, original.uid);
        expect(updated.email, original.email);
        expect(updated.createdAt, original.createdAt);
      });

      test('preserves all other fields when only one field is changed', () {
        final original = buildUser(
          photoUrl: 'https://example.com/photo.jpg',
          bio: 'Loves fitness',
          badges: ['badge-1'],
          lastWorkoutDate: lastWorkout,
          isAdmin: true,
        );

        final updated = original.copyWith(currentStreak: 20);

        expect(updated.photoUrl, original.photoUrl);
        expect(updated.bio, original.bio);
        expect(updated.badges, original.badges);
        expect(updated.lastWorkoutDate, original.lastWorkoutDate);
        expect(updated.isAdmin, original.isAdmin);
        expect(updated.longestStreak, original.longestStreak);
      });
    });
  });
}
