import 'package:cloud_firestore/cloud_firestore.dart';

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
      exerciseName: map['exerciseName'] ?? '',
      sets: map['sets'] ?? 3,
      reps: map['reps'] ?? 10,
      notes: map['notes'],
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
  final int? intensityRating; // 1-5 rating user provides after workout
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
  
  factory WorkoutModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkoutModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      workoutName: data['workoutName'] ?? '',
      difficulty: data['difficulty'] ?? 'Beginner',
      exercises: (data['exercises'] as List<dynamic>?)
              ?.map((ex) => WorkoutExercise.fromMap(ex as Map<String, dynamic>))
              .toList() ??
          [],
      durationMinutes: data['durationMinutes'],
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      intensityRating: data['intensityRating'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'workoutName': workoutName,
      'difficulty': difficulty,
      'exercises': exercises.map((ex) => ex.toMap()).toList(),
      'durationMinutes': durationMinutes,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'intensityRating': intensityRating,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
  
  bool get isCompleted => completedAt != null;
}
