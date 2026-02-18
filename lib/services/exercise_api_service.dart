import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/workout_model.dart';

class ExerciseAPIService {
  final String _apiKey = dotenv.env['EXERCISE_API_KEY'] ?? '';
  final String _baseUrl = dotenv.env['EXERCISE_API_BASE_URL'] ?? 'https://api.api-ninjas.com/v1';
  
  Future<List<Map<String, dynamic>>> searchExercises({
    String? name,
    String? type,
    String? muscle,
    String? difficulty,
  }) async {
    if (_apiKey.isEmpty) {
      // Return sample data if API key not configured
      return _getSampleExercises();
    }
    
    final queryParams = <String, String>{};
    if (name != null) queryParams['name'] = name;
    if (type != null) queryParams['type'] = type;
    if (muscle != null) queryParams['muscle'] = muscle;
    if (difficulty != null) queryParams['difficulty'] = difficulty;
    
    final uri = Uri.parse('$_baseUrl/exercises').replace(queryParameters: queryParams);
    
    try {
      final response = await http.get(
        uri,
        headers: {
          'X-Api-Key': _apiKey,
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        return _getSampleExercises();
      }
    } catch (e) {
      return _getSampleExercises();
    }
  }
  
  Future<WorkoutModel> generateWorkout({
    required String userId,
    required String difficulty,
    String? targetMuscle,
    int exerciseCount = 5,
  }) async {
    final exercises = await searchExercises(
      difficulty: difficulty.toLowerCase(),
      muscle: targetMuscle,
    );
    
    // Take random exercises from results
    final selectedExercises = (exercises..shuffle()).take(exerciseCount).toList();
    
    final workoutExercises = selectedExercises.map((ex) {
      return WorkoutExercise(
        exerciseName: ex['name'] ?? 'Exercise',
        sets: _getSetsForDifficulty(difficulty),
        reps: _getRepsForDifficulty(difficulty),
        notes: ex['instructions'] ?? '',
      );
    }).toList();
    
    return WorkoutModel(
      userId: userId,
      workoutName: 'Generated ${targetMuscle ?? "Full Body"} Workout',
      difficulty: difficulty,
      exercises: workoutExercises,
      createdAt: DateTime.now(),
    );
  }
  
  int _getSetsForDifficulty(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return 2;
      case 'intermediate':
        return 3;
      case 'advanced':
        return 4;
      default:
        return 3;
    }
  }
  
  int _getRepsForDifficulty(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return 10;
      case 'intermediate':
        return 12;
      case 'advanced':
        return 15;
      default:
        return 12;
    }
  }
  
  List<Map<String, dynamic>> _getSampleExercises() {
    return [
      {'name': 'Push-ups', 'type': 'strength', 'muscle': 'chest', 'difficulty': 'beginner'},
      {'name': 'Squats', 'type': 'strength', 'muscle': 'quadriceps', 'difficulty': 'beginner'},
      {'name': 'Lunges', 'type': 'strength', 'muscle': 'quadriceps', 'difficulty': 'beginner'},
      {'name': 'Plank', 'type': 'strength', 'muscle': 'abdominals', 'difficulty': 'beginner'},
      {'name': 'Burpees', 'type': 'cardio', 'muscle': 'full_body', 'difficulty': 'intermediate'},
      {'name': 'Bench Press', 'type': 'strength', 'muscle': 'chest', 'difficulty': 'intermediate'},
      {'name': 'Deadlift', 'type': 'strength', 'muscle': 'lower_back', 'difficulty': 'advanced'},
      {'name': 'Pull-ups', 'type': 'strength', 'muscle': 'lats', 'difficulty': 'intermediate'},
      {'name': 'Shoulder Press', 'type': 'strength', 'muscle': 'shoulders', 'difficulty': 'intermediate'},
      {'name': 'Bicep Curls', 'type': 'strength', 'muscle': 'biceps', 'difficulty': 'beginner'},
    ];
  }
}
