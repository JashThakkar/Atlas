import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/fitness_provider.dart';
import '../../models/exercise_log_model.dart';

class ExerciseLoggerScreen extends ConsumerStatefulWidget {
  const ExerciseLoggerScreen({super.key});

  @override
  ConsumerState<ExerciseLoggerScreen> createState() => _ExerciseLoggerScreenState();
}

class _ExerciseLoggerScreenState extends ConsumerState<ExerciseLoggerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _exerciseNameController = TextEditingController();
  final _notesController = TextEditingController();
  final List<ExerciseSet> _sets = [];
  
  void _addSet() {
    setState(() {
      _sets.add(ExerciseSet(
        setNumber: _sets.length + 1,
        reps: 10,
        weight: null,
      ));
    });
  }
  
  void _removeSet(int index) {
    setState(() {
      _sets.removeAt(index);
      // Renumber sets
      for (int i = 0; i < _sets.length; i++) {
        _sets[i] = ExerciseSet(
          setNumber: i + 1,
          reps: _sets[i].reps,
          weight: _sets[i].weight,
        );
      }
    });
  }
  
  Future<void> _saveExercise() async {
    if (!_formKey.currentState!.validate() || _sets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one set')),
      );
      return;
    }
    
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    
    try {
      final exerciseLog = ExerciseLogModel(
        userId: user.uid,
        exerciseName: _exerciseNameController.text.trim(),
        sets: _sets,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        date: DateTime.now(),
      );
      
      final fitnessService = ref.read(fitnessServiceProvider);
      await fitnessService.addExerciseLog(exerciseLog);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exercise logged successfully!')),
        );
        Navigator.of(context).pop();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Exercise'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveExercise,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _exerciseNameController,
                decoration: const InputDecoration(
                  labelText: 'Exercise Name',
                  hintText: 'e.g., Bench Press',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter exercise name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sets',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton.icon(
                    onPressed: _addSet,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Set'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              if (_sets.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(Icons.fitness_center, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No sets added yet',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _addSet,
                          icon: const Icon(Icons.add),
                          label: const Text('Add First Set'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._sets.asMap().entries.map((entry) {
                  final index = entry.key;
                  final set = entry.value;
                  return _SetRow(
                    set: set,
                    onRepsChanged: (reps) {
                      setState(() {
                        _sets[index] = ExerciseSet(
                          setNumber: set.setNumber,
                          reps: reps,
                          weight: set.weight,
                        );
                      });
                    },
                    onWeightChanged: (weight) {
                      setState(() {
                        _sets[index] = ExerciseSet(
                          setNumber: set.setNumber,
                          reps: set.reps,
                          weight: weight,
                        );
                      });
                    },
                    onRemove: () => _removeSet(index),
                  );
                }),
              
              const SizedBox(height: 24),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Any additional notes...',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.set,
    required this.onRepsChanged,
    required this.onWeightChanged,
    required this.onRemove,
  });

  final ExerciseSet set;
  final Function(int) onRepsChanged;
  final Function(double?) onWeightChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              child: Text('${set.setNumber}'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Reps',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(text: set.reps.toString())
                        ..selection = TextSelection.collapsed(offset: set.reps.toString().length),
                      onChanged: (value) {
                        final reps = int.tryParse(value) ?? 0;
                        onRepsChanged(reps);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(text: set.weight?.toString() ?? '')
                        ..selection = TextSelection.collapsed(
                            offset: (set.weight?.toString() ?? '').length),
                      onChanged: (value) {
                        final weight = double.tryParse(value);
                        onWeightChanged(weight);
                      },
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
