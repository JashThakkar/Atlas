import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/core/constants.dart';

void main() {
  group('AppConstants', () {
    group('app info', () {
      test('appName is Atlas Fitness', () {
        expect(AppConstants.appName, 'Atlas Fitness');
      });

      test('appVersion is set', () {
        expect(AppConstants.appVersion, isNotEmpty);
      });
    });

    group('streak settings', () {
      test('streakGracePeriodHours is 24', () {
        expect(AppConstants.streakGracePeriodHours, 24);
      });
    });

    group('difficultyLevels', () {
      test('contains exactly three levels', () {
        expect(AppConstants.difficultyLevels.length, 3);
      });

      test('contains Beginner', () {
        expect(AppConstants.difficultyLevels, contains('Beginner'));
      });

      test('contains Intermediate', () {
        expect(AppConstants.difficultyLevels, contains('Intermediate'));
      });

      test('contains Advanced', () {
        expect(AppConstants.difficultyLevels, contains('Advanced'));
      });
    });

    group('bodyMetricTypes', () {
      test('is not empty', () {
        expect(AppConstants.bodyMetricTypes, isNotEmpty);
      });

      test('contains Weight', () {
        expect(AppConstants.bodyMetricTypes, contains('Weight'));
      });

      test('contains Waist', () {
        expect(AppConstants.bodyMetricTypes, contains('Waist'));
      });
    });

    group('challengeTypes', () {
      test('is not empty', () {
        expect(AppConstants.challengeTypes, isNotEmpty);
      });

      test('contains Total Workouts', () {
        expect(AppConstants.challengeTypes, contains('Total Workouts'));
      });

      test('contains Total Minutes', () {
        expect(AppConstants.challengeTypes, contains('Total Minutes'));
      });

      test('contains Streak Days', () {
        expect(AppConstants.challengeTypes, contains('Streak Days'));
      });
    });

    group('Firebase collection names', () {
      test('usersCollection is non-empty', () {
        expect(AppConstants.usersCollection, isNotEmpty);
      });

      test('workoutsCollection is non-empty', () {
        expect(AppConstants.workoutsCollection, isNotEmpty);
      });

      test('postsCollection is non-empty', () {
        expect(AppConstants.postsCollection, isNotEmpty);
      });

      test('challengesCollection is non-empty', () {
        expect(AppConstants.challengesCollection, isNotEmpty);
      });

      test('circlesCollection is non-empty', () {
        expect(AppConstants.circlesCollection, isNotEmpty);
      });

      test('all collection names are distinct', () {
        final collections = [
          AppConstants.usersCollection,
          AppConstants.workoutsCollection,
          AppConstants.exerciseLogsCollection,
          AppConstants.bodyMetricsCollection,
          AppConstants.postsCollection,
          AppConstants.commentsCollection,
          AppConstants.friendsCollection,
          AppConstants.challengesCollection,
          AppConstants.circlesCollection,
          AppConstants.messagesCollection,
        ];
        final distinct = collections.toSet();
        expect(distinct.length, collections.length);
      });
    });

    group('notification channel names', () {
      test('workoutReminderChannel is non-empty', () {
        expect(AppConstants.workoutReminderChannel, isNotEmpty);
      });

      test('dailyTipChannel is non-empty', () {
        expect(AppConstants.dailyTipChannel, isNotEmpty);
      });

      test('streakAlertChannel is non-empty', () {
        expect(AppConstants.streakAlertChannel, isNotEmpty);
      });

      test('challengeNotificationChannel is non-empty', () {
        expect(AppConstants.challengeNotificationChannel, isNotEmpty);
      });
    });
  });
}
