import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/fitness_provider.dart';
import '../../models/workout_model.dart';
import '../../services/workout_time_adjustment_service.dart';

final _timeAdjustmentService =
    WorkoutTimeAdjustmentService();

class TimeConstrainedWorkoutScreen extends ConsumerStatefulWidget {
  const TimeConstrainedWorkoutScreen({super.key});

  @override
  ConsumerState<TimeConstrainedWorkoutScreen> createState() =>
      _TimeConstrainedWorkoutScreenState();
}

// Slider range constants to avoid duplication between slider and quick-pick chips.
const int _kMinMinutes = 10;
const int _kMaxMinutes = 90;

class _TimeConstrainedWorkoutScreenState
    extends ConsumerState<TimeConstrainedWorkoutScreen> {
  int _availableMinutes = 30;
  WorkoutModel? _adjustedWorkout;
  bool _isGenerating = false;
  bool _hasAdjusted = false;

  Future<void> _generateAndAdjust() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    setState(() {
      _isGenerating = true;
      _hasAdjusted = false;
      _adjustedWorkout = null;
    });

    try {
      final exerciseAPI = ref.read(exerciseAPIServiceProvider);

      // Generate a full-length workout first.
      final baseWorkout = await exerciseAPI.generateWorkout(
        userId: user.uid,
        difficulty: 'Intermediate',
        exerciseCount: 10,
      );

      // Estimate original duration for display.
      final originalMinutes =
          _timeAdjustmentService.estimateDurationMinutes(baseWorkout);

      // Adjust to fit the time constraint.
      final adjusted = _timeAdjustmentService.adjustForTimeConstraint(
        baseWorkout,
        availableMinutes: _availableMinutes,
      );

      setState(() {
        _adjustedWorkout = adjusted;
        _hasAdjusted = adjusted.isAiAdjusted;
      });

      if (mounted) {
        if (adjusted.isAiAdjusted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Optimised from ~$originalMinutes min → ${_availableMinutes} min. '
                '${adjusted.exercises.length} exercises selected.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _saveWorkout() async {
    if (_adjustedWorkout == null) return;
    final fitnessService = ref.read(fitnessServiceProvider);
    final workoutId = await fitnessService.createWorkout(_adjustedWorkout!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workout saved!')),
      );
      context.push('/workouts/$workoutId');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Workout'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time constraint input
            Text(
              'How much time do you have?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'AI will optimise the workout to fit your schedule by prioritising '
              'compound exercises and adjusting rest intervals.',
            ),
            const SizedBox(height: 24),

            // Slider
            Row(
              children: [
                const Icon(Icons.timer_outlined),
                const SizedBox(width: 8),
                Text(
                  '$_availableMinutes min',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Slider(
              value: _availableMinutes.toDouble(),
              min: _kMinMinutes.toDouble(),
              max: _kMaxMinutes.toDouble(),
              divisions: (_kMaxMinutes - _kMinMinutes) ~/ 5,
              label: '$_availableMinutes min',
              onChanged: (v) =>
                  setState(() => _availableMinutes = v.toInt()),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('$_kMinMinutes min', style: TextStyle(fontSize: 12)),
                Text('$_kMaxMinutes min', style: TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 24),

            // Quick-pick chips
            Wrap(
              spacing: 8,
              children: [15, 20, 30, 45, 60].map((mins) {
                return ChoiceChip(
                  label: Text('$mins min'),
                  selected: _availableMinutes == mins,
                  onSelected: (s) {
                    if (s) setState(() => _availableMinutes = mins);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateAndAdjust,
                icon: _isGenerating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_fix_high),
                label: Text(_isGenerating
                    ? 'Optimising...'
                    : 'Generate & Optimise Workout'),
              ),
            ),

            // Result
            if (_adjustedWorkout != null) ...[
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),

              // AI badge
              if (_hasAdjusted)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome,
                          size: 16,
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer),
                      const SizedBox(width: 6),
                      Text(
                        'AI Optimised',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              Text(
                _adjustedWorkout!.workoutName,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${_adjustedWorkout!.exercises.length} exercises · '
                'Est. ${_adjustedWorkout!.estimatedMinutes ?? _availableMinutes} min',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),

              ..._adjustedWorkout!.exercises.asMap().entries.map((entry) {
                final idx = entry.key;
                final ex = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                        child: Text('${idx + 1}')),
                    title: Text(ex.exerciseName),
                    subtitle:
                        Text('${ex.sets} sets × ${ex.reps} reps'),
                  ),
                );
              }),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _generateAndAdjust,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Regenerate'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saveWorkout,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Workout'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
