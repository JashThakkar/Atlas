import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseSet {
  final int setNumber;
  final int reps;
  final double? weight;
  
  ExerciseSet({
    required this.setNumber,
    required this.reps,
    this.weight,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'setNumber': setNumber,
      'reps': reps,
      'weight': weight,
    };
  }
  
  factory ExerciseSet.fromMap(Map<String, dynamic> map) {
    return ExerciseSet(
      setNumber: map['setNumber'] ?? 0,
      reps: map['reps'] ?? 0,
      weight: map['weight']?.toDouble(),
    );
  }
}

class ExerciseLogModel {
  final String? id;
  final String userId;
  final String exerciseName;
  final String? category;
  final List<ExerciseSet> sets;
  final String? notes;
  final DateTime date;
  
  ExerciseLogModel({
    this.id,
    required this.userId,
    required this.exerciseName,
    this.category,
    required this.sets,
    this.notes,
    required this.date,
  });
  
  factory ExerciseLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExerciseLogModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      exerciseName: data['exerciseName'] ?? '',
      category: data['category'],
      sets: (data['sets'] as List<dynamic>?)
              ?.map((set) => ExerciseSet.fromMap(set as Map<String, dynamic>))
              .toList() ??
          [],
      notes: data['notes'],
      date: (data['date'] as Timestamp).toDate(),
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'exerciseName': exerciseName,
      'category': category,
      'sets': sets.map((set) => set.toMap()).toList(),
      'notes': notes,
      'date': Timestamp.fromDate(date),
    };
  }
  
  int get totalVolume {
    return sets.fold(0, (sum, set) => sum + (set.reps * (set.weight ?? 0)).toInt());
  }
  
  int get totalReps {
    return sets.fold(0, (sum, set) => sum + set.reps);
  }
}
