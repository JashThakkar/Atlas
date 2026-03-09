import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/notification_provider.dart';
import '../../services/notification_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _dailyTipEnabled = true;
  bool _workoutReminderEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dailyTipEnabled = prefs.getBool('dailyTipEnabled') ?? true;
      _workoutReminderEnabled = prefs.getBool('workoutReminderEnabled') ?? true;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notifications'),
            subtitle: Text('Manage your notification preferences'),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.schedule),
            title: const Text('Daily Nutrition Tips'),
            subtitle: const Text('Receive daily healthy eating insights'),
            value: _dailyTipEnabled,
            onChanged: (value) async {
              setState(() => _dailyTipEnabled = value);
              await _savePreference('dailyTipEnabled', value);
              final notificationService = ref.read(notificationServiceProvider);
              if (value) {
                await notificationService.scheduleDailyNutritionTip(8, 0);
              } else {
                await notificationService
                    .cancelNotification(NotificationService.dailyTipId);
              }
            },
          ),
          if (_dailyTipEnabled)
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Daily Tip Time'),
              subtitle: const Text('Tap to change the time'),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: const TimeOfDay(hour: 8, minute: 0),
                );
                if (time != null) {
                  final notificationService =
                      ref.read(notificationServiceProvider);
                  await notificationService.scheduleDailyNutritionTip(
                      time.hour, time.minute);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setInt('dailyTipHour', time.hour);
                  await prefs.setInt('dailyTipMinute', time.minute);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Daily tip time updated!')),
                    );
                  }
                }
              },
            ),
          SwitchListTile(
            secondary: const Icon(Icons.fitness_center),
            title: const Text('Workout Reminders'),
            subtitle: const Text('Get reminded to work out'),
            value: _workoutReminderEnabled,
            onChanged: (value) async {
              setState(() => _workoutReminderEnabled = value);
              await _savePreference('workoutReminderEnabled', value);
              final notificationService = ref.read(notificationServiceProvider);
              if (value) {
                await notificationService.scheduleWorkoutReminder(18, 0);
              } else {
                await notificationService
                    .cancelNotification(NotificationService.workoutReminderId);
              }
            },
          ),
          if (_workoutReminderEnabled)
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Workout Reminder Time'),
              subtitle: const Text('Tap to change the time'),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: const TimeOfDay(hour: 18, minute: 0),
                );
                if (time != null) {
                  final notificationService =
                      ref.read(notificationServiceProvider);
                  await notificationService.scheduleWorkoutReminder(
                      time.hour, time.minute);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setInt('workoutReminderHour', time.hour);
                  await prefs.setInt('workoutReminderMinute', time.minute);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Workout reminder time updated!')),
                    );
                  }
                }
              },
            ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('About'),
            subtitle: Text('Atlas Fitness v1.0.0'),
          ),
        ],
      ),
    );
  }
}

