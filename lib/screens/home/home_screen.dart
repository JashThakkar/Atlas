import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/workout_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/fitness_provider.dart';
import '../../providers/music_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/spotify_player_sheet.dart';
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
        final workoutsAsync = ref.watch(userWorkoutsProvider(user.uid));
        final spotify = ref.watch(spotifyServiceProvider);
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Atlas Fitness'),
            actions: [
              IconButton(
                icon: const Icon(Icons.message),
                onPressed: () => context.push('/messages'),
                tooltip: 'Messages',
              ),
            ],
          ),
          drawer: const AppDrawer(),
          // ── Spotify floating music button ────────────────────────────────
          floatingActionButton: FloatingActionButton(
            heroTag: 'spotify_fab',
            backgroundColor: spotify.isPlaying
                ? const Color(0xFF1DB954) // Spotify green when playing
                : null,
            foregroundColor: spotify.isPlaying ? Colors.white : null,
            onPressed: () => showSpotifyPlayerSheet(context),
            tooltip: 'Music Player',
            child: spotify.isPlaying
                ? const Icon(Icons.music_note)
                : const Icon(Icons.music_note_outlined),
          ),
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
                    childAspectRatio: 1.3,
                    children: [
                      _StatCard(
                        icon: Icons.fitness_center,
                        label: 'Workouts',
                        value: stats['totalWorkouts'].toString(),
                        color: Colors.blue,
                        onTap: () => context.push('/workouts'),
                      ),
                      _StatCard(
                        icon: Icons.list_alt,
                        label: 'Exercises',
                        value: stats['totalExercises'].toString(),
                        color: Colors.green,
                        onTap: () => context.push('/exercise-history'),
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
                        onTap: () => showModalBottomSheet<void>(
                          context: context,
                          builder: (_) => _BadgesSheet(badges: user.badges),
                        ),
                      ),
                    ],
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Text('Error loading stats'),
                ),
                const SizedBox(height: 24),

                // Recent Workouts
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Workouts',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () => context.push('/workouts'),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                workoutsAsync.when(
                  data: (workouts) {
                    if (workouts.isEmpty) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(Icons.fitness_center,
                                  color: Colors.grey[400]),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'No workouts yet. Generate one to get started!',
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    final recent = workouts.take(3).toList();
                    return Column(
                      children: recent
                          .map((w) => _RecentWorkoutTile(workout: w))
                          .toList(),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Text('Error loading workouts'),
                ),

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
                    _ActionButton(
                      icon: Icons.timer,
                      label: 'Quick Workout',
                      onPressed: () => context.push('/quick-workout'),
                    ),
                    _ActionButton(
                      icon: Icons.group,
                      label: 'Circles',
                      onPressed: () => context.push('/circles'),
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
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
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
      ),
    );
  }
}

class _RecentWorkoutTile extends StatelessWidget {
  const _RecentWorkoutTile({required this.workout});

  final WorkoutModel workout;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => context.push('/workouts/${workout.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: workout.isCompleted
                    ? Colors.green.shade100
                    : Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  workout.isCompleted
                      ? Icons.check_circle
                      : Icons.fitness_center,
                  color: workout.isCompleted
                      ? Colors.green
                      : Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.workoutName,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${workout.difficulty} · ${workout.exercises.length} exercises',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat.MMMd().format(
                  workout.completedAt ?? workout.createdAt,
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgesSheet extends StatelessWidget {
  const _BadgesSheet({required this.badges});

  final List<String> badges;

  String _formatBadgeLabel(String badgeId) {
    return badgeId
        .replaceAll('_', ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your Badges',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (badges.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(Icons.emoji_events,
                        size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'No badges earned yet.\nComplete workouts to earn them!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: badges.map((badgeId) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.amber, width: 2),
                        ),
                        child: const Icon(
                          Icons.emoji_events,
                          size: 36,
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 80,
                        child: Text(
                          _formatBadgeLabel(badgeId),
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            const SizedBox(height: 8),
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
      width: (MediaQuery.of(context).size.width - 44) / 2,
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
