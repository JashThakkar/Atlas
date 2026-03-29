import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/notification_provider.dart';
import '../../services/notification_service.dart';
import '../../services/ai_diet_coach.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _dailyTipEnabled = true;
  bool _workoutReminderEnabled = true;
  final _apiKeyController = TextEditingController();
  bool _apiKeyObscured = true;
  bool _apiKeySaving = false;
  final _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = await _secureStorage.read(key: AIDietCoach.prefsKey) ?? '';
    setState(() {
      _dailyTipEnabled = prefs.getBool('dailyTipEnabled') ?? true;
      _workoutReminderEnabled = prefs.getBool('workoutReminderEnabled') ?? true;
      _apiKeyController.text = savedKey;
    });
  }

  Future<void> _saveApiKey() async {
    setState(() => _apiKeySaving = true);
    try {
      final coach = AIDietCoach();
      await coach.saveApiKey(_apiKeyController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API key saved!')),
        );
      }
    } finally {
      if (mounted) setState(() => _apiKeySaving = false);
    }
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
          // ── AI Diet Coach ──────────────────────────────────────────────
          const ListTile(
            leading: Icon(Icons.smart_toy),
            title: Text('AI Diet Coach'),
            subtitle: Text('Enter your Gemini API key to enable the AI coach'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _apiKeyController,
                  obscureText: _apiKeyObscured,
                  decoration: InputDecoration(
                    labelText: 'Gemini API Key',
                    hintText: 'AIza...',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_apiKeyObscured
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _apiKeyObscured = !_apiKeyObscured),
                      tooltip: _apiKeyObscured ? 'Show key' : 'Hide key',
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Get a free key at https://aistudio.google.com/app/apikey',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _apiKeySaving ? null : _saveApiKey,
                    child: _apiKeySaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save API Key'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // ── Notifications ─────────────────────────────────────────────
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

