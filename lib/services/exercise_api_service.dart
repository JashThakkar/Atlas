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
      {'name': 'Push-ups', 'type': 'strength', 'muscle': 'chest', 'difficulty': 'beginner', 'instructions': 'Start in a plank position. Lower your body until your chest nearly touches the floor. Push yourself back up.'},
      {'name': 'Squats', 'type': 'strength', 'muscle': 'quadriceps', 'difficulty': 'beginner', 'instructions': 'Stand with feet shoulder-width apart. Lower your hips until thighs are parallel to the floor. Return to standing.'},
      {'name': 'Lunges', 'type': 'strength', 'muscle': 'quadriceps', 'difficulty': 'beginner', 'instructions': 'Step forward with one leg, lowering your hips until both knees are bent at 90 degrees. Alternate legs.'},
      {'name': 'Plank', 'type': 'strength', 'muscle': 'abdominals', 'difficulty': 'beginner', 'instructions': 'Hold a push-up position with your body in a straight line. Keep core tight.'},
      {'name': 'Mountain Climbers', 'type': 'cardio', 'muscle': 'abdominals', 'difficulty': 'beginner', 'instructions': 'From a plank position, alternate driving your knees toward your chest rapidly.'},
      {'name': 'Jumping Jacks', 'type': 'cardio', 'muscle': 'full_body', 'difficulty': 'beginner', 'instructions': 'Jump with legs out wide and hands overhead, then return to standing position. Repeat.'},
      {'name': 'Glute Bridge', 'type': 'strength', 'muscle': 'glutes', 'difficulty': 'beginner', 'instructions': 'Lie on your back with knees bent. Lift your hips up and squeeze glutes at the top.'},
      {'name': 'Tricep Dips', 'type': 'strength', 'muscle': 'triceps', 'difficulty': 'beginner', 'instructions': 'Place hands on a bench behind you. Lower your body by bending elbows, then push back up.'},
      {'name': 'Burpees', 'type': 'cardio', 'muscle': 'full_body', 'difficulty': 'intermediate', 'instructions': 'From standing, drop to a squat, kick feet back to plank, do a push-up, return to squat, jump up.'},
      {'name': 'Bench Press', 'type': 'strength', 'muscle': 'chest', 'difficulty': 'intermediate', 'instructions': 'Lie on bench, lower barbell to chest, press back up. Keep feet flat on floor.'},
      {'name': 'Deadlift', 'type': 'strength', 'muscle': 'lower_back', 'difficulty': 'advanced', 'instructions': 'Stand with feet hip-width, bend to grip bar, keep back straight, lift by extending hips and knees.'},
      {'name': 'Pull-ups', 'type': 'strength', 'muscle': 'lats', 'difficulty': 'intermediate', 'instructions': 'Hang from bar with overhand grip, pull yourself up until chin clears the bar, lower with control.'},
      {'name': 'Shoulder Press', 'type': 'strength', 'muscle': 'shoulders', 'difficulty': 'intermediate', 'instructions': 'Hold dumbbells at shoulder height, press overhead until arms are fully extended, lower back down.'},
      {'name': 'Bicep Curls', 'type': 'strength', 'muscle': 'biceps', 'difficulty': 'beginner', 'instructions': 'Hold dumbbells with palms forward, curl weights toward shoulders, lower with control.'},
      {'name': 'Russian Twists', 'type': 'strength', 'muscle': 'abdominals', 'difficulty': 'intermediate', 'instructions': 'Sit with knees bent, lean back slightly, twist torso side to side holding a weight.'},
      {'name': 'Box Jumps', 'type': 'plyometrics', 'muscle': 'quadriceps', 'difficulty': 'intermediate', 'instructions': 'Stand facing a box, jump onto it with both feet, step or jump back down.'},
      {'name': 'Romanian Deadlift', 'type': 'strength', 'muscle': 'hamstrings', 'difficulty': 'intermediate', 'instructions': 'Hold weights in front of thighs, hinge at hips keeping back straight, lower weights, return to standing.'},
      {'name': 'Chest Fly', 'type': 'strength', 'muscle': 'chest', 'difficulty': 'intermediate', 'instructions': 'Lie on bench with dumbbells above chest, lower arms out to sides in arc motion, return to start.'},
      {'name': 'Lat Pulldown', 'type': 'strength', 'muscle': 'lats', 'difficulty': 'beginner', 'instructions': 'Grip cable bar wider than shoulder-width, pull down to upper chest, slowly return.'},
      {'name': 'Leg Press', 'type': 'strength', 'muscle': 'quadriceps', 'difficulty': 'beginner', 'instructions': 'Sit in machine, place feet on platform hip-width, lower platform by bending knees, press back up.'},
      {'name': 'Calf Raises', 'type': 'strength', 'muscle': 'calves', 'difficulty': 'beginner', 'instructions': 'Stand on edge of step, lower heels below step level, rise up onto toes as high as possible.'},
      {'name': 'Dumbbell Row', 'type': 'strength', 'muscle': 'lats', 'difficulty': 'intermediate', 'instructions': 'Brace one hand on bench, pull dumbbell up toward hip with other arm, lower with control.'},
      {'name': 'Tricep Pushdown', 'type': 'strength', 'muscle': 'triceps', 'difficulty': 'beginner', 'instructions': 'At cable machine, push bar down keeping elbows at sides until arms are fully extended.'},
      {'name': 'Hip Thrust', 'type': 'strength', 'muscle': 'glutes', 'difficulty': 'intermediate', 'instructions': 'Shoulders on bench, barbell on hips, thrust hips upward squeezing glutes, lower and repeat.'},
      {'name': 'Face Pulls', 'type': 'strength', 'muscle': 'shoulders', 'difficulty': 'beginner', 'instructions': 'At cable machine at face height, pull rope toward face separating hands, return slowly.'},
      {'name': 'Sumo Squat', 'type': 'strength', 'muscle': 'quadriceps', 'difficulty': 'beginner', 'instructions': 'Stand with feet wider than shoulder-width, toes pointed out, squat down keeping torso upright.'},
      {'name': 'Arnold Press', 'type': 'strength', 'muscle': 'shoulders', 'difficulty': 'intermediate', 'instructions': 'Start with dumbbells at face height palms facing you, rotate and press up, reverse on way down.'},
      {'name': 'Hammer Curl', 'type': 'strength', 'muscle': 'biceps', 'difficulty': 'beginner', 'instructions': 'Hold dumbbells with neutral grip (palms facing each other), curl to shoulders, lower with control.'},
      {'name': 'Jump Rope', 'type': 'cardio', 'muscle': 'full_body', 'difficulty': 'beginner', 'instructions': 'Hold rope ends, swing overhead and jump over as it passes under feet. Maintain a steady rhythm.'},
      {'name': 'High Knees', 'type': 'cardio', 'muscle': 'full_body', 'difficulty': 'beginner', 'instructions': 'Run in place, driving each knee up toward chest as high as possible at a fast pace.'},
      {'name': 'Side Plank', 'type': 'strength', 'muscle': 'abdominals', 'difficulty': 'intermediate', 'instructions': 'Lie on side, lift hips up balancing on forearm and feet edge. Hold position with body straight.'},
      {'name': 'Leg Raises', 'type': 'strength', 'muscle': 'abdominals', 'difficulty': 'beginner', 'instructions': 'Lie on back, keep legs straight, raise them to 90 degrees, lower slowly without touching ground.'},
      {'name': 'Good Mornings', 'type': 'strength', 'muscle': 'hamstrings', 'difficulty': 'intermediate', 'instructions': 'Bar on upper back, hinge forward at hips keeping back straight until torso is parallel to floor.'},
      {'name': 'Cable Crunch', 'type': 'strength', 'muscle': 'abdominals', 'difficulty': 'beginner', 'instructions': 'Kneel at cable machine, hold rope behind head, curl torso down contracting abs.'},
      {'name': 'Incline Push-ups', 'type': 'strength', 'muscle': 'chest', 'difficulty': 'beginner', 'instructions': 'Place hands on elevated surface, perform push-up movement. Easier than standard push-ups.'},
      {'name': 'Pike Push-ups', 'type': 'strength', 'muscle': 'shoulders', 'difficulty': 'intermediate', 'instructions': 'In downward dog position, bend elbows to lower head toward floor, push back up.'},
      {'name': 'Superman', 'type': 'strength', 'muscle': 'lower_back', 'difficulty': 'beginner', 'instructions': 'Lie face down, lift arms and legs simultaneously off ground, hold briefly, lower.'},
      {'name': 'Bear Crawl', 'type': 'cardio', 'muscle': 'full_body', 'difficulty': 'intermediate', 'instructions': 'On all fours with knees slightly off ground, crawl forward moving opposite arm and leg.'},
      {'name': 'Bulgarian Split Squat', 'type': 'strength', 'muscle': 'quadriceps', 'difficulty': 'advanced', 'instructions': 'Rear foot elevated on bench, squat on front leg until rear knee nearly touches floor.'},
      {'name': 'Nordic Hamstring Curl', 'type': 'strength', 'muscle': 'hamstrings', 'difficulty': 'advanced', 'instructions': 'Kneel with feet anchored, lower torso toward floor slowly using hamstrings, push back up.'},
      {'name': 'Dragon Flag', 'type': 'strength', 'muscle': 'abdominals', 'difficulty': 'advanced', 'instructions': 'Grip bench behind head, raise body in straight line pivoting on upper back, lower slowly.'},
      {'name': 'Pistol Squat', 'type': 'strength', 'muscle': 'quadriceps', 'difficulty': 'advanced', 'instructions': 'Stand on one leg, squat down with other leg extended forward, return to standing.'},
      {'name': 'Handstand Push-ups', 'type': 'strength', 'muscle': 'shoulders', 'difficulty': 'advanced', 'instructions': 'In handstand against wall, lower head toward ground by bending elbows, press back up.'},
      {'name': 'Muscle-up', 'type': 'strength', 'muscle': 'lats', 'difficulty': 'advanced', 'instructions': 'From pull-up position, explosively pull high enough to transition above the bar, push up.'},
      {'name': 'Turkish Get-up', 'type': 'strength', 'muscle': 'full_body', 'difficulty': 'advanced', 'instructions': 'Lying down with kettlebell held overhead, stand up while keeping weight overhead, reverse.'},
      {'name': 'Thruster', 'type': 'strength', 'muscle': 'full_body', 'difficulty': 'intermediate', 'instructions': 'Front squat into a push press. Squat with bar at shoulders, use momentum to press overhead.'},
      {'name': 'Snatch', 'type': 'olympic', 'muscle': 'full_body', 'difficulty': 'advanced', 'instructions': 'Lift barbell from floor to overhead in one explosive movement with wide grip.'},
      {'name': 'Battle Ropes', 'type': 'cardio', 'muscle': 'full_body', 'difficulty': 'intermediate', 'instructions': 'Hold rope ends, create waves by moving arms up and down alternately or simultaneously.'},
      {'name': 'Farmer Walk', 'type': 'strength', 'muscle': 'full_body', 'difficulty': 'beginner', 'instructions': 'Hold heavy weights at sides, walk with controlled steps maintaining upright posture.'},
      {'name': 'Sled Push', 'type': 'cardio', 'muscle': 'full_body', 'difficulty': 'intermediate', 'instructions': 'Push weighted sled across floor, driving with legs, keeping body at angle.'},
    ];
  }
}
