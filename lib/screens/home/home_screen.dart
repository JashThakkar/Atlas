import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/fitness_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../services/auth_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);
    
    return currentUserAsync.when(
      data: (user) {
        // Handle authenticated user but no profile (network issues)
        if (user == null) {
          final authState = ref.watch(authStateProvider);
          return authState.when(
            data: (authUser) {
              if (authUser != null) {
                // User is authenticated but profile couldn't be loaded
                return Scaffold(
                  appBar: AppBar(title: const Text('Atlas Fitness')),
                  drawer: const AppDrawer(),
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_off_outlined, size: 64, color: Colors.blue),
                          const SizedBox(height: 16),
                          const Text(
                            'Welcome to Atlas Fitness!',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Having trouble connecting to load your profile.\nYour data is safe and will sync when connection improves.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              ref.invalidate(currentUserProvider);
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final authService = ref.read(authServiceProvider);
                              final result = await authService.testFirestoreManually();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Test Result: $result'),
                                    duration: const Duration(seconds: 5),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.bug_report),
                            label: const Text('Run Diagnostics'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () {
                              final authService = ref.read(authServiceProvider);
                              authService.signOut();
                            },
                            icon: const Icon(Icons.logout),
                            label: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              // No authenticated user
              return const SizedBox();
            },
            loading: () => Scaffold(
              appBar: AppBar(title: const Text('Atlas Fitness')),
              body: const Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const SizedBox(),
          );
        }
        
        final statsAsync = ref.watch(userStatsProvider(user.uid));
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Atlas Fitness'),
            actions: [
              IconButton(
                icon: const Icon(Icons.chat),
                onPressed: () => context.push('/ai-chat'),
              ),
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {},
              ),
            ],
          ),
          drawer: const AppDrawer(),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Welcome Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: user.photoUrl != null
                              ? NetworkImage(user.photoUrl!)
                              : null,
                          child: user.photoUrl == null
                              ? Text(
                                  user.displayName[0].toUpperCase(),
                                  style: const TextStyle(fontSize: 24),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome, ${user.displayName}!',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.local_fire_department,
                                      color: Colors.orange, size: 20),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${user.currentStreak} day streak',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Quick Stats
                Text(
                  'Your Stats',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                statsAsync.when(
                  data: (stats) => GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _StatCard(
                        icon: Icons.fitness_center,
                        label: 'Workouts',
                        value: stats['totalWorkouts'].toString(),
                        color: Colors.blue,
                      ),
                      _StatCard(
                        icon: Icons.list_alt,
                        label: 'Exercises',
                        value: stats['totalExercises'].toString(),
                        color: Colors.green,
                      ),
                      _StatCard(
                        icon: Icons.timer,
                        label: 'Minutes',
                        value: stats['totalMinutes'].toString(),
                        color: Colors.orange,
                      ),
                      _StatCard(
                        icon: Icons.emoji_events,
                        label: 'Badges',
                        value: user.badges.length.toString(),
                        color: Colors.purple,
                      ),
                    ],
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Text('Error loading stats'),
                ),
                const SizedBox(height: 24),
                
                // Quick Actions
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _ActionButton(
                      icon: Icons.add_circle,
                      label: 'Log Exercise',
                      onPressed: () => context.push('/exercise-logger'),
                    ),
                    _ActionButton(
                      icon: Icons.auto_awesome,
                      label: 'Generate Workout',
                      onPressed: () => context.push('/generate-workout'),
                    ),
                    _ActionButton(
                      icon: Icons.monitor_weight,
                      label: 'Track Metrics',
                      onPressed: () => context.push('/body-metrics'),
                    ),
                    _ActionButton(
                      icon: Icons.emoji_events,
                      label: 'Challenges',
                      onPressed: () => context.push('/challenges'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Atlas Fitness')),
        drawer: const AppDrawer(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: const Text('Atlas Fitness')),
        drawer: const AppDrawer(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off, size: 64, color: Colors.orange),
                const SizedBox(height: 16),
                const Text(
                  'Connection Issue',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString().contains('unavailable') 
                    ? 'Unable to connect to the server. Please check your internet connection and try again.'
                    : 'Error loading user data. Please try again.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    // Trigger a refresh by invalidating the provider
                    ref.invalidate(currentUserProvider);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 56) / 2,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
