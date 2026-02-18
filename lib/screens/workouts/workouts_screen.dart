import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/fitness_provider.dart';
import '../../models/workout_model.dart';
import 'package:intl/intl.dart';

class WorkoutsScreen extends ConsumerWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Workouts'),
      ),
      body: currentUserAsync.when(
        data: (user) {
          if (user == null) return const SizedBox();
          
          final workoutsAsync = ref.watch(userWorkoutsProvider(user.uid));
          
          return workoutsAsync.when(
            data: (workouts) {
              if (workouts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.fitness_center, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No workouts yet',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text('Generate a workout to get started!'),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => context.push('/generate-workout'),
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Generate Workout'),
                      ),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: workouts.length,
                itemBuilder: (context, index) {
                  final workout = workouts[index];
                  return _WorkoutCard(workout: workout);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error loading user')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/generate-workout'),
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Generate'),
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({required this.workout});

  final WorkoutModel workout;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/workouts/${workout.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      workout.workoutName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  if (workout.isCompleted)
                    const Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Chip(
                    label: Text(workout.difficulty),
                    avatar: const Icon(Icons.trending_up, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text('${workout.exercises.length} exercises'),
                ],
              ),
              if (workout.isCompleted) ...[
                const SizedBox(height: 8),
                Text(
                  'Completed: ${DateFormat.yMMMd().format(workout.completedAt!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (workout.durationMinutes != null)
                  Text(
                    'Duration: ${workout.durationMinutes} minutes',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
