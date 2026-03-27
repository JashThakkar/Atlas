import 'dart:convert';

class WorkoutExercise {
  final String exerciseName;
  final int sets;
  final int reps;
  final String? notes;

  WorkoutExercise({
    required this.exerciseName,
    required this.sets,
    required this.reps,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'exerciseName': exerciseName,
      'sets': sets,
      'reps': reps,
      'notes': notes,
    };
  }

  factory WorkoutExercise.fromMap(Map<String, dynamic> map) {
    return WorkoutExercise(
      exerciseName: map['exerciseName'] as String? ?? '',
      sets: map['sets'] as int? ?? 3,
      reps: map['reps'] as int? ?? 10,
      notes: map['notes'] as String?,
    );
  }
}

class WorkoutModel {
  final String? id;
  final String userId;
  final String workoutName;
  final String difficulty;
  final List<WorkoutExercise> exercises;
  final int? durationMinutes;
  final DateTime? completedAt;
  final int? intensityRating;
  final DateTime createdAt;

  WorkoutModel({
    this.id,
    required this.userId,
    required this.workoutName,
    required this.difficulty,
    required this.exercises,
    this.durationMinutes,
    this.completedAt,
    this.intensityRating,
    required this.createdAt,
  });

  factory WorkoutModel.fromMap(Map<String, dynamic> map) {
    List<WorkoutExercise> parseExercises(dynamic raw) {
      if (raw == null) return [];
      final List<dynamic> list;
      if (raw is String) {
        list = jsonDecode(raw) as List<dynamic>;
      } else if (raw is List) {
        list = raw;
      } else {
        return [];
      }
      return list
          .map((e) => WorkoutExercise.fromMap(e as Map<String, dynamic>))
          .toList();
    }

    return WorkoutModel(
      id: map['id'] as String?,
      userId: map['userId'] as String? ?? '',
      workoutName: map['workoutName'] as String? ?? '',
      difficulty: map['difficulty'] as String? ?? 'Beginner',
      exercises: parseExercises(map['exercises']),
      durationMinutes: map['durationMinutes'] as int?,
      completedAt: map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'] as int)
          : null,
      intensityRating: map['intensityRating'] as int?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'workoutName': workoutName,
      'difficulty': difficulty,
      'exercises': jsonEncode(exercises.map((e) => e.toMap()).toList()),
      'durationMinutes': durationMinutes,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'intensityRating': intensityRating,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  bool get isCompleted => completedAt != null;
}
