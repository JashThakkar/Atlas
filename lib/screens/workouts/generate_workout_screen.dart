import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/fitness_provider.dart';
import '../../core/constants.dart';

class GenerateWorkoutScreen extends ConsumerStatefulWidget {
  const GenerateWorkoutScreen({super.key});

  @override
  ConsumerState<GenerateWorkoutScreen> createState() =>
      _GenerateWorkoutScreenState();
}

class _GenerateWorkoutScreenState extends ConsumerState<GenerateWorkoutScreen> {
  String _selectedDifficulty = 'Beginner';
  String? _selectedMuscle;
  int _exerciseCount = 5;
  bool _isGenerating = false;

  final List<String> _muscleGroups = [
    'chest',
    'back',
    'legs',
    'shoulders',
    'arms',
    'abs',
    'full_body',
  ];

  Future<void> _generateWorkout() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    setState(() => _isGenerating = true);

    try {
      final exerciseAPI = ref.read(exerciseAPIServiceProvider);
      final workout = await exerciseAPI.generateWorkout(
        userId: user.uid,
        difficulty: _selectedDifficulty,
        targetMuscle: _selectedMuscle,
        exerciseCount: _exerciseCount,
      );

      final fitnessService = ref.read(fitnessServiceProvider);
      final workoutId = await fitnessService.createWorkout(workout);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout generated successfully!')),
        );
        context.go('/workouts/$workoutId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Workout'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customize Your Workout',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            
            // Difficulty Selection
            Text(
              'Difficulty Level',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: AppConstants.difficultyLevels
                  .map((level) => ButtonSegment<String>(
                        value: level,
                        label: Text(level),
                      ))
                  .toList(),
              selected: {_selectedDifficulty},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() => _selectedDifficulty = newSelection.first);
              },
            ),
            const SizedBox(height: 24),
            
            // Muscle Group Selection
            Text(
              'Target Muscle (Optional)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _muscleGroups.map((muscle) {
                final isSelected = _selectedMuscle == muscle;
                return ChoiceChip(
                  label: Text(muscle.toUpperCase()),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedMuscle = selected ? muscle : null;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            
            // Exercise Count
            Text(
              'Number of Exercises: $_exerciseCount',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              value: _exerciseCount.toDouble(),
              min: 3,
              max: 10,
              divisions: 7,
              label: _exerciseCount.toString(),
              onChanged: (value) {
                setState(() => _exerciseCount = value.toInt());
              },
            ),
            const SizedBox(height: 32),
            
            // Generate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateWorkout,
                icon: _isGenerating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_isGenerating ? 'Generating...' : 'Generate Workout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
