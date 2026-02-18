import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();
  
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  Future<void> initialize() async {
    tz.initializeTimeZones();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(settings);
  }
  
  Future<void> requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }
  
  // Schedule daily nutrition tip
  Future<void> scheduleDailyNutritionTip(int hour, int minute) async {
    await _notifications.zonedSchedule(
      0, // notification id
      'Daily Nutrition Tip 🥗',
      'Tap to discover today\'s healthy eating insight!',
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_tip',
          'Daily Tips',
          channelDescription: 'Daily nutrition and fitness tips',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
  
  // Schedule workout reminder
  Future<void> scheduleWorkoutReminder(int hour, int minute) async {
    await _notifications.zonedSchedule(
      1, // notification id
      'Time to Work Out! 💪',
      'Your body is ready! Let\'s get moving.',
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'workout_reminder',
          'Workout Reminders',
          channelDescription: 'Reminders for scheduled workouts',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
  
  // Send streak alert
  Future<void> sendStreakAlert(int currentStreak) async {
    await _notifications.show(
      2,
      '🔥 Streak Alert!',
      'You\'re on a $currentStreak day streak! Don\'t break it!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'streak_alert',
          'Streak Alerts',
          channelDescription: 'Alerts about workout streaks',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
  
  // Send challenge completion notification
  Future<void> sendChallengeCompletionNotification(String challengeTitle) async {
    await _notifications.show(
      3,
      '🏆 Challenge Completed!',
      'Congratulations! You completed "$challengeTitle"',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'challenge_notification',
          'Challenge Notifications',
          channelDescription: 'Notifications about challenges',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
  
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }
  
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
