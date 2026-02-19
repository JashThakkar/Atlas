import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/exercise_log_model.dart';
import '../services/exercise_service.dart';

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({Key? key}) : super(key: key);

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  final _exerciseController = TextEditingController();
  final _durationController = TextEditingController();
  final ExerciseService _exerciseService = ExerciseService();
  final uuid = const Uuid();

  void _addExercise() async {
    if (_exerciseController.text.isEmpty ||
        _durationController.text.isEmpty) {
      return;
    }

    final newExercise = ExerciseLog(
      id: uuid.v4(),
      exerciseName: _exerciseController.text,
      duration: int.parse(_durationController.text),
      date: DateTime.now(),
    );

    await _exerciseService.addExercise(newExercise);

    _exerciseController.clear();
    _durationController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Logger'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _exerciseController,
              decoration: const InputDecoration(
                labelText: 'Exercise Name',
              ),
            ),
            TextField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Duration (minutes)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addExercise,
              child: const Text('Add Exercise'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<List<ExerciseLog>>(
                stream: _exerciseService.getExercises(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final exercises = snapshot.data!;

                  return ListView.builder(
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = exercises[index];

                      return ListTile(
                        title: Text(exercise.exerciseName),
                        subtitle:
                            Text('${exercise.duration} minutes'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
