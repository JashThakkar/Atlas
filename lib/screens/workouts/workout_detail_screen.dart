import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/workout_model.dart';
import '../../providers/fitness_provider.dart';
import '../../services/database_service.dart';

final _sqliteDb = DatabaseService();

final workoutDetailProvider = StreamProvider.family<WorkoutModel?, String>((ref, workoutId) async* {
  Future<WorkoutModel?> query() async {
    final db = await _sqliteDb.database;
    final rows = await db.query(
      'workouts',
      where: 'id = ?',
      whereArgs: [workoutId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return WorkoutModel.fromMap(rows.first);
  }

  yield await query();
  await for (final _ in _sqliteDb.watchTable('workouts')) {
    yield await query();
  }
});

class WorkoutDetailScreen extends ConsumerStatefulWidget {
  const WorkoutDetailScreen({super.key, required this.workoutId});

  final String workoutId;

  @override
  ConsumerState<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends ConsumerState<WorkoutDetailScreen> {
  int? _intensityRating;
  int? _durationMinutes;

  Future<void> _completeWorkout() async {
    if (_intensityRating == null || _durationMinutes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide intensity rating and duration')),
      );
      return;
    }

    // Read userId from the already-loaded workout provider (no extra network call).
    final workout =
        ref.read(workoutDetailProvider(widget.workoutId)).value;
    if (workout == null) return;

    try {
      final fitnessService = ref.read(fitnessServiceProvider);
      await fitnessService.completeWorkout(
        widget.workoutId,
        _intensityRating!,
        _durationMinutes!,
        userId: workout.userId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout completed! 🎉')),
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/workouts');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutAsync = ref.watch(workoutDetailProvider(widget.workoutId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Details'),
      ),
      body: workoutAsync.when(
        data: (workout) {
          if (workout == null) {
            return const Center(child: Text('Workout not found'));
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout.workoutName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Chip(label: Text(workout.difficulty)),
                      if (workout.isCompleted) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 8),
                            const Text('Completed'),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Exercises List
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Exercises',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      ...workout.exercises.asMap().entries.map((entry) {
                        final index = entry.key;
                        final exercise = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text('${index + 1}'),
                            ),
                            title: Text(exercise.exerciseName),
                            subtitle: Text('${exercise.sets} sets × ${exercise.reps} reps'),
                            trailing: exercise.notes != null
                                ? IconButton(
                                    icon: const Icon(Icons.info_outline),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text(exercise.exerciseName),
                                          content: Text(exercise.notes!),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Close'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  )
                                : null,
                          ),
                        );
                      }),
                      
                      if (!workout.isCompleted) ...[
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),
                        
                        // Complete Workout Form
                        Text(
                          'Complete Workout',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        
                        // Intensity Rating
                        Text('How intense was the workout?'),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(5, (index) {
                            final rating = index + 1;
                            return ChoiceChip(
                              label: Text('$rating'),
                              selected: _intensityRating == rating,
                              onSelected: (selected) {
                                setState(() => _intensityRating = rating);
                              },
                            );
                          }),
                        ),
                        const SizedBox(height: 16),
                        
                        // Duration
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Duration (minutes)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            _durationMinutes = int.tryParse(value);
                          },
                        ),
                        const SizedBox(height: 24),
                        
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _completeWorkout,
                            icon: const Icon(Icons.check),
                            label: const Text('Complete Workout'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
