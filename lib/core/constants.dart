class AppConstants {
  // App Info
  static const String appName = 'Atlas Fitness';
  static const String appVersion = '1.0.0';
  
  // Firebase Collections
  static const String usersCollection = 'User';
  static const String workoutsCollection = 'workouts';
  static const String exerciseLogsCollection = 'exercise_logs';
  static const String bodyMetricsCollection = 'body_metrics';
  static const String streaksCollection = 'streaks';
  static const String postsCollection = 'posts';
  static const String commentsCollection = 'comments';
  static const String friendsCollection = 'friends';
  static const String challengesCollection = 'challenges';
  static const String badgesCollection = 'badges';
  static const String bugReportsCollection = 'bug_reports';
  static const String chatHistoryCollection = 'chat_history';
  
  // Streak Settings
  static const int streakGracePeriodHours = 24;
  
  // Workout Difficulty Levels
  static const List<String> difficultyLevels = ['Beginner', 'Intermediate', 'Advanced'];
  
  // Body Metrics
  static const List<String> bodyMetricTypes = ['Weight', 'Chest', 'Waist', 'Hips', 'Arms', 'Thighs'];
  
  // Challenge Types
  static const List<String> challengeTypes = [
    'Total Workouts',
    'Total Minutes',
    'Specific Exercise',
    'Streak Days',
  ];
  
  // Notification Channels
  static const String workoutReminderChannel = 'workout_reminder';
  static const String dailyTipChannel = 'daily_tip';
  static const String streakAlertChannel = 'streak_alert';
  static const String challengeNotificationChannel = 'challenge_notification';
}
