import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/notification_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Daily Tip Time'),
            subtitle: const Text('Set when you want to receive nutrition tips'),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: const TimeOfDay(hour: 8, minute: 0),
              );
              if (time != null) {
                final notificationService = ref.read(notificationServiceProvider);
                await notificationService.scheduleDailyNutritionTip(time.hour, time.minute);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Daily tip scheduled!')),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.fitness_center),
            title: const Text('Workout Reminder'),
            subtitle: const Text('Set when you want workout reminders'),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: const TimeOfDay(hour: 18, minute: 0),
              );
              if (time != null) {
                final notificationService = ref.read(notificationServiceProvider);
                await notificationService.scheduleWorkoutReminder(time.hour, time.minute);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Workout reminder scheduled!')),
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
