import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/workout_model.dart';
import '../../providers/fitness_provider.dart';
import '../../providers/circle_provider.dart';
import '../../core/constants.dart';

final workoutDetailProvider = StreamProvider.family<WorkoutModel?, String>((ref, workoutId) {
  return FirebaseFirestore.instance
      .collection(AppConstants.workoutsCollection)
      .doc(workoutId)
      .snapshots()
      .map((doc) => doc.exists ? WorkoutModel.fromFirestore(doc) : null);
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

      // Award activity points in all circles the user belongs to.
      // Best-effort: a failure here should not block the workout completion flow.
      try {
        final circleService = ref.read(circleServiceProvider);
        await circleService.incrementActivityScore(workout.userId);
      } catch (_) {}

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
                        return _ExerciseCard(index: index, exercise: exercise);
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

/// Card widget that displays a single exercise with optional image and video link.
class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.index, required this.exercise});

  final int index;
  final WorkoutExercise exercise;

  Future<void> _openVideo(BuildContext context) async {
    final url = Uri.parse(exercise.videoUrl!);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open video')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise image
          if (exercise.imageUrl != null)
            CachedNetworkImage(
              imageUrl: exercise.imageUrl!,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 180,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                height: 120,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Center(
                  child: Icon(Icons.fitness_center, size: 48),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  child: Text('${index + 1}'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.exerciseName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text('${exercise.sets} sets × ${exercise.reps} reps'),
                    ],
                  ),
                ),
                // Info button for notes
                if (exercise.notes != null && exercise.notes!.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    tooltip: 'Instructions',
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
                  ),
              ],
            ),
          ),

          // Watch Video button
          if (exercise.videoUrl != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: OutlinedButton.icon(
                onPressed: () => _openVideo(context),
                icon: const Icon(Icons.play_circle_outline, size: 18),
                label: const Text('Watch Video'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
